class_name Main
extends Node3D

#region Exported variables

@export_group("Hex Colors")
@export var color_1 := Color.YELLOW
@export var color_2 := Color.GREEN
@export var color_3 := Color.BLUE
@export var color_4 := Color.WHITE

#endregion

#region Public data members

var camera_speed: float = 0.1

#endregion

#region OnReady public data members

@onready var scene_camera := $Camera3D
@onready var hex_grid := $HexGrid

@onready var check_box_1 := $CanvasLayer/HFlowContainer/CheckBox
@onready var check_box_2 := $CanvasLayer/HFlowContainer/CheckBox2
@onready var check_box_3 := $CanvasLayer/HFlowContainer/CheckBox3
@onready var check_box_4 := $CanvasLayer/HFlowContainer/CheckBox4

#endregion

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var left_right_movement = Input.get_axis("ui_left", "ui_right")
	var up_down_movement = Input.get_axis("ui_up", "ui_down")
	
	scene_camera.position.x += camera_speed * left_right_movement
	scene_camera.position.z += camera_speed * up_down_movement
	
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Z:
			scene_camera.position.y += camera_speed
		elif event.keycode == KEY_X:
			scene_camera.position.y -= camera_speed
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var RAY_LENGTH = 1000
			var space_state = get_world_3d().direct_space_state
			var mousepos = get_viewport().get_mouse_position()

			var origin = scene_camera.project_ray_origin(mousepos)
			var end = origin + scene_camera.project_ray_normal(mousepos) * RAY_LENGTH
			var query = PhysicsRayQueryParameters3D.create(origin, end)
			query.collide_with_areas = true

			var result = space_state.intersect_ray(query)
			if result:
				var color_to_use = Color.WHITE
				if check_box_1.button_pressed:
					color_to_use = color_1
				elif check_box_2.button_pressed:
					color_to_use = color_2
				elif check_box_3.button_pressed:
					color_to_use = color_3
				elif check_box_4.button_pressed:
					color_to_use = color_4
				
				hex_grid.color_cell(result.position, color_to_use)
