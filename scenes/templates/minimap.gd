extends Control

# Campus uses the live world; interiors use an isolated current-floor cutaway.
const MAP_SIZE := 260
const MAP_SPAN := 35.0
const NORTH := Vector3(0, 0, -1)
const INDOOR_MAP := preload("res://scenes/teaching_building/indoor_minimap.gd")

var player: Node3D
var view_pivot: Node3D
var map_camera: Camera3D
var map_view: SubViewport
var north_screen := Vector2.UP
var overlay: Control
var clock_label: Label
var floor_label: Label
var current_floor := -1
var _building: Node3D
var _indoor_environment: Environment
var _indoor_map: Node3D
var _indoor_world := World3D.new()


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
	floor_label = Label.new()
	floor_label.position = Vector2(12, -39)
	floor_label.add_theme_font_size_override("font_size", 24)
	floor_label.add_theme_color_override("font_color", Color("f5eaf7"))
	floor_label.add_theme_color_override("font_shadow_color", Color("221b2a"))
	floor_label.add_theme_constant_override("shadow_offset_y", 2)
	floor_label.hide()
	add_child(floor_label)
	_indoor_environment = Environment.new()
	_indoor_environment.background_mode = Environment.BG_COLOR
	_indoor_environment.background_color = Color("29323a")
	_indoor_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_indoor_environment.ambient_light_color = Color.WHITE
	_indoor_environment.ambient_light_energy = 0.5
	_indoor_environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC

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

func configure_world(world: Node) -> void:
	if is_instance_valid(_indoor_map):
		map_view.remove_child(_indoor_map)
		_indoor_map.queue_free()
		_indoor_map = null
	var provider := world.get_node_or_null("Building")
	_building = provider if provider != null and provider.has_method("get_minimap_slice") else null
	# Retain the private world across switches so the renderer can detach the
	# old viewport before its scenario is released.
	map_view.world_3d = _indoor_world if _building != null else get_viewport().world_3d
	if _building != null:
		_indoor_map = INDOOR_MAP.new()
		map_view.add_child(_indoor_map)
		_indoor_map.build(_building)
	current_floor = -1
	floor_label.visible = _building != null
	map_camera.environment = _indoor_environment if _building != null else null
	map_camera.size = 28.0 if _building != null else MAP_SPAN
	map_camera.near = 0.05
	map_camera.far = 80.0 if _building != null else 400.0
	if is_instance_valid(player):
		_process(0.0)

func _process(_delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(view_pivot):
		return
	# Pitch may freely pass overhead; the map heading follows yaw only.
	var forward := Vector3.UP.cross(view_pivot.global_basis.x).normalized()
	var target := player.global_position
	if is_instance_valid(_building):
		var slice: Dictionary = _building.get_minimap_slice(target, current_floor)
		current_floor = slice.floor_index
		floor_label.text = "%dF" % (current_floor + 1)
		var point := _building.to_local(target)
		point.y = slice.floor_y
		target = _building.to_global(Vector3(point.x, slice.floor_y, point.z))
		_indoor_map.show_floor(current_floor, target.y)
		# An angled cutaway shows the wall faces and stair flights clearly.
		map_camera.global_position = target + Vector3.UP * 40.0 - forward * 17.0
	else:
		map_camera.global_position = target + Vector3.UP * 150.0
	map_camera.look_at(target, forward)
	var right := map_camera.global_basis.x
	north_screen = Vector2(NORTH.dot(right), -NORTH.dot(forward)).normalized()
	overlay.queue_redraw()
	_update_clock()
