class_name HexCoordinates

#region Public data members

var X: int = 0

var Z: int = 0

#endregion

#region Constructor

func _init(x: int, z:int) -> void:
	X = x
	Z = z

#endregion

#region Properties

var Y: int:
	get:
		return (-X - Z)

#endregion

#region Overriden methods

func _to_string() -> String:
	return "(" + str(X) + ", " + str(Y) + ", " + str(Z) + ")"

#endregion

#region Methods

func ToStringOnSeparateLines () -> String:
	return str(X) + "\n" + str(Y) + "\n" + str(Z)

#endregion

#region Static methods

static func FromOffsetCoordinates (x: int, z: int) -> HexCoordinates:
	return HexCoordinates.new(x - (z/2), z)
	
static func FromPosition(position: Vector3) -> HexCoordinates:
	var x = position.x / (HexCell.INNER_RADIUS * 2.0)
	var y = -x
	
	var offset = position.z / (HexCell.OUTER_RADIUS * 3.0)
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

#endregion
