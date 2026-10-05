shader_type spatial;
render_mode unshaded, cull_disabled, depth_prepass_alpha;
uniform sampler2D color_texture : source_color, filter_linear_mipmap;
uniform vec4 ghost_color : source_color = vec4(1.0, 0.8, 0.25, 0.34);
void fragment() {
	vec4 tex = texture(color_texture, UV);
	if (tex.a < 0.4) { discard; }
	ALBEDO = ghost_color.rgb * (0.65 + dot(tex.rgb, vec3(0.2126, 0.7152, 0.0722)) * 0.35);
	ALPHA = ghost_color.a;
}
