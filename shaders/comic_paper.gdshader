shader_type canvas_item;
render_mode unshaded;
void fragment() {
 vec2 grid = FRAGCOORD.xy / 7.0;
 float dots = 1.0 - smoothstep(0.11, 0.19, length(fract(grid) - 0.5));
 float edge = smoothstep(0.12, 0.7, length(UV - vec2(0.5)));
 COLOR = vec4(vec3(0.93, 0.91, 0.84) - dots * edge * 0.07, 1.0);
}
