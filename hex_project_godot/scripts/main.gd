class_name Main
extends Node3D

#region Public data members

var edit_mode: bool = true

var paint_terrain_elevation_enabled: bool = false
var apply_water_level: bool = false
var apply_urban_level: bool = false
var apply_farm_level: bool = false
var apply_plant_level: bool = false
var apply_special_feature: bool = false

var active_terrain_type_index: int = 0
var active_elevation: int = 0
var active_brush_size: int = 0
var active_show_labels: bool = true
var active_water_level: int = 0
var active_urban_level: int = 0
var active_farm_level: int = 0
var active_plant_level: int = 0
var active_special_feature: int = 0

var river_mode: Enums.OptionalToggle = Enums.OptionalToggle.Ignore
var road_mode: Enums.OptionalToggle = Enums.OptionalToggle.Ignore
var walls_mode: Enums.OptionalToggle = Enums.OptionalToggle.Ignore

#endregion

#region OnReady public data members

@onready var hex_grid := $HexGrid as HexGrid

@onready var elevation_label := $CanvasLayer/HBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/ElevationValueLabel
@onready var check_button_enable_elevation := $CanvasLayer/HBoxContainer/PanelContainer/VBoxContainer/CheckButton_EnableElevation
@onready var brush_size_value_label := $CanvasLayer/HBoxContainer/PanelContainer/VBoxContainer/HBoxContainer2/BrushSizeValueLabel
@onready var check_button_show_labels := $CanvasLayer/HBoxContainer/PanelContainer/VBoxContainer/CheckButton_ShowLabels

@onready var check_button_color_none := $CanvasLayer/HBoxContainer/PanelContainer/VBoxContainer/GridContainer/CheckBox_NoColor
@onready var check_button_color_yellow := $CanvasLayer/HBoxContainer/PanelContainer/VBoxContainer/GridContainer/CheckBox_ColorYellow
@onready var check_button_color_green := $CanvasLayer/HBoxContainer/PanelContainer/VBoxContainer/GridContainer/CheckBox_ColorGreen
@onready var check_button_color_blue := $CanvasLayer/HBoxContainer/PanelContainer/VBoxContainer/GridContainer/CheckBox_ColorBlue
@onready var check_button_color_orange := $CanvasLayer/HBoxContainer/PanelContainer/VBoxContainer/GridContainer/CheckBox_ColorOrange
@onready var check_button_color_white := $CanvasLayer/HBoxContainer/PanelContainer/VBoxContainer/GridContainer/CheckBox_ColorWhite

@onready var check_button_rivers_ignore := $CanvasLayer/HBoxContainer/PanelContainer/VBoxContainer/HBoxContainer3/CheckBox_RiversIgnore
@onready var check_button_rivers_yes := $CanvasLayer/HBoxContainer/PanelContainer/VBoxContainer/HBoxContainer3/CheckBox_RiversYes
@onready var check_button_rivers_no := $CanvasLayer/HBoxContainer/PanelContainer/VBoxContainer/HBoxContainer3/CheckBox_RiversNo

@onready var check_button_roads_ignore := $CanvasLayer/HBoxContainer/PanelContainer/VBoxContainer/HBoxContainer4/CheckBox_RoadsIgnore
@onready var check_button_roads_yes := $CanvasLayer/HBoxContainer/PanelContainer/VBoxContainer/HBoxContainer4/CheckBox_RoadsYes
@onready var check_button_roads_no := $CanvasLayer/HBoxContainer/PanelContainer/VBoxContainer/HBoxContainer4/CheckBox_RoadsNo

@onready var check_button_water_level := $CanvasLayer/HBoxContainer/PanelContainer/VBoxContainer/CheckButton_WaterLevel
@onready var water_level_value_label := $CanvasLayer/HBoxContainer/PanelContainer/VBoxContainer/HBoxContainer5/WaterLevelValueLabel

@onready var check_button_urban_level := $CanvasLayer/PanelContainer2/MarginContainer/VBoxContainer/CheckButton_UrbanLevel
@onready var urban_level_value_label := $CanvasLayer/PanelContainer2/MarginContainer/VBoxContainer/HBoxContainer/UrbanLevelValueLabel

@onready var check_button_farm_level := $CanvasLayer/PanelContainer2/MarginContainer/VBoxContainer/CheckButton_FarmLevel
@onready var farm_level_value_label := $CanvasLayer/PanelContainer2/MarginContainer/VBoxContainer/HBoxContainer2/FarmLevelValueLabel

