shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform float opacity = 0.5;
void fragment() {
 vec2 p = (UV - vec2(0.5)) * 2.0;
 float shape = 1.0 - smoothstep(0.72, 1.0, length(p));
 float hatch = step(0.4, fract((UV.x + UV.y) * 13.0));
 ALBEDO = vec3(0.055, 0.065, 0.09);
 ALPHA = shape * opacity * (0.8 + hatch * 0.2);
}
