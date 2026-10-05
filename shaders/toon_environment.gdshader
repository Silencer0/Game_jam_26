shader_type spatial;
render_mode specular_disabled;
uniform vec4 paint : source_color = vec4(0.8, 0.8, 0.7, 1.0);
varying vec3 world_position;
varying float hatch;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	// World-anchored, filtered ink stays attached to the set as the camera tilts.
	float stroke = (world_position.x + world_position.y * 1.4 + world_position.z * 0.6) * 5.5;
	float footprint = max(fwidth(stroke), 0.001);
	hatch = (1.0 - smoothstep(0.13, 0.13 + footprint, abs(fract(stroke) - 0.5)))
		* (1.0 - smoothstep(0.35, 0.85, footprint));
	ALBEDO = paint.rgb;
	ROUGHNESS = 1.0;
}
void light() {
	if (!LIGHT_IS_DIRECTIONAL) {
		float facing = smoothstep(-0.02, 0.12, dot(NORMAL, LIGHT));
		DIFFUSE_LIGHT += facing * ATTENUATION * LIGHT_COLOR / PI;
	} else {
		float n = dot(NORMAL, LIGHT);
		float ramp = 0.35 + 0.40 * smoothstep(-0.025, 0.025, n) + 0.25 * smoothstep(0.60, 0.64, n);
		float cast_shadow = smoothstep(0.4, 0.6, ATTENUATION);
		float shade = max(1.0 - cast_shadow, 1.0 - smoothstep(-0.20, 0.08, n));
		vec3 lighting = mix(vec3(0.36, 0.30, 0.47), vec3(ramp), cast_shadow);
		DIFFUSE_LIGHT += lighting * (1.0 - hatch * shade * 0.40) * LIGHT_COLOR / PI;
	}
}
