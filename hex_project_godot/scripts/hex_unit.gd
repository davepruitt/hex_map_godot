class_name HexUnit
extends Node3D

#region Private data members

var _location: HexCell

var _orientation: float

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
		if (value):
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

func die () -> void:
	location.unit = null
	self.queue_free()

func validation_location () -> void:
	self.position = location.position

func save_to_file (writer: FileAccess) -> void:
	location.hex_coordinates.save_to_file(writer)
	writer.store_float(orientation)

#endregion

#region Static Methods

static func load_from_file (reader: FileAccess, grid: HexGrid) -> void:
	var coordinates: HexCoordinates = HexCoordinates.load_from_file(reader)
	var orientation: float = reader.get_float()
	
	var unit: HexUnit = HexUnit.unit_prefab.instantiate() as HexUnit
	grid.add_unit(unit, grid.get_cell_from_coordinates(coordinates), orientation)

#endregion
