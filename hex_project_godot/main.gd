extends Node3D

var camera_speed: float = 0.1

@onready var scene_camera := $Camera3D
@onready var hex_grid := $HexGrid

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
				hex_grid.touch_cell(result.position)
