extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var world = load("res://scenes/teaching_building/teaching_building_test.tscn").instantiate()
	root.add_child(world)
	await physics_frame
	await physics_frame
	var space = world.get_world_3d().direct_space_state
	for i in range(5):
		var h = i * 4.32
		for probe in [[Vector3(35,h+1,1),Vector3(35,h-0.4,1)], [Vector3(35,h+.6,3.5),Vector3(35,h+.6,5.2)], [Vector3(35,h+.6,1),Vector3(35,h+.6,-.5)]]:
			var query = PhysicsRayQueryParameters3D.create(probe[0],probe[1],1)
			if space.intersect_ray(query).is_empty():
				print("COLLISION_MISSING floor=", i+1, " probe=", probe)
				quit(1); return
	print("FLOOR_RAIL_WALL_OK floors=5")
	quit()
