shader_type spatial;

uniform vec4 base_color : source_color;
uniform sampler2D noise_texture;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_position.x *= 10.0;
	world_position.z *= 10.0;
}

void fragment() {
	vec4 noise = texture(noise_texture, world_position.xz * 0.025);
	vec4 c = base_color * (noise.y * 0.75 + 0.25);

	float blend = UV.x;
	blend *= noise.x + 0.5;
	blend = smoothstep(0.4, 0.7, blend);

	ALBEDO = c.rgb;
	ALPHA = blend;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
