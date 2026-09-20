extends Node

var target_position: Vector2 = Vector2.ZERO
var total_units_selected: int = 0
var minimal_distance_from_target: int = 10
var total_units: int = 0

var world_border_left = -360 - 360
var world_border_right = 360 + 360
var world_border_up = - 180 - 180 
var world_border_down = 180 + 180 
