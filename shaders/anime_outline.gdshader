shader_type spatial;
render_mode unshaded, cull_front;
uniform sampler2D color_texture : source_color, filter_linear_mipmap;
uniform float width = 0.012;
void vertex() { VERTEX += NORMAL * width; }
void fragment() { if (texture(color_texture, UV).a < 0.4) { discard; } ALBEDO = vec3(0.065, 0.045, 0.10); }
