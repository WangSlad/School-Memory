extends SceneTree
var failures := 0
var world_changes := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func settle() -> void:
	for frame in range(5):
		await physics_frame

func run() -> void:
	var clock := root.get_node("GameTime")
	clock.time_running = false
	clock.set_time(20.0)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.world_changed.connect(func(_world): world_changes += 1)
	var campus = game.get_node("World").get_child(0)
	var actor = game.get_node("StudentCharacter")
	actor.set_physics_process(false)
	var pivot = actor.get_node("CameraPivot")
	pivot.set_physics_process(false)
	var original_rotation: Vector3 = pivot.rotation
	var map = game.get_node("HUD/Minimap")
	var map_world: World3D = map.map_view.world_3d
	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	for lane in ["Left", "Right"]:
		actor.position = campus.get_node("Gate%sInsideSpawn" % lane).position
		await settle()
		for side in ["Inside", "Outside"]:
			var area = campus.get_node("Gate%s%s" % [lane, side])
			check(area.target_world_path.is_empty(), "Gate uses no world transition")
			check(area.has_node("ExitInteractionMarker/ExitBadge"), "Gate exit artwork")
			check(area.is_available(actor), "%s %s interaction reachable" % [lane, side])
			game._physics_process(0.0)
			check(game._selected == area, "Correct gate interaction selected")
			var target: Marker3D = area.get_node(area.local_teleport_target)
			# Test the production E-key dispatch and allow the capsule to settle.
			actor.velocity = Vector3(2, -1, 3)
			game._unhandled_input(event)
			check(actor.velocity == Vector3.ZERO, "Teleport clears velocity")
			await settle()
			actor.set_physics_process(false)
			check(actor.global_position.distance_to(target.global_position) < 0.25, "Arrives on opposite side")
			check(game.get_node("World").get_child(0) == campus and world_changes == 0, "Keeps same campus instance")
			check(is_equal_approx(clock.current_hour, 20.0), "Preserves time")
			check(pivot.rotation.is_equal_approx(original_rotation) and map.map_view.world_3d == map_world, "Preserves camera and map")
			var probe := PhysicsRayQueryParameters3D.create(target.global_position + Vector3.UP * 2, target.global_position - Vector3.UP, 1)
			var ground: Dictionary = actor.get_world_3d().direct_space_state.intersect_ray(probe)
			check(not ground.is_empty() and absf(ground.position.y) < 0.2, "Landing is grounded and clear of barrier")
	if "--capture" in OS.get_cmdline_user_args():
		clock.set_time(9.0)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		var camera := Camera3D.new()
		game.add_child(camera)
		camera.position = Vector3(-14.5, 7.0, 43.5)
		camera.look_at(Vector3(-15.5, 0.7, 35.9))
		camera.fov = 80.0
		camera.make_current()
		for frame in range(15):
			await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/teaching_world_review/gate_teleport.png")
	print("GATE_TELEPORT_CHECK crossings=4 failures=", failures)
	game.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures == 0 else 1)
