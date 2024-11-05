shader_type spatial;

#include "hex_cell_data.gdshaderinc"

uniform sampler2DArray terrain_texture_2d_array:source_color;
uniform sampler2D grid_texture:source_color;
uniform bool grid_on = false;
varying vec3 world_position;
varying vec3 terrain_index;
varying vec3 terrain_visibility;

vec4 get_terrain_color (vec4 color, vec3 wp, int index)
{
	vec2 uv = wp.xz * 0.02;
	vec3 uvw = vec3(uv, terrain_index[index]);
	vec4 c = texture(terrain_texture_2d_array, uvw);
	c *= color[index];
	c.r *= terrain_visibility[index];
	c.g *= terrain_visibility[index];
	c.b *= terrain_visibility[index];
	return c;
}

void vertex() {
	//Get the world position
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	//Get the terrain index
	vec4 cell0 = GetCellData(CUSTOM0.xyz, 0);
	vec4 cell1 = GetCellData(CUSTOM0.xyz, 1);
	vec4 cell2 = GetCellData(CUSTOM0.xyz, 2);

	//Get the terrain index
	terrain_index = vec3(cell0.w, cell1.w, cell2.w);
	
	//Get the terrain visibility
	terrain_visibility = vec3(cell0.x, cell1.x, cell2.x);
	
	
	
	//Limit the range of cell visibility to be from 0.25 to 1
	//So "invisible cells" still have some limited visibility
	terrain_visibility.x = mix(0.25, 1, terrain_visibility.x);
	terrain_visibility.y = mix(0.25, 1, terrain_visibility.y);
	terrain_visibility.z = mix(0.25, 1, terrain_visibility.z);
}

void fragment() {
	vec4 c = get_terrain_color(COLOR, world_position, 0) +
		get_terrain_color(COLOR, world_position, 1) +
		get_terrain_color(COLOR, world_position, 2);
	
	if (grid_on)
	{
		vec2 grid_uv = world_position.xz;
		grid_uv.x *= 1.0 / (4.0 * 8.66025404);
		grid_uv.y *= 1.0 / (2.0 * 15.0);

		vec4 grid = texture(grid_texture, grid_uv);

		ALBEDO = c.rgb * grid.rgb;
	}
	else
	{
		ALBEDO = c.rgb;
	}

	ALPHA = c.a;
}
