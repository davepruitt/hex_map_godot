float compute_river (vec2 river_uv, sampler2D noise_texture)
{
	vec2 uv = river_uv;
	uv.x = (uv.x * 0.0625) * (TIME * 0.005);
	uv.y -= TIME * 0.25f;
	uv.y = fract(uv.y);
	vec4 noise = texture(noise_texture, uv);

	vec2 uv2 = river_uv;
	uv2.x = (uv2.x * 0.0625) + (TIME * 0.0052);
	uv2.y -= TIME * 0.23;
	vec4 noise2 = texture(noise_texture, uv2);
	
	return (noise.x * noise2.w);
}

float compute_foam (float shore, vec2 world_xz, sampler2D noise_texture)
{
	shore = sqrt(shore) * 0.9;
	
	vec2 noise_uv = world_xz + TIME * 0.25;
	vec4 noise = texture(noise_texture, noise_uv * 0.015);
	
	float distortion1 = noise.x * (1.0 - shore);
	float foam1 = sin((shore + distortion1) * 10.0 - TIME);
	foam1 *= foam1 * shore;
	
	float distortion2 = noise.y * (1.0 - shore);
	float foam2 = sin((shore + distortion2) * 10.0 + TIME + 2.0);
	foam2 *= foam2 * 0.7;
	
	float foam = max(foam1, foam2) * shore;
	
	return foam;
}

float compute_waves (vec2 world_xz, sampler2D noise_texture)
{
	vec2 uv1 = world_xz;
	uv1.y += TIME * 0.25;
	vec4 noise1 = texture(noise_texture, uv1 * 0.025);
	
	vec2 uv2 = world_xz;
	uv2.x += TIME * 0.25;
	vec4 noise2 = texture(noise_texture, uv2 * 0.025);
	
	float blend_wave = sin((world_xz.x + world_xz.y) * 0.1f + (noise1.z + noise2.z) + TIME);
	blend_wave *= blend_wave;
	
	float waves = mix(noise1.z, noise1.w, blend_wave) + mix(noise2.z, noise2.y, blend_wave);
	waves = smoothstep(0.75, 2.0, waves);
	
	return waves;
}
