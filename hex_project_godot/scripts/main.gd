class_name Main
extends Node3D

#region Exported variables

@export_group("Hex Colors")
@export var color_1 := Color.YELLOW
@export var color_2 := Color.GREEN
@export var color_3 := Color.BLUE
@export var color_4 := Color.ORANGE
@export var color_5 := Color.WHITE

#endregion

#region Public data members

var camera_speed: float = 0.1

var paint_terrain_color_enabled: bool = true
var paint_terrain_elevation_enabled: bool = false
var apply_water_level: bool = false
var apply_urban_level: bool = false
var apply_farm_level: bool = false
var apply_plant_level: bool = false

var active_color: Color = Color.WHITE
var active_elevation: int = 0
var active_brush_size: int = 0
var active_show_labels: bool = true
var active_water_level: int = 0
var active_urban_level: int = 0
var active_farm_level: int = 0
var active_plant_level: int = 0

var river_mode: Enums.OptionalToggle = Enums.OptionalToggle.Ignore
var road_mode: Enums.OptionalToggle = Enums.OptionalToggle.Ignore
var walls_mode: Enums.OptionalToggle = Enums.OptionalToggle.Ignore

#endregion

#region OnReady public data members

@onready var hex_grid := $HexGrid
@onready var scene_camera := $HexMapCamera/Swivel/Stick/MainCamera

@onready var elevation_label := $CanvasLayer/PanelContainer/VBoxContainer/HBoxContainer/ElevationValueLabel
@onready var check_button_enable_elevation := $CanvasLayer/PanelContainer/VBoxContainer/CheckButton_EnableElevation
@onready var brush_size_value_label := $CanvasLayer/PanelContainer/VBoxContainer/HBoxContainer2/BrushSizeValueLabel
@onready var check_button_show_labels := $CanvasLayer/PanelContainer/VBoxContainer/CheckButton_ShowLabels

@onready var check_button_color_none := $CanvasLayer/PanelContainer/VBoxContainer/GridContainer/CheckBox_NoColor
@onready var check_button_color_yellow := $CanvasLayer/PanelContainer/VBoxContainer/GridContainer/CheckBox_ColorYellow
@onready var check_button_color_green := $CanvasLayer/PanelContainer/VBoxContainer/GridContainer/CheckBox_ColorGreen
@onready var check_button_color_blue := $CanvasLayer/PanelContainer/VBoxContainer/GridContainer/CheckBox_ColorBlue
@onready var check_button_color_orange := $CanvasLayer/PanelContainer/VBoxContainer/GridContainer/CheckBox_ColorOrange
@onready var check_button_color_white := $CanvasLayer/PanelContainer/VBoxContainer/GridContainer/CheckBox_ColorWhite

@onready var check_button_rivers_ignore := $CanvasLayer/PanelContainer/VBoxContainer/HBoxContainer3/CheckBox_RiversIgnore
@onready var check_button_rivers_yes := $CanvasLayer/PanelContainer/VBoxContainer/HBoxContainer3/CheckBox_RiversYes
@onready var check_button_rivers_no := $CanvasLayer/PanelContainer/VBoxContainer/HBoxContainer3/CheckBox_RiversNo

@onready var check_button_roads_ignore := $CanvasLayer/PanelContainer/VBoxContainer/HBoxContainer4/CheckBox_RoadsIgnore
@onready var check_button_roads_yes := $CanvasLayer/PanelContainer/VBoxContainer/HBoxContainer4/CheckBox_RoadsYes
@onready var check_button_roads_no := $CanvasLayer/PanelContainer/VBoxContainer/HBoxContainer4/CheckBox_RoadsNo

@onready var check_button_water_level := $CanvasLayer/PanelContainer/VBoxContainer/CheckButton_WaterLevel
@onready var water_level_value_label := $CanvasLayer/PanelContainer/VBoxContainer/HBoxContainer5/WaterLevelValueLabel

@onready var check_button_urban_level := $CanvasLayer/PanelContainer2/MarginContainer/VBoxContainer/CheckButton_UrbanLevel
@onready var urban_level_value_label := $CanvasLayer/PanelContainer2/MarginContainer/VBoxContainer/HBoxContainer/UrbanLevelValueLabel

