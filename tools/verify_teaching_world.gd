extends SceneTree
## Run headless for transition/movement checks; add -- --capture with a renderer
## to save morning/afternoon/night views from the same corridor camera.

var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	var clock := root.get_node("GameTime")
	clock.time_running = false
	clock.set_time(9.0)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	var actor = game.get_node("StudentCharacter")
	actor.set_physics_process(false)
	check(is_equal_approx(actor.character_scale, 0.75), "Campus scale")
	check(is_equal_approx(actor.movement_speed, 2.0), "Campus speed")
	var campus_position: Vector3 = actor.global_position
	var teaching := load("res://world/teaching_building1.tscn") as PackedScene
	check(game.change_world(teaching), "Enter teaching world")
	check(is_equal_approx(clock.current_hour, 9.0), "Transition preserves time")
	check(is_equal_approx(actor.character_scale, 1.0), "Indoor scale")
	check(is_equal_approx(actor.movement_speed, 4.0), "Indoor speed")
	check(is_equal_approx(actor.get_node("Sprite3D").pixel_size, 0.01), "Sprite resizes")
	check(is_equal_approx(actor.get_node("CollisionShape3D").shape.height, 1.55), "Collider resizes")
	var world: Node3D = game.get_node("World").get_child(0)
	var sun: DirectionalLight3D = world.get_node("Sun")
	var environment: Environment = world.get_node("WorldEnvironment").environment
	var morning_direction := sun.global_basis.z
	clock.set_time(15.0)
	var afternoon_direction := sun.global_basis.z
	check(morning_direction.x > 0.0 and afternoon_direction.x < 0.0, "Sun crosses building")
	check(morning_direction.z > 0.0 and afternoon_direction.z > 0.0, "Sun enters corridor facade on both sides of noon")
	check(morning_direction.dot(afternoon_direction) < 0.5, "Shadow direction changes through day")
	check(sun.shadow_enabled, "Sun casts shadows")
	clock.set_time(12.0)
	check(is_equal_approx(sun.global_basis.z.y, sin(deg_to_rad(60.0))), "Noon elevation")
	var day_ambient := environment.ambient_light_energy
	clock.set_time(0.0)
	check(is_zero_approx(sun.light_energy), "No sun at midnight")
	check(world.get_node("Moon").light_energy > 0.0, "Moon at midnight")
	check(environment.ambient_light_energy < day_ambient, "Night dims ambient")
	# Exercise the real input controller along an unobstructed corridor.
	actor.get_node("CameraPivot").rotation.y = 0.0
	actor.position = Vector3(85.0, 0.08, 2.4)
	for frame in range(20):
		await physics_frame
		actor._physics_process(1.0 / 60.0)
	for sprint in [false, true]:
		var start: Vector3 = actor.position
		Input.action_press("character_left")
		if sprint:
			Input.action_press("character_sprint")
		for frame in range(60):
			await physics_frame
			actor._physics_process(1.0 / 60.0)
		Input.action_release("character_left")
		Input.action_release("character_sprint")
		var distance: float = start.distance_to(actor.position)
		var expected := 7.2 if sprint else 4.0
		check(absf(distance - expected) < 0.15, "Indoor walk/sprint distance: %s expected %s" % [distance, expected])
		print("INDOOR_MOVEMENT sprint=", sprint, " distance=", distance)
	var indoor_position: Vector3 = actor.position
	check(game.change_world(load("res://world/campus.tscn")), "Return to campus")
	check(is_equal_approx(actor.character_scale, 0.75), "Restore campus scale")
	check(is_equal_approx(actor.movement_speed, 2.0), "Restore campus speed")
	check(actor.position.is_equal_approx(campus_position), "Restore campus position")
	check(game.change_world(teaching), "Reenter teaching world")
	check(actor.position.is_equal_approx(indoor_position), "Restore indoor position")
	check(is_equal_approx(actor.movement_speed, 4.0), "Reapply indoor speed")
	if "--capture" in OS.get_cmdline_user_args():
		actor.hide()
		actor.get_node("CameraPivot").set_physics_process(false)
		var camera := Camera3D.new()
		game.add_child(camera)
		camera.position = Vector3(65.8, 10.34, 3.1)
		camera.look_at(Vector3(47.8, 10.14, 1.1))
		camera.fov = 55.0
		camera.make_current()
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/teaching_world_review"))
		for hour in [9.0, 12.0, 15.0, 0.0]:
			clock.set_time(hour)
			for frame in range(20):
				await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/teaching_world_review/corridor_%02d.png" % int(hour))
	print("TEACHING_WORLD_CHECK failures=", failures)
	game.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures == 0 else 1)
