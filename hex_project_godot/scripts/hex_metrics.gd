class_name HexMetrics

#region Constants

## The current map file version
const MAP_FILE_VERSION: int = 5

## Ratio of outer to inner radius of a hex
const OUTER_TO_INNER: float = 0.866025404

## Ratio of inner to outer radius of a hex
const INNER_TO_OUTER: float = 1.0 / OUTER_TO_INNER

## The outer radius of a hex
const OUTER_RADIUS: float = 10.0

## The inner radius of a hex
const INNER_RADIUS: float = OUTER_RADIUS * OUTER_TO_INNER

## The inner diameter of a hex
const INNER_DIAMETER: float = INNER_RADIUS * 2.0

## Relative positions of each hex corner from the center of a hex
const CORNERS = [
	Vector3(0, 0, OUTER_RADIUS),
	Vector3(INNER_RADIUS, 0, 0.5 * OUTER_RADIUS),
	Vector3(INNER_RADIUS, 0, -0.5 * OUTER_RADIUS),
	Vector3(0, 0, -OUTER_RADIUS),
	Vector3(-INNER_RADIUS, 0, -0.5 * OUTER_RADIUS),
	Vector3(-INNER_RADIUS, 0, 0.5 * OUTER_RADIUS),
	Vector3(0, 0, OUTER_RADIUS),
]

## Percent of the inside of a hex that is the solid uniform region (0.8 = 80%)
const SOLID_FACTOR: float = 0.8

## Percent of the outside of a hex that is the "blending region" with other hexes
const BLEND_FACTOR: float = 1.0 - SOLID_FACTOR

## The y-axis height of a single elevation step
const ELEVATION_STEP: float = 3.0

## The number of terrace levels per slope
const TERRACES_PER_SLOPE: int = 2

## The number of terrace steps per slope
const TERRACE_STEPS: int = TERRACES_PER_SLOPE * 2 + 1

## The horizontal size of a terrace step
const HORIZONTAL_TERRACE_STEP_SIZE: float = 1.0 / float(TERRACE_STEPS)

## The vertical size of a terrace step
const VERTICAL_TERRACE_STEP_SIZE: float = 1.0 / float(TERRACES_PER_SLOPE + 1)

## The strength of cell position perturbation
const CELL_PERTURB_STRENGTH: float = 0.4

## Constant used to scale the world position when sampling from the world noise
const NOISE_SCALE: float = 10.0

## Strength of vertical elevation perturbation
const ELEVATION_PERTURB_STRENGTH: float = 0.0 #0.75

## The number of hexes in the x dimension of a hex chunk
const CHUNK_SIZE_X: int = 5

## The number of hexes int he z dimension of a hex chunk
const CHUNK_SIZE_Z: int = 5

## The y-axis elevation offset of a stream bed / river bed
const STREAM_BED_ELEVATION_OFFSET: float = -1.75

## The y-axis elevation offset of the surface of a river
const RIVER_SURFACE_ELEVATION_OFFSET: float = 0.5 * STREAM_BED_ELEVATION_OFFSET

## The y-axis elevation offset of water
const WATER_ELEVATION_OFFSET: float = -0.5

## In a water hex, the percent that defines the inner uniform region
const WATER_FACTOR: float = 0.6

## In a water hex, the percent that defines the outer blended region
const WATER_BLEND_FACTOR: float = 1.0 - WATER_FACTOR

## Size of the hash grid, used when randomizing features on the hex grid
const HASH_GRID_SIZE: int = 256

## Scale of the has grid, used when randomizing features on the hex grid
const HASH_GRID_SCALE: float = 0.25

## The number of feature levels
const FEATURE_THRESHOLD_LEVELS: int = 3

## The number of feature sub-levels
const FEATURE_THRESHOLD_SUB_LEVELS: int = 3

## The height of walls in the world
const WALL_HEIGHT: float = 4.0

## The y-offset of walls (so technically they go below the ground)
const WALL_Y_OFFSET: float = -1.0

## The thickness of walls in the world 
const WALL_THICKNESS: float = 0.75

const WALL_ELEVATION_OFFSET: float = VERTICAL_TERRACE_STEP_SIZE

const WALL_TOWER_THRESHOLD: float = 0.5

const BRIDGE_DESIGN_LENGTH: float = 7.0

#endregion

#region Static variables

static var noise_generator: Array[FastNoiseLite] = [
	FastNoiseLite.new(), 
	FastNoiseLite.new(), 
	FastNoiseLite.new(), 
	FastNoiseLite.new()
]

static var hash_grid: Array[HexHash] = []

static var feature_thresholds: Array[float] = [
	0.0, 0.0, 0.4,			#Low
	0.0, 0.4, 0.6,			#Medium
	0.4, 0.6, 0.8			#High
]

## This array is populated upon initialization of the application
static var colors: Array[Color] = []

static var display_mode: Enums.DisplayMode = Enums.DisplayMode.TerrainTextures

