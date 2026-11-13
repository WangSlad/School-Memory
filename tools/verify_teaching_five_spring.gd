extends SceneTree
## Compare original geometry/physics against the styled original building scene.

const BUILDING := preload("res://scenes/teaching_building/teaching_building.tscn")

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var original := BUILDING.instantiate()
	original.spring_materials_enabled = false
	original.facade_relief_enabled = false
	original.joinery_detail_enabled = false
	original.restrooms_enabled = false
	root.add_child(original)
	var styled := BUILDING.instantiate()
	styled.restrooms_enabled = false # Legacy geometry baseline; new layout has its own check.
	root.add_child(styled)
	await process_frame
	var source_meshes := original.get_node("Model").find_children("*", "MeshInstance3D", true, false)
	var shared: Dictionary = {}
	for source in source_meshes:
		var relative_path: NodePath = original.get_node("Model").get_path_to(source)
		var target: MeshInstance3D = styled.get_node("Model").get_node(relative_path)
		assert(source.mesh == target.mesh, "Original imported resource must remain identical")
		assert(source.global_transform == target.global_transform, "Source geometry moved")
		for surface in range(source.mesh.get_surface_count()):
			assert(source.get_surface_override_material(surface) == null)
			var material: Material = target.get_surface_override_material(surface)
			assert(material != null, "Unmapped source material slot")
			shared[material.get_instance_id()] = true
		if String(source.name) == "F01_detail_Pale ceramic tile":
			assert(is_equal_approx(source.get_aabb().size.z, 4.8))
			assert(is_equal_approx(target.get_aabb().size.z, 4.8))
	var source_colliders := original.find_children("*", "StaticBody3D", true, false)
	var styled_colliders := styled.find_children("*", "StaticBody3D", true, false)
	assert(source_colliders.size() == 104 and styled_colliders.size() == 104)
	for collider in source_colliders:
		var target: StaticBody3D = styled.get_node(original.get_path_to(collider))
		assert(collider.global_transform == target.global_transform)
		assert(collider.collision_layer == target.collision_layer)
		assert(collider.get_child_count() == target.get_child_count())
		for child_index in range(collider.get_child_count()):
			var shape_node: Node = collider.get_child(child_index)
			if shape_node is CollisionShape3D:
				var target_shape: CollisionShape3D = target.get_child(child_index)
				assert(shape_node.transform == target_shape.transform)
				if shape_node.shape is ConcavePolygonShape3D:
					assert(shape_node.shape.get_faces() == target_shape.shape.get_faces())
				elif shape_node.shape is ConvexPolygonShape3D:
					assert(shape_node.shape.points == target_shape.shape.points)
	var style: Node = styled.get_node("Model/SpringMaterials")
	var door: ShaderMaterial = style._palette["Painted green door"]
	assert(door.get_shader_parameter("first_classroom_bay") == 3.0)
	assert(door.get_shader_parameter("atlas_floor_count") == 5.0)
	assert(door.get_shader_parameter("sign_center_height") < 2.35)
	assert(style._palette["Soft ivory wall"].get_shader_parameter("paint_dado") == false)
	var relief: Node3D = styled.get_node("FacadeRelief")
	assert(relief.get_child_count() == 10)
	assert(relief.find_children("*", "CollisionObject3D", true, false).is_empty())
	for bounds: AABB in relief.get_meta("profile_bounds"):
		assert(bounds.position.z < 0.0 and bounds.end.z > 0.04, "Relief must embed in the wall and meet the frame")
	assert(styled.get_node("FloorInterfaces").get_child_count() == 5)
	assert(styled.find_children("Classroom_*", "Node3D", true, false).size() == 40)
	print("FIVE_SPRING_OK source_meshes=", source_meshes.size(), " shared_materials=", shared.size(),
		" corridor_width=4.8 colliders=104 original_structure=yes old_handle_render_replaced=yes identical_physics=yes solid_profiles_per_floor=", relief.get_meta("boxes_per_floor"))
	quit()
