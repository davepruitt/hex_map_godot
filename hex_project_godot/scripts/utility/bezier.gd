class_name Bezier

#region Static methods

static func get_point (a: Vector3, b: Vector3, c: Vector3, t: float) -> Vector3:
	var r: float = 1.0 - t
	return ((r * r * a) + 
			(2.0 * r * t * b) + 
			(t * t * c))

#endregion
