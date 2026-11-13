shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float floor_y = 0.0;
uniform float slice_height = 2.4;
uniform vec4 floor_color : source_color = vec4(0.76, 0.74, 0.66, 1.0);
instance uniform vec4 map_color : source_color = vec4(0.28, 0.39, 0.37, 1.0);
varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = MODEL_NORMAL_MATRIX * NORMAL;
}

void fragment() {
	if (world_position.y < floor_y - 0.16 || world_position.y > floor_y + slice_height) {
		discard;
	}
	float horizontal = smoothstep(0.75, 0.95, abs(normalize(world_normal).y));
	ALBEDO = mix(map_color.rgb, floor_color.rgb, horizontal);
}
