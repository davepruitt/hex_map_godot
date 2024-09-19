shader_type spatial;

void vertex() {
	UV.y -= TIME;
	UV.y = fract(UV.y);
}

void fragment() {
	ALBEDO = vec3(UV.x, UV.y, 0.0);
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