@onready var check_button_farm_level := $CanvasLayer/PanelContainer2/MarginContainer/VBoxContainer/CheckButton_FarmLevel
@onready var farm_level_value_label := $CanvasLayer/PanelContainer2/MarginContainer/VBoxContainer/HBoxContainer2/FarmLevelValueLabel

@onready var check_button_plant_level := $CanvasLayer/PanelContainer2/MarginContainer/VBoxContainer/CheckButton_PlantLevel
@onready var plant_level_value_label := $CanvasLayer/PanelContainer2/MarginContainer/VBoxContainer/HBoxContainer3/PlantLevelValueLabel

@onready var check_button_walls_ignore := $CanvasLayer/PanelContainer2/MarginContainer/VBoxContainer/HBoxContainer4/CheckBox_WallsIgnore
@onready var check_button_walls_yes := $CanvasLayer/PanelContainer2/MarginContainer/VBoxContainer/HBoxContainer4/CheckBox_WallsYes
@onready var check_button_walls_no := $CanvasLayer/PanelContainer2/MarginContainer/VBoxContainer/HBoxContainer4/CheckBox_WallsNo

#endregion

#region Private data members

var _is_drag: bool = false
var _drag_direction: HexDirectionsClass.HexDirections = HexDirectionsClass.HexDirections.NE
var _mouse_down_cell: HexCell = null
var _mouse_up_cell: HexCell = null

#endregion

#region Overrides

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Set the seed of the global random number generator. 
	#This allows for deterministic repeated-runs of the application.
	seed(1)
	
	RenderingServer.set_debug_generate_wireframes(true)
	
	_initialize_ui()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var left_right_movement = Input.get_axis("ui_left", "ui_right")
	var up_down_movement = Input.get_axis("ui_up", "ui_down")
	
	
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_P:
			var vp = get_viewport()
			vp.debug_draw = (vp.debug_draw + 1) % 5
			
	elif event is InputEventMouseButton:
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
				var cell = hex_grid.get_cell(result.position)
				
				if event.pressed:
					#Set the cell object that was initially pressed
					_mouse_down_cell = cell
				else:
					#Set the cell object that received the end of the press event
					_mouse_up_cell = cell
					
					#Check to see if a drag event occurred
					if (_mouse_down_cell and _mouse_up_cell and (_mouse_down_cell != _mouse_up_cell)):
						_validate_drag()
					else:
						_is_drag = false
					
					#Edit the cells
					_edit_cells(cell)

#endregion

#region GUI event handlers

func _on_check_box_no_color_pressed() -> void:
	paint_terrain_color_enabled = false


func _on_check_box_color_yellow_pressed() -> void:
	paint_terrain_color_enabled = true
	active_color = color_1


func _on_check_box_color_green_pressed() -> void:
	paint_terrain_color_enabled = true
	active_color = color_2


func _on_check_box_color_blue_pressed() -> void:
	paint_terrain_color_enabled = true
	active_color = color_3


func _on_check_box_color_orange_pressed() -> void:
	paint_terrain_color_enabled = true
	active_color = color_4
	

func _on_check_box_color_white_pressed() -> void:
	paint_terrain_color_enabled = true
	active_color = color_5


func _on_elevation_slider_value_changed(value: float) -> void:
	active_elevation = int(value)
	elevation_label.text = str(active_elevation)


func _on_check_button_enable_elevation_toggled(toggled_on: bool) -> void:
	paint_terrain_elevation_enabled = toggled_on


func _on_brush_size_slider_value_changed(value: float) -> void:
	active_brush_size = int(value)
	brush_size_value_label.text = str(active_brush_size)


func _on_check_button_show_labels_toggled(toggled_on: bool) -> void:
	active_show_labels = toggled_on
	show_ui(active_show_labels)


func _on_check_box_rivers_ignore_pressed() -> void:
	_set_river_mode(Enums.OptionalToggle.Ignore)


func _on_check_box_rivers_yes_pressed() -> void:
	_set_river_mode(Enums.OptionalToggle.Yes)


func _on_check_box_rivers_no_pressed() -> void:
	_set_river_mode(Enums.OptionalToggle.No)


func _on_check_box_roads_ignore_pressed() -> void:
	_set_road_mode(Enums.OptionalToggle.Ignore)


