shader_type canvas_item;

void fragment() {
	vec2 p = UV - vec2(0.5);
	float alpha = 1.0 - smoothstep(0.49, 0.5, length(p));
	COLOR = texture(TEXTURE, UV) * vec4(1.0, 1.0, 1.0, alpha);
}
