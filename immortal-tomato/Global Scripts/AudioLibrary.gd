extends Node


# ===========================================================
# AUDIO LIBRARY
#
# Responsibilities:
#
# - Define identifiers for audio assets
# - Store asset paths
# - Store optional metadata
# - Cache loaded AudioStreams
# - Provide convenient functions for Audio.gd
#
# This script is intentionally a CLEAN TEMPLATE.
#
# There are no project-specific audio files here.
# ===========================================================


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


# ===========================================================
# MUSIC
# ===========================================================

enum Music{
	NONE,
}

	# Add project music here.
	#
	# EXAMPLE:
	#
	# MENU,
	# GAMEPLAY,
	# BOSS,


const MUSIC_PATHS: Dictionary = {
	# Add entries here.
	#
	# Music.MENU: "res://path/to/menu.ogg",
}


const MUSIC_METADATA: Dictionary = {
	# Optional.
	#
	# Example:
	#
	# Music.MENU: {
	#     "default_volume_db": 0.0,
	#     "default_pitch": 1.0,
	# },
}


# ===========================================================
# ONE-SHOT SFX
# ===========================================================

enum SFX{
	NONE,
	SELECT_NEW_TARGET_MOUSE,
	SELECT_NEW_TARGET_INVALID_LOCATION_MOUSE,
	END_SELECT_UNIT_SOUND,
	START_SELECT_UNIT_SOUND,
}

	# Add project SFX here.
	#
	# EXAMPLE:
	#
	# BUTTON_CLICK,
	# PLAYER_HIT,
	# EXPLOSION,


const SFX_PATHS: Dictionary = {
	SFX.SELECT_NEW_TARGET_MOUSE: "res://Assets/Audio/Sounds/select_new_target.wav",
	SFX.SELECT_NEW_TARGET_INVALID_LOCATION_MOUSE: "res://Assets/Audio/Sounds/select_new_target_invalid.wav",
	#SFX.END_SELECT_UNIT_SOUND: "res://Assets/Audio/Sounds/end_select_units_sound.wav",
	SFX.END_SELECT_UNIT_SOUND: "res://Assets/Audio/Sounds/unit_select_started.wav",
	SFX.START_SELECT_UNIT_SOUND: "res://Assets/Audio/Sounds/unit_select_started.wav",
	# Add entries here.
}


const SFX_METADATA: Dictionary = {
	SFX.SELECT_NEW_TARGET_MOUSE: {
		 "default_volume_db": -15.0,
		 "default_pitch": 1.0,
		 "priority": 5,
	},
	SFX.SELECT_NEW_TARGET_INVALID_LOCATION_MOUSE: {
		 "default_volume_db": 0.0,
		 "default_pitch": 1.0,
		 "priority": 5,
	},
	SFX.END_SELECT_UNIT_SOUND: {
		 "default_volume_db": -5.0,
		 "default_pitch": 0.9,
		 "priority": 5,
	},
	SFX.START_SELECT_UNIT_SOUND: {
		 "default_volume_db": -5.0,
		 "default_pitch": 0.6,
		 "priority": 5,
	},
	# Optional.
	#
	# Example:
	#
	# SFX.EXPLOSION: {
	#     "default_volume_db": 0.0,
	#     "default_pitch": 1.0,
	#     "priority": 5,
	# },
}


# ===========================================================
# PERSISTENT / LOOPING SFX
# ===========================================================

enum PersistentSFX{
	NONE,
		
}

	# Add project persistent sounds here.
	#
	# EXAMPLE:
	#
	# ENGINE,
	# FIRE,
	# AMBIENCE,


const PERSISTENT_SFX_PATHS: Dictionary = {
	# Add entries here.
}


const PERSISTENT_SFX_METADATA: Dictionary = {
	# Optional.
}


# ===========================================================
# CACHES
# ===========================================================

var _music_cache: Dictionary = {}
var _sfx_cache: Dictionary = {}
var _persistent_sfx_cache: Dictionary = {}


# ===========================================================
# MUSIC
# ===========================================================

func get_music(
	music: Music
) -> AudioStream:
	if music == Music.NONE:
		return null

	if not MUSIC_PATHS.has(music):
		push_warning(
			"No path registered for music: %s"
			% str(music)
		)

		return null

	if not _music_cache.has(music):
		var path: String = MUSIC_PATHS[music]
		var stream := load(path) as AudioStream

		if stream == null:
			push_warning(
				"Failed to load music: %s"
				% path
			)

			return null

		_music_cache[music] = stream

	return _music_cache[music]


func get_music_metadata(
	music: Music
) -> Dictionary:
	return MUSIC_METADATA.get(
		music,
		{}
	)


func get_music_default_volume_db(
	music: Music
) -> float:
	return get_music_metadata(music).get(
		"default_volume_db",
		0.0
	)


func get_music_default_pitch(
	music: Music
) -> float:
	return get_music_metadata(music).get(
		"default_pitch",
		1.0
	)


# ===========================================================
# SFX
# ===========================================================

