shader_type spatial;
render_mode specular_disabled;
uniform vec4 wall_color : source_color = vec4(0.78, 0.30, 0.27, 1.0);
uniform vec4 ink_color : source_color = vec4(0.48, 0.22, 0.24, 1.0);
uniform vec4 stencil_color : source_color = vec4(0.88, 0.85, 0.69, 1.0);

// Fixed painted panel design, with derivative filtering for small comic panels.
// No screen texture, animation, noise texture or full-screen post process.
float ink_line(float distance_to_line, float width, float footprint) {
	return 1.0 - smoothstep(width, width + footprint, abs(distance_to_line));
}

void fragment() {
	vec2 pixel = max(fwidth(UV), vec2(0.0001));
	vec3 red = wall_color.rgb;
	vec3 seam = ink_color.rgb;
	float joints = max(ink_line(UV.x - 0.23, 0.0013, pixel.x),
		ink_line(UV.x - 0.57, 0.0013, pixel.x));
	joints = max(joints, ink_line(UV.x - 0.95, 0.0013, pixel.x));
	joints = max(joints, ink_line(UV.y - 0.80, 0.0018, pixel.y));
	// A narrow shadow under the coping gives the wall a drawn architectural edge.
	float cornice = 1.0 - smoothstep(0.022, 0.042, UV.y);
	vec3 paint = mix(red, seam, max(joints * 0.70, cornice * 0.60));
	// Hatching is restricted to two small corner patches, leaving most paint clean.
	float patch_a = smoothstep(0.76, 0.80, UV.x) * (1.0 - smoothstep(0.94, 0.96, UV.x))
		* smoothstep(0.11, 0.14, UV.y) * (1.0 - smoothstep(0.24, 0.30, UV.y));
	float patch_b = (1.0 - smoothstep(0.12, 0.19, UV.x)) * smoothstep(0.70, 0.85, UV.y);
	float stroke = (UV.x * 1.76 + UV.y) * 30.0;
	float stroke_pixel = max(fwidth(stroke), 0.001);
	float hatch = ink_line(fract(stroke) - 0.5, 0.14, stroke_pixel);
	hatch *= 1.0 - smoothstep(0.4, 1.0, stroke_pixel);
	paint = mix(paint, seam, hatch * max(patch_a, patch_b) * 0.66);
	// A muted cream service stripe, interrupted around the panels rather than
	// repeated across the full facade. The broad mark survives inactive views.
	float stripe = ink_line(UV.y - 0.15, 0.012, pixel.y)
		* smoothstep(0.30, 0.31, UV.x) * (1.0 - smoothstep(0.66, 0.67, UV.x));
	paint = mix(paint, stencil_color.rgb, stripe * 0.80);
	ALBEDO = paint;
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
		DIFFUSE_LIGHT += mix(vec3(0.36, 0.30, 0.47), vec3(ramp), cast_shadow) * LIGHT_COLOR / PI;
	}
}
