extends Node
## Global lifecycle signals only (hard cap ~15). Feature-local
## communication uses direct signals inside the feature's scene.

@warning_ignore("unused_signal")
signal battle_started
@warning_ignore("unused_signal")
signal battle_ended(player_won: bool)
@warning_ignore("unused_signal")
signal settings_changed
