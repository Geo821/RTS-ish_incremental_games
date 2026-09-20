extends CharacterBody2D

var speed: int = 300
var local_target_position: Vector2
var selected: bool = false
var detecting_another_unit_close: bool

var stuck_position: Vector2
var picked_rand_rotation: bool = false

@onready var normal_sprite: AnimatedSprite2D = $NormalSprite
@onready var sprite: AnimatedSprite2D = $OutlinedSprite
@onready var detect_possible_move_area: Area2D = $DetectPossibleMoveArea
@onready var ray_cast: RayCast2D = %RayCast2D


func _ready() -> void:
	sprite.visible = false
	#sprite.material.set_shader_parameter("outline_color",Color(0,0,0,0))
	local_target_position = global_position
	Signals.new_target_position_selected.connect(retarget)
	Signals.new_units_selected.connect(check_if_selected)

func retarget(new_position: Vector2):
	if selected:
		local_target_position = new_position
		$CheckIfStuckTimer.start()
		picked_rand_rotation = false
		
func _draw() -> void:
	var local_draw_position = to_local(local_target_position)
	if velocity:
		draw_line(Vector2.ZERO,local_draw_position,Color(1,0.5,0.5,0.4),2)

var can_draw: bool = false

var orbit_speed = 1
func _process(delta: float) -> void:
	ray_cast.target_position = to_local(local_target_position)
	var direction = global_position.direction_to(local_target_position)
	#if local_target_position.distance_to(global_position) > Global.minimal_distance_from_target and ray_cast.is_colliding():
	#if local_target_position.distance_to(global_position) > Global.minimal_distance_from_target and local_target_position.distance_to(global_position) < Global.minimal_distance_from_target * 3 and ray_cast.is_colliding():
	if local_target_position.distance_to(global_position) > Global.minimal_distance_from_target and detect_possible_move_area.get_overlapping_bodies():
		detect_closest_unit()
	#if local_target_position.distance_to(global_position) > Global.minimal_distance_from_target and ray_cast.get_collision_point().distance_to(global_position) > 10 and ray_cast.is_colliding():
		#print(detect_possible_move_area.get_overlapping_bodies())
		
		var away_from_unit = global_position - closest_unit.global_position
		var tangent = Vector2(-away_from_unit.y, away_from_unit.x).normalized()
	
		if tangent.dot(direction) < 0:
			tangent = -tangent
	
		velocity = tangent * speed
		#velocity = direction * speed
		#velocity = (direction + Vector2(5,0)) * speed * 3
		#local_target_position = global_position
	elif local_target_position.distance_to(global_position) > Global.minimal_distance_from_target:
		velocity = direction * speed 
	else:
		velocity = Vector2.ZERO
		$CheckIfStuckTimer.stop()
		local_target_position = global_position

	look_at(local_target_position)
	move_and_slide()
	animation_handling()
	
	if velocity:
		can_draw = true
		queue_redraw()
	elif can_draw:
		can_draw = false
		queue_redraw()

func animation_handling():
	if velocity:
		if sprite.animation != "walk":
			sprite.play("walk")
			normal_sprite.play("walk")
	else:
		if sprite.animation != "idle":
			sprite.play("idle")
			normal_sprite.play("idle")

func check_if_selected(start_pos: Vector2, end_pos: Vector2, shift_pressed: bool = false):
	var current_texture = sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
	var frame_size = current_texture.get_size()
	if (global_position.x > start_pos.x - frame_size.x / 2 and 
		global_position.x < end_pos.x + frame_size.x / 2 and 
		global_position.y > start_pos.y - frame_size.y / 2 and 
		global_position.y < end_pos.y + frame_size.y / 2 and 
		start_pos.distance_to(end_pos) > 10
	):
		sprite.visible = true
		#sprite.material.set_shader_parameter("outline_color",Color(1,1,1,1))
		if not selected:
			Global.total_units_selected += 1
		selected = true
	else:
		#sprite.material.set_shader_parameter("outline_color",Color(0,0,0,0))
		sprite.visible = false
		if not shift_pressed:
			if selected:
				Global.total_units_selected -= 1
			selected = false

var check_stuck_position_once: = false
var max_stuck_distance: int = 2

func _on_check_if_stuck_timer_timeout() -> void:
	if not check_stuck_position_once or stuck_position.distance_to(global_position) > max_stuck_distance and stuck_position.distance_to(local_target_position) + max_stuck_distance * 5 > global_position.distance_to(local_target_position):
		stuck_position = global_position
		check_stuck_position_once = true
		max_stuck_distance += 1
	else:
		max_stuck_distance = 2
		local_target_position = global_position
		check_stuck_position_once = false
		
var closest_distance
var closest_unit
func detect_closest_unit():
	var overlapping_units = detect_possible_move_area.get_overlapping_bodies()

	if overlapping_units:
		closest_unit = overlapping_units[0]
		closest_distance = global_position.distance_to(closest_unit.global_position)
	
		for unit in overlapping_units:
			var distance = global_position.distance_to(unit.global_position)
	
			if distance < closest_distance:
				closest_unit = unit
				closest_distance = distance
