shader_type canvas_item;
render_mode unshaded;
void fragment() {
 vec2 grid = FRAGCOORD.xy / 9.0;
 float dot = 1.0 - smoothstep(0.1, 0.23, length(fract(grid) - 0.5));
 float hatch = step(0.92, fract((FRAGCOORD.x + FRAGCOORD.y * 0.75) / 32.0));
 float edge = smoothstep(0.0, 0.8, length(UV - 0.5));
 COLOR = vec4(vec3(0.025, 0.03, 0.045) + vec3(0.045, 0.04, 0.03) * dot * edge + hatch * edge * 0.025, 0.94);
}