@onready var check_button_plant_level := $CanvasLayer/PanelContainer2/MarginContainer/VBoxContainer/CheckButton_PlantLevel
@onready var plant_level_value_label := $CanvasLayer/PanelContainer2/MarginContainer/VBoxContainer/HBoxContainer3/PlantLevelValueLabel

@onready var check_button_walls_ignore := $CanvasLayer/PanelContainer2/MarginContainer/VBoxContainer/HBoxContainer4/CheckBox_WallsIgnore
@onready var check_button_walls_yes := $CanvasLayer/PanelContainer2/MarginContainer/VBoxContainer/HBoxContainer4/CheckBox_WallsYes
@onready var check_button_walls_no := $CanvasLayer/PanelContainer2/MarginContainer/VBoxContainer/HBoxContainer4/CheckBox_WallsNo

@onready var check_button_special_feature := $CanvasLayer/PanelContainer2/MarginContainer/VBoxContainer/CheckButton_SpecialFeature
@onready var drop_down_special_feature := $CanvasLayer/PanelContainer2/MarginContainer/VBoxContainer/OptionButton_SpecialFeature

@onready var new_map_popup_menu := $CanvasLayer/PopupMenu
@onready var save_map_file_dialog := $CanvasLayer/SaveFileDialog
@onready var load_map_file_dialog := $CanvasLayer/LoadFileDialog

@onready var cameras: Array[Camera3D] = [
	$HexMapCamera/Swivel/Stick/MainCamera,
	$DebugCamera
]

@onready var main_camera_assembly = $HexMapCamera
@onready var debug_camera = $DebugCamera

@onready var current_camera_value_label := $CanvasLayer/HBoxContainer/PanelContainer3/MarginContainer/VBoxContainer/HBoxContainer/CurrentCameraValueLabel
@onready var check_button_edit_mode := $CanvasLayer/PanelContainer2/MarginContainer/VBoxContainer/CheckButton_EditMode

#endregion

#region Private data members

var _is_drag: bool = false
var _drag_direction: HexDirectionsClass.HexDirections = HexDirectionsClass.HexDirections.NE
var _mouse_down_cell: HexCell = null
var _mouse_up_cell: HexCell = null
var _search_from_cell: HexCell = null
var _search_to_cell: HexCell = null

var _selected_camera: int = 0

var _is_left_shift_pressed: bool = false

#endregion

#region Overrides

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Set the seed of the global random number generator. 
	#This allows for deterministic repeated-runs of the application.
	seed(1)
	
	#This allows us to cycle through some debug views of our meshes
	RenderingServer.set_debug_generate_wireframes(true)
	
	#Initialize the user interface
	_initialize_ui()
	
	#Set the default camera
	cameras[_selected_camera].make_current()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
