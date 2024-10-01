shader_type spatial;

uniform vec4 base_color : source_color;
uniform sampler2D noise_texture;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 noise = texture(noise_texture, NODE_POSITION_WORLD.xz * 0.025);
	vec4 c = base_color * (noise.y * 0.75 + 0.25);
	float blend = UV.x;
	blend *= noise.x + 0.5;
	blend = smoothstep(0.4, 0.7, blend);

	ALBEDO = c.rgb;
	//ALPHA = blend;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
