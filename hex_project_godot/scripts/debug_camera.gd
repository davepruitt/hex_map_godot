class_name DebugCamera
extends Camera3D

#This camera code has largely been borrowed from Github user timjonaswechler. Thanks!

#region Exported variables

@export_range(0, 10, 0.01) var sensitivity : float = 3
@export_range(0, 1000, 0.1) var default_velocity : float = 5
@export_range(0, 10, 0.01) var speed_scale : float = 1.17
@export_range(1, 100, 0.1) var boost_speed_multiplier : float = 3.0
@export var max_speed : float = 1000
@export var min_speed : float = 0.2

#endregion

#region Private data members

@onready var _velocity = default_velocity

#endregion

#region Overrides

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if (current):
		#Get the direction of movement based on user interaction
		var direction = Vector3(
			float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
			float(Input.is_physical_key_pressed(KEY_E)) - float(Input.is_physical_key_pressed(KEY_Q)), 
			float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
		).normalized()
	
		#Apply a boost if the user is pressing shift
		if Input.is_physical_key_pressed(KEY_SHIFT):
			translate(direction * _velocity * delta * boost_speed_multiplier)
		else:
			translate(direction * _velocity * delta)
	
	return

func _input(event: InputEvent) -> void:
	if (current):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			if event is InputEventMouseMotion:
				rotation.y -= event.relative.x / 1000 * sensitivity
				rotation.x -= event.relative.y / 1000 * sensitivity
				rotation.x = clamp(rotation.x, PI/-2, PI/2)
		
		if event is InputEventMouseButton:
			match event.button_index:
				MOUSE_BUTTON_RIGHT:
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE)
				MOUSE_BUTTON_WHEEL_UP: # increase fly velocity
					_velocity = clamp(_velocity * speed_scale, min_speed, max_speed)
				MOUSE_BUTTON_WHEEL_DOWN: # decrease fly velocity
					_velocity = clamp(_velocity / speed_scale, min_speed, max_speed)

#endregion
