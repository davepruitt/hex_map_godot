class_name Bezier

#region Static methods

static func get_point (a: Vector3, b: Vector3, c: Vector3, t: float) -> Vector3:
	t = clampf(t, 0.0, 1.0)
	
	var r: float = 1.0 - t
	return ((r * r * a) + 
			(2.0 * r * t * b) + 
			(t * t * c))

static func get_derivative (a: Vector3, b: Vector3, c: Vector3, t: float) -> Vector3:
	return (2.0 * ((1.0 - t) * (b - a) + (t * (c - b))))

#endregion
