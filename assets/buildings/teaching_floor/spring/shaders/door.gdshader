shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D paint_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D panel_texture : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D roughness_texture : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sign_texture : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform float bay_width = 8.0;
uniform float floor_height = 3.6;
uniform float first_classroom_bay = 2.0;
uniform float sign_center_height = 2.052;
uniform float sign_height = 0.18;
uniform float atlas_floor_count = 1.0;
uniform vec3 building_origin = vec3(0.0);
varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = MODEL_NORMAL_MATRIX * NORMAL;
}

void fragment() {
	vec3 p = world_position - building_origin;
	float x_in_bay = mod(p.x, bay_width);
	float bay = floor(p.x / bay_width);
	float is_classroom = step(first_classroom_bay, bay) * step(bay, first_classroom_bay + 7.0);
	float door_center = (x_in_bay < bay_width * 0.5 ? 0.11875 : 0.88125) * bay_width;
	if (is_classroom < 0.5) {
		door_center = (abs(bay - (first_classroom_bay + 8.0)) < 0.5 ? 0.1625 : 0.1375) * bay_width;
	}
	float y_in_floor = mod(p.y, floor_height);
	float door_width = bay_width * 0.125;
	vec2 panel_uv = vec2((x_in_bay - door_center) / door_width + 0.5, 1.0 - y_in_floor / 2.35);
	vec2 grain_uv = vec2(p.x * 0.65, -p.y * 0.42);
	float front = step(0.5, abs(world_normal.z));
	ALBEDO = mix(texture(paint_texture, grain_uv).rgb, texture(panel_texture, panel_uv).rgb, front);
	vec2 sign_uv = vec2((x_in_bay - door_center) / (bay_width * 0.0975) + 0.5,
		0.5 - (mod(p.y, floor_height) - sign_center_height) / sign_height);
	float face_mask = step(0.0, sign_uv.x) * step(sign_uv.x, 1.0)
		* step(0.0, sign_uv.y) * step(sign_uv.y, 1.0);
	// Office and toilet doors share this source material but are not classrooms.
	face_mask *= is_classroom * front;
	float room = clamp(bay - first_classroom_bay, 0.0, 7.0);
	float level = clamp(floor((p.y + 0.001) / floor_height), 0.0, atlas_floor_count - 1.0);
	vec2 atlas_uv = vec2((level + clamp(sign_uv.x, 0.025, 0.975)) / atlas_floor_count,
		(room + clamp(sign_uv.y, 0.01, 0.99)) / 8.0);
	ALBEDO = mix(ALBEDO, texture(sign_texture, atlas_uv).rgb, face_mask);
	METALLIC = 0.0;
	ROUGHNESS = mix(texture(roughness_texture, grain_uv).r, 0.75, face_mask);
	SPECULAR = 0.28;
}
