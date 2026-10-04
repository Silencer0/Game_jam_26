shader_type canvas_item;
render_mode unshaded;
void fragment() {
	vec2 cell = mod(FRAGCOORD.xy, 9.0) - vec2(4.5);
	float dot = 1.0 - smoothstep(1.1, 1.5, length(cell));
	vec3 base = vec3(0.035, 0.043, 0.065);
	COLOR = vec4(base + dot * vec3(0.025, 0.03, 0.04), 1.0);
}
