shader_type spatial;

#include "hex_cell_data.gdshaderinc"

uniform vec4 base_color : source_color;
uniform sampler2D noise_texture;

varying vec3 world_position;
varying float visibility;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	vec4 cell0 = GetCellData(CUSTOM0.xyz, 0);
	vec4 cell1 = GetCellData(CUSTOM0.xyz, 1);
	
	visibility = (cell0.x * COLOR.x) + (cell1.x * COLOR.y);
	visibility = mix(0.25, 1.0, visibility);
}

void fragment() {
	vec4 noise = texture(noise_texture, world_position.xz * 0.025);
	vec4 c = base_color * ((noise.y * 0.75 + 0.25) * visibility);

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
