class_name Main
extends Node3D

#region Public data members

var edit_mode: bool = true

#endregion

#region OnReady public data members

@onready var hex_grid := $HexGrid as HexGrid

@onready var cameras: Array[Camera3D] = [
	$HexMapCamera/Swivel/Stick/MainCamera,
	$DebugCamera
]

@onready var edit_mode_ui: HexMapEditorUi = $UI/HexMapEditorUi
@onready var game_mode_ui: HexGameUi = $UI/HexGameUi

#endregion

#region Private data members

var _selected_camera: int = 0

#endregion

#region Overrides

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Set the seed of the global random number generator. 
	#This allows for deterministic repeated-runs of the application.
	seed(1)
	
	#This allows us to cycle through some debug views of our meshes
	RenderingServer.set_debug_generate_wireframes(true)
	
	#Set the default camera
	cameras[_selected_camera].make_current()
	
	#Listen to the "exit edit mode" signal from the hex map editor ui
	edit_mode_ui.edit_mode_exited.connect(_handle_edit_mode_exited)
	
	#Listen to the "edit mode enabled" signal from the game ui
	game_mode_ui.edit_mode_enabled.connect(_handle_edit_mode_enabled)
	
	#Initialize the UI
	_initialize_ui()


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
		
		if event.keycode == KEY_G:
			hex_grid.hex_grid_overlay_enabled = !hex_grid.hex_grid_overlay_enabled
		
	
#endregion

#region Private methods

func _initialize_ui () -> void:
	_toggle_edit_mode(edit_mode)

func _handle_edit_mode_exited () -> void:
	_toggle_edit_mode(false)

func _handle_edit_mode_enabled () -> void:
	_toggle_edit_mode(true)

func _toggle_edit_mode (toggled: bool) -> void:
	edit_mode = toggled
	if (edit_mode):
		edit_mode_ui.enable()
		game_mode_ui.disable()
	else:
		edit_mode_ui.disable()
		game_mode_ui.enable()

#endregion