func _input(event: InputEvent) -> void:
	#Check for user input...
	if event is InputEventKey and event.pressed:
		#If the "P" key was pressed, let's cycle through debug views
		if event.keycode == KEY_P:
			var vp = get_viewport()
			vp.debug_draw = (vp.debug_draw + 1) % 5
			
		#If the "C" key was pressed, let's alternate the camera being used
		if event.keycode == KEY_C:
			#Increment the index of the selected camera
			_selected_camera += 1
			if (_selected_camera >= len(cameras)):
				#Set the index to 0 if we have exceeded the length of the list
				_selected_camera = 0
			
			#Set the current camera to the newly selected camera
			cameras[_selected_camera].make_current()

			#Update the UI to reflect which camera is selected
			if (_selected_camera == 0):
				current_camera_value_label.text = "Main"
			elif (_selected_camera == 1):
				current_camera_value_label.text = "Debug"
			else:
				current_camera_value_label.text = "NA"
		
		if event.keycode == KEY_G:
			hex_grid.hex_grid_overlay_enabled = !hex_grid.hex_grid_overlay_enabled
		
		if event.keycode == KEY_T:
			for i in range(0, len(hex_grid._hex_cells)):
				hex_grid._hex_cells[i].cell_content.position.y += 0.1
				print_debug(str(hex_grid._hex_cells[i].cell_content.position.y))
		if event.keycode == KEY_Y:
			for i in range(0, len(hex_grid._hex_cells)):
				hex_grid._hex_cells[i].cell_content.position.y -= 0.1
		if event.keycode == KEY_SHIFT and (event as InputEventKey).location == KEY_LOCATION_LEFT:
			_is_left_shift_pressed = true
	
	elif event is InputEventKey and not event.pressed:
		
		if event.keycode == KEY_SHIFT and (event as InputEventKey).location == KEY_LOCATION_LEFT:
			_is_left_shift_pressed = false
	
	#If a mouse button was pressed...
	elif event is InputEventMouseButton:
		#If the left mouse button was pressed...
		if event.button_index == MOUSE_BUTTON_LEFT:
			#Shoot a ray through a cell in the hex grid to see what cell was touched by the user
			var RAY_LENGTH = 1000
			var space_state = get_world_3d().direct_space_state
			var mousepos = get_viewport().get_mouse_position()

			var scene_camera: Camera3D = cameras[_selected_camera]
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
					if (edit_mode):
						_edit_cells(cell)
					elif (_is_left_shift_pressed) and (_search_to_cell != cell):
						if (_search_from_cell):
							_search_from_cell.disable_highlight()
						_search_from_cell = cell
						_search_from_cell.enable_highlight(Color.BLUE)
						
						if (_search_to_cell):
							hex_grid.find_path(_search_from_cell, _search_to_cell)
					elif (_search_from_cell) and (_search_from_cell != cell):
						_search_to_cell = cell
						hex_grid.find_path(_search_from_cell, _search_to_cell)
						

#endregion

#region GUI event handlers

func _on_check_box_no_color_pressed() -> void:
	active_terrain_type_index = -1
	return


func _on_check_box_color_yellow_pressed() -> void:
	active_terrain_type_index = 0
	return


func _on_check_box_color_green_pressed() -> void:
	active_terrain_type_index = 1
	return


func _on_check_box_color_blue_pressed() -> void:
	active_terrain_type_index = 2
	return


func _on_check_box_color_orange_pressed() -> void:
	active_terrain_type_index = 3
	return
	

func _on_check_box_color_white_pressed() -> void:
	active_terrain_type_index = 4
	return


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
	_set_wall_mode(Enums.OptionalToggle.Ignore)


func _on_check_box_walls_yes_pressed() -> void:
	_set_wall_mode(Enums.OptionalToggle.Yes)


func _on_check_box_walls_no_pressed() -> void:
	_set_wall_mode(Enums.OptionalToggle.No)


func _on_check_button_special_feature_toggled(toggled_on: bool) -> void:
	_set_apply_special_feature(toggled_on)


func _on_option_button_special_feature_item_selected(index: int) -> void:
	_set_special_feature_index(index)


func _on_save_button_pressed() -> void:
	#Lock the cameras
	main_camera_assembly.locked = true
	debug_camera.locked = true
	
	#Show the save file dialog
	save_map_file_dialog.show()


func _on_load_button_pressed() -> void:
	#Lock the cameras
	main_camera_assembly.locked = true
	debug_camera.locked = true
	
	#Show the load file dialog
	load_map_file_dialog.show()


func _on_new_map_button_pressed() -> void:
	#Show the popup menu
	new_map_popup_menu.show()
	
	#Lock the cameras
	main_camera_assembly.locked = true
	debug_camera.locked = true
	
	return


func _on_popup_menu_index_pressed(index: int) -> void:
	#Create the map based on the user's selection
	if (index == 0):
		hex_grid.create_map(20, 15)
	elif (index == 1):
		hex_grid.create_map(40, 30)
	elif (index == 2):
		hex_grid.create_map(80, 60)
	elif (index == 3):
		return
		
	#Unlock the cameras
	main_camera_assembly.locked = false
	debug_camera.locked = false
	
	#Validate the position of the main camera
	main_camera_assembly.validate_position()


func _on_save_file_dialog_file_selected(path: String) -> void:
	#Save the map to the file that was chosen by the user
	_save_map_file(path)
	
	#Unlock the cameras
	main_camera_assembly.locked = false
	debug_camera.locked = false


func _on_save_file_dialog_canceled() -> void:
	#Unlock the cameras
	main_camera_assembly.locked = false
	debug_camera.locked = false


