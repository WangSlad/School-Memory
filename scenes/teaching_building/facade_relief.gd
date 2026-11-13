extends Node3D
## Solid facade finishes fitted to the existing five-storey model (metres).
## All boxes penetrate the original wall at z=0; nothing is a floating card.
## This node is added AFTER collision generation and adds no physics objects.

const FLOOR_HEIGHT := 4.32
const BAY_WIDTH := 10.4
const FLOOR_COUNT := 5
const CONCRETE := preload("res://assets/buildings/teaching_floor/spring/materials/concrete.tres")
const SAKURA := preload("res://assets/buildings/teaching_floor/spring/materials/sakura.tres")
var _builders: Dictionary = {}
var restrooms_enabled := false
var _unit_box := BoxMesh.new()
var _boxes_per_floor := 0
var _floor_bounds: Array[AABB] = []

func _ready() -> void:
	_unit_box.size = Vector3.ONE
	for role in ["Dado", "Supports"]:
		var builder := SurfaceTool.new()
		builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		_builders[role] = builder
	for bay in range(1, 14):
		_build_bay(bay)
	for role in _builders:
		var mesh: ArrayMesh = _builders[role].commit()
		mesh.surface_set_material(0, SAKURA if role == "Dado" else CONCRETE)
		for floor_index in range(FLOOR_COUNT):
			var instance := MeshInstance3D.new()
			instance.name = "Floor%02d_%s" % [floor_index + 1, role]
			instance.mesh = mesh
			instance.position.y = floor_index * FLOOR_HEIGHT
			add_child(instance)
	set_meta("boxes_per_floor", _boxes_per_floor)
	set_meta("profile_bounds", _floor_bounds)
	_builders.clear()

func _box(role: String, x0: float, x1: float, y0: float, y1: float, z0: float, z1: float) -> void:
	if x1 <= x0 or y1 <= y0:
		return
	var size := Vector3(x1 - x0, y1 - y0, z1 - z0)
	var corner := Vector3(x0, y0, z0)
	var center := corner + size * 0.5
	_builders[role].append_from(_unit_box, 0, Transform3D(Basis.from_scale(size), center))
	_floor_bounds.append(AABB(corner, size))
	_boxes_per_floor += 1

func _dado(x0: float, x1: float) -> void:
	_box("Dado", x0, x1, 0.012, 0.82, -0.012, 0.045)
	_box("Supports", x0, x1, 0.82, 0.885, -0.012, 0.075)
	_box("Dado", x0, x1, 0.012, 0.14, -0.012, 0.09)

func _source_height(height: float) -> float:
	# The original five-storey generator stretches only points ABOVE 2.35m.
	return height if height <= 2.35 else 2.35 + (height - 2.35) * (FLOOR_HEIGHT - 2.35) / 1.25

func _surround(center_x: float, width: float, sill: float, height: float) -> void:
	# Fill the existing frame's 4cm rear gap with a slightly wider solid reveal.
	var top := sill + height
	var bottom_y := maxf(0.012, _source_height(sill - 0.04) - 0.015)
	var top_y := _source_height(top + 0.04) + 0.015
	var half_jamb := 0.07 * 1.3 * 0.5 + 0.015
	for x in [center_x - width * 0.5, center_x + width * 0.5]:
		_box("Supports", x - half_jamb, x + half_jamb, bottom_y, top_y, -0.012, 0.060)
	var half_width := width * 0.5 + half_jamb
	for y in [sill, top]:
		if y < 0.1:
			continue # Keep thresholds flush and leave the original floor exposed.
		_box("Supports", center_x - half_width, center_x + half_width,
			_source_height(y - 0.035) - 0.015, _source_height(y + 0.035) + 0.015, -0.012, 0.060)
	if sill > 0.0:
		# The sill top meets the bottom of the existing green horizontal frame.
		var sill_top := sill - 0.035
		_box("Supports", center_x - width * 0.5 - 0.105, center_x + width * 0.5 + 0.105,
			sill_top - 0.085, sill_top, -0.015, 0.245)

func _build_bay(bay: int) -> void:
	if bay == 13 and restrooms_enabled:
		return # This facade and its finishes are supplied by RestroomConversion.
	var start := bay * BAY_WIDTH
	if bay == 1 or bay == 11:
		# Actual 4.90m stair openings, including the inserted left stair bay.
		_dado(start, start + 2.75)
		_dado(start + 7.65, start + BAY_WIDTH)
		return
	var doors: Array[Vector2] = []
	var windows: Array[Vector3] = [] # center X, width, sill
	if bay >= 3 and bay <= 10:
		doors = [Vector2(start + 0.95 * 1.3, 1.3), Vector2(start + 7.05 * 1.3, 1.3)]
		windows = [Vector3(start + 3.0 * 1.3, 1.95, 1.0), Vector3(start + 5.0 * 1.3, 1.95, 1.0)]
	elif bay == 12:
		doors = [Vector2(start + 1.3 * 1.3, 1.3)]
		windows = [Vector3(start + 4.1 * 1.3, 1.625, 1.35), Vector3(start + 6.2 * 1.3, 1.625, 1.35)]
	else:
		doors = [Vector2(start + 1.1 * 1.3, 1.3)]
		windows = [Vector3(start + 3.4 * 1.3, 1.95, 1.0), Vector3(start + 5.5 * 1.3, 1.95, 1.0)]
	var previous := start
	for door in doors:
		_dado(previous, door.x - door.y * 0.5)
		previous = door.x + door.y * 0.5
		_surround(door.x, door.y, 0.0, 2.3 if bay == 12 else 2.35)
	_dado(previous, start + BAY_WIDTH)
	for window in windows:
		_surround(window.x, window.y, window.z, 1.0 if bay == 12 else 1.35)
