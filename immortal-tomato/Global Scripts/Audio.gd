extends Node

# ===========================================================
# AUDIO MANAGER
#
# Responsibilities:
#
# - Control audio buses
# - Manage music
# - Manage one-shot SFX through a pool
# - Manage persistent / looping sounds
# - Provide pause effects
#
# This script contains no project-specific audio assets.
# ===========================================================

# ===========================================================
# CONFIGURATION
# ===========================================================

@export_category("Bus Volume")

# 1.0 = 0 dB
# 1.5 = approximately +3.52 dB
#
# This is simply the maximum allowed linear volume for
# the convenience set_bus_volume() functions.
@export var max_linear_volume: float = 1.5

@export_category("Music")

@export var default_music_fade_time: float = 0.5

@export var default_music_volume_db: float = 0.0

@export var default_music_pitch: float = 1.0

@export var music_bus: StringName = &"Music"

@export_category("One-Shot SFX")

@export var sfx_pool_size: int = 16

@export var sfx_bus: StringName = &"SFX"

@export_category("Persistent SFX")

@export var persistent_sfx_bus: StringName = &"SFX"

@export_category("Pause Effect")

@export var pause_volume_modifier_db: float = -12.0

@export var pause_pitch_multiplier: float = 0.85

@export var pause_fade_time: float = 0.3

# ===========================================================
# BUS VOLUME
# ===========================================================

var _muted_buses: Dictionary = {}

func set_bus_volume(
	bus_name: StringName,
	linear_volume: float,
	max_volume: float = -1.0
) -> void:

	var bus_index := AudioServer.get_bus_index(bus_name)

	if bus_index == -1:
		push_warning("Audio bus not found: %s" % bus_name)
		return

	var maximum := max_linear_volume

	if max_volume >= 0.0:
		maximum = max_volume

	var clamped_volume: float = clamp(
		linear_volume,
		0.0,
		maximum
	)

	AudioServer.set_bus_volume_db(
		bus_index,
		linear_to_db(clamped_volume)
	)

func get_bus_volume(
	bus_name: StringName
) -> float:

	var bus_index := AudioServer.get_bus_index(bus_name)

	if bus_index == -1:
		push_warning("Audio bus not found: %s" % bus_name)
		return 0.0

	return db_to_linear(
		AudioServer.get_bus_volume_db(bus_index)
	)

func set_bus_volume_db(
	bus_name: StringName,
	volume_db: float
) -> void:

	var bus_index := AudioServer.get_bus_index(bus_name)

	if bus_index == -1:
		push_warning("Audio bus not found: %s" % bus_name)
		return

	AudioServer.set_bus_volume_db(
		bus_index,
		volume_db
	)

func get_bus_volume_db(
	bus_name: StringName
) -> float:

	var bus_index := AudioServer.get_bus_index(bus_name)

	if bus_index == -1:
		push_warning("Audio bus not found: %s" % bus_name)
		return -80.0

	return AudioServer.get_bus_volume_db(bus_index)

func mute_bus(
	bus_name: StringName
) -> void:

	if _muted_buses.has(bus_name):
		return

	_muted_buses[bus_name] = get_bus_volume_db(bus_name)

	set_bus_volume_db(
		bus_name,
		-80.0
	)

func unmute_bus(
	bus_name: StringName
) -> void:

	if not _muted_buses.has(bus_name):
		return

	set_bus_volume_db(
		bus_name,
		_muted_buses[bus_name]
	)

	_muted_buses.erase(bus_name)

func is_bus_muted(
	bus_name: StringName
) -> bool:

	return _muted_buses.has(bus_name)

func toggle_bus_mute(
	bus_name: StringName
) -> void:

	if is_bus_muted(bus_name):
		unmute_bus(bus_name)
	else:
		mute_bus(bus_name)

# Convenience functions.

func set_master_volume(volume: float) -> void:
	set_bus_volume(&"Master", volume)

func set_music_volume(volume: float) -> void:
	set_bus_volume(&"Music", volume)

func set_sfx_volume(volume: float) -> void:
	set_bus_volume(&"SFX", volume)

