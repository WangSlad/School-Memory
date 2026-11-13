extends SceneTree
## Free indoor orbit, continuous region transitions, and current-floor minimap.

var failures := 0
var checks := 0
var worst_step := 0.0

func _initialize() -> void:
	run.call_deferred()

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		if failures <= 20:
			push_error(message)

func capture(label: String, minimap: Control) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	for frame in range(15):
		await RenderingServer.frame_post_draw
	var directory := "res://docs/teaching_world_review"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	root.get_texture().get_image().save_png(directory + "/camera_" + label + ".png")
	minimap.map_view.get_texture().get_image().save_png(directory + "/minimap_" + label + ".png")

func run() -> void:
	root.get_node("GameTime").time_running = false
	root.get_node("GameTime").set_time(9.0)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	var actor: CharacterBody3D = game.get_node("StudentCharacter")
	actor.set_physics_process(false)
	var pivot = actor.get_node("CameraPivot")
	pivot.set_physics_process(false)
	var camera: Camera3D = pivot.get_node("Camera3D")
	var minimap = game.get_node("HUD/Minimap")
	pivot.rotation = Vector3(-0.4, -1.0, 0.0)
	camera.position.z = 12.0
	var outdoor_pose: Vector3 = pivot.rotation
	var outdoor_transform := camera.transform
	var outdoor_fov := camera.fov
	check(game.change_world(load("res://world/teaching_building1.tscn")), "Enter teaching world")
	check(pivot._indoor_camera != null, "Install indoor strategy")
	var building: Node3D = game.get_node("World/teaching_building1/Building")
	var original: Dictionary = {}
	for mesh in building.find_children("*", "GeometryInstance3D", true, false):
		original[mesh] = mesh.transparency
	await physics_frame
	await physics_frame
	var space := actor.get_world_3d().direct_space_state
	var shape := SphereShape3D.new()
	shape.radius = 0.15
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 4
	query.exclude = [actor.get_rid()]
	var pose_count := 0
	for floor_index in range(5):
		var h := floor_index * 4.32
		var positions: Array[Vector3] = [Vector3(35, h + 0.08, 2.4), Vector3(35, h + 0.08, 0.65), Vector3(35, h + 0.08, 4.1), Vector3(0.8, h + 0.08, 2.4), Vector3(144.8, h + 0.08, 2.4)]
		for center in [15.6, 119.6]:
			positions.append(Vector3(center - 1.2, h + 0.08, 1.0))
			if floor_index < 4:
				positions.append(Vector3(center - 1.2, h + 1.08, -2.6))
				positions.append(Vector3(center - 1.2, h + 2.16, -5.5))
				positions.append(Vector3(center + 1.2, h + 3.24, -2.6))
		for point in positions:
			actor.position = point
			for yaw in [-180.0, -120.0, -80.0, -55.0, 0.0, 55.0, 80.0, 120.0, 180.0]:
				for pitch in [-100.0, -75.0, -35.0, -20.0, -8.0, 20.0, 60.0]:
					var orbit := Vector3(deg_to_rad(pitch), deg_to_rad(yaw), 0.0)
					pivot.rotation = orbit
					pivot._indoor_camera.requested_distance = 5.0
					pivot._indoor_camera._follow_distance = 5.0
					pivot._indoor_camera._initialized = false
					pivot._physics_process(1.0 / 60.0)
					var region: Dictionary = building.get_camera_region(point)
					var y := building.to_local(camera.global_position).y
					var description := " point=%s yaw=%s pitch=%s" % [point, yaw, pitch]
					check(pivot.rotation.is_equal_approx(orbit), "Never rewrite orbit angles" + description)
					check(y <= region.max_height + 0.001 and y >= region.min_height - 0.001, "Height cap" + description)
					query.transform = Transform3D(Basis.IDENTITY, camera.global_position)
					check(space.intersect_shape(query, 1).is_empty(), "Camera avoids solid geometry" + description)
					var ray := PhysicsRayQueryParameters3D.create(camera.global_position, pivot.global_position, 4, [actor.get_rid()])
					check(space.intersect_ray(ray).is_empty(), "Clear view through solid walls" + description)
					pose_count += 1
	# Walk both directions through both stair entrances with fixed orbit angles.
	for center in [15.6, 119.6]:
		for yaw in [-55.0, 0.0, 55.0]:
			for reverse in [false, true]:
				pivot.rotation = Vector3(deg_to_rad(-20.0), deg_to_rad(yaw), 0.0)
				var previous := Vector3.ZERO
				for frame in range(181):
					var t := float(frame) / 180.0
					if reverse:
						t = 1.0 - t
					actor.position = Vector3(center - 1.2, 0.08, lerpf(3.5, -0.6, t))
					if frame == 0:
						for settle in range(90):
							pivot._physics_process(1.0 / 60.0)
					pivot._physics_process(1.0 / 60.0)
					if frame > 0:
						var step := previous.distance_to(camera.global_position)
						worst_step = maxf(worst_step, step)
						check(step < 0.24, "Continuous stair entry center=%s yaw=%s reverse=%s frame=%s step=%s" % [center, yaw, reverse, frame, step])
					previous = camera.global_position
	# No railing collision or horizontal region clamp when orbiting outside it.
	actor.position = Vector3(50, 0.08, 4.1)
	pivot.rotation = Vector3(deg_to_rad(-20.0), 0.0, 0.0)
	for frame in range(120):
		pivot._physics_process(1.0 / 60.0)
	check(camera.global_position.z > 6.0, "Camera can orbit beyond corridor railing")
	var still := camera.global_position
	for frame in range(60):
		pivot._physics_process(1.0 / 60.0)
	check(camera.global_position.distance_to(still) < 0.03, "Stable camera at railing")
	var before_input: Vector3 = pivot.rotation
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(1500.0, 500.0)
	pivot._unhandled_input(motion)
	check(is_equal_approx(pivot.rotation.y, before_input.y - 4.5), "Unrestricted horizontal mouse input")
	check(is_equal_approx(pivot.rotation.x, before_input.x - 1.5), "Unrestricted vertical mouse input")
	# The private map scene renders only the current floor's cutaway.
	for floor_index in range(5):
		actor.position = Vector3(118.4, floor_index * 4.32 + 0.08, 2.4)
		pivot.rotation = Vector3(deg_to_rad(-20.0), deg_to_rad(55.0), 0.0)
		for frame in range(90):
			pivot._physics_process(1.0 / 60.0)
		minimap._process(0.0)
		check(minimap.current_floor == floor_index, "Current minimap floor")
		check(minimap.floor_label.text == "%dF" % (floor_index + 1), "Floor label")
		var map_camera: Camera3D = minimap.map_camera
		check(minimap.map_view.world_3d != actor.get_world_3d(), "Map cutaway is isolated from gameplay")
		check(minimap._indoor_map.floor_index == floor_index, "Map geometry tracks floor")
		check(is_equal_approx(minimap._indoor_map.material.get_shader_parameter("floor_y"), floor_index * 4.32), "Cutaway floor plane")
		var ray := PhysicsRayQueryParameters3D.create(actor.position + Vector3.UP * 3.0, Vector3(actor.position.x, floor_index * 4.32 - 0.2, actor.position.z), 1, [actor.get_rid()])
		var floor_hit := space.intersect_ray(ray)
		check(not floor_hit.is_empty() and absf(floor_hit.position.y - floor_index * 4.32) < 0.2, "Map sees current floor, not roof")
		if floor_index in [0, 2, 4]:
			await capture("floor_%d" % (floor_index + 1), minimap)
	var floor_deadband: Dictionary = building.get_minimap_slice(Vector3(118.4, 4.32 - 0.1, 0.0), 1)
	check(floor_deadband.floor_index == 1, "Landing floor hysteresis")
	for mesh in original:
		check(is_equal_approx(mesh.transparency, original[mesh]), "Preserve building opacity")
	check(game.change_world(load("res://world/campus.tscn")), "Return to campus")
	check(pivot._indoor_camera == null, "Release indoor camera")
	check(pivot.rotation.is_equal_approx(outdoor_pose), "Restore outdoor orbit")
	check(camera.transform.is_equal_approx(outdoor_transform), "Restore complete camera transform")
	check(is_equal_approx(camera.fov, outdoor_fov), "Restore outdoor FOV")
	check(minimap.current_floor == -1 and not minimap.floor_label.visible, "Release indoor minimap")
	check(is_equal_approx(minimap.map_camera.far, 400.0) and minimap.map_camera.environment == null, "Restore campus map rendering")
	check(game.change_world(load("res://world/teaching_building1.tscn")), "Reenter teaching world")
	minimap._process(0.0)
	check(minimap.current_floor == 4, "Reentry restores floor map at saved position")
	game.queue_free()
	await process_frame
	print("TEACHING_CAMERA_CHECK poses=", pose_count, " checks=", checks, " failures=", failures, " worst_entry_step=", worst_step)
	quit(0 if failures == 0 else 1)
