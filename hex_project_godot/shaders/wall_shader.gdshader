shader_type spatial;

#include "hex_cell_data.gdshaderinc"

uniform vec4 color: source_color;

varying vec3 world_position;
varying float visibility;

void vertex() {
	//Get the world position
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	//Get the cell data
	vec4 cell0 = GetCellData(CUSTOM0.xyz, 0);
	vec4 cell1 = GetCellData(CUSTOM0.xyz, 1);
	vec4 cell2 = GetCellData(CUSTOM0.xyz, 2);

	//Set the visibility
	visibility = cell0.x;
	//visibility = mix(0.25, 1, visibility);
}

void fragment() {
	vec4 c = color;
	
	ALBEDO = c.rgb;// * visibility;
	ALPHA = c.a;
}