func _on_check_box_roads_yes_pressed() -> void:
	_set_road_mode(Enums.OptionalToggle.Yes)


func _on_check_box_roads_no_pressed() -> void:
	_set_road_mode(Enums.OptionalToggle.No)


func _on_check_button_water_level_toggled(toggled_on: bool) -> void:
	_set_apply_water_level(toggled_on)


func _on_water_level_slider_value_changed(value: float) -> void:
	_set_water_level(value)
	water_level_value_label.text = str(value)


func _on_urban_level_slider_value_changed(value: float) -> void:
	_set_urban_level(value)
	urban_level_value_label.text = str(value)


func _on_check_button_urban_level_toggled(toggled_on: bool) -> void:
	_set_apply_urban_level(toggled_on)


func _on_check_button_farm_level_toggled(toggled_on: bool) -> void:
	_set_apply_farm_level(toggled_on)


func _on_farm_level_slider_value_changed(value: float) -> void:
	_set_farm_level(value)
	farm_level_value_label.text = str(value)


func _on_check_button_plant_level_toggled(toggled_on: bool) -> void:
	_set_apply_plant_level(toggled_on)


func _on_plant_level_slider_value_changed(value: float) -> void:
	_set_plant_level(value)
	plant_level_value_label.text = str(value)


func _on_check_box_walls_ignore_pressed() -> void:
	pass # Replace with function body.


func _on_check_box_walls_yes_pressed() -> void:
	pass # Replace with function body.


func _on_check_box_walls_no_pressed() -> void:
	pass # Replace with function body.


#endregion

#region Private methods

func _initialize_ui () -> void:
	check_button_show_labels.set_pressed_no_signal(active_show_labels)
	check_button_enable_elevation.set_pressed_no_signal(paint_terrain_elevation_enabled)
	check_button_water_level.set_pressed_no_signal(apply_water_level)
	check_button_urban_level.set_pressed_no_signal(apply_urban_level)
	check_button_farm_level.set_pressed_no_signal(apply_farm_level)
	check_button_plant_level.set_pressed_no_signal(apply_plant_level)
	
	if (paint_terrain_color_enabled):
		if (active_color == Color.YELLOW):
			check_button_color_yellow.set_pressed_no_signal(true)
		elif (active_color == Color.GREEN):
			check_button_color_green.set_pressed_no_signal(true)
		elif (active_color == Color.BLUE):
			check_button_color_blue.set_pressed_no_signal(true)
		elif (active_color == Color.ORANGE):
			check_button_color_orange.set_pressed_no_signal(true)
		elif (active_color == Color.WHITE):
			check_button_color_white.set_pressed_no_signal(true)
	else:
		check_button_color_none.set_pressed_no_signal(true)
		
	if (river_mode == Enums.OptionalToggle.Ignore):
		check_button_rivers_ignore.set_pressed_no_signal(true)
	elif (river_mode == Enums.OptionalToggle.Yes):
		check_button_rivers_yes.set_pressed_no_signal(true)
	elif (river_mode == Enums.OptionalToggle.No):
		check_button_rivers_no.set_pressed_no_signal(true)
		
	if (road_mode == Enums.OptionalToggle.Ignore):
		check_button_roads_ignore.set_pressed_no_signal(true)
	elif (road_mode == Enums.OptionalToggle.Yes):
		check_button_roads_yes.set_pressed_no_signal(true)
	elif (road_mode == Enums.OptionalToggle.No):
		check_button_roads_no.set_pressed_no_signal(true)
	
	if (walls_mode == Enums.OptionalToggle.Ignore):
		check_button_walls_ignore.set_pressed_no_signal(true)
	elif (walls_mode == Enums.OptionalToggle.Yes):
		check_button_walls_yes.set_pressed_no_signal(true)
	elif (walls_mode == Enums.OptionalToggle.No):
		check_button_walls_no.set_pressed_no_signal(true)

func show_ui (visible: bool) -> void:
	hex_grid.show_ui(visible)

