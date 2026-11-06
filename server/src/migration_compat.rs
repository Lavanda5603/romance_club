// Exact SurrealDB 3 -> 4 equivalents. The applied legacy checksum is retained.
// Source: pon at 752904ef34170ca44cae79da44ad03f1405c37b5.
// Each pair also pins the current file: later edits still fail validation.
const UPGRADES: &[(&str, &str, &str)] = &[
    (
        "011_scene_next.surql",
        "8376a53c8d8b127f2c4a6f0a464ba85fa3f93b341e53e23d666b1190932bcbef",
        "0830253f97f9911e6d31074287a4a17eebfd92201f75532a82710f767ab59f44",
    ),
    (
        "012_player_admin.surql",
        "af409acd71da83a6bd5f31d4f39de8eb6334908b5e973ce04d99f02470fa9f00",
        "0cb0feda4fc7d21ea8a53c706ab24fd449496443bc7bfce7d7b1cab6e861c215",
    ),
    (
        "014_progress_atomic.surql",
        "f63ac0dbeb155865d905600108a1d4e89375e772ab56065414f40bcf83bc878d",
        "26807b373ca039f2fbb92cebb76006a30d9ae95f5430e079ea17b04620fc8e87",
    ),
    (
        "016_progress_completed.surql",
        "a33d3f12cbff34f9e24156f1439737cdc8ba27f0d9a8f55a58880eaed7a33b37",
        "3e8abcacb9a02db8480edbc9909bff2d9677b25b283c36123d064e21c1a3fed1",
    ),
    (
        "017_episode_completion.surql",
        "cec1369db55f3d32d5593dbd5b6cd541c6bdd0cf7d1e2f57de858d895c383a11",
        "4a98f7a347b44d59078fdd562aaddcf6fa955b68a0922bbf1a268dc5227fdadb",
    ),
    (
        "018_asset_bytes.surql",
        "38666c1fcfe909f40066c02c0c87c7008f56c932342f1e26fd5d7eeab061709d",
        "584afd3e575f122a036c4944a0995a332ab0b0e642d9da68e98283c56d483773",
    ),
];

pub(super) fn accepts(name: &str, recorded: &str, current: &str) -> bool {
    UPGRADES.iter().any(|&(file, previous, expected)|
        file == name && previous == recorded && expected == current)
}
