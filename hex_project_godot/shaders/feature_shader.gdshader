shader_type spatial;

#include "hex_cell_data.gdshaderinc"

uniform vec4 color:source_color;

instance uniform float _index = 0.0;

varying vec3 world_position;
varying float visibility;
varying float explored;

void vertex() {
	//Get the world position
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	vec4 cell_data = GetCellData_FromFloatIndex(_index);
	
	visibility = cell_data.x;
	visibility = mix(0.25, 1, visibility);
	explored = cell_data.y;
}

void fragment() {
	vec4 c = color;
	
	ALBEDO = c.rgb * visibility * explored;
	ALPHA = c.a;
	SPECULAR = 0.2 * explored;
	AO = explored;
	EMISSION = vec3(0, 0, 0) * (1.0 - explored);
}