func get_master_volume() -> float:
	return get_bus_volume(&"Master")

func get_music_volume() -> float:
	return get_bus_volume(&"Music")

func get_sfx_volume() -> float:
	return get_bus_volume(&"SFX")

# ===========================================================
# MUSIC
#
# Two players are used so music can truly crossfade:
#
# Player A: fades out
# Player B: fades in
#
# Then they swap roles.
# ===========================================================

var _music_players: Array[AudioStreamPlayer] = []

var _active_music_index: int = 0

var _current_music_key: StringName = &""

var _music_positions: Dictionary = {}

var _music_volume_db: float = 0.0

var _music_pitch: float = 1.0

var _music_is_paused: bool = false

var _music_transition_tween: Tween

var _music_volume_tween: Tween

var _music_pitch_tween: Tween

var _music_pause_tween: Tween

func _create_music_players() -> void:

	for i in range(2):

		var player := AudioStreamPlayer.new()

		player.bus = music_bus

		player.volume_db = -80.0

		add_child(player)

		_music_players.append(player)

func _get_active_music_player() -> AudioStreamPlayer:

	return _music_players[_active_music_index]

func _get_inactive_music_player() -> AudioStreamPlayer:

	return _music_players[1 - _active_music_index]

func is_music_playing() -> bool:

	for player in _music_players:

		if player.playing:
			return true

	return false

func get_current_music_key() -> StringName:

	return _current_music_key

func get_music_playback_position() -> float:

	if not is_music_playing():
		return 0.0

	return _get_active_music_player().get_playback_position()

func play_music(
	track_key: StringName,
	stream: AudioStream,
	fade_time: float = -1.0,
	resume: bool = false,
	volume_db: float = -999.0,
	pitch: float = -1.0
) -> void:

	if stream == null:
		push_warning("Attempted to play a null music stream.")
		return

	if (
		track_key == _current_music_key
		and _get_active_music_player().playing
	):
		return

	var actual_fade_time := default_music_fade_time

	if fade_time >= 0.0:
		actual_fade_time = fade_time

	var actual_volume := default_music_volume_db

	if volume_db != -999.0:
		actual_volume = volume_db

	var actual_pitch := default_music_pitch

	if pitch >= 0.0:
		actual_pitch = pitch

	# Save current position.
	if _current_music_key != &"":
		@warning_ignore("confusable_local_declaration")
		var old_player := _get_active_music_player()

		if old_player.playing:
			_music_positions[_current_music_key] = (
				old_player.get_playback_position()
			)

	_music_volume_db = actual_volume
	_music_pitch = actual_pitch
	_music_is_paused = false

	var start_position := 0.0

	if (
		resume
		and _music_positions.has(track_key)
	):
		start_position = _music_positions[track_key]

	var old_player := _get_active_music_player()

	var new_player := _get_inactive_music_player()

	if _music_transition_tween:
		_music_transition_tween.kill()

	new_player.stop()

	new_player.stream = stream

	new_player.pitch_scale = actual_pitch

	new_player.volume_db = -80.0

	new_player.play(start_position)

	_current_music_key = track_key

	# Immediate switch.
	if actual_fade_time <= 0.0:

		old_player.stop()

		new_player.volume_db = actual_volume

		_active_music_index = 1 - _active_music_index

		return

	# Real crossfade.
	_music_transition_tween = create_tween()

	_music_transition_tween.set_parallel(true)

	if old_player.playing:

		_music_transition_tween.tween_property(
			old_player,
			"volume_db",
			-80.0,
			actual_fade_time
		)

		_music_transition_tween.tween_callback(
			func():
				old_player.stop()
		)

	_music_transition_tween.tween_property(
		new_player,
		"volume_db",
		actual_volume,
		actual_fade_time
	)

	_music_transition_tween.finished.connect(
		func():
			_active_music_index = 1 - _active_music_index,
		CONNECT_ONE_SHOT
	)

