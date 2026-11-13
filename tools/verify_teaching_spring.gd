extends SceneTree
## Run with Godot --headless --path . --script res://tools/verify_teaching_spring.gd

func _initialize() -> void:
	run.call_deferred()

func meshes(node: Node, result: Array) -> void:
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		meshes(child, result)

func run() -> void:
	var sample: Node3D = load("res://scenes/tests/teaching_spring_sample.tscn").instantiate()
	root.add_child(sample)
	await process_frame
	var style: Node = sample.get_node("Building/SpringMaterials")
	var all: Array = []
	meshes(sample.get_node("Building"), all)
	var shared := {}
	var expected := []
	var shader_count := 0
	for mesh in all:
		assert(mesh.material_override == null)
		for surface in range(mesh.mesh.get_surface_count()):
			var material: Material = mesh.get_active_material(surface)
			assert(material != null)
			shared[material.get_instance_id()] = true
			expected.append([mesh, surface, material])
			assert(mesh.mesh.surface_get_material(surface) != material)
			if material is ShaderMaterial:
				shader_count += 1
			elif material.resource_name not in ["Spring warm grout", "Spring mist blue glass", "Spring classroom frosted reflective glass"]:
				assert(material.uv1_triplanar and material.uv1_world_triplanar)
	assert(shared.size() == 9, "Expected separate wood, metal, window and railing roles")
	assert(shader_count > 0)
	# Disable restores the source resource exactly, then enable restores the palette.
	style.enabled = false
	await process_frame
	for slot in expected:
		assert(slot[0].get_surface_override_material(slot[1]) == null)
		assert(slot[0].get_active_material(slot[1]) == slot[0].mesh.surface_get_material(slot[1]))
	style.enabled = true
	await process_frame
	for slot in expected:
		var current: Material = slot[0].get_active_material(slot[1])
		assert(current.resource_name == slot[2].resource_name)
	# A second scene using the same GLB retains original material references.
	var original: Node3D = load("res://assets/buildings/teaching_floor/teaching_floor.glb").instantiate()
	root.add_child(original)
	var untouched: Array = []
	meshes(original, untouched)
	for mesh in untouched:
		for surface in range(mesh.mesh.get_surface_count()):
			assert(mesh.get_surface_override_material(surface) == null)
	print("SPRING_MATERIALS_OK meshes=", all.size(), " shared_materials=", shared.size(), " restoration=ok isolation=ok")
	quit()