static var wrap_size: int = 0

static var wrapping: bool:
	get:
		return (wrap_size > 0)

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
	
	if (wrapping) and (position.x < (INNER_DIAMETER * 1.5)):
		var sample2: Vector4 = Vector4.ZERO
		for i in range(0, len(noise_generator)):
			var s_i: float = noise_generator[i].get_noise_2d(
				(position.x + wrap_size * INNER_DIAMETER) * NOISE_SCALE,
				position.z * NOISE_SCALE
			)
		
		sample = sample2.lerp(sample, position.x * (1.0 / INNER_DIAMETER) - 0.5)
	
	return sample

static func initialize_hash_grid () -> void:
	hash_grid.clear()
	hash_grid.resize(HASH_GRID_SIZE * HASH_GRID_SIZE)
	for i in range(0, len(hash_grid)):
		hash_grid[i] = HexHash.create()

static func sample_hash_grid (position: Vector3) -> HexHash:
	var x: int = int((position.x * 10.0) * HASH_GRID_SCALE) % HASH_GRID_SIZE
	if (x < 0):
		x += HASH_GRID_SIZE
		
	var z: int = int((position.z * 10.0) * HASH_GRID_SCALE) % HASH_GRID_SIZE
	if (z < 0):
		z += HASH_GRID_SIZE
	
	return hash_grid[x + z * HASH_GRID_SIZE]

static func get_feature_thresholds (level: int) -> Array[float]:
	var idx: int = level * FEATURE_THRESHOLD_SUB_LEVELS
	
	var result: Array[float] = []
	result.resize(FEATURE_THRESHOLD_SUB_LEVELS)
	
	for i in range(0, FEATURE_THRESHOLD_SUB_LEVELS):
		if ((idx + i) < len(feature_thresholds)):
			result[i] = feature_thresholds[idx + i]
	
	return result

static func get_first_corner (direction: HexDirectionsClass.HexDirections) -> Vector3:
	return HexMetrics.CORNERS[int(direction)]
	
static func get_second_corner (direction: HexDirectionsClass.HexDirections) -> Vector3:
	return HexMetrics.CORNERS[int(direction) + 1]	
	
static func get_first_solid_corner (direction: HexDirectionsClass.HexDirections) -> Vector3:
	return HexMetrics.CORNERS[int(direction)] * HexMetrics.SOLID_FACTOR
	
static func get_second_solid_corner (direction: HexDirectionsClass.HexDirections) -> Vector3:
	return HexMetrics.CORNERS[int(direction) + 1] * HexMetrics.SOLID_FACTOR
	
static func get_first_water_corner (direction: HexDirectionsClass.HexDirections) -> Vector3:
	return HexMetrics.CORNERS[int(direction)] * HexMetrics.WATER_FACTOR
	
static func get_second_water_corner (direction: HexDirectionsClass.HexDirections) -> Vector3:
	return HexMetrics.CORNERS[int(direction) + 1] * HexMetrics.WATER_FACTOR

static func get_bridge (direction: HexDirectionsClass.HexDirections) -> Vector3:
	return (HexMetrics.CORNERS[int(direction)] + HexMetrics.CORNERS[int(direction) + 1]) * HexMetrics.BLEND_FACTOR

static func get_water_bridge (direction: HexDirectionsClass.HexDirections) -> Vector3:
	return (HexMetrics.CORNERS[int(direction)] + HexMetrics.CORNERS[int(direction) + 1]) * HexMetrics.WATER_BLEND_FACTOR

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
	
static func get_solid_edge_middle (direction: HexDirectionsClass.HexDirections) -> Vector3:
	return (CORNERS[int(direction)] + CORNERS[int(direction) + 1]) * (0.5 * SOLID_FACTOR)

static func perturb (pos: Vector3) -> Vector3:
	#Get a 4D noise sample
	var sample: Vector4 = HexMetrics.sample_noise(pos)
	
	pos.x += (sample.x * 2.0 - 1.0) * HexMetrics.CELL_PERTURB_STRENGTH
	pos.z += (sample.z * 2.0 - 1.0) * HexMetrics.CELL_PERTURB_STRENGTH
	
	return pos

static func wall_thickness_offset (near: Vector3, far: Vector3) -> Vector3:
	var offset: Vector3 = Vector3.ZERO
	
	offset.x = far.x - near.x
	offset.y = 0
	offset.z = far.z - near.z
	
	return (offset.normalized() * (WALL_THICKNESS * 0.5))

static func wall_lerp (near: Vector3, far: Vector3) -> Vector3:
	near.x += (far.x - near.x) * 0.5
	near.z += (far.z - near.z) * 0.5
	
	var v: float = WALL_ELEVATION_OFFSET
	if (near.y < far.y):
		v = 1.0 - WALL_ELEVATION_OFFSET
	
	near.y += (far.y - near.y) * v + WALL_Y_OFFSET
	
	return near

#endregion