func stop_music(
	fade_time: float = -1.0,
	save_position: bool = true
) -> void:

	if not is_music_playing():
		return

	var actual_fade_time := default_music_fade_time

	if fade_time >= 0.0:
		actual_fade_time = fade_time

	var player := _get_active_music_player()

	if (
		save_position
		and _current_music_key != &""
	):
		_music_positions[_current_music_key] = (
			player.get_playback_position()
		)

	if _music_transition_tween:
		_music_transition_tween.kill()

	if actual_fade_time <= 0.0:

		for music_player in _music_players:
			music_player.stop()

		_current_music_key = &""

		return

	_music_transition_tween = create_tween()

	_music_transition_tween.tween_property(
		player,
		"volume_db",
		-80.0,
		actual_fade_time
	)

	_music_transition_tween.tween_callback(
		func():

			player.stop()

			_current_music_key = &""
	)

func clear_music_position(
	track_key: StringName
) -> void:

	_music_positions.erase(track_key)

func clear_all_music_positions() -> void:

	_music_positions.clear()

# -----------------------------------------------------------
# MUSIC VOLUME
# -----------------------------------------------------------

func set_music_track_volume_db(
	target_volume_db: float,
	duration: float = 0.0
) -> void:

	_music_volume_db = target_volume_db

	var player := _get_active_music_player()

	var final_volume := target_volume_db

	if _music_is_paused:
		final_volume += pause_volume_modifier_db

	if _music_volume_tween:
		_music_volume_tween.kill()

	if duration <= 0.0:

		player.volume_db = final_volume

		return

	_music_volume_tween = create_tween()

	_music_volume_tween.tween_property(
		player,
		"volume_db",
		final_volume,
		duration
	)

func get_music_track_volume_db() -> float:

	return _music_volume_db

# -----------------------------------------------------------
# MUSIC PITCH
# -----------------------------------------------------------

func set_music_track_pitch(
	target_pitch: float,
	duration: float = 0.0
) -> void:

	_music_pitch = target_pitch

	var player := _get_active_music_player()

	var final_pitch := target_pitch

	if _music_is_paused:
		final_pitch *= pause_pitch_multiplier

	if _music_pitch_tween:
		_music_pitch_tween.kill()

	if duration <= 0.0:

		player.pitch_scale = final_pitch

		return

	_music_pitch_tween = create_tween()

	_music_pitch_tween.tween_property(
		player,
		"pitch_scale",
		final_pitch,
		duration
	)

func get_music_track_pitch() -> float:

	return _music_pitch

# -----------------------------------------------------------
# MUSIC PAUSE EFFECT
# -----------------------------------------------------------

func pause_music(
	fade_time: float = -1.0
) -> void:

	if not is_music_playing():
		return

	if _music_is_paused:
		return

	_music_is_paused = true

	var actual_fade_time := pause_fade_time

	if fade_time >= 0.0:
		actual_fade_time = fade_time

	var player := _get_active_music_player()

	if _music_pause_tween:
		_music_pause_tween.kill()

	_music_pause_tween = create_tween()

	_music_pause_tween.set_parallel(true)

	_music_pause_tween.tween_property(
		player,
		"volume_db",
		_music_volume_db
		+ pause_volume_modifier_db,
		actual_fade_time
	)

	_music_pause_tween.tween_property(
		player,
		"pitch_scale",
		_music_pitch
		* pause_pitch_multiplier,
		actual_fade_time
	)

func resume_music(
	fade_time: float = -1.0
) -> void:

	if not _music_is_paused:
		return

	_music_is_paused = false

	var actual_fade_time := pause_fade_time

	if fade_time >= 0.0:
		actual_fade_time = fade_time

	var player := _get_active_music_player()

	if _music_pause_tween:
		_music_pause_tween.kill()

	_music_pause_tween = create_tween()

	_music_pause_tween.set_parallel(true)

	_music_pause_tween.tween_property(
		player,
		"volume_db",
		_music_volume_db,
		actual_fade_time
	)

	_music_pause_tween.tween_property(
		player,
		"pitch_scale",
		_music_pitch,
		actual_fade_time
	)

# ===========================================================
# ONE-SHOT SFX POOL
#
# These are short-lived sounds.
#
# The players are created once and reused.
#
# Example:
#
# Pool size = 4
#
# Player 0 -> free
# Player 1 -> playing
# Player 2 -> free
# Player 3 -> playing
#
# New SFX can reuse Player 0 or Player 2.
#
# The pool does NOT create/destroy players for every sound.
# ===========================================================

