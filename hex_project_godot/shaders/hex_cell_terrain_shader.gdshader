shader_type spatial;

uniform sampler2DArray terrain_texture_2d_array:source_color;
uniform sampler2D grid_texture:source_color;
varying vec3 world_position;
varying vec3 terrain_index;

vec4 get_terrain_color (vec4 color, vec3 wp, int index)
{
	vec2 uv = wp.xz * 0.02;
	vec3 uvw = vec3(uv, terrain_index[index]);
	vec4 c = texture(terrain_texture_2d_array, uvw);
	return c * color[index];
}

void vertex() {
	//Get the world position
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	//Get the terrain index
	terrain_index = CUSTOM0.xyz;
}

void fragment() {
	vec4 c = get_terrain_color(COLOR, world_position, 0) +
		get_terrain_color(COLOR, world_position, 1) +
		get_terrain_color(COLOR, world_position, 2);
	
	vec2 grid_uv = world_position.xz;
	grid_uv.x *= 1.0 / (4.0 * 8.66025404);
	grid_uv.y *= 1.0 / (2.0 * 15.0);
	
	vec4 grid = texture(grid_texture, grid_uv);
	
	ALBEDO = c.rgb * grid.rgb;
	ALPHA = c.a;
}
