extends Node3D
## Shared by all teaching worlds. Geometry stays separate from player/camera collision.
const WARM := Color(1.0, 0.68, 0.36)
const HEIGHT := 4.32
const BAY := 10.4

var lights: Array[SpotLight3D] = []
var diffuser := StandardMaterial3D.new()
var _housing := BoxMesh.new()
var _panel := BoxMesh.new()

func _ready() -> void:
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color("54605b")
	metal.metallic = 0.35
	metal.roughness = 0.55
	_housing.size = Vector3(1.45, 0.11, 0.46)
	_housing.material = metal
	diffuser.albedo_color = Color("fff0d5")
	diffuser.roughness = 0.6
	diffuser.emission_enabled = true
	diffuser.emission = WARM
	_panel.size = Vector3(1.29, 0.035, 0.34)
	_panel.material = diffuser
	for level in range(5):
		var ceiling := (level + 1) * HEIGHT - 0.24
		for bay in range(14):
			for offset in [0.25, 0.75]:
				_fixture("F%d_Corridor_%d_%d" % [level + 1, bay, int(offset * 4)], Vector3((bay + offset) * BAY, ceiling, 2.4))
		# Two fixtures per enclosed bay, clear of stair shafts and restroom walls.
		for bay in [2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 13]:
			for offset in [0.25, 0.75]:
				_fixture("F%d_Room_%d_%d" % [level + 1, bay, int(offset * 4)], Vector3((bay + offset) * BAY, ceiling, -3.6))
		for center in [BAY * 1.5, BAY * 11.5]:
			# Attach to the next overhead turn landing, or to the roof above the top turn.
			if level < 4:
				var overhead := (level + 1) * HEIGHT + HEIGHT * 0.5 - 0.2 if level < 3 else 5 * HEIGHT - 0.24
				_fixture("F%d_StairTurn_%d" % [level + 1, int(center)], Vector3(center, overhead, -5.8))
			_fixture("F%d_StairEntry_%d" % [level + 1, int(center)], Vector3(center, (level + 1) * HEIGHT - (0.2 if level < 4 else 0.24), -0.4))
	GameTime.time_changed.connect(_on_time_changed)
	_on_time_changed(GameTime.current_hour)

func _fixture(label: String, ceiling: Vector3) -> void:
	var fixture := Node3D.new()
	fixture.name = label
	fixture.position = ceiling
	add_child(fixture)
	var housing := MeshInstance3D.new()
	housing.mesh = _housing
	housing.position.y = -0.055
	fixture.add_child(housing)
	var panel := MeshInstance3D.new()
	panel.mesh = _panel
	panel.position.y = -0.115
	panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fixture.add_child(panel)
	var light := SpotLight3D.new()
	light.name = "WarmLight"
	light.position.y = -0.17
	light.rotation.x = -PI / 2.0
	light.light_color = WARM
	light.spot_range = 5.5
	light.spot_angle = 64.0
	light.spot_attenuation = 0.7
	light.spot_angle_attenuation = 0.6
	light.shadow_enabled = true
	# Local shadows prevent light leaking through walls and between floors.
	light.distance_fade_enabled = true
	light.distance_fade_begin = 24.0
	light.distance_fade_length = 6.0
	light.distance_fade_shadow = 24.0
	fixture.add_child(light)
	lights.append(light)

func _on_time_changed(hour: float) -> void:
	var sun_height := sin((hour - 6.0) * TAU / 24.0)
	var night := 1.0 - smoothstep(-0.08, 0.16, sun_height)
	diffuser.emission_energy_multiplier = 3.5 * night
	for light in lights:
		light.light_energy = 1.5 * night
		light.visible = night > 0.001

func _exit_tree() -> void:
	if GameTime.time_changed.is_connected(_on_time_changed):
		GameTime.time_changed.disconnect(_on_time_changed)
