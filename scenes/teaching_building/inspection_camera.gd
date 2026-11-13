extends "res://scenes/templates/student_camera.gd"

var _desired_distance := 9.93

func _ready() -> void:
	super._ready()
	_desired_distance = $Camera3D.position.z

func _unhandled_input(event: InputEvent) -> void:
	$Camera3D.position.z = _desired_distance
	super._unhandled_input(event)
	_desired_distance = $Camera3D.position.z

func _physics_process(delta: float) -> void:
	$Camera3D.position.z = _desired_distance
	var start := global_position
	var end := global_transform * Vector3(0, 0, _desired_distance)
	var query := PhysicsRayQueryParameters3D.create(start, end, 1)
	query.exclude = [get_parent().get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		$Camera3D.position.z = maxf(0.35, start.distance_to(hit.position) - 0.18)
	super._physics_process(delta)
