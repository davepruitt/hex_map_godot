shader_type spatial;

#include "hex_cell_data.gdshaderinc"
#include "water.gdshaderinc"

uniform vec4 base_color : source_color;
uniform sampler2D noise_texture;

varying vec3 world_position;
varying float visibility;
varying float explored;

void vertex()
{
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vec4 cell0 = GetCellData(CUSTOM0.xyz, 0);
	vec4 cell1 = GetCellData(CUSTOM0.xyz, 1);

	visibility = (cell0.x * COLOR.x) + (cell1.x * COLOR.y);
	visibility = mix(0.25, 1.0, visibility);
	explored = (cell0.y * COLOR.x) + (cell1.y * COLOR.y);
}

void fragment()
{
	float shore = UV.y;
	float foam = compute_foam(shore, world_position.xz, noise_texture);
	float waves = compute_waves(world_position.xz, noise_texture);

	float shore_water = max(foam, waves);

	float river = compute_river(UV2, noise_texture);

	float water = mix(shore_water, river, UV.x);

	//vec4 c = vec4(UV2, 1, 1);
	vec4 c = clamp(base_color + water, 0.0, 1.0);
	ALBEDO = c.rgb * visibility;
	ALPHA = c.a * explored;
	SPECULAR *= explored;
	AO = explored;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
