shader_type canvas_item;
uniform float strength = 0.0;
uniform float phase = 0.0;
void fragment() {
 vec2 p = UV - vec2(0.5);
 float angle = atan(p.y, p.x);
 float rays = step(0.55, sin(angle * 19.0 + length(p) * 8.0));
 float edge = smoothstep(0.17, 0.65, length(p));
 float dots = step(0.72, sin(UV.x * 260.0) * sin(UV.y * 180.0));
 vec3 ink = phase < 0.22 ? vec3(1.0, 0.98, 0.85) : vec3(0.95, 0.12, 0.08);
 COLOR = vec4(ink, strength * (0.12 + edge * rays * 0.58 + dots * edge * 0.12));
}
