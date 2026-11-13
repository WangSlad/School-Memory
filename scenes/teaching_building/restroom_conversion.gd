extends Node3D
## Convert ONLY the last bay into two enclosed rooms. Source files stay intact.
const START := 135.2
const END := 145.6
const CENTER := 140.4
const HEIGHT := 4.32
const BASE := "res://assets/buildings/teaching_floor/spring/materials/"
const TRIM_ROLES := {
	"detail_Deep green frames": 144, "solid_Deep green frames": 24,
	"solid_Painted green door": 12, "solid_Railing metal": 12,
	"solid_Soft ivory wall": 98, "solid_Window glazing": 24,
}
static var _cropped: Dictionary = {}
const PALETTE := {
	"Wall": preload(BASE + "restroom_wall.tres"),
	"Floor": preload(BASE + "floor.tres"),
	"Wood": preload(BASE + "door_wood.tres"),
	"Frame": preload(BASE + "frame_wood.tres"),
	"Glass": preload(BASE + "window_glass.tres"),
	"Pink": preload(BASE + "sakura.tres"),
	"Concrete": preload(BASE + "concrete.tres"),
	"Ceramic": preload(BASE + "restroom_ceramic.tres"),
	"Metal": preload(BASE + "joinery_metal.tres"),
	"Dark": preload(BASE + "joinery_seal.tres"),
	"Signs": preload(BASE + "restroom_signs.tres"),
}
var _builders := {}
var _solid_faces := PackedVector3Array()
var _unit := BoxMesh.new()

static func prepare_model(model: Node3D) -> void:
	for instance: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		var name_string := String(instance.name)
		if not name_string.begins_with("F") or name_string.length() < 5:
			continue
		var role := name_string.substr(4)
		if not TRIM_ROLES.has(role):
			continue
		var source := instance.mesh
		var id := source.get_instance_id()
		if not _cropped.has(id):
			var arrays := source.surface_get_arrays(0)
			var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var retained := PackedInt32Array()
			var removed := PackedInt32Array()
			for i in range(0, indices.size(), 3):
				var replace := true
				var shared_boundary := true
				for index in range(i, i + 3):
					var p := points[indices[index]]
					replace = replace and p.x >= START - 0.001 and p.z >= -0.201 and p.z <= 0.301
					shared_boundary = shared_boundary and absf(p.x - START) < 0.001 and normals[indices[index]].x > 0.9
				if replace and not shared_boundary:
					removed.append_array(indices.slice(i, i + 3))
				else:
					retained.append_array(indices.slice(i, i + 3))
			assert(removed.size() / 3 == TRIM_ROLES[role], "Unexpected right-bay topology: %s removed=%d" % [role, removed.size() / 3])
			arrays[Mesh.ARRAY_INDEX] = retained
			var mesh := ArrayMesh.new()
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			mesh.surface_set_material(0, source.surface_get_material(0))
			mesh.set_meta("restroom_source", source)
			mesh.set_meta("removed_indices", removed)
			_cropped[id] = mesh
		instance.mesh = _cropped[id]

func _ready() -> void:
	_unit.size = Vector3.ONE
	for role in PALETTE:
		var builder := SurfaceTool.new()
		builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		_builders[role] = builder
	_front()
	_interior()
	for role in PALETTE:
		var mesh: ArrayMesh = _builders[role].commit()
		mesh.surface_set_material(0, PALETTE[role])
		for level in range(5):
			var instance := MeshInstance3D.new()
			instance.name = "Floor%02d_%s" % [level + 1, role]
			instance.position.y = level * HEIGHT
			instance.mesh = mesh
			add_child(instance)
	for level in range(5):
		var body := StaticBody3D.new()
		body.name = "Floor%02d_RestroomCollision" % (level + 1)
		body.position.y = level * HEIGHT
		var collision := CollisionShape3D.new()
		var shape := ConcavePolygonShape3D.new()
		shape.set_faces(_solid_faces)
		shape.backface_collision = true
		collision.shape = shape
		body.add_child(collision)
		add_child(body)
		_interfaces(level)
	_builders.clear()
	set_meta("converted_bay", 13)
	set_meta("rooms_per_floor", 2)
	set_meta("room_bounds", [AABB(Vector3(START + 0.16, 0, -7.0), Vector3(4.96, 4.08, 6.8)), AABB(Vector3(CENTER + 0.08, 0, -7.0), Vector3(4.92, 4.08, 6.8))])

func _box(role: String, lo: Vector3, hi: Vector3, solid: bool = false) -> void:
	var transform := Transform3D(Basis.from_scale(hi - lo), (lo + hi) * 0.5)
	_builders[role].append_from(_unit, 0, transform)
	if solid:
		for p in _unit.get_faces():
			_solid_faces.append(transform * p)

