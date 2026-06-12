extends Node
## Key-based SFX playback over a small player pool. Real sounds are
## assigned in res://data/audio/sound_bank.tres; missing keys stay
## silent so the game is fully playable before audio exists.

const _BANK_PATH := "res://data/audio/sound_bank.tres"
const _POOL_SIZE := 8

var _bank: SoundBank
var _players: Array[AudioStreamPlayer] = []
var _warned: Dictionary = {}


func _ready() -> void:
	_bank = load(_BANK_PATH) as SoundBank
	for i in range(_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


func play_sfx(key: StringName) -> void:
	if _bank == null or not _bank.sounds.has(key):
		if not _warned.has(key):
			_warned[key] = true
			push_warning("SoundBank: no sound assigned for key '%s'" % key)
		return
	for player in _players:
		if not player.playing:
			player.stream = _bank.sounds[key]
			player.play()
			return
