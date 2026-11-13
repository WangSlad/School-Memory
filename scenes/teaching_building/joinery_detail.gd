extends Node3D
## Closed, bevelled joinery details; shared by all five floors, without physics.

const HEIGHT := 4.32
const BAY := 10.4
const BASE := "res://assets/buildings/teaching_floor/spring/materials/"
const PALETTE := {
	"DoorWood": preload(BASE + "door_wood.tres"),
	"FrameWood": preload(BASE + "frame_wood.tres"),
	"Metal": preload(BASE + "joinery_metal.tres"),
	"Seal": preload(BASE + "joinery_seal.tres"),
}
var _builders: Dictionary = {}
var restrooms_enabled := false
var _box_count := 0

func _ready() -> void:
	_remove_old_handle_rendering()
	for role in PALETTE:
		var builder := SurfaceTool.new()
		builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		_builders[role] = builder
	for bay in range(2, 14):
		if bay == 11:
			continue
		var start := bay * BAY
		if bay == 13 and restrooms_enabled:
			for offset in [1.45, 6.65]:
				_door(start + offset, 2.35)
			for offset in [3.75, 8.95]:
				_window(start + offset, 1.25, 2.65, 3.5)
		elif bay >= 3 and bay <= 10:
			for x in [0.95, 7.05]:
				_door(start + x * 1.3, 2.35)
			for x in [3.0, 5.0]:
				_window(start + x * 1.3, 1.95, 1.0, 2.35)
		elif bay == 12:
			_door(start + 1.3 * 1.3, 2.3)
			for x in [4.1, 6.2]:
				_window(start + x * 1.3, 1.625, 1.35, 2.35)
		else:
			_door(start + 1.1 * 1.3, 2.35)
			for x in [3.4, 5.5]:
				_window(start + x * 1.3, 1.95, 1.0, 2.35)
	for role in PALETTE:
		var mesh: ArrayMesh = _builders[role].commit()
		mesh.surface_set_material(0, PALETTE[role])
		for floor_index in range(5):
			var instance := MeshInstance3D.new()
			instance.name = "Floor%02d_%s" % [floor_index + 1, role]
			instance.position.y = floor_index * HEIGHT
			instance.mesh = mesh
			add_child(instance)
	set_meta("closed_profiles_per_floor", _box_count)
	set_meta("doors_per_floor", 20 if restrooms_enabled else 19)
	set_meta("windows_per_floor", 22)
	_builders.clear()

func _remove_old_handle_rendering() -> void:
	# Original handles are grouped separately from the railings. Hide only their
	# rendering after collision creation; preserve their source mesh and physics.
	var hidden := 0
	for instance: MeshInstance3D in get_parent().get_node("Model").find_children("*", "MeshInstance3D", true, false):
		if String(instance.name).contains("solid_Railing metal"):
			instance.hide()
			hidden += 1
	assert(hidden == 5, "Expected one original handle group per floor")
	set_meta("hidden_source_handle_groups", hidden)

func restore_source() -> void:
	hide()
	for instance: MeshInstance3D in get_parent().get_node("Model").find_children("*", "MeshInstance3D", true, false):
		if String(instance.name).contains("solid_Railing metal"):
			instance.show()

func _ring(role: String, x: float, half_width: float, y0: float, y1: float, strip: float, z0: float, z1: float) -> void:
	_box(role, Vector3(x - half_width, y0, z0), Vector3(x - half_width + strip, y1, z1))
	_box(role, Vector3(x + half_width - strip, y0, z0), Vector3(x + half_width, y1, z1))
	_box(role, Vector3(x - half_width + strip, y0, z0), Vector3(x + half_width - strip, y0 + strip, z1))
	_box(role, Vector3(x - half_width + strip, y1 - strip, z0), Vector3(x + half_width - strip, y1, z1))

func _door(x: float, height: float) -> void:
	# Thin panel mouldings and dark grooves lie on the original solid door leaf.
	for interval in [Vector2(0.48, 1.70), Vector2(0.16, 0.40)]:
		_ring("Seal", x, 0.485, interval.x - 0.005, interval.y + 0.005, 0.026, 0.064, 0.069)
		_ring("DoorWood", x, 0.476, interval.x + 0.004, interval.y - 0.004, 0.018, 0.067, 0.083)
	# Door stop closes the reveal; it does not cross the opening or threshold.
	_ring("Seal", x, 0.605, 0.042, height - 0.044, 0.012, 0.064, 0.072)
	# Hinges have mounting leaves, barrel and pin caps, with real side thickness.
	for y in [0.32, 1.16, 1.98]:
		_box("Metal", Vector3(x - 0.64, y - 0.055, 0.067), Vector3(x - 0.585, y + 0.055, 0.080))
		_box("Metal", Vector3(x - 0.643, y - 0.066, 0.078), Vector3(x - 0.617, y + 0.066, 0.108))
	# Nickel backplate and supported rounded pull cover the old simple handle.
	var handle := x + 0.416
	_box("Metal", Vector3(handle - 0.035, 0.90, 0.066), Vector3(handle + 0.035, 1.14, 0.080))
	for y in [0.955, 1.085]:
		_box("Metal", Vector3(handle - 0.014, y - 0.014, 0.078), Vector3(handle + 0.014, y + 0.014, 0.145), 0.004)
	_box("Metal", Vector3(handle - 0.015, 0.938, 0.131), Vector3(handle + 0.015, 1.102, 0.159), 0.008)
	for y in [0.918, 1.122]:
		_box("Metal", Vector3(handle - 0.005, y - 0.005, 0.080), Vector3(handle + 0.005, y + 0.005, 0.084), 0.001)
		_box("Seal", Vector3(handle - 0.003, y - 0.0008, 0.083), Vector3(handle + 0.003, y + 0.0008, 0.085), 0.0004)
	# A modest brushed kick plate protects the foot of each door.
	_box("Metal", Vector3(x - 0.54, 0.057, 0.066), Vector3(x + 0.54, 0.112, 0.076))

