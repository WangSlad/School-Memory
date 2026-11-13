extends Node3D

const FLOOR_HEIGHT := 4.32
const FLOOR_COUNT := 5
const BAY_WIDTH := 10.4
const STAIR_CENTERS := [BAY_WIDTH * 1.5, BAY_WIDTH * 11.5]
const MODEL := preload("res://assets/buildings/teaching_five_floor/teaching_five_floor.glb")
const SPRING_STYLE := preload("res://assets/buildings/teaching_floor/spring/spring_materials.gd")
const FACADE_RELIEF := preload("res://scenes/teaching_building/facade_relief.gd")
const JOINERY_DETAIL := preload("res://scenes/teaching_building/joinery_detail.gd")
const GLAZING_PANELS := preload("res://scenes/teaching_building/glazing_panels.gd")
const RESTROOM_CONVERSION := preload("res://scenes/teaching_building/restroom_conversion.gd")
const CEILING_LIGHTS := preload("res://scenes/teaching_building/ceiling_lights.gd")
const FIVE_FLOOR_SIGNS := preload("res://assets/buildings/teaching_floor/spring/textures/B03_teaching_spring_sign_five_平面.png")

@export_group("Appearance")
@export var spring_materials_enabled := true
@export var facade_relief_enabled := true
@export var joinery_detail_enabled := true
@export_group("Room Layout")
@export var restrooms_enabled := true

func _ready() -> void:
	var model := MODEL.instantiate()
	model.name = "Model"
	if restrooms_enabled:
		RESTROOM_CONVERSION.prepare_model(model)
	add_child(model)
	_build_model_collisions(model)
	_build_stairs_collision()
	_build_interfaces()
	# Rendering additions are built after collision generation and never enter it.
	if spring_materials_enabled:
		var style := SPRING_STYLE.new()
		style.name = "SpringMaterials"
		style.floor_height = FLOOR_HEIGHT
		style.bay_width = BAY_WIDTH
		style.first_classroom_bay = 3
		style.atlas_floor_count = FLOOR_COUNT
		style.sign_texture = FIVE_FLOOR_SIGNS
		style.floor_texture_scale = Vector3(1.0 / 1.3, 1.0, 0.5)
		style.solid_dado = facade_relief_enabled
		model.add_child(style)
		var glazing := GLAZING_PANELS.new()
		glazing.name = "GlazingPanels"
		add_child(glazing)
	if facade_relief_enabled:
		var relief := FACADE_RELIEF.new()
		relief.name = "FacadeRelief"
		relief.restrooms_enabled = restrooms_enabled
		add_child(relief)
	if joinery_detail_enabled:
		var joinery := JOINERY_DETAIL.new()
		joinery.name = "JoineryDetail"
		joinery.restrooms_enabled = restrooms_enabled
		add_child(joinery)
	if restrooms_enabled:
		var restrooms := RESTROOM_CONVERSION.new()
		restrooms.name = "Restrooms"
		add_child(restrooms)
	var ceiling_lights := CEILING_LIGHTS.new()
	ceiling_lights.name = "CeilingLights"
	add_child(ceiling_lights)

## Continuous weights avoid hard switches at the corridor/stair boundary.
func get_camera_region(world_position: Vector3) -> Dictionary:
	var point := to_local(world_position)
	var floor_index := clampi(int(floor((point.y + 0.1) / FLOOR_HEIGHT)), 0, FLOOR_COUNT - 1)
	var floor_y := floor_index * FLOOR_HEIGHT
	var stair_weight := 0.0
	for center: float in STAIR_CENTERS:
		var across := 1.0 - smoothstep(2.15, 3.5, absf(point.x - center))
		var along := (1.0 - smoothstep(0.8, 3.0, point.z)) * smoothstep(-7.8, -7.2, point.z)
		stair_weight = maxf(stair_weight, across * along)
	var region := "stairs" if stair_weight > 0.5 else ("room" if point.z < 0.25 else "corridor")
	return {"name": region, "stair_weight": stair_weight,
		"min_height": point.y + 0.2,
		"max_height": lerpf(floor_y + FLOOR_HEIGHT - 0.4, point.y + 2.5, stair_weight)}

func get_minimap_slice(world_position: Vector3, previous_floor: int = -1) -> Dictionary:
	var point := to_local(world_position)
	var index := clampi(int(floor((point.y + 0.08) / FLOOR_HEIGHT)), 0, FLOOR_COUNT - 1)
	# A small landing deadband prevents the floor label oscillating on stair seams.
	if previous_floor >= 0:
		if index < previous_floor and point.y > previous_floor * FLOOR_HEIGHT - 0.25:
			index = previous_floor
		elif index > previous_floor and point.y < index * FLOOR_HEIGHT - 0.03:
			index = previous_floor
	return {"floor_index": index, "floor_y": index * FLOOR_HEIGHT}

