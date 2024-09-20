shader_type spatial;

uniform vec4 base_color : source_color;
uniform sampler2D noise_texture;

varying vec3 world_position;

void vertex() 
{
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_position.x *= 10.0;
	world_position.z *= 10.0;
}

void fragment() 
{
	float shore = UV.y;
	shore = sqrt(shore);
	
	vec2 noise_uv = world_position.xz + TIME * 0.25;
	vec4 noise = texture(noise_texture, noise_uv * 0.015);
	
	float distortion1 = noise.x * (1.0 - shore);
	float foam1 = sin((shore + distortion1) * 10.0 - TIME);
	foam1 *= foam1 * shore;
	
	float distortion2 = noise.y * (1.0 - shore);
	float foam2 = sin((shore + distortion2) * 10.0 + TIME + 2.0);
	foam2 *= foam2 * 0.7;
	
	float foam = max(foam1, foam2) * shore;
	
	//vec4 c = clamp(base_color + waves, 0.0, 1.0);
	vec4 c = clamp(base_color + foam, 0.0, 1.0);
	ALBEDO = c.rgb;
	ALPHA = c.a;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
