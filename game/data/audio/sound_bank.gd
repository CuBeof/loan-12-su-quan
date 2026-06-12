class_name SoundBank
extends Resource
## Key -> AudioStream lookup. Designers assign real sounds here later;
## missing keys are silent (AudioManager warns once per key).

@export var sounds: Dictionary[StringName, AudioStream] = {}
