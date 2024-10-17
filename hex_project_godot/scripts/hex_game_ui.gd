class_name HexGameUi
extends Node3D

#region Private data members

var _current_cell: HexCell = null

var _selected_unit: HexUnit = null

#endregion

#region Public data members

var grid: HexGrid = null

#endregion

#region Overrides

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#endregion

#region Methods

func set_edit_mode (toggle: bool) -> void:
	pass

#endregion

#region Private methods

func _do_selection () -> void:
	_update_current_cell()
	
	if (_current_cell):
		_selected_unit = _current_cell.unit

func _update_current_cell () -> bool:
	#Set the ray length
	var RAY_LENGTH = 1000
	
	#Get the current mouse position
	var mousepos = get_viewport().get_mouse_position()

	#Determine the start and end points of the ray
	var scene_camera: Camera3D = get_viewport().get_camera_3d()
	var origin: Vector3 = scene_camera.project_ray_origin(mousepos)
	var end: Vector3 = origin + scene_camera.project_ray_normal(mousepos) * RAY_LENGTH
	
	#Create a ray query object
	var ray_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, end)
	ray_query.collide_with_areas = true

	#Send the ray query object to the hex grid to determine which cell the ray is hitting (if any)
	var result_cell: HexCell = grid.get_cell_from_ray(ray_query)
	if (result_cell != _current_cell):
		_current_cell = result_cell
		return true
	
	#Return the resulting cell
	return false

#endregion
