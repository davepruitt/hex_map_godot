class_name HexMapCamera
extends Node3D

#region Exported data members

@export var stick_min_zoom : float = 1.0
@export var stick_max_zoom : float = 10.0
@export var swivel_min_zoom : float = -90
@export var swivel_max_zoom : float = -45
@export var movement_speed_min_zoom : float = 40
@export var movement_speed_max_zoom : float = 10
@export var rotation_speed : float = 1.8


@export var hex_grid : HexGrid

#endregion

#region Private data members

@onready var _swivel := $Swivel
@onready var _stick := $Swivel/Stick
@onready var _main_camera := $Swivel/Stick/MainCamera

var _zoom: float = 1.0
var _movement_speed: float = 25
var _rotation_angle: float = 0

#endregion

#region Method overrides

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_main_camera.make_current()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var left_right_movement = Input.get_axis("ui_left", "ui_right")
	var forward_back_movement = Input.get_axis("ui_up", "ui_down")

	if (left_right_movement != 0.0 || forward_back_movement != 0.0):
		_adjust_position(left_right_movement, forward_back_movement, delta)
	
	var rotate_up_down_movement = Input.get_axis("ui_rotate_down", "ui_rotate_up")
	var rotate_left_right_movement = Input.get_axis("ui_rotate_left", "ui_rotate_right")

	if (rotate_left_right_movement != 0.0):
		_adjust_rotation(rotate_left_right_movement, delta)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Z:
			_adjust_zoom(0.1)
		elif event.keycode == KEY_X:
			_adjust_zoom(-0.1)

#endregion

#region Private methods

func _adjust_zoom (zoom_delta: float) -> void:
	_zoom = clampf(_zoom + zoom_delta, 0.0, 1.0)

	var distance: float = lerpf(stick_min_zoom, stick_max_zoom, _zoom)
	_stick.position = Vector3(0.0, 0.0, distance)
	
	var angle: float = lerpf(swivel_min_zoom, swivel_max_zoom, _zoom)
	_swivel.rotation = Vector3(angle, 0.0, 0.0)

func _adjust_position (x_delta: float, z_delta: float, time_delta: float) -> void:
	var direction: Vector3 = Vector3(x_delta, 0.0, z_delta).normalized()
	var damping: float = maxf(absf(x_delta), absf(z_delta))
	var distance: float = _movement_speed * damping * time_delta
	position += direction * distance
	#position = _clamp_position(position)

func _clamp_position (pos: Vector3) -> Vector3:
	var x_max: float = (hex_grid.chunk_count_x * HexMetrics.CHUNK_SIZE_X - 0.5) * (2.0 * HexMetrics.INNER_RADIUS)
	pos.x = clampf(pos.x, 0.0, x_max)
	
	var z_max: float = (hex_grid.chunk_count_z * HexMetrics.CHUNK_SIZE_Z - 1.0) * (1.5 * HexMetrics.OUTER_RADIUS)
	pos.z = clampf(pos.z, 0.0, z_max)
	
	return pos

func _adjust_rotation (rotation_delta: float, time_delta: float) -> void:
	_rotation_angle += rotation_delta * rotation_speed * time_delta
	if (_rotation_angle < 0.0):
		_rotation_angle += 360.0
	elif (_rotation_angle >= 360.0):
		_rotation_angle -= 360.0
	
	self.rotation = Vector3(0.0, _rotation_angle, 0.0)
	

#endregion
