shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D wall_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D skirt_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roughness_texture : filter_linear_mipmap, repeat_enable;
uniform float floor_height = 3.6;
uniform float origin_y = 0.0;
uniform bool paint_dado = true;
varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = MODEL_NORMAL_MATRIX * NORMAL;
}

vec3 paint(sampler2D tex, vec3 p, vec3 weights) {
	return texture(tex, p.zy).rgb * weights.x
		+ texture(tex, p.xz).rgb * weights.y
		+ texture(tex, p.xy).rgb * weights.z;
}

void fragment() {
	vec3 weights = pow(abs(normalize(world_normal)), vec3(8.0));
	weights /= max(dot(weights, vec3(1.0)), 0.001);
	vec3 p = world_position * 0.5;
	vec3 ivory = paint(wall_texture, p, weights);
	vec3 sakura = paint(skirt_texture, p, weights);
	float height = mod(world_position.y - origin_y + 0.001, floor_height);
	// Painted dado and two narrow trim lines; no added or displaced geometry.
	float vertical = (paint_dado ? 1.0 : 0.0) * (1.0 - smoothstep(0.05, 0.35, abs(normalize(world_normal).y)));
	float dado = (1.0 - smoothstep(0.82, 0.83, height)) * vertical;
	float trim = smoothstep(0.84, 0.85, height) * (1.0 - smoothstep(0.875, 0.885, height));
	float plinth = 1.0 - smoothstep(0.10, 0.11, height);
	ALBEDO = mix(ivory, sakura, dado * 0.92);
	ALBEDO = mix(ALBEDO, sakura * 0.86, max(trim, plinth) * 0.7 * vertical);
	ROUGHNESS = clamp(texture(roughness_texture, p.xy).r, 0.80, 0.94);
	SPECULAR = 0.22;
}
