extends SceneTree
const OUT := "res://docs/teaching_spring_review"
const VIEWS := [
	["restrooms_f1", Vector3(140.4, 2.2, 7.5), Vector3(140.4, 1.6, 0), 76.0],
	["restrooms_f5", Vector3(140.4, 19.48, 7.5), Vector3(140.4, 18.88, 0), 76.0],
	["restroom_men", Vector3(138.3, 2.35, -1.35), Vector3(137.7, 1.15, -5.5), 76.0],
	["restroom_women", Vector3(143.0, 2.3, -1.35), Vector3(143.0, 1.2, -5.5), 76.0],
	["restroom_sinks", Vector3(139.4, 1.65, -3.2), Vector3(138.8, 1.15, -0.3), 72.0],
	["restroom_toilet", Vector3(136.25, 2.0, -4.8), Vector3(136.25, 0.6, -6.3), 64.0],
	["restroom_plan", Vector3(140.4, 29, -0.8), Vector3(140.4, 17.6, -3.6), 55.0],
]
func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var world: Node3D = load("res://scenes/teaching_building/teaching_building_test.tscn").instantiate()
	root.add_child(world)
	var actor := world.get_node("StudentCharacter")
	actor.process_mode = Node.PROCESS_MODE_DISABLED
	actor.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var camera := Camera3D.new()
	camera.far = 250
	world.add_child(camera)
	camera.make_current()
	for view in VIEWS:
		# Review cutaway only: the saved production scene keeps its roof intact.
		if view[0] == "restroom_plan":
			world.get_node("Building/Model/solid_slab_5").hide()
		camera.position = view[1]
		camera.look_at(view[2])
		camera.fov = view[3]
		for frame in range(45):
			await RenderingServer.frame_post_draw
		var status := root.get_texture().get_image().save_png(OUT + "/five_" + view[0] + ".png")
		print("RESTROOM_CAPTURE ", view[0], " result=", status)
	print("RESTROOM_CAPTURE_COMPLETE")
	quit()
