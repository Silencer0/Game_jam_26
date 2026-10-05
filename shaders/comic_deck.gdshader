shader_type spatial;
render_mode specular_disabled;
void fragment() {
	float seam = smoothstep(0.496, 0.5, abs(fract(UV.x * 8.0) - 0.5));
	ALBEDO = mix(vec3(0.64, 0.66, 0.54), vec3(0.42, 0.44, 0.40), seam);
	ROUGHNESS = 1.0;
}
void light() {
	if (!LIGHT_IS_DIRECTIONAL) {
		float facing = smoothstep(-0.02, 0.12, dot(NORMAL, LIGHT));
		DIFFUSE_LIGHT += facing * ATTENUATION * LIGHT_COLOR / PI;
	} else {
		float band = 0.50 + 0.50 * smoothstep(0.0, 0.04, dot(NORMAL, LIGHT));
		DIFFUSE_LIGHT += mix(vec3(0.36, 0.31, 0.45), vec3(band), smoothstep(0.4, 0.6, ATTENUATION)) * LIGHT_COLOR / PI;
	}
}
