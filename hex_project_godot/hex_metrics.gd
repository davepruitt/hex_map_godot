class_name HexMetrics

#region Constants

const OUTER_RADIUS: float = 1.0
const INNER_RADIUS: float = OUTER_RADIUS * 0.866025404

const CORNERS = [
	Vector3(0, 0, OUTER_RADIUS),
	Vector3(INNER_RADIUS, 0, 0.5 * OUTER_RADIUS),
	Vector3(INNER_RADIUS, 0, -0.5 * OUTER_RADIUS),
	Vector3(0, 0, -OUTER_RADIUS),
	Vector3(-INNER_RADIUS, 0, -0.5 * OUTER_RADIUS),
	Vector3(-INNER_RADIUS, 0, 0.5 * OUTER_RADIUS),
	Vector3(0, 0, OUTER_RADIUS),
]

const SOLID_FACTOR: float = 0.75

const BLEND_FACTOR: float = 1.0 - SOLID_FACTOR

const ELEVATION_STEP: float = 0.5

const TERRACES_PER_SLOPE: int = 2

const TERRACE_STEPS: int = TERRACES_PER_SLOPE * 2 + 1

const HORIZONTAL_TERRACE_STEP_SIZE: float = 1.0 / float(TERRACE_STEPS)

const VERTICAL_TERRACE_STEP_SIZE: float = 1.0 / float(TERRACES_PER_SLOPE + 1)

const CELL_PERTURB_STRENGTH: float = 0.1

const CELL_PERTURB_POSITION_MULTIPLIER: float = 100.0

const NOISE_SCALE: float = 1.0

const ELEVATION_PERTURB_STRENGTH: float = 0.015

const CHUNK_SIZE_X: int = 5

const CHUNK_SIZE_Z: int = 5

const STREAM_BED_ELEVATION_OFFSET: float = -0.1

#endregion

#region Static variables

static var noise_generator: Array[FastNoiseLite] = [
	FastNoiseLite.new(), 
	FastNoiseLite.new(), 
	FastNoiseLite.new(), 
	FastNoiseLite.new()
]

#endregion

#region Static Methods

static func initialize_noise_generator () -> void:
	for i in range(0, len(noise_generator)):
		noise_generator[i].noise_type = FastNoiseLite.TYPE_PERLIN
		noise_generator[i].seed = i
		noise_generator[i].frequency = 0.025
		noise_generator[i].fractal_type = FastNoiseLite.FRACTAL_FBM
		noise_generator[i].fractal_octaves = 2
		noise_generator[i].fractal_lacunarity = 2
		noise_generator[i].fractal_gain = 0.5
		noise_generator[i].fractal_weighted_strength = 0.0
		
	
static func sample_noise (position: Vector3) -> Vector4:
	var sample: Vector4 = Vector4.ZERO
	for i in range(0, len(noise_generator)):
		var s_i: float = noise_generator[i].get_noise_2d(
			position.x * NOISE_SCALE, 
			position.z * NOISE_SCALE
		)
		sample[i] = s_i
	
	return sample

static func get_first_corner (direction: HexDirectionsClass.HexDirections) -> Vector3:
	return HexMetrics.CORNERS[int(direction)]
	
static func get_second_corner (direction: HexDirectionsClass.HexDirections) -> Vector3:
	return HexMetrics.CORNERS[int(direction) + 1]	
	
static func get_first_solid_corner (direction: HexDirectionsClass.HexDirections) -> Vector3:
	return HexMetrics.CORNERS[int(direction)] * HexMetrics.SOLID_FACTOR
	
static func get_second_solid_corner (direction: HexDirectionsClass.HexDirections) -> Vector3:
	return HexMetrics.CORNERS[int(direction) + 1] * HexMetrics.SOLID_FACTOR

static func get_bridge (direction: HexDirectionsClass.HexDirections) -> Vector3:
	return (HexMetrics.CORNERS[int(direction)] + HexMetrics.CORNERS[int(direction) + 1]) * HexMetrics.BLEND_FACTOR

static func terrace_lerp (a: Vector3, b: Vector3, step: int) -> Vector3:
	var h = step * HORIZONTAL_TERRACE_STEP_SIZE
	a.x += (b.x - a.x) * h
	a.z += (b.z - a.z) * h
	
	#It is important for the first part of this equation to be integer
	#division, otherwise this does not work properly
	var v = ((step + 1) / 2) * VERTICAL_TERRACE_STEP_SIZE
	a.y += (b.y - a.y) * v
	
	return a
	
static func terrace_color_lerp (a: Color, b: Color, step: int) -> Color:
	var h = step * HORIZONTAL_TERRACE_STEP_SIZE
	return a.lerp(b, h)
	
static func get_edge_type (elevation1: int, elevation2: int) -> Enums.HexEdgeType:
	if (elevation1 == elevation2):
		return Enums.HexEdgeType.Flat
	
	var delta: int = elevation2 - elevation1
	if (delta == 1) or (delta == -1):
		return Enums.HexEdgeType.Slope
	
	return Enums.HexEdgeType.Cliff
	

#endregion