func get_sfx(
	sfx: SFX
) -> AudioStream:
	if sfx == SFX.NONE:
		return null

	if not SFX_PATHS.has(sfx):
		push_warning(
			"No path registered for SFX: %s"
			% str(sfx)
		)

		return null

	if not _sfx_cache.has(sfx):
		var path: String = SFX_PATHS[sfx]
		var stream := load(path) as AudioStream

		if stream == null:
			push_warning(
				"Failed to load SFX: %s"
				% path
			)

			return null

		_sfx_cache[sfx] = stream

	return _sfx_cache[sfx]


func get_sfx_metadata(
	sfx: SFX
) -> Dictionary:
	return SFX_METADATA.get(
		sfx,
		{}
	)


func get_sfx_default_volume_db(
	sfx: SFX
) -> float:
	return get_sfx_metadata(sfx).get(
		"default_volume_db",
		0.0
	)


func get_sfx_default_pitch(
	sfx: SFX
) -> float:
	return get_sfx_metadata(sfx).get(
		"default_pitch",
		1.0
	)


func get_sfx_priority(
	sfx: SFX
) -> int:
	return get_sfx_metadata(sfx).get(
		"priority",
		0
	)


# ===========================================================
# PERSISTENT SFX
# ===========================================================

func get_persistent_sfx(
	sfx: PersistentSFX
) -> AudioStream:
	if sfx == PersistentSFX.NONE:
		return null

	if not PERSISTENT_SFX_PATHS.has(sfx):
		push_warning(
			"No path registered for persistent SFX: %s"
			% str(sfx)
		)

		return null

	if not _persistent_sfx_cache.has(sfx):
		var path: String = PERSISTENT_SFX_PATHS[sfx]
		var stream := load(path) as AudioStream

		if stream == null:
			push_warning(
				"Failed to load persistent SFX: %s"
				% path
			)

			return null

		_persistent_sfx_cache[sfx] = stream

	return _persistent_sfx_cache[sfx]


func get_persistent_sfx_metadata(
	sfx: PersistentSFX
) -> Dictionary:
	return PERSISTENT_SFX_METADATA.get(
		sfx,
		{}
	)


func get_persistent_sfx_default_volume_db(
	sfx: PersistentSFX
) -> float:
	return get_persistent_sfx_metadata(sfx).get(
		"default_volume_db",
		0.0
	)


func get_persistent_sfx_default_pitch(
	sfx: PersistentSFX
) -> float:
	return get_persistent_sfx_metadata(sfx).get(
		"default_pitch",
		1.0
	)


# ===========================================================
# CONVENIENCE FUNCTIONS
#
# These bridge the Library and Audio manager.
# ===========================================================

func play_sfx(
	sfx: SFX,
	volume_modifier_db: float = 0.0,
	pitch_modifier: float = 1.0,
	bus_name: StringName = &""
) -> int:
	var stream := get_sfx(sfx)

	if stream == null:
		return -1

	var volume_db := (
		get_sfx_default_volume_db(sfx)
		+ volume_modifier_db
	)

	var pitch := (
		get_sfx_default_pitch(sfx)
		* pitch_modifier
	)

	var priority := get_sfx_priority(sfx)

	return Audio.play_sfx(
		stream,
		volume_db,
		pitch,
		priority,
		bus_name
	)


func play_random_sfx(
	sfx_array: Array[SFX],
	volume_modifier_db: float = 0.0,
	pitch_modifier: float = 1.0,
	bus_name: StringName = &""
) -> int:
	if sfx_array.is_empty():
		push_warning(
			"Cannot play random SFX from an empty array."
		)

		return -1

	return play_sfx(
		sfx_array.pick_random(),
		volume_modifier_db,
		pitch_modifier,
		bus_name
	)


func play_persistent_sfx(
	sfx: PersistentSFX,
	key: StringName = &"",
	volume_modifier_db: float = 0.0,
	pitch_modifier: float = 1.0,
	restart_if_existing: bool = false
) -> int:
	var stream := get_persistent_sfx(sfx)

	if stream == null:
		return -1

	var volume_db := (
		get_persistent_sfx_default_volume_db(sfx)
		+ volume_modifier_db
	)

	var pitch := (
		get_persistent_sfx_default_pitch(sfx)
		* pitch_modifier
	)

	return Audio.play_persistent_sfx(
		stream,
		key,
		volume_db,
		pitch,
		&"",
		restart_if_existing
	)


func play_music(
	music: Music,
	fade_time: float = -1.0,
	resume: bool = false,
	volume_modifier_db: float = 0.0,
	pitch_modifier: float = 1.0
) -> void:
	var stream := get_music(music)

	if stream == null:
		return

	var volume_db := (
		get_music_default_volume_db(music)
		+ volume_modifier_db
	)

	var pitch := (
		get_music_default_pitch(music)
		* pitch_modifier
	)

	var track_key := StringName(
		str(music)
	)

	Audio.play_music(
		track_key,
		stream,
		fade_time,
		resume,
		volume_db,
		pitch
	)