func _build_model_collisions(node: Node) -> void:
	if node is MeshInstance3D and not String(node.name).begins_with("solid_midlanding_") and not String(node.name).begins_with("solid_toplanding_") and (String(node.name).contains("_solid_") or String(node.name).begins_with("solid_")):
		node.create_trimesh_collision()
		# Rails keep their player collision but do not push the camera inward.
		var label := String(node.name)
		var rail := label.contains("Railing metal") or label.contains("Transparent blue green glass") or label.contains("balcony_end_glass") or label.contains("new_glass")
		for child in node.get_children():
			if child is StaticBody3D and not rail:
				child.set_collision_layer_value(3, true)
	for child in node.get_children():
		if not child is StaticBody3D:
			_build_model_collisions(child)

# Continuous walk surfaces share exact edges with the corridor and landings.
# The visible steps remain in the GLB; a single mesh collision avoids stacked
# ramp and landing shapes catching the capsule at their seams.
func _walk_quad(faces: PackedVector3Array, x0: float, x1: float, z0: float, z1: float, y0: float, y1: float) -> PackedVector3Array:
	var a := Vector3(x0, y0, z0)
	var b := Vector3(x1, y0, z0)
	var c := Vector3(x1, y1, z1)
	var d := Vector3(x0, y1, z1)
	faces.append_array(PackedVector3Array([a, b, c, a, c, d]))
	return faces

func _build_stairs_collision() -> void:
	var body := StaticBody3D.new()
	body.name = "StairWalkSurfaces"
	body.set_collision_layer_value(3, true)
	add_child(body)
	var faces := PackedVector3Array()
	for center in STAIR_CENTERS:
		for floor_index in range(4):
			var h := floor_index * FLOOR_HEIGHT
			var half := h + FLOOR_HEIGHT / 2.0
			var top := h + FLOOR_HEIGHT
			faces = _walk_quad(faces, center - 2.25, center - 0.15, -0.8, -4.4, h, half)
			faces = _walk_quad(faces, center + 0.15, center + 2.25, -0.8, -4.4, top, half)
			faces = _walk_quad(faces, center - 2.3, center + 2.3, -4.4, -7.2, half, half)
			faces = _walk_quad(faces, center - 2.3, center + 2.3, 0.0, -0.8, top, top)
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	shape.backface_collision = true
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	# Central handrail retains a separate continuous collision per flight.
	var rails := StaticBody3D.new()
	rails.name = "StairHandrails"
	add_child(rails)
	for center in STAIR_CENTERS:
		for floor_index in range(4):
			var h := floor_index * FLOOR_HEIGHT
			_guard(rails, center - 0.08, h, h + FLOOR_HEIGHT / 2.0, -0.8, -4.4)
			_guard(rails, center + 0.08, h + FLOOR_HEIGHT / 2.0, h + FLOOR_HEIGHT, -4.4, -0.8)

func _guard(body: StaticBody3D, x: float, y0: float, y1: float, z0: float, z1: float) -> void:
	var collision := CollisionShape3D.new()
	var shape := ConvexPolygonShape3D.new()
	shape.points = PackedVector3Array([Vector3(x-0.025,y0,z0), Vector3(x+0.025,y0,z0), Vector3(x-0.025,y1,z1), Vector3(x+0.025,y1,z1), Vector3(x-0.025,y0+1.1,z0), Vector3(x+0.025,y0+1.1,z0), Vector3(x-0.025,y1+1.1,z1), Vector3(x+0.025,y1+1.1,z1)])
	collision.shape = shape
	body.add_child(collision)

func _build_interfaces() -> void:
	var floors := Node3D.new()
	floors.name = "FloorInterfaces"
	add_child(floors)
	for index in range(FLOOR_COUNT):
		var floor_root := Node3D.new()
		floor_root.name = "Floor_%02d" % (index + 1)
		floor_root.position.y = index * FLOOR_HEIGHT
		floor_root.set_meta("floor_id", index + 1)
		floor_root.set_meta("occlusion_interface", true)
		floors.add_child(floor_root)
		var spawn := Marker3D.new()
		spawn.name = "Spawn"
		spawn.position = Vector3(STAIR_CENTERS[1] - 1.2, 0.08, 2.4)
		floor_root.add_child(spawn)
		var camera_area := Marker3D.new()
		camera_area.name = "CameraRegionAnchor"
		camera_area.position = Vector3(BAY_WIDTH * 7.0, 1.6, 2.4)
		floor_root.add_child(camera_area)
		for room in range(8):
			var classroom := Node3D.new()
			classroom.name = "Classroom_%02d" % (room + 1)
			classroom.set_meta("room_id", "F%02d_C%02d" % [index + 1, room + 1])
			classroom.set_meta("scene_transition_target", "")
			floor_root.add_child(classroom)
			for door_index in range(2):
				var marker := Marker3D.new()
				marker.name = "FrontDoor" if door_index == 0 else "RearDoor"
				marker.position = Vector3((room + 3) * BAY_WIDTH + (0.95 if door_index == 0 else 7.05) * 1.3, 0.0, 0.65)
				classroom.add_child(marker)






