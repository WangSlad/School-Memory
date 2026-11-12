extends Node

## A full in-game day takes this many real seconds.
@export_range(1.0, 86400.0, 1.0, "or_greater") var day_duration_seconds := 300.0
@export_range(0.0, 24.0, 0.01) var start_hour := 10.0
## Compass bearing of sunrise in the XZ plane, in degrees from +X towards +Z.
@export_range(-180.0, 180.0, 1.0) var sunrise_bearing := 0.0
@export var time_running := true

var current_hour: float

@onready var sun: DirectionalLight3D = $"../Sun"
@onready var moon: DirectionalLight3D = $"../Moon"
@onready var world_environment: WorldEnvironment = $"../WorldEnvironment"

func _ready() -> void:
	current_hour = fposmod(start_hour, 24.0)
	# Keep runtime changes local to this scene instance.
	world_environment.environment = world_environment.environment.duplicate(true)
	_update_lighting()

func _process(delta: float) -> void:
	if time_running and day_duration_seconds > 0.0:
		current_hour = fposmod(current_hour + delta * 24.0 / day_duration_seconds, 24.0)
		_update_lighting()

## Set the clock directly, including when the clock is paused.
func set_time(hour: float) -> void:
	current_hour = fposmod(hour, 24.0)
	if is_node_ready():
		_update_lighting()

func _update_lighting() -> void:
	# 06:00 and 18:00 lie on the horizon; noon is overhead.
	var angle := (current_hour - 6.0) * TAU / 24.0
	var bearing := deg_to_rad(sunrise_bearing)
	var sun_position := Vector3(cos(angle) * cos(bearing), sin(angle), cos(angle) * sin(bearing))
	_point_light(sun, sun_position)
	_point_light(moon, -sun_position)

	var daylight := smoothstep(-0.08, 0.16, sun_position.y)
	var moonlight := smoothstep(-0.08, 0.16, -sun_position.y)
	sun.light_energy = 4.0 * daylight
	moon.light_energy = 0.3 * moonlight
	var warm := 1.0 - smoothstep(0.0, 0.35, sun_position.y)
	sun.light_color = Color(1.0, 0.82, 0.52).lerp(Color(1.0, 0.94, 0.82), 1.0 - warm)
	var environment := world_environment.environment
	environment.ambient_light_energy = lerpf(0.035, 0.3, daylight)
	environment.ambient_light_color = Color(0.35, 0.43, 0.65).lerp(Color(0.86, 0.91, 1.0), daylight)
	var sky_material := environment.sky.sky_material as ShaderMaterial
	if sky_material:
		sky_material.set_shader_parameter("daylight", daylight)

func _point_light(light: DirectionalLight3D, position_in_sky: Vector3) -> void:
	# Godot directional lights shine along local -Z; +Z points at the source.
	var up := Vector3.FORWARD if absf(position_in_sky.dot(Vector3.UP)) > 0.99 else Vector3.UP
	light.global_basis = Basis.looking_at(-position_in_sky, up)
