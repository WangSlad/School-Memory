extends Node

@export_range(0.0, 10.0, 0.1) var night_emission := 3.5
@export_range(0.0, 10.0, 0.1) var night_light_energy := 1.5
@export_range(0.1, 20.0, 0.1) var light_range := 5.0

var _materials: Array[BaseMaterial3D] = []
var _lights: Array[OmniLight3D] = []
var _day_emission: Array[float] = []

func _ready() -> void:
	# Model templates finish instantiating their meshes during their own _ready.
	_setup.call_deferred()

func _setup() -> void:
	for lamp in $"../CampusAdditions".get_children():
		if lamp.get("glb_scene") is PackedScene and lamp.glb_scene.resource_path.ends_with("/P06_plaza_lamp_v2.glb"):
			_setup_meshes(lamp, lamp)
	_update_lamps()

func _setup_meshes(node: Node, lamp: Node3D) -> void:
	if node is MeshInstance3D and node.mesh:
		for surface in node.mesh.get_surface_count():
			var original: Material = node.get_active_material(surface)
			if original is BaseMaterial3D and original.resource_name.to_lower() == "warm ivory glass":
				var material: BaseMaterial3D = original.duplicate()
				node.set_surface_override_material(surface, material)
				_materials.append(material)
				_day_emission.append(material.emission_energy_multiplier)
				var light := OmniLight3D.new()
				light.light_color = Color(1.0, 0.68, 0.36)
				light.omni_range = light_range
				light.shadow_enabled = false
				lamp.add_child(light)
				light.global_position = node.to_global(node.get_aabb().get_center())
				_lights.append(light)
	for child in node.get_children():
		_setup_meshes(child, lamp)

func _process(_delta: float) -> void:
	_update_lamps()

func _update_lamps() -> void:
	var sun_height := sin((GameTime.current_hour - 6.0) * TAU / 24.0)
	var night := 1.0 - smoothstep(-0.08, 0.16, sun_height)
	for i in _materials.size():
		_materials[i].emission_energy_multiplier = lerpf(_day_emission[i], night_emission, night)
	for light in _lights:
		light.light_energy = night_light_energy * night
		light.visible = night > 0.001
