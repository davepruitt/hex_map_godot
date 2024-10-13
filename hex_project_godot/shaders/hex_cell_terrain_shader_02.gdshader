shader_type spatial;

uniform sampler2D texture_sand:source_color;
uniform sampler2D texture_grass:source_color;
uniform sampler2D texture_mud:source_color;
uniform sampler2D texture_stone:source_color;
uniform sampler2D texture_snow:source_color;

varying vec3 world_position;
varying vec3 terrain_index;

vec4 get_terrain_color (vec4 color, vec3 wp, int index)
{
	vec2 uv = wp.xz * 10.0 * 0.02;
	
	int t_idx = int(terrain_index[index]);
	vec4 c;
	switch(t_idx)
	{
		case 0:
			c = texture(texture_sand, uv);
			break;
		case 1:
			c = texture(texture_grass, uv);
			break;
		case 2:
			c = texture(texture_mud, uv);
			break;
		case 3:
			c = texture(texture_stone, uv);
			break;
		case 4:
			c = texture(texture_snow, uv);
			break;
	}
	
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
	vec4 c = get_terrain_color(COLOR, world_position, 0) +
		get_terrain_color(COLOR, world_position, 1) +
		get_terrain_color(COLOR, world_position, 2);
	ALBEDO = c.rgb;
	ALPHA = c.a;
}
