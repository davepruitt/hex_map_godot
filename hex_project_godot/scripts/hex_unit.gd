class_name HexUnit
extends Node3D

#region Constants

const _TRAVEL_SPEED: int = 4

const _ROTATION_SPEED: float = 5.0

const _VISION_RANGE: int = 3

#endregion

#region Public data members

var hex_grid: HexGrid

#endregion

#region Private data members

var _location: HexCell

var _current_travel_location: HexCell

var _orientation: float

var _path_to_travel: Array[HexCell] = []

#endregion

#region Public static data members

static var unit_prefab: PackedScene

#endregion

#region Overrides

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#endregion

#region Properties

var location: HexCell:
	get:
		return _location
	set(value):
		if(value):
			#Check if there is a location previously set
			if (_location):
				#Decrease the visibility of the previous location as we leave that location
				hex_grid.decrease_visibility_in_game(location, _VISION_RANGE)
				
				#Set the previous location's unit reference to null
				_location.unit = null
			
			#Update the location to the new location
			_location = value
			
			#Set the unit reference of the new location to be the current unit
			value.unit = self
			
			#Increase the visibility of the new location
			hex_grid.increase_visibility_in_game(value, _VISION_RANGE)
			
			#Set the position of the unit to be the position of the hex cell location
			self.position = value.position

var orientation: float:
	get:
		return _orientation
	set(value):
		_orientation = value
		self.quaternion = Quaternion.from_euler(Vector3(0, value, 0))

#endregion

#region Methods

func travel (path: Array[HexCell]) -> void:
	#Unset the location's unit
	location.unit = null
	
	#Set the location to be the end of the path to travel
	location = path[len(path) - 1]
	
	#Set the location's unit to be this unit
	location.unit = self
	
	#Set the path to travel
	_path_to_travel = path
	
	#Travel the path
	_travel_path()

func die () -> void:
	if (location):
		hex_grid.decrease_visibility_in_game(location, _VISION_RANGE)
	
	location.unit = null
	self.queue_free()

func validation_location () -> void:
	self.position = location.position

func save_to_file (writer: FileAccess) -> void:
	location.hex_coordinates.save_to_file(writer)
	writer.store_float(orientation)

func is_valid_destination (cell: HexCell) -> bool:
	return (not cell.is_underwater) and (not cell.unit)

#endregion

#region Private Methods

func _look_at (point: Vector3) -> void:
	point.y =  self.position.y
	
	var from_rotation: Quaternion = self.quaternion
	var to_rotation: Quaternion = Transform3D.IDENTITY.looking_at(point - self.position).basis.get_rotation_quaternion()
	var angle: float = from_rotation.angle_to(to_rotation)
	var speed: float = _ROTATION_SPEED / angle
	
	if (angle > 0.0):
		var t: float = 0
		while t < 1.0:
			self.quaternion = from_rotation.slerp(to_rotation, t)
			
			#Wait for the next frame
			var delta_time: float = await _wait_for_next_frame()
			
			#Increment t
			t += delta_time * speed
	
	self.look_at(point)
	_orientation = self.rotation_degrees.y

func _wait_for_next_frame () -> float:
	#Get the current microseconds timestamp
	var start_us: int = Time.get_ticks_usec()
	
	#Wait until the next frame
	await get_tree().process_frame
	
	#Get the current microseconds timestamp
	var end_us: int = Time.get_ticks_usec()
	
	#Calculate the difference in time
	var elapsed_us: int = end_us - start_us
	
	#Convert the elapsed time to ms
	var elapsed_ms: float = float(elapsed_us) / 1000.0
	
	#Convert the elapsed time to seconds
	var elapsed_sec: float = elapsed_ms / 1000.0

	#Return the amount of elapsed time in units of seconds
	return elapsed_sec

func _travel_path () -> void:
	var a: Vector3 = _path_to_travel[0].position
	var b: Vector3 = a
	var c: Vector3 = a
	
	self.position = c
	await _look_at(_path_to_travel[1].position)
	
	#Decrease the visibility of the initial cell after we have looked away from it
	if (_current_travel_location != null):
		hex_grid.decrease_visibility_in_game(_current_travel_location, _VISION_RANGE)
	else:
		hex_grid.decrease_visibility_in_game(_path_to_travel[0], _VISION_RANGE)
	
	var t: float = 0.01
	for i in range(1, len(_path_to_travel)):
		#Set the current travel location
		_current_travel_location = _path_to_travel[i]
		
		#Get position information for the bezier curve generation
		a = c
		b = _path_to_travel[i - 1].position
		c = (b + _current_travel_location.position) * 0.5
		
		#Increase visibility of the path to travel cell
		hex_grid.increase_visibility_in_game(_path_to_travel[i], _VISION_RANGE)
		
		while t < 1.0:
			#Set the position
			var bezier_point: Vector3 = Bezier.get_point(a, b, c, t)
			self.position = bezier_point
			
			#Set the rotation
			var d: Vector3 = Bezier.get_derivative(a, b, c, t)
			d.y = 0
			self.orientation = Transform3D.IDENTITY.looking_at(d, Vector3.UP).basis.get_euler().y
			
			#Convert the elapsed time to seconds
			var elapsed_sec: float = await _wait_for_next_frame()
			
			#Increment t by the amount of time that elapsed
			t += elapsed_sec * _TRAVEL_SPEED
		
		#Decrease visibility of the path to travel cell
		hex_grid.decrease_visibility_in_game(_path_to_travel[i], _VISION_RANGE)
		
		t -= 1.0
	
	#Unset the current travel location
	_current_travel_location = null
	
	#Set the final bezier curve position information
	a = c
	b = location.position
	c = b
	
	#Increase visibility of the end location
	hex_grid.increase_visibility_in_game(location, _VISION_RANGE)
	
	while t < 1.0:
		#Set the position
		self.position = Bezier.get_point(a, b, c, t)
		
		#Set the rotation
		var d: Vector3 = Bezier.get_derivative(a, b, c, t)
		d.y = 0
		self.orientation = Transform3D.IDENTITY.looking_at(d, Vector3.UP).basis.get_euler().y
		
		#Wait for the next frame
		var elapsed_sec: float = await _wait_for_next_frame()
		t += elapsed_sec * _TRAVEL_SPEED
	
	#Set the final position and orientation
	self.position = location.position
	
	#Clear the path to travel
	_path_to_travel.clear()

#endregion

#region Static Methods

static func load_from_file (reader: FileAccess, grid: HexGrid) -> void:
	var coordinates: HexCoordinates = HexCoordinates.load_from_file(reader)
	var orientation: float = reader.get_float()
	
	var unit: HexUnit = HexUnit.unit_prefab.instantiate() as HexUnit
	grid.add_unit(unit, grid.get_cell_from_coordinates(coordinates), orientation)

#endregion
