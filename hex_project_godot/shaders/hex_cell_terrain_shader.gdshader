shader_type spatial;

uniform sampler2DArray terrain_texture_2d_array:source_color;
varying vec3 world_position;
varying vec3 terrain_index;

vec4 get_terrain_color (vec4 color, vec3 wp, int index)
{
	vec2 uv = wp.xz * 10.0 * 0.02;
	vec3 uvw = vec3(uv, terrain_index[index]);
	vec4 c = texture(terrain_texture_2d_array, uvw);
	return c * color[index];
}

void vertex() {
	//Get the world position
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_position.x *= 10.0;
	world_position.z *= 10.0;

	//Get the terrain index
	terrain_index = CUSTOM0.xyz;
}

void fragment() {
	//vec2 uv = (world_position.xz * 10.0) * 0.02;
	//vec4 c = texture(terrain_texture_2d_array, vec3(uv, 0));
	vec4 c = get_terrain_color(COLOR, world_position, 0); +
		get_terrain_color(COLOR, world_position, 1) +
		get_terrain_color(COLOR, world_position, 2);
	ALBEDO = c.rgb;// * COLOR.rgb;
	ALPHA = c.a;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