func _window(x: float, width: float, sill: float, top: float) -> void:
	var half := width * 0.5
	# Inset seal and two sash frames: glass stays visible inside these rings.
	_ring("Seal", x, half - 0.048, sill + 0.046, top - 0.046, 0.013, 0.064, 0.074)
	for side in [-1.0, 1.0]:
		var center: float = x + side * width * 0.25
		var front := 0.086 if side < 0.0 else 0.108
		_ring("FrameWood", center, width * 0.25 - 0.041, sill + 0.062, top - 0.062, 0.026, 0.063, front)
		# Slim glazing beads follow the inner edge and seal against the pane.
		_ring("Seal", center, width * 0.25 - 0.071, sill + 0.091, top - 0.091, 0.007, 0.065, 0.072)
	# Recessed sliding tracks, visibly attached to the existing lower rail.
	for z in [0.13, 0.17]:
		_box("Seal", Vector3(x - half + 0.045, sill + 0.033, z), Vector3(x + half - 0.045, sill + 0.041, z + 0.008))
	# The centre latch is attached to the existing centre mullion (front z=.22).
	var latch_y := sill + (top - sill) * 0.45
	_box("Metal", Vector3(x - 0.035, latch_y - 0.04, 0.216), Vector3(x + 0.035, latch_y + 0.04, 0.232))
	_box("Metal", Vector3(x - 0.009, latch_y - 0.008, 0.229), Vector3(x + 0.079, latch_y + 0.008, 0.250), 0.004)

func _face(builder: SurfaceTool, vertices: Array, normal: Vector3) -> void:
	# Godot front faces wind clockwise when viewed from outside.
	if (vertices[1] - vertices[0]).cross(vertices[2] - vertices[0]).dot(normal) > 0:
		vertices.reverse()
	for index in range(1, vertices.size() - 1):
		for v: Vector3 in [vertices[0], vertices[index], vertices[index + 1]]:
			builder.set_normal(normal)
			builder.set_uv(Vector2(v.x, v.y))
			builder.add_vertex(v)

func _box(role: String, lo: Vector3, hi: Vector3, bevel: float = 0.002) -> void:
	var h := (hi - lo) * 0.5
	var center := (hi + lo) * 0.5
	var b := minf(bevel, minf(h.x, minf(h.y, h.z)) * 0.8)
	var inner := h - Vector3.ONE * b
	var builder: SurfaceTool = _builders[role]
	# Six flat faces, twelve chamfer strips and eight triangular corners.
	for axis in range(3):
		var u := (axis + 1) % 3
		var v := (axis + 2) % 3
		for sign_a in [-1.0, 1.0]:
			var points: Array = []
			for pair in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
				var p := Vector3.ZERO
				p[axis] = sign_a * h[axis]
				p[u] = pair.x * inner[u]
				p[v] = pair.y * inner[v]
				points.append(center + p)
			var normal := Vector3.ZERO
			normal[axis] = sign_a
			_face(builder, points, normal)
		# Edges parallel to this axis, joining the two adjacent face planes.
		for sign_u in [-1.0, 1.0]:
			for sign_v in [-1.0, 1.0]:
				var points: Array = []
				for pair in [Vector2(-1, 0), Vector2(1, 0), Vector2(1, 1), Vector2(-1, 1)]:
					var p := Vector3.ZERO
					p[axis] = pair.x * inner[axis]
					p[u] = sign_u * (h[u] if pair.y == 0 else inner[u])
					p[v] = sign_v * (inner[v] if pair.y == 0 else h[v])
					points.append(center + p)
				var normal := Vector3.ZERO
				normal[u] = sign_u
				normal[v] = sign_v
				_face(builder, points, normal.normalized())
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var sign_v := Vector3(sx, sy, sz)
				var points: Array = []
				for axis in range(3):
					var p := inner * sign_v
					p[axis] = h[axis] * sign_v[axis]
					points.append(center + p)
				_face(builder, points, sign_v.normalized())
	_box_count += 1
