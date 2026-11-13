extends Node

## Compass bearing of sunrise in the XZ plane, in degrees from +X towards +Z.
@export_range(-180.0, 180.0, 1.0) var sunrise_bearing := 0.0
## Lower elevations keep sunlight entering windows instead of only hitting roofs.
@export_range(10.0, 90.0, 1.0) var noon_elevation := 90.0
## Per-world ambient levels keep covered interiors readable through the day.
@export_range(0.0, 2.0, 0.01) var night_ambient_energy := 0.035
@export_range(0.0, 2.0, 0.01) var day_ambient_energy := 0.3

@onready var sun: DirectionalLight3D = $"../Sun"
@onready var moon: DirectionalLight3D = $"../Moon"
@onready var world_environment: WorldEnvironment = $"../WorldEnvironment"

func _ready() -> void:
	# Keep runtime changes local to this scene instance.
	world_environment.environment = world_environment.environment.duplicate(true)
	GameTime.time_changed.connect(_on_time_changed)
	_update_lighting()

func _exit_tree() -> void:
	if GameTime.time_changed.is_connected(_on_time_changed):
		GameTime.time_changed.disconnect(_on_time_changed)

func _on_time_changed(_hour: float) -> void:
	_update_lighting()

func _update_lighting() -> void:
	# Tilt the daily arc around the sunrise axis for each world's orientation.
	var angle := (GameTime.current_hour - 6.0) * TAU / 24.0
	var bearing := deg_to_rad(sunrise_bearing)
	var elevation := deg_to_rad(noon_elevation)
	var sunrise_axis := Vector3(cos(bearing), 0.0, sin(bearing))
	var noon_axis := Vector3(-sin(bearing) * cos(elevation), sin(elevation), cos(bearing) * cos(elevation))
	var sun_position := sunrise_axis * cos(angle) + noon_axis * sin(angle)
	_point_light(sun, sun_position)
	_point_light(moon, -sun_position)

	var daylight := smoothstep(-0.08, 0.16, sun_position.y)
	var moonlight := smoothstep(-0.08, 0.16, -sun_position.y)
	sun.light_energy = 4.0 * daylight
	moon.light_energy = 0.3 * moonlight
	var warm := 1.0 - smoothstep(0.0, 0.35, sun_position.y)
	sun.light_color = Color(1.0, 0.82, 0.52).lerp(Color(1.0, 0.94, 0.82), 1.0 - warm)
	var environment := world_environment.environment
	environment.ambient_light_energy = lerpf(night_ambient_energy, day_ambient_energy, daylight)
	environment.ambient_light_color = Color(0.35, 0.43, 0.65).lerp(Color(0.86, 0.91, 1.0), daylight)
	var sky_material := environment.sky.sky_material as ShaderMaterial
	if sky_material:
		sky_material.set_shader_parameter("daylight", daylight)

func _point_light(light: DirectionalLight3D, position_in_sky: Vector3) -> void:
	# Godot directional lights shine along local -Z; +Z points at the source.
	var up := Vector3.FORWARD if absf(position_in_sky.dot(Vector3.UP)) > 0.99 else Vector3.UP
	light.global_basis = Basis.looking_at(-position_in_sky, up)
