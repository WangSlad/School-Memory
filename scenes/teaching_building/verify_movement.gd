extends SceneTree
var actor: CharacterBody3D
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var world = load("res://scenes/teaching_building/teaching_building_test.tscn").instantiate()
	root.add_child(world)
	actor = world.get_node("StudentCharacter")
	actor.set_physics_process(false)
	await physics_frame
	var points: Array[Vector3] = []
	for level in range(4):
		points.append(Vector3(118.4, level * 4.32 + 2.16, -4.8))
		points.append(Vector3(120.8, level * 4.32 + 2.16, -4.8))
		points.append(Vector3(120.8, (level + 1) * 4.32, 0.3))
		points.append(Vector3(118.4, (level + 1) * 4.32, 0.3))
	var ascent = points.duplicate()
	for target in ascent:
		if not await walk(target): quit(1); return
	print("ASCENT_OK ", actor.position)
	points.clear()
	for level in range(3,-1,-1):
		points.append(Vector3(120.8, (level + 1) * 4.32, 0.3))
		points.append(Vector3(120.8, level * 4.32 + 2.16, -4.8))
		points.append(Vector3(118.4, level * 4.32 + 2.16, -4.8))
		points.append(Vector3(118.4, level * 4.32, 0.3))
	for target in points:
		if not await walk(target): quit(1); return
	print("DESCENT_OK ", actor.position)
	print("ROOMS=", world.find_children("Classroom_*", "Node3D", true, false).size(), " COLLIDERS=",world.find_children("*", "StaticBody3D",true,false).size())
	quit(0)
func walk(target: Vector3) -> bool:
	for frame in range(360):
		await physics_frame
		var diff = target - actor.position
		var horizontal = Vector3(diff.x,0,diff.z)
		if horizontal.length() < 0.12 and absf(diff.y) < 0.32:
			return true
		var dir = horizontal.normalized()
		actor.velocity.x = dir.x * minf(3.0, horizontal.length() * 30.0)
		actor.velocity.z = dir.z * minf(3.0, horizontal.length() * 30.0)
		actor.velocity.y = -0.1 if actor.is_on_floor() else actor.velocity.y - 9.8 / 60.0
		actor.move_and_slide()
	print("FAILED target=", target, " actual=", actor.position, " floor=", actor.is_on_floor()); for c in actor.get_slide_collision_count(): print("HIT ",actor.get_slide_collision(c).get_collider().get_path(), " normal=", actor.get_slide_collision(c).get_normal())
	return false

