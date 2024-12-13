class_name HexCoordinates

#region Public data members

## The x-coordinate within the grid
var X: int = 0

## The z-coordinate within the grid
var Z: int = 0

#endregion

#region Constructor

func _init(x: int, z: int) -> void:
	if (HexMetrics.wrapping):
		var oX: int = x + z / 2
		if (oX < 0):
			x += HexMetrics.wrap_size
		elif (oX >= HexMetrics.wrap_size):
			x -= HexMetrics.wrap_size
	
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
	var op1: int = 0
	if (X < other.X):
		op1 = other.X - X
	else:
		op1 = X - other.X
	
	var op2: int = 0
	if (Y < other.Y):
		op2 = other.Y - Y
	else:
		op2 = Y - other.Y
	
	var xy: int = op1 + op2
	
	if (HexMetrics.wrapping):
		other.X += HexMetrics.wrap_size

		if (X < other.X):
			op1 = other.X - X
		else:
			op1 = X - other.X
		
		if (Y < other.Y):
			op2 = other.Y - Y
		else:
			op2 = Y - other.Y
		
		var xy_wrapped: int = op1 + op2
		if (xy_wrapped < xy):
			xy = xy_wrapped
		else:
			other.X -= 2 * HexMetrics.wrap_size
			
			if (X < other.X):
				op1 = other.X - X
			else:
				op1 = X - other.X
			
			if (Y < other.Y):
				op2 = other.Y - Y
			else:
				op2 = Y - other.Y
			
			xy_wrapped = op1 + op2
			if (xy_wrapped < xy):
				xy = xy_wrapped
	
	var op_z: int = 0
	if (Z < other.Z):
		op_z = other.Z - Z
	else:
		op_z = Z - other.Z
	
	return (xy + op_z) / 2

func ToStringOnSeparateLines () -> String:
	#Same as the _to_string function, except each value is seperated by a new-line character
	return str(X) + "\n" + str(Y) + "\n" + str(Z)

func save_to_file (writer: FileAccess) -> void:
	writer.store_64(X)
	writer.store_64(Z)

#endregion

#region Static methods

static func FromOffsetCoordinates (x: int, z: int) -> HexCoordinates:
	#Static function to construct a HexCoordinates object from a set of offset coordinates
	return HexCoordinates.new(x - (z/2), z)
	
static func FromPosition(position: Vector3) -> HexCoordinates:
	#This function determines hex coordinates from a Vector3 position within the local hex grid
	var x = position.x / HexMetrics.INNER_DIAMETER
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
	var x: int = reader.get_64()
	var z: int = reader.get_64()
	var c: HexCoordinates = HexCoordinates.new(x, z)
	
	return c

#endregion
