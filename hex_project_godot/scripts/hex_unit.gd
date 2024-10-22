class_name HexUnit
extends Node3D

#region Constants

const _TRAVEL_SPEED: int = 4.0;

#endregion

#region Private data members

var _location: HexCell

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
			if (_location):
				_location.unit = null
			_location = value
			value.unit = self
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
	location = path[len(path) - 1]
	_path_to_travel = path
	
	_travel_path()

func die () -> void:
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

func _travel_path () -> void:
	for i in range(0, len(_path_to_travel)):
		var a: Vector3 = _path_to_travel[i - 1].position
		var b: Vector3 = _path_to_travel[i].position
		
		var t: float = 0.0
		while t < 1.0:
			#Set the position
			self.position = a.lerp(b, t)
			
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
			
			#Increment t by the amount of time that elapsed
			t += elapsed_sec * _TRAVEL_SPEED

#endregion

#region Static Methods

static func load_from_file (reader: FileAccess, grid: HexGrid) -> void:
	var coordinates: HexCoordinates = HexCoordinates.load_from_file(reader)
	var orientation: float = reader.get_float()
	
	var unit: HexUnit = HexUnit.unit_prefab.instantiate() as HexUnit
	grid.add_unit(unit, grid.get_cell_from_coordinates(coordinates), orientation)

#endregion
