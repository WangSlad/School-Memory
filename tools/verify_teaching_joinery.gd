extends SceneTree
## Check the actual geometry and transparency decisions that avoid the reported bug.

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var building: Node3D = load("res://scenes/teaching_building/teaching_building.tscn").instantiate()
	building.restrooms_enabled = false # Verify the original joinery independently of room conversion.
	root.add_child(building)
	await process_frame
	var style: Node = building.get_node("Model/SpringMaterials")
	var window: StandardMaterial3D = style._palette["Window glazing"]
	var railing: StandardMaterial3D = style._palette["Transparent blue green glass"]
	assert(window != railing, "Classroom pane must not expose the unfurnished shell")
	assert(window.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED)
	assert(window.albedo_color.a == 1.0)
	assert(railing.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA)
	assert(railing.cull_mode == BaseMaterial3D.CULL_BACK)
	var glazing := building.get_node("GlazingPanels")
	assert(glazing.get_child_count() == 75)
	assert(glazing._sources.size() == 15)
	for source in glazing._sources:
		assert(not source.visible, "Merged transparent source must not also render")
	for pane: MeshInstance3D in glazing.get_children():
		assert(pane.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	var detail := building.get_node("JoineryDetail")
	assert(detail.get_child_count() == 20)
	assert(detail.get_meta("hidden_source_handle_groups") == 5)
	assert(detail.find_children("*", "CollisionObject3D", true, false).is_empty())
	assert(detail.get_meta("doors_per_floor") == 19)
	assert(detail.get_meta("windows_per_floor") == 22)
	var shared := {}
	var triangles := 0
	for instance: MeshInstance3D in detail.get_children():
		var mesh := instance.mesh
		if shared.has(mesh.get_instance_id()):
			continue
		shared[mesh.get_instance_id()] = true
		var arrays := mesh.surface_get_arrays(0)
		var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var edges := {}
		for i in range(0, points.size(), 3):
			var a := points[i]
			var b := points[i + 1]
			var c := points[i + 2]
			var cross := (b - a).cross(c - a)
			assert(cross.length_squared() > 1e-20, "Degenerate joinery triangle")
			assert(cross.dot(normals[i]) < 0, "Front face must wind clockwise")
			for pair in [[a, b], [b, c], [c, a]]:
				var p: Vector3 = pair[0].snapped(Vector3.ONE * 0.00001)
				var q: Vector3 = pair[1].snapped(Vector3.ONE * 0.00001)
				var key := str(p) + ":" + str(q) if p < q else str(q) + ":" + str(p)
				edges[key] = edges.get(key, 0) + 1
			triangles += 1
		for count in edges.values():
			assert(count % 2 == 0, "Joinery has an open boundary")
	assert(shared.size() == 4)
	assert(building.find_children("*", "StaticBody3D", true, false).size() == 104)
	print("JOINERY_OK closed_bevelled_profiles_per_floor=", detail.get_meta("closed_profiles_per_floor"),
		" shared_meshes=4 nodes=20 doors=95 windows=110 triangles_per_floor=", triangles,
		" window_opaque=yes railing_independent_panes=75 boundary_edges=0 colliders=104")
	quit()
