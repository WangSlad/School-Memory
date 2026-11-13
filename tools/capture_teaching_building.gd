extends SceneTree
## Capture the ORIGINAL teaching_building_test scene. This does not replace its
## cameras or controller files. The temporary inspection camera exists only here.

const OUT := "res://docs/teaching_spring_review"
const VIEWS := [
	["corridor_f1", Vector3(45, 1.7, 3.1), Vector3(27, 1.5, 1.1), 55.0],
	["corridor_f3", Vector3(65.8, 10.34, 3.1), Vector3(47.8, 10.14, 1.1), 55.0],
	["corridor_f5", Vector3(86.6, 18.98, 3.1), Vector3(68.6, 18.78, 1.1), 55.0],
	["facade", Vector3(72, 32, 93), Vector3(72, 10.5, 0), 66.0],
	["window_support", Vector3(36.4, 1.35, 2.5), Vector3(35.1, 1.0, 0.12), 48.0],
	["door_detail", Vector3(33.05, 1.30, 2.5), Vector3(32.435, 1.17, 0.09), 53.0],
	["window_detail", Vector3(36.15, 1.8, 2.45), Vector3(35.1, 1.67, 0.09), 52.0],
	["glass_layers", Vector3(70, 10.5, 11), Vector3(70, 7.5, -1), 66.0],
	["underside", Vector3(32, 1.1, 3.1), Vector3(38, 4, 0), 65.0],
	["stair_left", Vector3(14.4, 1.8, 2.6), Vector3(14.4, 2.0, -3.7), 64.0],
]

func _initialize() -> void:
	run.call_deferred()

func settle() -> void:
	for frame in range(45):
		await RenderingServer.frame_post_draw

func run() -> void:
	var world: Node3D = load("res://scenes/teaching_building/teaching_building_test.tscn").instantiate()
	root.add_child(world)
	var actor: Node3D = world.get_node("StudentCharacter")
	actor.process_mode = Node.PROCESS_MODE_DISABLED
	actor.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var camera := Camera3D.new()
	camera.far = 250.0
	world.add_child(camera)
	camera.make_current()
	for view in VIEWS:
		camera.position = view[1]
		camera.look_at(view[2])
		camera.fov = view[3]
		await settle()
		var result := root.get_texture().get_image().save_png(OUT + "/five_" + view[0] + ".png")
		print("FIVE_CAPTURE ", view[0], " result=", result)
	# Same exact five-storey geometry/camera, with BOTH finish layers switched off.
	camera.position = VIEWS[0][1]
	camera.look_at(VIEWS[0][2])
	camera.fov = VIEWS[0][3]
	world.get_node("Building/Model/SpringMaterials").enabled = false
	world.get_node("Building/FacadeRelief").hide()
	world.get_node("Building/JoineryDetail").restore_source()
	world.get_node("Building/GlazingPanels").restore_source()
	await settle()
	root.get_texture().get_image().save_png(OUT + "/five_original_same_camera.png")
	print("FIVE_CAPTURE_COMPLETE")
	quit()
