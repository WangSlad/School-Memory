extends RefCounted
## Free orbit with a height cap, continuous stair zoom, and wall avoidance.

const CAMERA_RADIUS := 0.18
const WALL_MARGIN := 0.08
const CAMERA_OBSTACLES := 4
const ZOOM_RESPONSE := 8.0
const RECOVER_RESPONSE := 5.0
const COLLISION_HOLD := 0.16

var building: Node3D
var requested_distance := 4.0
var region_name := "corridor"
var _pivot: Node3D
var _camera: Camera3D
var _actor: CharacterBody3D
var _outdoor_rotation: Vector3
var _outdoor_camera_transform: Transform3D
var _outdoor_fov: float
var _sphere := SphereShape3D.new()
var _query := PhysicsShapeQueryParameters3D.new()
var _follow_distance := 4.0
var _actual_distance := 4.0
var _obstruction_hold := 0.0
var _initialized := false
var _previous_actor_position := Vector3.ZERO
var _has_previous_actor_position := false

func _init(pivot: Node3D, provider: Node3D) -> void:
	_pivot = pivot
	_camera = pivot.get_node("Camera3D")
	_actor = pivot.get_parent()
	building = provider
	_outdoor_rotation = pivot.rotation
	_outdoor_camera_transform = _camera.transform
	_outdoor_fov = _camera.fov
	# Start inside the corridor; allow outward recovery after physics sync.
	_camera.position = Vector3(0.0, 0.0, 0.5)
	_camera.fov = 70.0
	_sphere.radius = CAMERA_RADIUS
	_query.shape = _sphere
	_query.margin = 0.02
	_query.exclude = [_actor.get_rid()]
	_query.collision_mask = CAMERA_OBSTACLES

func detach() -> void:
	_pivot.rotation = _outdoor_rotation
	_camera.transform = _outdoor_camera_transform
	_camera.fov = _outdoor_fov

func handle_input(event: InputEvent) -> bool:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_pivot.rotation.y -= event.relative.x * _pivot.MOUSE_SENSITIVITY
		_pivot.rotation.x -= event.relative.y * _pivot.MOUSE_SENSITIVITY
		return true
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var zoom := pow(_pivot.ZOOM_FACTOR, maxf(event.factor, 0.01))
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = 1.0 / zoom
		requested_distance = clampf(requested_distance * zoom, 1.2, 5.0)
		return true
	return false

func update(delta: float) -> void:
	if not is_instance_valid(building) or not building.is_inside_tree():
		return
	var region: Dictionary = building.get_camera_region(_actor.global_position)
	region_name = region.name
	var stair_weight: float = region.stair_weight
	var desired_distance := minf(requested_distance, lerpf(5.0, 1.8, stair_weight))
	_follow_distance = lerpf(_follow_distance, desired_distance, 1.0 - exp(-ZOOM_RESPONSE * delta))
	var origin := _pivot.global_position
	var desired := origin + _pivot.global_basis.z * _follow_distance
	var local_desired := building.to_local(desired)
	# Only height is bounded. The orbit may pass outside corridor railings and
	# across the stair entrance without switching between different XZ boxes.
	local_desired.y = clampf(local_desired.y, region.min_height, region.max_height)
	desired = building.to_global(local_desired)
	var motion := desired - origin
	var distance := motion.length()
	if distance < 0.001:
		return
	var safe_distance := _safe_distance(origin, motion)
	# Start retracting before a doorway edge reaches the boom. Looking slightly
	# ahead avoids a sudden jump when a wall first enters the swept volume.
	var anticipated_distance := safe_distance
	if _has_previous_actor_position and delta > 0.0:
		var movement := _actor.global_position - _previous_actor_position
		if movement.length() < 0.5:
			var lookahead := movement / delta * 0.3
			anticipated_distance = minf(safe_distance, _safe_distance(origin + lookahead, motion))
	_previous_actor_position = _actor.global_position
	_has_previous_actor_position = true
	if not _initialized:
		_actual_distance = safe_distance
		_initialized = true
	elif safe_distance < _actual_distance - 0.01:
		_actual_distance = safe_distance
		_obstruction_hold = COLLISION_HOLD
	elif anticipated_distance < _actual_distance - 0.01:
		_actual_distance = lerpf(_actual_distance, anticipated_distance, 1.0 - exp(-10.0 * delta))
		_obstruction_hold = COLLISION_HOLD
	else:
		_obstruction_hold = maxf(0.0, _obstruction_hold - delta)
		if _obstruction_hold <= 0.0 and safe_distance > _actual_distance + 0.025:
			_actual_distance = lerpf(_actual_distance, safe_distance, 1.0 - exp(-RECOVER_RESPONSE * delta))
		_actual_distance = minf(_actual_distance, safe_distance)
	_camera.global_position = origin + motion / distance * _actual_distance
	# Keep the character centered after a vertical height correction, without
	# rewriting the orbit angles used by input, movement, or the minimap.
	var view_direction := (origin - _camera.global_position).normalized()
	var up := _pivot.global_basis.y
	if absf(view_direction.dot(up)) > 0.999:
		up = _pivot.global_basis.x.cross(view_direction).normalized()
	_camera.look_at(origin, up)
	_camera.fov = lerpf(_camera.fov, lerpf(70.0, 75.0, stair_weight), 1.0 - exp(-8.0 * delta))

func _safe_distance(origin: Vector3, motion: Vector3) -> float:
	var distance := motion.length()
	# Sweep a sphere so near-plane edges cannot cut through walls or stairs.
	_query.transform = Transform3D(Basis.IDENTITY, origin)
	_query.motion = motion
	var fractions := _pivot.get_world_3d().direct_space_state.cast_motion(_query)
	var safe_distance := maxf(0.05, distance * fractions[0] - WALL_MARGIN)
	# A sweep ignores a body already overlapping its initial shape. The center
	# ray still catches other faces of that body's combined wall/floor mesh.
	var ray := PhysicsRayQueryParameters3D.create(origin, origin + motion, CAMERA_OBSTACLES, [_actor.get_rid()])
	ray.hit_back_faces = true
	var hit := _pivot.get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty():
		safe_distance = minf(safe_distance, maxf(0.05, origin.distance_to(hit.position) - CAMERA_RADIUS - WALL_MARGIN))
	return safe_distance
