class_name HexCoordinates

#region Public data members

## The x-coordinate within the grid
var X: int = 0

## The z-coordinate within the grid
var Z: int = 0

#endregion

#region Constructor

func _init(x: int, z: int) -> void:
	X = x
	Z = z

#endregion

#region Properties

## The y-coordinate within the grid. This value is calculated from the X and Z coordinates
var Y: int:
	get:
		return (-X - Z)

#endregion

#region Overriden methods

func _to_string() -> String:
	#Return a string with the representation "(x, y, z)"
	return "(" + str(X) + ", " + str(Y) + ", " + str(Z) + ")"

#endregion

#region Methods

func DistanceTo (other: HexCoordinates) -> int:
	var result_x: int = abs(X - other.X)
	var result_y: int = abs(Y - other.Y)
	var result_z: int = abs(Z - other.Z)
	
	var result: int = (result_x + result_y + result_z) / 2
	
	return result

func ToStringOnSeparateLines () -> String:
	#Same as the _to_string function, except each value is seperated by a new-line character
	return str(X) + "\n" + str(Y) + "\n" + str(Z)

func save_to_file (writer: FileAccess) -> void:
	writer.store_32(X)
	writer.store_32(Z)

#endregion

#region Static methods

static func FromOffsetCoordinates (x: int, z: int) -> HexCoordinates:
	#Static function to construct a HexCoordinates object from a set of offset coordinates
	return HexCoordinates.new(x - (z/2), z)
	
static func FromPosition(position: Vector3) -> HexCoordinates:
	#This function determines hex coordinates from a Vector3 position within the local hex grid
	var x = position.x / (HexMetrics.INNER_RADIUS * 2.0)
	var y = -x
	
	var offset = position.z / (HexMetrics.OUTER_RADIUS * 3.0)
	x -= offset
	y -= offset
	
	var iX: int = roundi(x)
	var iY: int = roundi(y)
	var iZ: int = roundi(-x - y)
	
	if (iX + iY + iZ) != 0:
		var dX = abs(x - iX)
		var dY = abs(y - iY)
		var dZ = abs(-x - y - iZ)
		
		if (dX > dY) and (dX > dZ):
			iX = -iY - iZ
		elif (dZ > dY):
			iZ = -iX - iY
	
	return HexCoordinates.new(iX, iZ)

static func load_from_file (reader: FileAccess) -> HexCoordinates:
	var x: int = reader.get_32()
	var z: int = reader.get_32()
	var c: HexCoordinates = HexCoordinates.new(x, z)
	
	return c

#endregion
