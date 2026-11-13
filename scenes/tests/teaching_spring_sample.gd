extends Node3D
## A dedicated visual review scene. Number keys select fixed inspection views.
## Original model, controller, collision scripts and main scene remain separate.

const REVIEW_DIR := "res://docs/teaching_spring_review"
const VIEWS := [
	[Vector3(30.6, 1.65, 1.45), Vector3(16.0, 1.45, 0.65), 65.0],
	[Vector3(30.0, 5.3, 16.0), Vector3(34.0, 1.3, -0.5), 56.0],
	[Vector3(84.0, 1.65, 2.1), Vector3(84.0, 1.9, -3.8), 67.0],
]

@onready var camera: Camera3D = $ReviewCamera
@onready var style: Node = $Building/SpringMaterials

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Local review settings: keep project-wide rendering and other scenes intact.
	get_viewport().use_taa = true
	RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)
	RenderingServer.directional_shadow_atlas_set_size(4096, false)
	_set_view(0)
	if "--capture-spring" in OS.get_cmdline_user_args():
		_capture_review.call_deferred()

func _set_view(index: int) -> void:
	camera.position = VIEWS[index][0]
	camera.look_at(VIEWS[index][1])
	camera.fov = VIEWS[index][2]

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_3:
			_set_view(event.keycode - KEY_1)
		elif event.keycode == KEY_B:
			style.enabled = not style.enabled
		elif event.keycode == KEY_ESCAPE:
			get_tree().quit()

func _settle() -> void:
	for frame in range(30):
		await RenderingServer.frame_post_draw

func _capture_review() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REVIEW_DIR))
	$ReviewUI.hide()
	for i in range(VIEWS.size()):
		_set_view(i)
		await _settle()
		var result := get_viewport().get_texture().get_image().save_png(REVIEW_DIR + "/spring_%02d.png" % (i + 1))
		print("SPRING_CAPTURE view=", i + 1, " result=", result)
	_set_view(0)
	style.enabled = false
	await _settle()
	get_viewport().get_texture().get_image().save_png(REVIEW_DIR + "/original_01.png")
	print("SPRING_REVIEW_COMPLETE")
	get_tree().quit()
