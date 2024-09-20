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
	vec2 uv1 = world_position.xz;
	uv1.y += TIME * 0.25;
	vec4 noise1 = texture(noise_texture, uv1 * 0.025);
	
	vec2 uv2 = world_position.xz;
	uv2.x += TIME * 0.25;
	vec4 noise2 = texture(noise_texture, uv2 * 0.025);
	
	float blend_wave = sin((world_position.x + world_position.z) * 0.1f + (noise1.z + noise2.z) + TIME);
	blend_wave *= blend_wave;
	
	float waves = mix(noise1.z, noise1.w, blend_wave) + mix(noise2.z, noise2.y, blend_wave);
	waves = smoothstep(0.75, 2.0, waves);
	
	vec4 c = clamp(base_color + waves, 0.0, 1.0);
	ALBEDO = c.rgb;
	ALPHA = c.a;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
