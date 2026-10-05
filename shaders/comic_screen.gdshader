shader_type spatial;
render_mode unshaded;
uniform float local_time = 0.0;
uniform vec4 dark_color : source_color = vec4(0.16, 0.29, 0.34, 1.0);
uniform vec4 graphic_color : source_color = vec4(0.38, 0.65, 0.60, 1.0);

void fragment() {
	// Brief horizontal interference every six local seconds; no bright flashing.
	float phase = mod(local_time, 6.0);
	float glitch = step(5.78, phase) * (1.0 - step(5.92, phase));
	vec2 uv = UV;
	float strip = step(0.38, uv.y) * (1.0 - step(0.48, uv.y));
	uv.x += strip * glitch * 0.045;
	vec2 pixel = max(fwidth(uv), vec2(0.001));
	// Original station symbol: a diamond and a pair of direction chevrons.
	float diamond = abs(uv.x - 0.28) + abs(uv.y - 0.47) * 0.65;
	float icon = 1.0 - smoothstep(0.018, 0.018 + pixel.x, abs(diamond - 0.16));
	float arrow = abs(fract(uv.x * 5.0 + abs(uv.y - 0.46) * 3.0) - 0.5);
	float arrows = (1.0 - smoothstep(0.10, 0.10 + pixel.x * 5.0, arrow))
		* step(0.55, uv.x) * step(uv.x, 0.90) * step(abs(uv.y - 0.46), 0.17);
	float footer = step(0.77, uv.y) * step(uv.y, 0.80) * step(0.12, uv.x) * step(uv.x, 0.85);
	float scan = 0.97 + 0.03 * sin(uv.y * 150.0);
	ALBEDO = mix(dark_color.rgb, graphic_color.rgb, max(max(icon, arrows), footer)) * scan;
}
