shader_type canvas_item;
render_mode unshaded;
uniform vec4 edges = vec4(0.0, 1.0, 0.0, 1.0); // left/right at top, then bottom
void fragment() {
 float left = mix(edges.x, edges.z, UV.y);
 float right = mix(edges.y, edges.w, UV.y);
 float aa = max(fwidth(UV.x), 0.0001);
 float mask = smoothstep(left, left + aa, UV.x) * (1.0 - smoothstep(right - aa, right, UV.x));
 vec4 scene = texture(TEXTURE, UV);
 COLOR = vec4(scene.rgb, scene.a * mask);
}
