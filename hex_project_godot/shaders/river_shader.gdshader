shader_type spatial;

#include "water.gdshaderinc"

uniform vec4 base_color : source_color;
uniform sampler2D noise_texture;

void vertex()
{
	//empty
}

void fragment()
{
	float river = compute_river(UV, noise_texture);
	vec4 c = clamp(base_color + river, 0.0, 1.0);
	ALBEDO = c.rgb;
	ALPHA = c.a;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
