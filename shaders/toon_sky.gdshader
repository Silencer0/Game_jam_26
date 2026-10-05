shader_type spatial;
render_mode unshaded, cull_disabled;
void fragment() {
	vec3 blue = mix(vec3(0.035, 0.26, 0.78), vec3(0.34, 0.77, 0.93), UV.y);
	// Fixed printed dots, filtered away when too small to resolve in side panels.
	vec2 grid = UV * vec2(640.0, 360.0);
	float footprint = max(length(fwidth(grid)), 0.001);
	float dots = 1.0 - smoothstep(0.19, 0.19 + footprint * 0.5, length(fract(grid) - 0.5));
	dots *= 1.0 - smoothstep(0.55, 1.15, footprint);
	ALBEDO = blue * (1.0 - dots * 0.075);
}
