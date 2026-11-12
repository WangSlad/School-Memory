shader_type particles;

uniform vec2 emission_area = vec2(20.0, 20.0);
uniform float position_randomness = 1.0;
uniform float fall_speed = 1.5;
uniform vec2 wind = vec2(0.6, 0.15);
uniform float turbulence = 0.4;
uniform float rotation_speed = 1.0;
uniform float leaf_size = 0.35;
uniform float size_randomness = 0.35;
uniform float speed_randomness = 0.3;
uniform float particle_count = 120.0;

float random_value(float seed) {
	return fract(sin(seed * 127.1 + 311.7) * 43758.5453);
}

void start() {
	float seed = float(NUMBER) + float(RANDOM_SEED % 65536u) * 0.03125;
	float x = random_value(seed + 1.0);
	float z = random_value(seed + 2.0);
	float grid_width = max(1.0, ceil(sqrt(particle_count)));
	vec2 grid = (vec2(mod(float(INDEX), grid_width), floor(float(INDEX) / grid_width)) + 0.5) / grid_width;
	vec2 position_2d = mix(grid, vec2(x, z), position_randomness) - vec2(0.5);
	TRANSFORM[3].xyz = vec3(position_2d.x * emission_area.x, 0.0, position_2d.y * emission_area.y);
	float leaf_scale = leaf_size * mix(1.0, mix(0.5, 1.5, random_value(seed + 3.0)), size_randomness);
	TRANSFORM[0].xyz = vec3(leaf_scale, 0.0, 0.0);
	TRANSFORM[1].xyz = vec3(0.0, leaf_scale, 0.0);
	TRANSFORM[2].xyz = vec3(0.0, 0.0, leaf_scale);
	CUSTOM.x = random_value(seed + 4.0) * TAU;
	CUSTOM.y = 0.0;
	CUSTOM.z = random_value(seed + 5.0);
	CUSTOM.w = mix(1.0, mix(0.5, 1.5, random_value(seed + 6.0)), speed_randomness);
	COLOR = vec4(1.0);
}

void process() {
	CUSTOM.y += DELTA;
	CUSTOM.z = fract(CUSTOM.z + rotation_speed * DELTA);
	float phase = CUSTOM.x + CUSTOM.y;
	vec2 gust = vec2(sin(phase * 1.35), cos(phase * 0.91)) * turbulence;
	VELOCITY = vec3(wind.x + gust.x, -fall_speed * CUSTOM.w, wind.y + gust.y);
}
