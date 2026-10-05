shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform float local_time = 0.0;
void fragment() {
 float center = abs(UV.y - 0.5) * 2.0;
 float core = 1.0 - smoothstep(0.07, 0.19, center);
 float aura = pow(max(0.0, 1.0 - center), 2.0);
 float taper = smoothstep(0.0, 0.22, UV.x);
 float ripple = 0.82 + 0.18 * sin(UV.x * 45.0 - local_time * 70.0);
 ALBEDO = mix(vec3(0.20, 0.75, 1.0), vec3(1.0, 1.0, 0.92), core);
 ALPHA = (core + aura * 0.55) * taper * ripple;
}