func _edit_cells (center_cell: HexCell) -> void:
	var center_x: int = center_cell.hex_coordinates.X
	var center_z: int = center_cell.hex_coordinates.Z
	
	#Bottom half of brush
	var r: int = 0
	var z: int = center_z - active_brush_size
	while (z <= center_z):
		#Set initial x
		var x: int = center_x - r
		while (x <= (center_x + active_brush_size)):
			#Edit the cell
			var hex_coordinates: HexCoordinates = HexCoordinates.new(x, z)
			_edit_cell(hex_grid.get_cell_from_coordinates(hex_coordinates))
			
			#Increment x
			x += 1
		
		#Increment z and r
		z += 1
		r += 1
	
	#Top half of brush
	r = 0
	z = center_z + active_brush_size
	while (z > center_z):
		#Set initial x
		var x: int = center_x - active_brush_size
		while (x <= (center_x + r)):
			#Edit the cell
			var hex_coordinates: HexCoordinates = HexCoordinates.new(x, z)
			_edit_cell(hex_grid.get_cell_from_coordinates(hex_coordinates))
			
			#Increment x
			x += 1
		
		#Decrement z and increment r
		z -= 1
		r += 1

func _edit_cell (cell: HexCell) -> void:
	#Make sure the cell is not null
	if (cell):
		#Paint the color
		if (paint_terrain_color_enabled):
			cell.hex_color = active_color
		
		#Paint the terrain elevation value
		if (paint_terrain_elevation_enabled):
			cell.elevation = active_elevation
		
		#Paint the water level value
		if (apply_water_level):
			cell.water_level = active_water_level
		
		#Paint the urban level value
		if (apply_urban_level):
			cell.urban_level = active_urban_level
			
		#Paint the farm level value
		if (apply_farm_level):
			cell.farm_level = active_farm_level
		
		#Paint the plant level value
		if (apply_plant_level):
			cell.plant_level = active_plant_level
		
		#Remove rivers if the river mode is "no"
		if (river_mode == Enums.OptionalToggle.No):
			cell.remove_river()
			
		#Remove roads if the road toggle is "no"
		if (road_mode == Enums.OptionalToggle.No):
			cell.remove_roads()
		
		#Add or remove walls
		if (walls_mode != Enums.OptionalToggle.Ignore):
			cell.walled = (walls_mode == Enums.OptionalToggle.Yes)
		
		#Check to see if a drag event was completed
		if (_is_drag):
			var opposite_direction = HexDirectionsClass.opposite(_drag_direction)
			var other_cell: HexCell = cell.get_neighbor(opposite_direction)
			if (other_cell):
				#Place rivers if the river mode is set to "yes"
				if (river_mode == Enums.OptionalToggle.Yes):
					other_cell.set_outgoing_river(_drag_direction)
					
				#Place roads if the road mode is set to "yes"
				if (road_mode == Enums.OptionalToggle.Yes):
					other_cell.add_road(_drag_direction)

func _set_river_mode (mode: Enums.OptionalToggle) -> void:
	river_mode = mode
	
func _set_road_mode (mode: Enums.OptionalToggle) -> void:
	road_mode = mode
	
func _set_apply_water_level (toggle: bool) -> void:
	apply_water_level = toggle
	
func _set_water_level (level: float) -> void:
	active_water_level = int(level)

func _set_apply_urban_level (toggle: bool) -> void:
	apply_urban_level = toggle

func _set_urban_level (level: float) -> void:
	active_urban_level = int(level)

func _set_apply_farm_level (toggle: bool) -> void:
	apply_farm_level = toggle

func _set_farm_level (level: float) -> void:
	active_farm_level = int(level)
	
func _set_apply_plant_level (toggle: bool) -> void:
	apply_plant_level = toggle

func _set_plant_level (level: float) -> void:
	active_plant_level = int(level)

func _set_wall_mode (mode: int) -> void:
	walls_mode = mode
	
func _validate_drag () -> void:
	#Set the initial drag direction
	_drag_direction = HexDirectionsClass.HexDirections.NE
	
	#Loop over each drag direction
	while (_drag_direction <= HexDirectionsClass.HexDirections.NW):
		#Check to see if the cells are neighbors in this direction
		if (_mouse_down_cell.get_neighbor(_drag_direction) == _mouse_up_cell):
			#If they are neighbors, then a drag occurred in this direction
			_is_drag = true
			
			#Return immediately
			return
		
		#Increment the drag direction
		_drag_direction += 1
	
	#If we reach this point in the code, then no drag occurred
	_is_drag = false
		

#endregion
