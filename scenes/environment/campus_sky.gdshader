shader_type sky;

uniform float daylight : hint_range(0.0, 1.0) = 1.0;
uniform sampler2D horizon_texture : source_color, filter_linear, repeat_disable;
uniform vec4 distant_haze : source_color = vec4(0.40, 0.57, 0.64, 1.0);

void sky() {
	// Mirror the flat artwork around the sphere to join its left and right edges.
	float u = 1.0 - abs(fract(SKY_COORDS.x * 2.0 + 0.25) * 2.0 - 1.0);
	u = mix(0.006, 0.994, u);
	float elevation = asin(clamp(EYEDIR.y, -1.0, 1.0));
	float v = clamp(0.805 - (elevation + 0.187) * 1.65, 0.01, 0.98);
	float zenith = smoothstep(0.20, 0.43, elevation);
	vec3 panorama = texture(horizon_texture, vec2(u, v)).rgb;
	vec3 top = texture(horizon_texture, vec2(0.5, 0.025)).rgb;
	vec3 sky_color = mix(panorama, top, zenith);
	sky_color = mix(sky_color, distant_haze.rgb, smoothstep(0.798, 0.822, v));
	sky_color = mix(sky_color * vec3(0.055, 0.075, 0.16), sky_color, daylight);
	if (AT_CUBEMAP_PASS) {
		float luminance = dot(sky_color, vec3(0.2126, 0.7152, 0.0722));
		sky_color = mix(vec3(luminance), sky_color, 0.35);
	}
	COLOR = sky_color;
}