func _front_span(x0: float, x1: float, y0: float, y1: float) -> void:
	_box("Wall", Vector3(x0, y0, -0.2), Vector3(x1, y1, 0), true)
	if y0 < 0.82:
		_box("Pink", Vector3(x0, maxf(y0, 0.012), -0.012), Vector3(x1, minf(y1, 0.82), 0.045))
	if y0 <= 0.82 and y1 >= 0.885:
		_box("Concrete", Vector3(x0, 0.82, -0.012), Vector3(x1, 0.885, 0.075))

func _frame(x: float, width: float, y0: float, y1: float) -> void:
	for sign_x in [-1.0, 1.0]:
		var side: float = x + sign_x * width * 0.5
		_box("Frame", Vector3(side - 0.0455, maxf(0, y0 - 0.04), -0.015), Vector3(side + 0.0455, y1 + 0.04, 0.20))
	for y in [y0, y1]:
		_box("Frame", Vector3(x - width * 0.5, maxf(0, y - 0.035), -0.015), Vector3(x + width * 0.5, y + 0.035, 0.20))

func _front() -> void:
	for gender in range(2):
		var start := START + gender * 5.2
		var door := start + 1.45
		var window := start + 3.75
		_front_span(start, door - 0.65, 0, 4.08)
		_front_span(door + 0.65, window - 0.625, 0, 4.08)
		_front_span(window + 0.625, start + 5.2, 0, 4.08)
		_front_span(door - 0.65, door + 0.65, 2.35, 4.08)
		_front_span(window - 0.625, window + 0.625, 0, 2.65)
		_front_span(window - 0.625, window + 0.625, 3.5, 4.08)
		_box("Wood", Vector3(door - 0.65, 0, 0.005), Vector3(door + 0.65, 2.35, 0.065), true)
		_frame(door, 1.3, 0, 2.35)
		_frame(window, 1.25, 2.65, 3.5)
		_box("Glass", Vector3(window - 0.625, 2.65, 0.02), Vector3(window + 0.625, 3.5, 0.065), true)
		_box("Frame", Vector3(window - 0.029, 2.65, 0.06), Vector3(window + 0.029, 3.5, 0.22))
		# Opaque high privacy panes retain the existing mist-blue glass finish.
		_box("Concrete", Vector3(window - 0.73, 2.53, -0.015), Vector3(window + 0.73, 2.615, 0.245))
		_sign(door, gender)

func _sign(x: float, gender: int) -> void:
	_box("Metal", Vector3(x - 0.22, 1.41, 0.064), Vector3(x + 0.22, 2.05, 0.090))
	var builder: SurfaceTool = _builders["Signs"]
	var left := gender * 0.5
	var vertices := [Vector3(x - 0.21, 2.04, 0.091), Vector3(x + 0.21, 2.04, 0.091), Vector3(x + 0.21, 1.42, 0.091), Vector3(x - 0.21, 1.42, 0.091)]
	var uvs := [Vector2(left, 0), Vector2(left + 0.5, 0), Vector2(left + 0.5, 1), Vector2(left, 1)]
	for index in [0, 1, 2, 0, 2, 3]:
		builder.set_normal(Vector3.FORWARD * -1)
		builder.set_uv(uvs[index])
		builder.add_vertex(vertices[index])

func _interior() -> void:
	# Existing rear/right shell and all slabs stay. New left and centre walls close
	# the two independent spaces; their frontage is wholly inside the last bay.
	_box("Wall", Vector3(START, 0, -7.0), Vector3(START + 0.16, 4.08, -0.2), true)
	_box("Wall", Vector3(CENTER - 0.08, 0, -7.0), Vector3(CENTER + 0.08, 4.08, -0.2), true)
	_box("Floor", Vector3(START + 0.16, 0.003, -7.0), Vector3(END - 0.2, 0.014, -0.2))
	for gender in range(2):
		var start := START + gender * 5.2
		# A washable ceramic dado on the back wall and room-side walls.
		_box("Ceramic", Vector3(start + 0.18, 0.015, -7.005), Vector3(start + 5.0, 1.12, -6.98))
		var side_faces: Array = [START + 0.16, CENTER - 0.08] if gender == 0 else [CENTER + 0.08, END - 0.26]
		for x in side_faces:
			_box("Ceramic", Vector3(x - 0.012, 0.015, -6.98), Vector3(x + 0.012, 1.12, -0.22))
		var stall_count := 2 if gender == 0 else 3
		for i in range(stall_count):
			var x := start + 0.32 + i * 1.47
			_stall(x, 1.47, gender)
		for x in [start + 3.1, start + 4.2]:
			_sink(x)
	# Two wall-mounted urinals in the men's room, with a privacy screen.
	for z in [-2.55, -3.55]:
		_box("Ceramic", Vector3(START + 0.17, 0.38, z - 0.22), Vector3(START + 0.39, 1.0, z + 0.22), true)
		_box("Dark", Vector3(START + 0.388, 0.50, z - 0.14), Vector3(START + 0.395, 0.89, z + 0.14))
		_box("Ceramic", Vector3(START + 0.25, 0.38, z - 0.22), Vector3(START + 0.53, 0.49, z + 0.22))
		_box("Metal", Vector3(START + 0.20, 1.0, z - 0.018), Vector3(START + 0.25, 1.18, z + 0.018))
	_box("Frame", Vector3(START + 0.16, 0.32, -3.07), Vector3(START + 0.88, 1.62, -3.03), true)

