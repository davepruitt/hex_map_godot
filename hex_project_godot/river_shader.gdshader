shader_type spatial;

uniform vec4 base_color : source_color;
uniform sampler2D noise_texture;

void vertex()
{
	//empty
}

void fragment()
{
	vec2 uv = UV;
	uv.x = (uv.x * 0.0625) * (TIME * 0.005);
	uv.y -= TIME * 0.25f;
	uv.y = fract(uv.y);

	vec2 uv2 = UV;
	uv2.x = (uv2.x * 0.0625) + (TIME * 0.0052);
	uv2.y -= TIME * 0.23;

	vec4 noise = texture(noise_texture, uv);
	vec4 noise2 = texture(noise_texture, uv2);
	vec4 c = clamp(base_color + (noise.r * noise2.a), 0.0, 1.0);
	ALBEDO = c.rgb;

	//ALPHA = 0.5;
	ALPHA = c.a;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
