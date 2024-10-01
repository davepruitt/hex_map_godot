shader_type spatial;

#include "water.gdshaderinc"

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
	float foam = compute_foam(shore, world_position.xz, noise_texture);
	float waves = compute_waves(world_position.xz, noise_texture);

	waves *= 1.0 - shore;

	vec4 c = clamp(base_color + max(foam, waves), 0.0, 1.0);
	ALBEDO = c.rgb;
	ALPHA = c.a;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
