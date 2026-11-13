extends Control

# The map uses the same world as the main camera, so paths and buildings stay in sync.
const MAP_SIZE := 260
const MAP_SPAN := 35.0
const NORTH := Vector3(0, 0, -1)

var player: Node3D
var view_pivot: Node3D
var map_camera: Camera3D
var map_view: SubViewport
var north_screen := Vector2.UP
var overlay: Control
var clock_label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_view = SubViewport.new()
	map_view.size = Vector2i(MAP_SIZE * 2, MAP_SIZE * 2)
	map_view.world_3d = get_viewport().world_3d
	map_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(map_view)
	map_camera = Camera3D.new()
	map_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	map_camera.size = MAP_SPAN
	map_camera.far = 400.0
	map_view.add_child(map_camera)
	map_camera.current = true
	var image := TextureRect.new()
	image.position = Vector2(8, 8)
	image.size = Vector2(MAP_SIZE - 16, MAP_SIZE - 16)
	image.texture = map_view.get_texture()
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = load("res://scenes/templates/minimap_mask.gdshader")
	image.material = material
	add_child(image)
	# Draw the frame and markers above the viewport texture.
	overlay = Control.new()
	overlay.set_script(load("res://scenes/templates/minimap_overlay.gd"))
	overlay.size = Vector2(MAP_SIZE, MAP_SIZE)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	_create_clock()

func _create_clock() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(64, -45)
	panel.size = Vector2(132, 38)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("d9211b2a")
	style.border_color = Color("b86acb")
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	clock_label = Label.new()
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	clock_label.add_theme_font_size_override("font_size", 23)
	clock_label.add_theme_color_override("font_color", Color("f5eaf7"))
	clock_label.add_theme_color_override("font_shadow_color", Color("8c17121c"))
	clock_label.add_theme_constant_override("shadow_offset_y", 1)
	panel.add_child(clock_label)
	_update_clock()

func _update_clock() -> void:
	var total_minutes := int(floor(GameTime.current_hour * 60.0)) % 1440
	clock_label.text = "%02d:%02d" % [int(total_minutes / 60), total_minutes % 60]

func set_target(target: Node3D, camera_pivot: Node3D) -> void:
	player = target
	view_pivot = camera_pivot

func _process(_delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(view_pivot):
		return
	var forward := -view_pivot.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var target := player.global_position
	map_camera.global_position = target + Vector3.UP * 150.0
	map_camera.look_at(target, forward)
	var right := map_camera.global_basis.x
	north_screen = Vector2(NORTH.dot(right), -NORTH.dot(forward)).normalized()
	overlay.queue_redraw()
	_update_clock()
