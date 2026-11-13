extends SceneTree
const BUILDING := preload("res://scenes/teaching_building/teaching_building.tscn")
const RESTROOM := preload("res://scenes/teaching_building/restroom_conversion.gd")

func _initialize() -> void:
	run.call_deferred()

func probe(space: PhysicsDirectSpaceState3D, a: Vector3, b: Vector3) -> Dictionary:
	return space.intersect_ray(PhysicsRayQueryParameters3D.create(a, b, 1))

func run() -> void:
	var baseline := BUILDING.instantiate()
	baseline.restrooms_enabled = false
	root.add_child(baseline)
	var revised := BUILDING.instantiate()
	root.add_child(revised)
	var source_model := baseline.get_node("Model")
	var target_model := revised.get_node("Model")
	var revised_resources := {}
	var modified_nodes := 0
	for source: MeshInstance3D in source_model.find_children("*", "MeshInstance3D", true, false):
		var target: MeshInstance3D = target_model.get_node(source_model.get_path_to(source))
		assert(source.transform == target.transform)
		if target.mesh.has_meta("restroom_source"):
			assert(target.mesh.get_meta("restroom_source") == source.mesh)
			modified_nodes += 1
			if revised_resources.has(target.mesh.get_instance_id()):
				continue
			revised_resources[target.mesh.get_instance_id()] = true
			var before := source.mesh.surface_get_arrays(0)
			var after := target.mesh.surface_get_arrays(0)
			assert(before[Mesh.ARRAY_VERTEX] == after[Mesh.ARRAY_VERTEX])
			var normals_before: PackedVector3Array = before[Mesh.ARRAY_NORMAL]
			var normals_after: PackedVector3Array = after[Mesh.ARRAY_NORMAL]
			for i in range(normals_before.size()):
				assert(normals_before[i].distance_to(normals_after[i]) < 0.001, "Normal changed beyond re-encoding tolerance")
			var removed: PackedInt32Array = target.mesh.get_meta("removed_indices")
			assert(before[Mesh.ARRAY_INDEX].size() == after[Mesh.ARRAY_INDEX].size() + removed.size())
			for index in removed:
				var p: Vector3 = before[Mesh.ARRAY_VERTEX][index]
				assert(p.x >= 135.199 and p.z >= -0.201 and p.z <= 0.301, "Geometry outside the last facade changed")
		else:
			assert(source.mesh == target.mesh, "Unrelated geometry replaced")
	assert(modified_nodes == 30 and revised_resources.size() == 6)
	var old_bodies := baseline.find_children("*", "StaticBody3D", true, false)
	assert(old_bodies.size() == 104)
	assert(revised.find_children("*", "StaticBody3D", true, false).size() == 109)
	var original_physics_unchanged := 0
	for body: StaticBody3D in old_bodies:
		var target: StaticBody3D = revised.get_node(baseline.get_path_to(body))
		assert(body.transform == target.transform and body.collision_layer == target.collision_layer)
		if body.get_parent() is MeshInstance3D and body.get_parent().mesh != target.get_parent().mesh:
			continue
		for i in range(body.get_child_count()):
			var original_shape: CollisionShape3D = body.get_child(i)
			var target_shape: CollisionShape3D = target.get_child(i)
			assert(original_shape.transform == target_shape.transform)
			if original_shape.shape is ConcavePolygonShape3D:
				assert(original_shape.shape.get_faces() == target_shape.shape.get_faces())
			elif original_shape.shape is ConvexPolygonShape3D:
				assert(original_shape.shape.points == target_shape.shape.points)
		original_physics_unchanged += 1
	assert(original_physics_unchanged == 79)
	assert(revised.find_children("Classroom_*", "Node3D", true, false).size() == 40)
	var restrooms := revised.get_node("Restrooms")
	var shared := {}
	for instance: MeshInstance3D in restrooms.find_children("*", "MeshInstance3D", true, false):
		shared[instance.mesh.get_instance_id()] = true
	assert(shared.size() == 11)
	assert(revised.get_node("JoineryDetail").get_meta("doors_per_floor") == 20)
	# Remove the comparison world's colliders before physical probes.
	baseline.queue_free()
	await process_frame
	await physics_frame
	await physics_frame
	var space: PhysicsDirectSpaceState3D = revised.get_world_3d().direct_space_state
	for floor_index in range(5):
		var h := floor_index * 4.32
		var floor_node := restrooms.get_node("Floor%02d_RestroomInterfaces" % (floor_index + 1))
		var men: Node3D = floor_node.get_node("Men/Entrance")
		var women: Node3D = floor_node.get_node("Women/Entrance")
		assert(men.global_position.x < women.global_position.x)
		assert(is_equal_approx(men.global_position.y, h + 0.04))
		assert(floor_node.get_node("Men").get_meta("side") == "left")
		assert(floor_node.get_node("Women").get_meta("side") == "right")
		# Full-height middle partition and left enclosure block cross-room passage.
		for y in [0.5, 1.6, 3.7]:
			assert(not probe(space, Vector3(139.5, h + y, -3.5), Vector3(141.5, h + y, -3.5)).is_empty())
		assert(not probe(space, Vector3(134.8, h + 1.5, -2), Vector3(136.0, h + 1.5, -2)).is_empty())
		for x in [136.65, 141.85]:
			# Doors remain closed static leaves, matching the rest of the building.
			var hit := probe(space, Vector3(x, h + 1.2, 0.6), Vector3(x, h + 1.2, -0.3))
			assert(not hit.is_empty() and hit.collider.get_parent() == restrooms)
		for x in [137.4, 142.5]:
			assert(not probe(space, Vector3(x, h + 0.4, -3.2), Vector3(x, h - 0.1, -3.2)).is_empty())
		# Toilet bases rest on the floor and physically block each occupied stall.
		for x in [136.255, 137.725, 141.455, 142.925, 144.395]:
			assert(not probe(space, Vector3(x, h + 0.1, -5.9), Vector3(x, h + 0.1, -6.6)).is_empty())
		# No residual old window/office facade in the new open interior.
		assert(probe(space, Vector3(136.9, h + 1.2, -3.2), Vector3(139.7, h + 1.2, -3.2)).is_empty())
		assert(probe(space, Vector3(135.5, h + 1, 2), Vector3(145.1, h + 1, 2)).is_empty(), "Corridor obstructed")
	print("RESTROOMS_OK floors=5 rooms=10 men_left=yes women_right=yes replacement_meshes=6 shared_room_meshes=11 colliders=109 unchanged_original_bodies=79 classrooms=40 corridor=4.8")
	quit()
