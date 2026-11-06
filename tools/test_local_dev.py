import importlib.util
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import zipfile

spec = importlib.util.spec_from_file_location("local_dev", Path(__file__).with_name("local_dev.py"))
dev = importlib.util.module_from_spec(spec)
spec.loader.exec_module(dev)


class RestorePreparationTests(unittest.TestCase):
    def test_utf16_dump_keeps_data_and_counts_only_top_level_records(self):
        sql = """OPTION IMPORT;
DEFINE TABLE player SCHEMAFULL;
DEFINE TABLE progress_archive SCHEMALESS;
DEFINE ACCESS asset_delete_access ON DATABASE TYPE RECORD SIGNIN (SELECT * FROM player) WITH JWT ALGORITHM HS512 KEY '[REDACTED]' WITH ISSUER KEY '[REDACTED]' DURATION FOR TOKEN 1h, FOR SESSION NONE;
INSERT [{id:player:one,login:'Иван',password_hash:'keep hash',note:'id:player:fake'}];
INSERT [{id:progress_archive:one,original:{id:player:old,snapshots:[{id:player:older}]}}];
"""
        with tempfile.TemporaryDirectory() as directory:
            source, target = Path(directory) / "source.surql", Path(directory) / "prepared.surql"
            source.write_text(sql, encoding="utf-16")
            original = source.read_bytes()
            stats = dev.prepare_source(source, target)
            restored = target.read_text(encoding="utf-8")
            self.assertEqual(stats["source_counts"], {"player": 1, "progress_archive": 1})
            self.assertEqual(stats["regenerated_internal_access_keys"], 1)
            self.assertIn("login:'Иван',password_hash:'keep hash'", restored)
            self.assertIn("original:{id:player:old", restored)
            self.assertNotIn("[REDACTED]", restored)
            self.assertNotIn("WITH JWT", restored)
            self.assertEqual(source.read_bytes(), original)

    def test_archive_paths_cannot_escape_import_directory(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            archive, output = root / "backup.zip", root / "output"
            output.mkdir()
            with zipfile.ZipFile(archive, "w") as z:
                z.writestr("../../escape.surql", "OPTION IMPORT;\n")
            source = dev.unpack_source(archive, output)
            self.assertEqual(source, output / "source.surql")
            self.assertEqual(source.read_text(), "OPTION IMPORT;\n")
            self.assertFalse((root / "escape.surql").exists())

    def test_multiple_dump_files_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with zipfile.ZipFile(root / "backup.zip", "w") as z:
                z.writestr("one.surql", "OPTION IMPORT;")
                z.writestr("two.surql", "OPTION IMPORT;")
            with self.assertRaisesRegex(ValueError, "exactly one"):
                dev.unpack_source(root / "backup.zip", root)

    def test_existing_database_is_refused_before_any_import(self):
        env = {"SURREAL_NAMESPACE": "romance_club", "SURREAL_DATABASE": "main"}
        with patch.object(dev, "query", side_effect=[[], [{"result": {"tables": {"player": "definition"}}}]]):
            with self.assertRaisesRegex(ValueError, "not empty"):
                dev.require_empty_database(env, "http://127.0.0.1:8000")

    def test_dump_cannot_switch_to_another_database(self):
        with tempfile.TemporaryDirectory() as directory:
            source, target = Path(directory) / "source.surql", Path(directory) / "prepared.surql"
            source.write_text("OPTION IMPORT;\nUSE NS other DB important;\n", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "database-only"):
                dev.prepare_source(source, target)

    def test_env_quotes_and_equals_are_retained_without_expanding_secrets(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / ".env"
            source.write_text("SURREAL_USER=root\nSURREAL_PASS='secret $literal=a#b'\n", encoding="utf-8")
            env = dev.load_env(source)
            self.assertEqual(env["SURREAL_PASS"], "secret $literal=a#b")


if __name__ == "__main__":
    unittest.main()
