extends Node
## Versioned profile persistence. The save is a JSON envelope:
##   {"version": N, "timestamp": ..., "profile": {...}}
## Extensibility rules baked in:
## - every read uses .get(key, default), so new fields never break old saves;
## - stats are stored by NAME, so new stats are additive;
## - bump SAVE_VERSION + add a step in _migrate() when the shape changes;
## - a rolling .bak copy protects against corruption mid-write.

const SAVE_PATH := "user://profile.save"
const BACKUP_PATH := "user://profile.save.bak"
const SAVE_VERSION := 1


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(BACKUP_PATH)


func save_profile(profile: PlayerProfile) -> bool:
	if profile == null:
		return false
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(SAVE_PATH, BACKUP_PATH)
	var data := {
		"version": SAVE_VERSION,
		"timestamp": int(Time.get_unix_time_from_system()),
		"profile": profile.to_dict(),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Save failed: %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true


## Returns null when no (readable) save exists. Falls back to the backup
## if the primary file is corrupt.
func load_profile() -> PlayerProfile:
	var data := _read(SAVE_PATH)
	if data.is_empty():
		data = _read(BACKUP_PATH)
	if data.is_empty():
		return null
	data = _migrate(data)
	return PlayerProfile.from_dict(data.get("profile", {}))


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	if FileAccess.file_exists(BACKUP_PATH):
		DirAccess.remove_absolute(BACKUP_PATH)


func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		return parsed
	push_warning("Save file is corrupt: %s" % path)
	return {}


## Upgrade older saves step by step. Add one block per version bump:
##   if version < 2: ...reshape data...; version = 2
func _migrate(data: Dictionary) -> Dictionary:
	var version := int(data.get("version", 0))
	if version > SAVE_VERSION:
		push_warning("Save from a newer game version (%d); loading best-effort" % version)
	return data