class SFXInstance:

	var id: int

	var player: AudioStreamPlayer

	var priority: int

	var start_time: int

var _sfx_players: Array[AudioStreamPlayer] = []

var _sfx_instances: Dictionary = {}

var _next_sfx_id: int = 0

func _create_sfx_pool() -> void:

	for i in range(sfx_pool_size):

		var player := AudioStreamPlayer.new()

		player.bus = sfx_bus

		add_child(player)

		_sfx_players.append(player)

func _get_free_sfx_player() -> AudioStreamPlayer:

	for player in _sfx_players:

		if not player.playing:
			return player

	return null

func _find_stealable_sfx(
	new_priority: int
) -> SFXInstance:

	var selected: SFXInstance = null

	for instance in _sfx_instances.values():

		if instance.priority >= new_priority:
			continue

		if selected == null:

			selected = instance

			continue

		if instance.start_time < selected.start_time:

			selected = instance

	return selected

func _release_sfx_instance(
	instance_id: int
) -> void:

	_sfx_instances.erase(instance_id)

func play_sfx(
	stream: AudioStream,
	volume_db: float = 0.0,
	pitch: float = 1.0,
	priority: int = 0,
	bus_name: StringName = &""
) -> int:

	if stream == null:

		push_warning("Attempted to play a null SFX stream.")

		return -1

	var player := _get_free_sfx_player()

	# Pool is full.
	if player == null:

		var stealable := _find_stealable_sfx(
			priority
		)

		if stealable == null:

			return -1

		player = stealable.player

		player.stop()

		_release_sfx_instance(
			stealable.id
		)

	if bus_name != &"":
		player.bus = bus_name
	else:
		player.bus = sfx_bus

	player.stream = stream

	player.volume_db = volume_db

	player.pitch_scale = pitch

	var instance_id := _next_sfx_id

	_next_sfx_id += 1

	var instance := SFXInstance.new()

	instance.id = instance_id
	instance.player = player
	instance.priority = priority
	instance.start_time = Time.get_ticks_msec()

	_sfx_instances[instance_id] = instance

	player.play()

	player.finished.connect(
		func():
			_release_sfx_instance(instance_id),
		CONNECT_ONE_SHOT
	)

	return instance_id

func stop_sfx(
	instance_id: int
) -> void:

	if not _sfx_instances.has(instance_id):
		return

	var instance: SFXInstance = (
		_sfx_instances[instance_id]
	)

	instance.player.stop()

	_release_sfx_instance(instance_id)

func is_sfx_playing(
	instance_id: int
) -> bool:

	if not _sfx_instances.has(instance_id):
		return false

	var instance: SFXInstance = (
		_sfx_instances[instance_id]
	)

	return instance.player.playing

func stop_all_sfx() -> void:

	for instance in _sfx_instances.values():

		instance.player.stop()

	_sfx_instances.clear()

# ===========================================================
# PERSISTENT / LOOPING SFX
#
# These sounds do NOT use the one-shot pool.
#
# Good examples in a future project:
#
# - engine loops
# - fire loops
# - environmental ambience
# - charging sounds
# - sustained abilities
#
# Each active persistent sound owns its own player.
# ===========================================================

class PersistentSFXInstance:

	var id: int

	var player: AudioStreamPlayer

	var key: StringName

	var base_volume_db: float

	var base_pitch: float

var _persistent_sfx: Dictionary = {}

var _next_persistent_sfx_id: int = 0

