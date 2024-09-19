shader_type spatial;

uniform sampler2D noise_texture;

void vertex()
{
	UV.x *= 0.0625;
	UV.y -= TIME * 0.25f;
	UV.y = fract(UV.y);
}

void fragment()
{
	vec4 texture_color = texture(noise_texture, UV);
	vec4 c = COLOR * texture_color.r;
	ALBEDO = vec3(c.r, c.g, c.b);
	ALPHA = c.a;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
