class_name EdgeVertices

#region Public data members

var v1: Vector3 = Vector3.ZERO

var v2: Vector3 = Vector3.ZERO

var v3: Vector3 = Vector3.ZERO

var v4: Vector3 = Vector3.ZERO

var v5: Vector3 = Vector3.ZERO

#endregion

#region Constructor

func _init(corner1: Vector3, corner2: Vector3, outer_step: float = 0.25) -> void:
	v1 = corner1
	v2 = corner1.lerp(corner2, outer_step)
	v3 = corner1.lerp(corner2, 0.5)
	v4 = corner1.lerp(corner2, 1.0 - outer_step)
	v5 = corner2


#endregion

#region Static methods

static func terrace_lerp (a: EdgeVertices, b: EdgeVertices, step: int) -> EdgeVertices:
	var result: EdgeVertices = EdgeVertices.new(Vector3.ZERO, Vector3.ZERO)
	
	result.v1 = HexMetrics.terrace_lerp(a.v1, b.v1, step)
	result.v2 = HexMetrics.terrace_lerp(a.v2, b.v2, step)
	result.v3 = HexMetrics.terrace_lerp(a.v3, b.v3, step)
	result.v4 = HexMetrics.terrace_lerp(a.v4, b.v4, step)
	result.v5 = HexMetrics.terrace_lerp(a.v5, b.v5, step)
	
	return result

#endregion
