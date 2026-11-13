extends Node3D

func _ready() -> void:
	_add_collisions($Building)
	_add_stair_ramp()

func _add_collisions(node: Node) -> void:
	if node is MeshInstance3D:
		var label := String(node.name)
		if label.begins_with("Floor slab") or label.begins_with("Facade") or label.begins_with("Sill") or label.begins_with("Lintel") or label.begins_with("Door ") or label.begins_with("Window ") or label.begins_with("Frame column") or label.begins_with("Glass balustrade") or label.begins_with("Rear wall") or label.begins_with("Left end wall") or label.begins_with("Right end wall"):
			node.create_trimesh_collision()
	for child in node.get_children():
		if not child is StaticBody3D:
			_add_collisions(child)

func _add_stair_ramp() -> void:
	# Smooth collision over the visible 18 risers so the existing controller can ascend.
	var body := StaticBody3D.new()
	var shape_node := CollisionShape3D.new()
	var shape := ConvexPolygonShape3D.new()
	shape.points = PackedVector3Array([Vector3(83.25, 0, -0.4), Vector3(84.75, 0, -0.4), Vector3(83.25, 3.6, -5.8), Vector3(84.75, 3.6, -5.8), Vector3(83.25, 0, -5.8), Vector3(84.75, 0, -5.8)])
	shape_node.shape = shape
	body.add_child(shape_node)
	add_child(body)