func _on_load_file_dialog_file_selected(path: String) -> void:
	#Load the map from the file chosen by the user
	_load_map_file(path)
	
	#Unlock the cameras
	main_camera_assembly.locked = false
	debug_camera.locked = false
	
	#Validate the position of the main camera
	main_camera_assembly.validate_position()


func _on_load_file_dialog_canceled() -> void:
	#Unlock the cameras
	main_camera_assembly.locked = false
	debug_camera.locked = false


func _on_check_button_edit_mode_toggled(toggled_on: bool) -> void:
	_set_edit_mode(toggled_on)


#endregion

#region Private methods

func _initialize_ui () -> void:
	if (_selected_camera == 0):
		current_camera_value_label.text = "Main"
	elif (_selected_camera == 1):
		current_camera_value_label.text = "Debug"
	else:
		current_camera_value_label.text = "NA"
	
	check_button_show_labels.set_pressed_no_signal(active_show_labels)
	check_button_enable_elevation.set_pressed_no_signal(paint_terrain_elevation_enabled)
	check_button_water_level.set_pressed_no_signal(apply_water_level)
	check_button_urban_level.set_pressed_no_signal(apply_urban_level)
	check_button_farm_level.set_pressed_no_signal(apply_farm_level)
	check_button_plant_level.set_pressed_no_signal(apply_plant_level)
	
	if (active_terrain_type_index == -1):
		check_button_color_none.set_pressed_no_signal(true)
	elif (active_terrain_type_index == 0):
		check_button_color_yellow.set_pressed_no_signal(true)
	elif (active_terrain_type_index == 1):
		check_button_color_green.set_pressed_no_signal(true)
	elif (active_terrain_type_index == 2):
		check_button_color_blue.set_pressed_no_signal(true)
	elif (active_terrain_type_index == 3):
		check_button_color_orange.set_pressed_no_signal(true)
	elif (active_terrain_type_index == 4):
		check_button_color_white.set_pressed_no_signal(true)
		
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
	
	check_button_edit_mode.set_pressed_no_signal(edit_mode)

func show_ui (visible: bool) -> void:
	if (visible):
		hex_grid.set_all_cell_label_modes(HexCell.CellInformationLabelMode.Position)
	else:
		hex_grid.set_all_cell_label_modes(HexCell.CellInformationLabelMode.Off)

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
		if (active_terrain_type_index >= 0):
			cell.terrain_type_index = active_terrain_type_index
		
		#Paint the terrain elevation value
		if (paint_terrain_elevation_enabled):
			cell.elevation = active_elevation
		
		#Paint the water level value
		if (apply_water_level):
			cell.water_level = active_water_level
		
		#Paint the special feature
		if (apply_special_feature):
			cell.special_index = active_special_feature
		
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

func _set_terrain_type_index (index: int) -> void:
	active_terrain_type_index = index

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

func _set_apply_special_feature (toggle: bool) -> void:
	apply_special_feature = toggle

func _set_special_feature_index (index: float) -> void:
	active_special_feature = index

func _set_edit_mode (toggle: bool) -> void:
	edit_mode = toggle
	
	#Set the label mode
	if (edit_mode):
		hex_grid.disable_all_cell_highlights()
		hex_grid.reset_all_cell_distances()
		
		if (active_show_labels):
			hex_grid.set_all_cell_label_modes(HexCell.CellInformationLabelMode.Position)
		else:
			hex_grid.set_all_cell_label_modes(HexCell.CellInformationLabelMode.Off)
	else:
		hex_grid.set_all_cell_label_modes(HexCell.CellInformationLabelMode.Information)
		
	
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
		

func _save_map_file (file_path_and_name: String) -> void:
	#Open the file for writing
	var save_file: FileAccess = FileAccess.open(file_path_and_name, FileAccess.WRITE)
	
	#File version
	save_file.store_32(1)
	
	#Save the hex grid
	hex_grid.save_hex_grid(save_file)
	
	#Close the file
	save_file.close()

func _load_map_file (file_path_and_name: String) -> void:
	#Open the file for writing
	var load_file: FileAccess = FileAccess.open(file_path_and_name, FileAccess.READ)
	
	#Get the file version
	var file_version: int = load_file.get_32()
	
	#If the file version is 0...
	if (file_version <= 1):
		#Load the hex grid
		hex_grid.load_hex_grid(load_file, file_version)
		
		#Validate the position of the main camera
		main_camera_assembly.validate_position()
	
	#Close the file
	load_file.close()

#endregion
