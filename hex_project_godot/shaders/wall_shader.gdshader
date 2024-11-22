shader_type spatial;

#include "hex_cell_data.gdshaderinc"

//This is the primary wall color
uniform vec4 color: source_color;

//This is the world position of the wall
varying vec3 world_position;

//This is whether the wall is currently visible by the player
varying float visibility;

//This is whether the wall sits in a cell that has been explored by the player
varying float explored;

void vertex() {
	//Get the world position
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	//Get the cell data
	vec4 cell0 = GetCellData(CUSTOM0.xyz, 0);
	vec4 cell1 = GetCellData(CUSTOM0.xyz, 1);
	vec4 cell2 = GetCellData(CUSTOM0.xyz, 2);

	//Set the visibility
	visibility = cell0.x;
	visibility = mix(0.25, 1, visibility);
	explored = cell0.y;
}

void fragment() {
	vec4 c = color;
	
	ALBEDO = c.rgb * visibility * explored;
	ALPHA = c.a;
	SPECULAR = 0.2 * explored;
	AO = explored;
	EMISSION = vec3(0, 0, 0) * (1.0 - explored);
}

