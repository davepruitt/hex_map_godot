shader_type spatial;

#include "hex_cell_data.gdshaderinc"
#include "water.gdshaderinc"

uniform vec4 base_color : source_color;
uniform sampler2D noise_texture;

varying float visibility;

void vertex()
{
	vec4 cell0 = GetCellData(CUSTOM0.xyz, 0);
	vec4 cell1 = GetCellData(CUSTOM0.xyz, 1);
	
	visibility = (cell0.x * COLOR.x) + (cell1.x * COLOR.y);
	visibility = mix(0.25, 1, visibility);
}

void fragment()
{
	float river = compute_river(UV, noise_texture);
	vec4 c = clamp(base_color + river, 0.0, 1.0);
	ALBEDO = c.rgb * visibility;
	ALPHA = c.a;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
