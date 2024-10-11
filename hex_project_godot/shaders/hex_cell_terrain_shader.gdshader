shader_type spatial;

uniform sampler2DArray terrain_texture_2d_array:source_color;
varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_position.x *= 10.0;
	world_position.z *= 10.0;
}

void fragment() {
	vec2 uv = (world_position.xz * 10.0) * 0.02;
	vec4 c = texture(terrain_texture_2d_array, vec3(uv, 0));
	ALBEDO = c.rgb;// * COLOR.rgb;
	ALPHA = c.a;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
