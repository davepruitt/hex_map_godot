extends Node3D

var camera_speed: float = 0.1

@onready var scene_camera := $Camera3D

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

	