func _stall(x: float, width: float, gender: int) -> void:
	var role := "Frame" if gender == 0 else "Pink"
	_box(role, Vector3(x, 0.15, -6.97), Vector3(x + 0.045, 2.1, -4.55), true)
	_box(role, Vector3(x + width - 0.045, 0.15, -6.97), Vector3(x + width, 2.1, -4.55), true)
	_box(role, Vector3(x + 0.07, 0.18, -4.60), Vector3(x + width - 0.07, 2.05, -4.55), true)
	for side in [x + 0.02, x + width - 0.02]:
		_box("Metal", Vector3(side - 0.02, 0.014, -4.64), Vector3(side + 0.02, 0.23, -4.53))
	_box("Metal", Vector3(x + width - 0.19, 0.94, -4.553), Vector3(x + width - 0.16, 1.07, -4.50))
	_toilet(x + width * 0.5, -6.32)

func _primitive(role: String, mesh: Mesh, center: Vector3, scale_value: Vector3 = Vector3.ONE) -> void:
	_builders[role].append_from(mesh, 0, Transform3D(Basis.from_scale(scale_value), center))

func _toilet(x: float, z: float) -> void:
	_box("Ceramic", Vector3(x - 0.13, 0.012, z - 0.18), Vector3(x + 0.13, 0.24, z + 0.18), true)
	_box("Ceramic", Vector3(x - 0.20, 0.25, z - 0.43), Vector3(x + 0.20, 0.82, z - 0.25), true)
	var bowl := CylinderMesh.new()
	bowl.top_radius = 0.21
	bowl.bottom_radius = 0.13
	bowl.height = 0.30
	bowl.radial_segments = 16
	_primitive("Ceramic", bowl, Vector3(x, 0.32, z), Vector3(1, 1, 1.3))
	var seat := TorusMesh.new()
	seat.inner_radius = 0.115
	seat.outer_radius = 0.22
	seat.rings = 16
	seat.ring_segments = 8
	_primitive("Ceramic", seat, Vector3(x, 0.49, z), Vector3(1, 0.4, 1.3))
	_box("Dark", Vector3(x - 0.10, 0.47, z - 0.15), Vector3(x + 0.10, 0.475, z + 0.15))
	_box("Metal", Vector3(x + 0.12, 0.71, z - 0.24), Vector3(x + 0.18, 0.74, z - 0.21))

func _sink(x: float) -> void:
	_box("Ceramic", Vector3(x - 0.44, 0.72, -1.07), Vector3(x + 0.44, 0.82, -0.19), true)
	for side in [-0.30, 0.30]:
		_box("Metal", Vector3(x + side - 0.018, 0.52, -0.90), Vector3(x + side + 0.018, 0.725, -0.18))
	var inset := CylinderMesh.new()
	inset.top_radius = 0.205
	inset.bottom_radius = 0.205
	inset.height = 0.006
	inset.radial_segments = 24
	_primitive("Dark", inset, Vector3(x, 0.823, -0.68), Vector3(1.25, 1, 1))
	var rim := TorusMesh.new()
	rim.inner_radius = 0.20
	rim.outer_radius = 0.26
	rim.rings = 16
	rim.ring_segments = 8
	_primitive("Ceramic", rim, Vector3(x, 0.828, -0.68), Vector3(1.25, 0.30, 1.0))
	_box("Metal", Vector3(x - 0.018, 0.81, -0.39), Vector3(x + 0.018, 1.00, -0.35))
	_box("Metal", Vector3(x - 0.018, 0.97, -0.58), Vector3(x + 0.018, 1.005, -0.35))
	_box("Frame", Vector3(x - 0.41, 1.12, -0.225), Vector3(x + 0.41, 2.04, -0.195))
	_box("Glass", Vector3(x - 0.38, 1.15, -0.228), Vector3(x + 0.38, 2.01, -0.224))

func _interfaces(level: int) -> void:
	var floor_node := Node3D.new()
	floor_node.name = "Floor%02d_RestroomInterfaces" % (level + 1)
	floor_node.position.y = level * HEIGHT
	add_child(floor_node)
	for gender in range(2):
		var room := Node3D.new()
		room.name = "Men" if gender == 0 else "Women"
		room.set_meta("room_id", "F%02d_WC_%s" % [level + 1, "M" if gender == 0 else "F"])
		room.set_meta("gender", "men" if gender == 0 else "women")
		room.set_meta("side", "left" if gender == 0 else "right")
		floor_node.add_child(room)
		var entry := Marker3D.new()
		entry.name = "Entrance"
		entry.position = Vector3(START + gender * 5.2 + 1.45, 0.04, 0.65)
		room.add_child(entry)
		var inside := Marker3D.new()
		inside.name = "Interior"
		inside.position = Vector3(START + gender * 5.2 + 2.5, 0.04, -2.7)
		room.add_child(inside)
