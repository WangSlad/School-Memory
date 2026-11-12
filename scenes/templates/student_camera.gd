extends Node3D

const MOUSE_SENSITIVITY := 0.003
const MIN_PITCH := deg_to_rad(-75.0)
const MAX_PITCH := deg_to_rad(-8.0)
const MIN_CAMERA_DISTANCE := 5
const MAX_CAMERA_DISTANCE := 15.0
const ZOOM_FACTOR := 1.15
const FADE_AMOUNT := 0.8
const FADE_SPEED := 5.0
const MAX_OCCLUDERS_PER_RAY := 16

@onready var _camera: Camera3D = $Camera3D
@onready var _character: CharacterBody3D = get_parent()

# Store the pre-existing transparency for each affected mesh.
var _original_transparency: Dictionary = {}
var _occluded: Dictionary = {}


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var steps := maxf(event.factor, 0.01)
		var zoom := pow(ZOOM_FACTOR, steps)
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = 1.0 / zoom
		_camera.position.z = clampf(_camera.position.z * zoom, MIN_CAMERA_DISTANCE, MAX_CAMERA_DISTANCE)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * MOUSE_SENSITIVITY
		rotation.x = clampf(rotation.x - event.relative.y * MOUSE_SENSITIVITY, MIN_PITCH, MAX_PITCH)


func _physics_process(delta: float) -> void:
	_find_occluders()
	_update_transparency(delta)


func _find_occluders() -> void:
	_occluded.clear()
	var space := get_world_3d().direct_space_state
	var camera_position := _camera.global_position
	var target := _character.global_position
	var character_height: float = _character.get_node("CollisionShape3D").position.y * 2.0
	var camera_right := _camera.global_basis.x.normalized()
	var offsets := [
		Vector3.UP * character_height * 0.45,
		Vector3.UP * character_height * 0.85,
		Vector3.UP * character_height * 0.15,
		Vector3.UP * character_height * 0.55 + camera_right * 0.2 * character_height,
		Vector3.UP * character_height * 0.55 - camera_right * 0.2 * character_height,
	]
	for offset in offsets:
		var query := PhysicsRayQueryParameters3D.create(camera_position, target + offset)
		query.collision_mask = _character.collision_mask
		query.hit_from_inside = true
		var excluded: Array[RID] = [_character.get_rid()]
		for i in range(MAX_OCCLUDERS_PER_RAY):
			query.exclude = excluded
			var hit := space.intersect_ray(query)
			if hit.is_empty():
				break
			var collider := hit["collider"] as CollisionObject3D
			if collider == null:
				break
			excluded.append(collider.get_rid())
			var parent := collider.get_parent()
			if parent != null and parent.get("ground_mode") == true:
				continue
			var visual: Node = parent.get_node_or_null("Visual") if parent != null else null
			if visual != null:
				_collect_meshes(visual)
			else:
				_collect_meshes(collider)


func _collect_meshes(node: Node) -> void:
	if node is GeometryInstance3D and not node is Sprite3D:
		_occluded[node] = true
		if not _original_transparency.has(node):
			_original_transparency[node] = node.transparency
	for child in node.get_children():
		_collect_meshes(child)


func _update_transparency(delta: float) -> void:
	for mesh in _original_transparency.keys():
		if not is_instance_valid(mesh):
			_original_transparency.erase(mesh)
			continue
		var original: float = _original_transparency[mesh]
		var target := maxf(original, FADE_AMOUNT) if _occluded.has(mesh) else original
		mesh.transparency = move_toward(mesh.transparency, target, FADE_SPEED * delta)
		if not _occluded.has(mesh) and is_equal_approx(mesh.transparency, original):
			_original_transparency.erase(mesh)


func _exit_tree() -> void:
	for mesh in _original_transparency:
		if is_instance_valid(mesh):
			mesh.transparency = _original_transparency[mesh]
	_original_transparency.clear()
	if not Engine.is_editor_hint():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
