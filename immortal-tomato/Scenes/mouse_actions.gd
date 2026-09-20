extends Node2D

var selecting_units: bool = false
var selecting_new_position: bool = false
var select_start_pos: Vector2 = Vector2(40,30)
var select_end_pos: Vector2 = Vector2(100,200)
var circle_draw_position: Vector2
var circle_draw_radius: float = 0.0


var circle_tween: Tween
var pressing_shift: bool = false

func _ready() -> void:
	circle_tween = create_tween()

func _process(delta: float) -> void:
	if selecting_units:
		select_end_pos = get_global_mouse_position()
	queue_redraw()
	#circle_draw_radius += delta * 100
	if circle_draw_radius > 10:
		selecting_new_position = false
	
	if Input.is_action_pressed("shift"):
		pressing_shift = true
	else:
		pressing_shift = false

func _input(event: InputEvent) -> void:
	
	
	
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1 and Global.total_units_selected:
		#if Global.target_position.distance_to(get_global_mouse_position()) > Global.minimal_distance_from_target:
			Global.target_position = get_global_mouse_position()
			AudioLibrary.play_sfx(AudioLibrary.SFX.SELECT_NEW_TARGET_MOUSE)
			Signals.new_target_position_selected.emit(Global.target_position)
			selecting_new_position = true
			circle_draw_position = get_global_mouse_position()
			circle_draw_radius = 1
			#await get_tree().create_timer(1.0).timeout
			var time: float = 10
			if circle_tween:
				circle_tween.kill()
				circle_tween = create_tween()
			circle_tween.tween_property(self,"circle_draw_radius",10,7/time)
			circle_tween.tween_property(self,"circle_draw_radius",1,0.01)
			circle_tween.tween_property(self,"circle_draw_radius",10,8/time)
			circle_tween.tween_property(self,"circle_draw_radius",1,0.01)
			circle_tween.tween_property(self,"circle_draw_radius",11,9/time)
			#circle_tween.tween_property(self,"circle_draw_radius",1,0.01)
			#circle_tween.tween_property(self,"circle_draw_radius",26,26/time)
			
		#else:
			#AudioLibrary.play_sfx(AudioLibrary.SFX.SELECT_NEW_TARGET_INVALID_LOCATION_MOUSE)

	if event is InputEventMouseButton and event.button_index == 2:
		if event.is_pressed():
			if !selecting_units:
				select_start_pos = get_global_mouse_position()
			selecting_units = true
			select_end_pos = get_global_mouse_position()
			queue_redraw()
			AudioLibrary.play_sfx(AudioLibrary.SFX.START_SELECT_UNIT_SOUND)
		elif event.is_released():	
			selecting_units = false
			queue_redraw()
			var new_start_pos: Vector2
			var new_end_pos: Vector2
			new_start_pos.x = select_start_pos.x if select_start_pos.x < select_end_pos.x else select_end_pos.x
			new_start_pos.y = select_start_pos.y if select_start_pos.y < select_end_pos.y else select_end_pos.y
			new_end_pos.x = select_start_pos.x if select_start_pos.x > select_end_pos.x else select_end_pos.x
			new_end_pos.y = select_start_pos.y if select_start_pos.y > select_end_pos.y else select_end_pos.y
			Signals.new_units_selected.emit(new_start_pos,new_end_pos,pressing_shift)
			print("select_start_pos: ",new_start_pos)
			print("select_end_pos: ",new_end_pos)
			if new_start_pos.distance_to(new_end_pos) > 5:
				AudioLibrary.play_sfx(AudioLibrary.SFX.END_SELECT_UNIT_SOUND)
				
		

func _draw() -> void:
	if selecting_new_position:
		draw_circle(circle_draw_position,circle_draw_radius*1.5,Color("ffffff32"),false,2)
		draw_circle(circle_draw_position,circle_draw_radius,Color("ffffff64"),false,2)
		draw_circle(circle_draw_position,circle_draw_radius/2,Color("ffffff96"),false,2)
	if selecting_units:
		var rect := Rect2(select_start_pos,select_end_pos-select_start_pos)
		draw_rect(rect,Color(0.2,0.2,0.2,0.2),true)
		draw_rect(rect,Color("ffffff"),false,2)
