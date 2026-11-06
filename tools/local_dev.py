"""Local startup and export/import migration. Python 3.10+, standard library only."""
from __future__ import annotations

import argparse
import base64
from collections import Counter
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import secrets
import shlex
import shutil
import subprocess
import sys
import urllib.request
import uuid
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ENV_FILE = ROOT / "server/.env"
IMPORTS = ROOT / "database/imports"


def load_env(path: Path = ENV_FILE) -> dict[str, str]:
    if not path.is_file():
        raise ValueError("Run init first to create server/.env")
    env = os.environ.copy()
    for line in path.read_text(encoding="utf-8-sig").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        key, value = line.removeprefix("export ").split("=", 1)
        words = shlex.split(value.strip(), comments=False)
        if len(words) > 1 or not re.fullmatch(r"[A-Za-z_][A-Za-z_0-9]*", key.strip()):
            raise ValueError("Invalid .env entry; quote values containing spaces")
        env[key.strip()] = words[0] if words else ""
    for key in ("SURREAL_USER", "SURREAL_PASS"):
        if not env.get(key):
            raise ValueError(f"Set {key} in server/.env")
    return env


def init_env() -> None:
    if not ENV_FILE.exists():
        shutil.copyfile(ROOT / "server/.env.example", ENV_FILE)
    text = ENV_FILE.read_text(encoding="utf-8-sig")
    for key in ("JWT_SECRET", "SURREAL_PASS"):
        pattern = re.compile(rf"^{key}=[ \t]*(?:''|\"\")?[ \t]*$", re.MULTILINE)
        if pattern.search(text):
            text = pattern.sub(f"{key}={secrets.token_hex(32)}", text, count=1)
        elif not re.search(rf"^{key}=", text, re.MULTILINE):
            text = text.rstrip() + f"\n{key}={secrets.token_hex(32)}\n"
    ENV_FILE.write_text(text, encoding="utf-8")
    ENV_FILE.chmod(0o600)
    print("server/.env is ready; existing nonempty credentials were retained")


def require_version(executable: str, major: int) -> None:
    result = subprocess.run([executable, "version"], check=True, capture_output=True, text=True)
    if not re.search(rf"\b{major}\.\d+\.\d+\b", result.stdout):
        raise ValueError(f"This command requires SurrealDB {major}.x; use --surreal to select its binary")


def identifier(name: str) -> str:
    if not re.fullmatch(r"[A-Za-z_][A-Za-z_0-9-]*", name):
        raise ValueError("Namespace/database names may contain letters, digits, _ and -")
    return f"`{name}`"


def query(env: dict[str, str], endpoint: str, sql: str) -> list:
    credentials = base64.b64encode((env["SURREAL_USER"] + ":" + env["SURREAL_PASS"]).encode()).decode()
    headers = {"Accept": "application/json", "Content-Type": "text/plain",
               "Authorization": "Basic " + credentials,
               "Surreal-NS": env["SURREAL_NAMESPACE"], "Surreal-DB": env["SURREAL_DATABASE"]}
    request = urllib.request.Request(endpoint.rstrip("/") + "/sql", data=sql.encode(), headers=headers)
    with urllib.request.urlopen(request, timeout=120) as response:
        results = json.load(response)
    for result in results:
        if result.get("status") != "OK":
            raise ValueError(str(result.get("result", "SQL failed"))[:300])
    return results


def table_counts(env: dict[str, str], endpoint: str, tables: list[str]) -> dict[str, int]:
    if not tables:
        return {}
    fields = ",".join(f"{identifier(t)}:array::len((SELECT VALUE id FROM {identifier(t)}))" for t in tables)
    return query(env, endpoint, "RETURN {" + fields + "};")[0]["result"]


def require_empty_database(env: dict[str, str], endpoint: str) -> None:
    ns, db = identifier(env["SURREAL_NAMESPACE"]), identifier(env["SURREAL_DATABASE"])
    query(env, endpoint, f"DEFINE NAMESPACE IF NOT EXISTS {ns}; USE NS {ns}; DEFINE DATABASE IF NOT EXISTS {db};")
    info = query(env, endpoint, "INFO FOR DB;")[0]["result"]
    if info.get("tables") or info.get("accesses") or info.get("functions"):
        raise ValueError("Target database is not empty. Choose a NEW --database; existing data was not imported over")


