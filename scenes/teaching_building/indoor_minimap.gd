extends Node3D
## Shared meshes in a private viewport world: cutaway changes never touch gameplay.

const MAP_SHADER := preload("res://scenes/teaching_building/indoor_minimap.gdshader")
var floor_index := -1
var material := ShaderMaterial.new()
var _entries: Array[Dictionary] = []

func build(building: Node3D) -> void:
	material.shader = MAP_SHADER
	for source: MeshInstance3D in building.find_children("*", "MeshInstance3D", true, false):
		if not source.is_visible_in_tree() or source.mesh == null:
			continue
		var copy := MeshInstance3D.new()
		copy.name = source.name
		copy.mesh = source.mesh
		copy.material_override = material
		copy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(copy)
		copy.global_transform = source.global_transform
		var label := String(source.name).to_lower()
		var color := Color("526f68")
		if label.contains("glass") or label.contains("glaz"):
			color = Color("7fadb9")
		elif label.contains("metal") or label.contains("frame") or label.contains("joinery"):
			color = Color("40534f")
		copy.set_instance_shader_parameter("map_color", color)
		_entries.append({"mesh": copy, "bounds": source.global_transform * source.get_aabb()})

func show_floor(index: int, world_floor_y: float) -> void:
	if floor_index == index:
		return
	floor_index = index
	material.set_shader_parameter("floor_y", world_floor_y)
	for entry in _entries:
		var bounds: AABB = entry.bounds
		entry.mesh.visible = bounds.end.y >= world_floor_y - 0.16 and bounds.position.y <= world_floor_y + 2.4
