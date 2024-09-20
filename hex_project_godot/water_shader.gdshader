shader_type spatial;

uniform vec4 base_color : source_color;
uniform sampler2D noise_texture;


void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 c = base_color;
	ALBEDO = c.rgb;
	ALPHA = c.a;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