def unpack_source(source: Path, directory: Path) -> Path:
    if source.suffix.lower() != ".zip":
        return source
    with zipfile.ZipFile(source) as archive:
        candidates = [i for i in archive.infolist() if i.filename.lower().endswith((".surql", ".sql"))]
        if len(candidates) != 1:
            raise ValueError("ZIP must contain exactly one .surql/.sql file")
        # Never use archive member paths as filesystem paths.
        target = directory / "source.surql"
        with archive.open(candidates[0]) as src, target.open("xb") as dst:
            shutil.copyfileobj(src, dst, 1024 * 1024)
    return target


TOKEN = re.compile(r"'[^'\\]*(?:\\.[^'\\]*)*'|\"[^\"\\]*(?:\\.[^\"\\]*)*\"|`[^`]*`|[{}\[\]]|\bid:\s*\(?([A-Za-z_][A-Za-z_0-9]*):")


def prepare_source(source: Path, target: Path) -> dict:
    with source.open("rb") as file:
        prefix = file.read(4)
    encoding = "utf-16" if prefix.startswith((b"\xff\xfe", b"\xfe\xff")) else "utf-8-sig"
    tables: set[str] = set()
    counts: Counter = Counter()
    regenerated = 0
    with source.open(encoding=encoding) as src, target.open("x", encoding="utf-8", newline="\n") as dst:
        for line in src:
            if re.match(r"\s*(?:USE\b|(?:DEFINE|ALTER|REMOVE)\s+(?:NAMESPACE|DATABASE)\b)", line, re.IGNORECASE):
                raise ValueError("Expected a database-only export without namespace/database switching")
            definition = re.match(r"DEFINE TABLE (?:OVERWRITE |IF NOT EXISTS )?([A-Za-z_][A-Za-z_0-9]*)\b", line)
            if definition:
                tables.add(definition[1])
            if line.startswith("INSERT "):
                objects = arrays = 0
                for match in TOKEN.finditer(line):
                    token = match[0]
                    if match[1] and objects == 1 and arrays == 1:
                        counts[match[1]] += 1
                    elif token == "{": objects += 1
                    elif token == "}": objects -= 1
                    elif token == "[": arrays += 1
                    elif token == "]": arrays -= 1
            if line.startswith("DEFINE ACCESS asset_delete_access ") and " WITH JWT " in line:
                if " DURATION FOR TOKEN " not in line or not line.rstrip().endswith(";"):
                    raise ValueError("Unexpected asset_delete_access definition; review the source dump")
                # Exports redact signing keys. Let SurrealDB generate new keys for this internal access.
                line = line.split(" WITH JWT ", 1)[0] + " DURATION FOR TOKEN " + line.split(" DURATION FOR TOKEN ", 1)[1]
                regenerated += 1
            dst.write(line)
    for table in tables:
        counts.setdefault(table, 0)
    return {"source_counts": dict(sorted(counts.items())), "source_encoding": encoding,
            "regenerated_internal_access_keys": regenerated}


def run_logged(argv: list[str], env: dict[str, str], log: Path) -> None:
    with log.open("w", encoding="utf-8") as output:
        result = subprocess.run(argv, env=env, stdout=output, stderr=subprocess.STDOUT)
    if result.returncode:
        raise ValueError(f"Command failed (exit {result.returncode}); details: {log}. An import may be partial; do not start the app on it")


