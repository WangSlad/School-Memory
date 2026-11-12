shader_type spatial;
render_mode unshaded, blend_mix, depth_prepass_alpha, cull_disabled;

uniform sampler2D leaf_sheet : source_color, filter_linear, repeat_disable;

void vertex() {
	float scale_x = length(MODEL_MATRIX[0].xyz);
	float scale_y = length(MODEL_MATRIX[1].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(INV_VIEW_MATRIX[0].xyz * scale_x, 0.0),
		vec4(INV_VIEW_MATRIX[1].xyz * scale_y, 0.0),
		vec4(INV_VIEW_MATRIX[2].xyz, 0.0),
		MODEL_MATRIX[3]);
	float frame = floor(fract(INSTANCE_CUSTOM.z) * 10.0);
	UV = vec2((frame + UV.x) / 10.0, mix(0.36, 0.64, UV.y));
}

void fragment() {
	vec4 leaf = texture(leaf_sheet, UV);
	ALBEDO = leaf.rgb;
	ALPHA = leaf.a;
	ALPHA_SCISSOR_THRESHOLD = 0.08;
}
