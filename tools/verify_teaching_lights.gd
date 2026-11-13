extends SceneTree
## Run headless for all worlds; use -- --capture with a renderer for review images.
var failures := 0
const OUT := "res://docs/teaching_world_review"

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func capture(label: String) -> void:
	for frame in range(12):
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + "/" + label + ".png")
	print("CAPTURE ", label)

func run() -> void:
	var clock := root.get_node("GameTime")
	clock.time_running = false
	clock.set_time(12.0)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	var actor = game.get_node("StudentCharacter")
	actor.set_physics_process(false)
	actor.get_node("CameraPivot").set_physics_process(false)
	var campus = game.get_node("World").get_child(0)
	for label in ["TeachingEntrance", "Teaching2Entrance", "Teaching3Entrance"]:
		var area = campus.get_node(label)
		check(area.has_node("BookInteractionMarker/BookBadge"), "%s has book badge" % label)
		var marker = area.get_node("BookInteractionMarker")
		check(marker.get_node("BookBadge").texture.get_width() == 256, "Book artwork loaded")
		check(is_equal_approx(marker.get_node("InteractionRing").mesh.outer_radius, area.interaction_range + 0.025), "Ring follows interaction radius")
		actor.position = area.position - Vector3(0, 0.4, 0)
		for frame in range(4):
			await physics_frame
		marker._process(0.0)
		check(area.is_available(actor), "%s interaction remains available" % label)
		check(marker.get_node("BookBadge").modulate == Color.WHITE, "Book highlights inside trigger")
	if "--capture" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
		clock.set_time(9.0)
		actor.position = Vector3(2.2, 0.1, 30.2)
		var camera := Camera3D.new()
		game.add_child(camera)
		camera.position = Vector3(5.6, 3.7, 37.2)
		camera.look_at(Vector3(2.2, 1.1, 31.4))
		camera.fov = 56.0
		camera.make_current()
		await capture("teaching_entrance_book")
		camera.queue_free()
	for number in range(1, 4):
		check(game.change_world(load("res://world/teaching_building%d.tscn" % number)), "Enter world %d" % number)
		var world = game.get_node("World").get_child(0)
		var exit = world.get_node("TeachingExit")
		check(exit.has_node("ExitInteractionMarker/ExitBadge"), "World %d has safety-exit badge" % number)
		var exit_marker = exit.get_node("ExitInteractionMarker")
		check(exit_marker.icon_texture.resource_path.ends_with("teaching_exit.svg"), "Exit uses its own artwork")
		actor.position = exit.position - Vector3(0, 0.4, 0)
		for frame in range(4):
			await physics_frame
		exit_marker._process(0.0)
		check(exit.is_available(actor), "World %d exit interaction available" % number)
		check(exit_marker.get_node("ExitBadge").modulate == Color.WHITE, "Exit highlights in range")
		check(is_equal_approx(exit_marker.get_node("InteractionRing").global_position.y, 0.035), "Exit ring lies on corridor floor")
		var lamps = world.get_node("Building/CeilingLights")
		check(lamps.lights.size() > 250, "World %d has fixtures across five floors" % number)
		clock.set_time(12.0)
		check(is_zero_approx(lamps.diffuser.emission_energy_multiplier), "Daytime diffusers off")
		for lamp: SpotLight3D in lamps.lights:
			check(not lamp.visible and is_zero_approx(lamp.light_energy), "Daytime light off")
		clock.set_time(18.0)
		var dusk: float = lamps.lights[0].light_energy
		check(dusk > 0.0 and dusk < 1.5, "Gradual dusk lighting")
		clock.set_time(0.0)
		check(is_equal_approx(lamps.diffuser.emission_energy_multiplier, 3.5), "Nighttime diffuser glows")
		for lamp: SpotLight3D in lamps.lights:
			check(lamp.visible and is_equal_approx(lamp.light_energy, 1.5), "Nighttime light on")
			check(lamp.light_color == Color(1.0, 0.68, 0.36), "Matches campus lamp warmth")
			check(lamp.global_basis.z.dot(Vector3.UP) > 0.99 and lamp.shadow_enabled, "Downlight with wall/floor shadows")
		if number == 1 and "--capture" in OS.get_cmdline_user_args():
			actor.hide()
			game.get_node("HUD").hide()
			var camera := Camera3D.new()
			game.add_child(camera)
			camera.position = Vector3(115.0, 1.9, 3.4)
			camera.look_at(Vector3(96.0, 2.3, 1.7))
			camera.fov = 72.0
			camera.make_current()
			clock.set_time(12.0)
			camera.position = Vector3(121.8, 2.3, 4.0)
			camera.look_at(Vector3(118.4, 0.8, 1.4))
			await capture("teaching_indoor_exit")
			camera.position = Vector3(115.0, 1.9, 3.4)
			camera.look_at(Vector3(96.0, 2.3, 1.7))
			for hour in [12.0, 0.0]:
				clock.set_time(hour)
				await capture("ceiling_corridor_%02d" % int(hour))
			camera.position = Vector3(118.2, 2.8, -5.5)
			camera.look_at(Vector3(120.4, 4.3, -0.3))
			await capture("ceiling_stairs_night")
			camera.queue_free()
		await process_frame
	print("TEACHING_LIGHTS_CHECK worlds=3 failures=", failures)
	game.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures == 0 else 1)
