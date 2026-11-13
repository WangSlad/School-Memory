extends Node3D
## Independent closed railing panes sort at each pane, with one visible skin.
## Imported render nodes are hidden AFTER their original collisions are built.
const GLASS := preload("res://assets/buildings/teaching_floor/spring/materials/glass.tres")
var _sources: Array[MeshInstance3D] = []

func _ready() -> void:
	for instance: MeshInstance3D in get_parent().get_node("Model").find_children("*", "MeshInstance3D", true, false):
		for surface in range(instance.mesh.get_surface_count()):
			var original := instance.mesh.surface_get_material(surface)
			if original != null and original.resource_name == "Transparent blue green glass":
				_sources.append(instance)
				instance.hide()
	var regular := BoxMesh.new()
	regular.size = Vector3(9.854, 1.04, 0.05)
	var inserted := BoxMesh.new()
	inserted.size = Vector3(9.85, 1.04, 0.05)
	var end := BoxMesh.new()
	end.size = Vector3(0.05, 1.04, 4.45)
	for floor_index in range(5):
		var h := floor_index * 4.32
		for bay in range(14):
			var mesh := inserted if bay == 1 else regular
			_pane("Floor%02d_Bay%02d" % [floor_index + 1, bay], mesh,
				Vector3((bay + 0.5) * 10.4, h + (0.55 if bay == 1 else 0.56), 4.6))
		_pane("Floor%02d_BalconyEnd" % (floor_index + 1), end, Vector3(0.1, h + 0.55, 2.4))

func _pane(label: String, mesh: BoxMesh, center: Vector3) -> void:
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = mesh
	instance.material_override = GLASS
	instance.position = center
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)

func restore_source() -> void:
	hide()
	for source in _sources:
		source.show()