def import_v4(args, env: dict[str, str]) -> None:
    require_version(args.surreal, 4)
    source = args.source.resolve()
    if not source.is_file():
        raise ValueError("Source file does not exist")
    require_empty_database(env, args.endpoint)
    directory = IMPORTS / (datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ") + "-" + uuid.uuid4().hex[:8])
    directory.mkdir(parents=True)
    original = unpack_source(source, directory)
    prepared = directory / "prepared-v4.surql"
    manifest = prepare_source(original, prepared)
    with original.open("rb") as file:
        manifest["source_sha256"] = hashlib.file_digest(file, "sha256").hexdigest() if hasattr(hashlib, "file_digest") else file_digest(file)
    manifest.update({"source": str(source), "namespace": env["SURREAL_NAMESPACE"], "database": env["SURREAL_DATABASE"]})
    manifest_file = directory / "manifest.json"
    manifest_file.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    run_logged([args.surreal, "validate", "--json", str(prepared)], env, directory / "validate.log")
    run_logged([args.surreal, "import", "--endpoint", args.endpoint, "--namespace", env["SURREAL_NAMESPACE"],
                "--database", env["SURREAL_DATABASE"], str(prepared)], env, directory / "import.log")
    actual = table_counts(env, args.endpoint, list(manifest["source_counts"]))
    if actual != manifest["source_counts"]:
        raise ValueError(f"Restored record counts differ; inspect {manifest_file}")
    manifest["restored_counts"] = actual
    manifest["verified"] = True
    manifest_file.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(json.dumps({"verified": True, "counts": actual, "manifest": str(manifest_file)}, indent=2))
    print("Original source was retained. Set SURREAL_DATABASE in server/.env to this database before starting the app.")


def file_digest(file) -> str:
    digest = hashlib.sha256()
    for chunk in iter(lambda: file.read(1024 * 1024), b""):
        digest.update(chunk)
    return digest.hexdigest()


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("init")
    db = commands.add_parser("db")
    db.add_argument("--path", type=Path, default=ROOT / "database/local-v4")
    db.add_argument("--bind", default="127.0.0.1:8000")
    db.add_argument("--surreal", default="surreal")
    server = commands.add_parser("server")
    server.add_argument("--lan", action="store_true")
    commands.add_parser("test")
    for name in ("export-v3", "import-v4", "verify"):
        command = commands.add_parser(name)
        command.add_argument("--endpoint", default="http://127.0.0.1:8000")
        command.add_argument("--namespace")
        command.add_argument("--database")
        command.add_argument("--surreal", default="surreal")
        if name == "export-v3": command.add_argument("output", type=Path)
        if name == "import-v4": command.add_argument("source", type=Path)
    args = parser.parse_args(argv)
    if args.command == "init":
        init_env()
        return 0
    env = load_env()
    env.setdefault("SURREAL_NAMESPACE", "romance_club")
    env.setdefault("SURREAL_DATABASE", "main")
    for key in ("namespace", "database"):
        if getattr(args, key, None): env["SURREAL_" + key.upper()] = getattr(args, key)
    if args.command == "import-v4":
        import_v4(args, env)
        return 0
    if args.command == "verify":
        info = query(env, args.endpoint, "INFO FOR DB;")[0]["result"]
        print(json.dumps(table_counts(env, args.endpoint, sorted(info.get("tables", {}))), indent=2))
        return 0
    if args.command == "db":
        require_version(args.surreal, 4)
        args.path = args.path.resolve()
        args.path.parent.mkdir(parents=True, exist_ok=True)
        # Migration is through an export into NEW storage, never an in-place 3.x conversion.
        env.pop("SURREAL_EXPERIMENTAL_UPGRADE_FROM_3X", None)
        command = [args.surreal, "start", "--bind", args.bind, "surrealkv://" + args.path.as_posix()]
        cwd = ROOT
    elif args.command == "export-v3":
        require_version(args.surreal, 3)
        if args.output.exists(): raise ValueError("Export destination already exists; choose a new file")
        args.output.parent.mkdir(parents=True, exist_ok=True)
        command = [args.surreal, "export", "--endpoint", args.endpoint, "--namespace", env["SURREAL_NAMESPACE"],
                   "--database", env["SURREAL_DATABASE"], str(args.output.resolve())]
        cwd = ROOT
    else:
        if args.command == "server" and args.lan:
            env["GRPC_BIND"] = "0.0.0.0:" + env.get("GRPC_BIND", "127.0.0.1:50051").rsplit(":", 1)[1]
        command = ["cargo", "test", "--locked", "--", "--include-ignored", "--test-threads=1"] if args.command == "test" else ["cargo", "run", "--locked"]
        cwd = ROOT / "server"
    return subprocess.call(command, cwd=cwd, env=env)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        print(f"Error: {error}", file=sys.stderr)
        raise SystemExit(1)
    except KeyboardInterrupt:
        raise SystemExit(130)
