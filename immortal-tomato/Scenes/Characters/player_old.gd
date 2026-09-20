extends CharacterBody2D

@export var speed := 100.0

@onready var sprite: Sprite2D = $Sprite2D
var sprite_direction_offset = 12
var target_pos: Vector2
func _physics_process(_delta):
	#var input := Input.get_vector(
		#"move_left",
		#"move_right",
		#"move_up",
		#"move_down"
	#)
	#
	#velocity = input * speed
	#move_and_slide()
	var direction := global_position.direction_to(target_pos)
	print(target_pos.distance_to(get_global_mouse_position()))
	if target_pos.distance_to(global_position) > 10:
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO
		
	move_and_slide()
	

	#if input != Vector2.ZERO:
		#var sprite_direction := int(round(input.angle() / (TAU / 16.0))) % 16
		#
		#sprite_direction = (sprite_direction + sprite_direction_offset) % 16
		#flip_if_frame(sprite_direction)
		#sprite.frame = sprite_direction
		#print(sprite_direction)
		


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		if target_pos.distance_to(get_global_mouse_position()) > 10:
			target_pos = get_global_mouse_position()


func flip_if_frame(frame: int):
	if frame == 2 or frame == 4 or frame == 6 or frame == 10 or frame == 12 or frame == 14:
		sprite.flip_h = true
	else:
		sprite.flip_h = false