func play_persistent_sfx(
	stream: AudioStream,
	key: StringName = &"",
	volume_db: float = 0.0,
	pitch: float = 1.0,
	bus_name: StringName = &"",
	restart_if_existing: bool = false
) -> int:

	if stream == null:

		push_warning(
			"Attempted to play a null persistent SFX stream."
		)

		return -1

	# Optional key-based reuse.
	if key != &"":

		for instance in _persistent_sfx.values():

			if instance.key == key:

				if restart_if_existing:
					instance.player.play()

				return instance.id

	var player := AudioStreamPlayer.new()

	if bus_name != &"":
		player.bus = bus_name
	else:
		player.bus = persistent_sfx_bus

	player.stream = stream

	player.volume_db = volume_db

	player.pitch_scale = pitch

	add_child(player)

	var instance_id := _next_persistent_sfx_id

	_next_persistent_sfx_id += 1

	var instance := PersistentSFXInstance.new()

	instance.id = instance_id

	instance.player = player

	instance.key = key

	instance.base_volume_db = volume_db

	instance.base_pitch = pitch

	_persistent_sfx[instance_id] = instance

	player.play()

	return instance_id

func stop_persistent_sfx(
	instance_id: int,
	fade_time: float = 0.0
) -> void:

	if not _persistent_sfx.has(instance_id):
		return

	var instance: PersistentSFXInstance = (
		_persistent_sfx[instance_id]
	)

	var player := instance.player

	if fade_time <= 0.0:

		player.stop()

		player.queue_free()

		_persistent_sfx.erase(instance_id)

		return

	var tween := create_tween()

	tween.tween_property(
		player,
		"volume_db",
		-80.0,
		fade_time
	)

	tween.tween_callback(
		func():

			player.stop()

			player.queue_free()

			_persistent_sfx.erase(instance_id)
	)

func stop_persistent_sfx_by_key(
	key: StringName,
	fade_time: float = 0.0
) -> void:

	var ids: Array[int] = []

	for instance_id in _persistent_sfx:

		var instance: PersistentSFXInstance = (
			_persistent_sfx[instance_id]
		)

		if instance.key == key:
			ids.append(instance_id)

	for instance_id in ids:

		stop_persistent_sfx(
			instance_id,
			fade_time
		)

func get_persistent_sfx_id(
	key: StringName
) -> int:

	for instance in _persistent_sfx.values():

		if instance.key == key:
			return instance.id

	return -1

func is_persistent_sfx_playing(
	instance_id: int
) -> bool:

	if not _persistent_sfx.has(instance_id):
		return false

	var instance: PersistentSFXInstance = (
		_persistent_sfx[instance_id]
	)

	return instance.player.playing

func set_persistent_sfx_volume_db(
	instance_id: int,
	target_volume_db: float,
	duration: float = 0.0
) -> void:

	if not _persistent_sfx.has(instance_id):
		return

	var instance: PersistentSFXInstance = (
		_persistent_sfx[instance_id]
	)

	instance.base_volume_db = target_volume_db

	if duration <= 0.0:

		instance.player.volume_db = target_volume_db

		return

	var tween := create_tween()

	tween.tween_property(
		instance.player,
		"volume_db",
		target_volume_db,
		duration
	)

func set_persistent_sfx_pitch(
	instance_id: int,
	target_pitch: float,
	duration: float = 0.0
) -> void:

	if not _persistent_sfx.has(instance_id):
		return

	var instance: PersistentSFXInstance = (
		_persistent_sfx[instance_id]
	)

	instance.base_pitch = target_pitch

	if duration <= 0.0:

		instance.player.pitch_scale = target_pitch

		return

	var tween := create_tween()

	tween.tween_property(
		instance.player,
		"pitch_scale",
		target_pitch,
		duration
	)

func stop_all_persistent_sfx(
	fade_time: float = 0.0
) -> void:

	var ids: Array[int] = []

	for instance_id in _persistent_sfx:
		ids.append(instance_id)

	for instance_id in ids:

		stop_persistent_sfx(
			instance_id,
			fade_time
		)

# ===========================================================
# GLOBAL CONTROL
# ===========================================================

func stop_all_audio(
	music_fade_time: float = 0.0,
	persistent_fade_time: float = 0.0
) -> void:

	stop_music(
		music_fade_time,
		false
	)

	stop_all_sfx()

	stop_all_persistent_sfx(
		persistent_fade_time
	)

# ===========================================================
# INITIALIZATION
# ===========================================================

func _ready() -> void:

	process_mode = Node.PROCESS_MODE_ALWAYS

	_create_music_players()

	_create_sfx_pool()
