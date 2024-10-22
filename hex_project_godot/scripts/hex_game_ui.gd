class_name HexGameUi
extends Node3D

#region Signals

signal edit_mode_enabled

#endregion

#region Exported data members

@export var grid: HexGrid

#endregion

#region Private data members

var _enabled: bool = false

var _current_cell: HexCell = null

var _selected_unit: HexUnit = null

#endregion

#region Overrides

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (_selected_unit):
		_do_pathfinding()

func _unhandled_input(event: InputEvent) -> void:
	if _enabled:
		#If a mouse button was pressed...
		if event is InputEventMouseButton:
			#If the left mouse button was pressed...
			if event.button_index == MOUSE_BUTTON_LEFT:
				_do_selection()
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				_do_move()

#endregion

#region Methods

func enable () -> void:
	if (not _enabled):
		_enabled = true
		$CanvasLayer.visible = true

func disable () -> void:
	if (_enabled):
		_enabled = false
		$CanvasLayer.visible = false

#endregion

#region Private methods

func _do_move () -> void:
	if (grid.has_path):
		_selected_unit.location = _current_cell
		grid.clear_path()

func _do_pathfinding () -> void:
	if (_update_current_cell()):
		if (_current_cell) and (_selected_unit.is_valid_destination(_current_cell)):
			grid.find_path(_selected_unit.location, _current_cell, 24)
		else:
			grid.clear_path()

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

#region UI event handlers

func _on_enable_edit_mode_button_pressed() -> void:
	edit_mode_enabled.emit()
	
#endregion
