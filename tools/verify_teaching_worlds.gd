extends SceneTree
## Verify all three campus entrances, indoor strategies, and matching exits.

var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func settle() -> void:
	# Allow newly instantiated areas and teleported bodies to sync in physics.
	for frame in range(4):
		await physics_frame
	await process_frame

func run() -> void:
	root.get_node("GameTime").time_running = false
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	var actor = game.get_node("StudentCharacter")
	actor.set_physics_process(false)
	var pivot = actor.get_node("CameraPivot")
	var map = game.get_node("HUD/Minimap")
	var campus_scene: PackedScene = load("res://world/campus.tscn")
	var model_names := ["ChunhuiBuilding3", "ChunhuiBuilding4", "ChunhuiBuilding5"]
	var saved_positions: Array[Vector3] = []
	for number in range(1, 4):
		var suffix := "" if number == 1 else str(number)
		var campus = game.get_node("World").get_child(0)
		var entrance = campus.get_node("Teaching%sEntrance" % suffix)
		var return_name := StringName("Teaching%sReturnSpawn" % suffix)
		var relative_entry: Vector3 = entrance.position - campus.get_node(model_names[number - 1]).position
		check(relative_entry.is_equal_approx(Vector3(-0.0075953, 0.5000019, 2.621968)), "Building %d entrance alignment" % number)
		actor.position = entrance.position - Vector3(0, 0.4, 0)
		await settle()
		check(entrance.is_available(actor), "Building %d reachable entrance interaction" % number)
		var target_path: String = entrance.target_world_path
		check(target_path == "res://world/teaching_building%d.tscn" % number, "Building %d destination" % number)
		var target: PackedScene = load(target_path)
		check(game.change_world(target, entrance.spawn_name), "Enter building %d" % number)
		await settle()
		var indoor = game.get_node("World").get_child(0)
		check(actor.position.is_equal_approx(indoor.get_node("DefaultSpawn").position), "Building %d entry spawn" % number)
		check(is_equal_approx(actor.character_scale, 1.0) and is_equal_approx(actor.movement_speed, 4.0), "Building %d player settings" % number)
		check(pivot._indoor_camera != null and pivot._indoor_camera.building == indoor.get_node("Building"), "Building %d indoor camera" % number)
		check(map._building == indoor.get_node("Building") and map.map_view.world_3d != root.world_3d, "Building %d floor minimap" % number)
		root.get_node("GameTime").set_time(9.0)
		var morning: Vector3 = indoor.get_node("Sun").global_basis.z
		root.get_node("GameTime").set_time(15.0)
		check(morning.dot(indoor.get_node("Sun").global_basis.z) < 0.5, "Building %d moving sunlight" % number)
		actor.position = Vector3(85.0 + number, 8.72, 2.4)
		map._process(0.0)
		check(map.current_floor == 2 and map.floor_label.text == "3F", "Building %d third-floor cutaway" % number)
		saved_positions.append(actor.position)
		var exit = indoor.get_node("TeachingExit")
		check(exit.spawn_name == return_name, "Building %d matching return marker" % number)
		var exit_target: PackedScene = load(exit.target_world_path)
		check(game.change_world(exit_target, exit.spawn_name), "Leave building %d" % number)
		await settle()
		campus = game.get_node("World").get_child(0)
		check(actor.position.is_equal_approx(campus.get_node(NodePath(return_name)).position), "Building %d returns to its own entrance" % number)
		check(is_equal_approx(actor.character_scale, 0.75) and is_equal_approx(actor.movement_speed, 2.0), "Building %d restores campus player settings" % number)
		check(pivot._indoor_camera == null and map._building == null, "Building %d restores campus camera/map" % number)
		# Reenter without an explicit spawn to verify independent world save keys.
		check(game.change_world(target), "Restore building %d" % number)
		check(actor.position.is_equal_approx(saved_positions[number - 1]), "Building %d remembers its position" % number)
		check(game.change_world(campus_scene, return_name), "Return for next entrance")
		await settle()
	for number in range(1, 4):
		check(game.change_world(load("res://world/teaching_building%d.tscn" % number)), "Revisit building %d" % number)
		check(actor.position.is_equal_approx(saved_positions[number - 1]), "Building %d position remains independent" % number)
		await settle()
	print("TEACHING_WORLDS_CHECK worlds=3 failures=", failures)
	game.queue_free()
	await settle()
	quit(0 if failures == 0 else 1)
