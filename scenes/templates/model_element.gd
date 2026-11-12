@tool
extends Node3D

enum Pivot {
	BOTTOM_CENTER, BOTTOM_FRONT_LEFT, BOTTOM_FRONT_RIGHT, BOTTOM_BACK_LEFT, BOTTOM_BACK_RIGHT,
	MIDDLE_CENTER, MIDDLE_FRONT_LEFT, MIDDLE_FRONT_RIGHT, MIDDLE_BACK_LEFT, MIDDLE_BACK_RIGHT,
	TOP_CENTER, TOP_FRONT_LEFT, TOP_FRONT_RIGHT, TOP_BACK_LEFT, TOP_BACK_RIGHT,
}

const CORNERS := [
	Vector2(0.5, 0.5), Vector2(0.0, 1.0), Vector2(1.0, 1.0),
	Vector2(0.0, 0.0), Vector2(1.0, 0.0),
]

@export var glb_scene: PackedScene:
	set(value):
		glb_scene = value
		_queue_update()
## Every +1 doubles the size. Every -1 halves it. 0 uses the imported size.
@export_range(-6.0, 6.0, 0.01) var scale_steps := 0.0:
	set(value):
		scale_steps = value
		_queue_update()
## Front is +Z, and left is -X, in the template's local coordinates.
@export var pivot := Pivot.BOTTOM_CENTER:
	set(value):
		pivot = value
		_queue_update()
## Reflects the model along its local X axis.
@export var mirror_horizontal := false:
	set(value):
		mirror_horizontal = value
		_queue_update()
## Reflects the model along its local Y axis.
@export var mirror_vertical := false:
	set(value):
		mirror_vertical = value
		_queue_update()

@export_group("Rendering")
@export var soften_materials := false:
	set(value):
		soften_materials = value
		_queue_render_update()
@export_range(0.0, 2.0, 0.01) var window_glow := 1.0:
	set(value):
		window_glow = value
		_queue_render_update()
@export var plate_tint := Color.WHITE
@export var facade_tint := Color.WHITE:
	set(value):
		facade_tint = value
		_queue_render_update()
@export_range(0.0, 1.0, 0.01) var clay_sheen := 0.0:
	set(value):
		clay_sheen = value
		_queue_render_update()
@export var cast_model_shadows := true:
	set(value):
		cast_model_shadows = value
		_queue_render_update()

var _render_dirty := true
var _update_queued := false
var _loaded_scene: PackedScene
var _model: Node3D
var _bounds := AABB()
var _has_bounds := false
var _faces := PackedVector3Array()

@onready var _visual: Node3D = $Visual
@onready var _collision: CollisionShape3D = $StaticBody3D/CollisionShape3D


func _ready() -> void:
	_update()


func _queue_render_update() -> void:
	_render_dirty = true
	_queue_update()


func _queue_update() -> void:
	if is_node_ready() and not _update_queued:
		_update_queued = true
		_update.call_deferred()


func _update() -> void:
	_update_queued = false
	if glb_scene != _loaded_scene or _render_dirty:
		_render_dirty = false
		_load_model()
	if not _has_bounds:
		_collision.shape = null
		return

	var factor := pow(2.0, scale_steps)
	var axes := Vector3(-1.0 if mirror_horizontal else 1.0,
		-1.0 if mirror_vertical else 1.0, 1.0) * factor
	var basis := Basis.from_scale(axes)
	var mirrored_bounds := Transform3D(basis, Vector3.ZERO) * _bounds
	var corner: Vector2 = CORNERS[pivot % CORNERS.size()]
	var anchor := mirrored_bounds.position + mirrored_bounds.size * Vector3(
		corner.x, floorf(float(pivot) / CORNERS.size()) * 0.5, corner.y)
	_visual.transform = Transform3D(basis, -anchor)

	if _faces.is_empty():
		_collision.shape = null
		return
	# Bake the visual transform into the vertices so the physics node stays unscaled.
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(_visual.transform * _faces)
	_collision.shape = shape


func _load_model() -> void:
	if is_instance_valid(_model):
		_visual.remove_child(_model)
		_model.queue_free()
		_model = null
	_loaded_scene = glb_scene
	_has_bounds = false
	_faces.clear()
	if glb_scene == null:
		return
	var instance := glb_scene.instantiate()
	_model = instance as Node3D
	if _model == null:
		instance.free()
		push_warning("The model template needs a 3D scene root.")
		return
	_visual.add_child(_model)
	_refine_meshes(_model)
	_collect_meshes(_model, Transform3D.IDENTITY)


func _collect_meshes(node: Node, parent_transform: Transform3D) -> void:
	var local_transform := parent_transform
	if node is Node3D:
		local_transform *= node.transform
	if node is MeshInstance3D and node.mesh != null:
		var mesh_bounds: AABB = local_transform * node.get_aabb()
		_bounds = _bounds.merge(mesh_bounds) if _has_bounds else mesh_bounds
		_has_bounds = true
		var faces: PackedVector3Array = node.mesh.get_faces()
		if not faces.is_empty() and not is_zero_approx(local_transform.basis.determinant()):
			_faces.append_array(local_transform * faces)
	for child in node.get_children():
		_collect_meshes(child, local_transform)




# Reinstantiation above supplies an untouched baseline for every rebuild.
func _refine_meshes(node: Node) -> void:
	if node is MeshInstance3D and node.mesh != null:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_model_shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if soften_materials:
			var whole_override: Material = node.material_override
			if whole_override != null:
				node.material_override = _refine_material(whole_override)
			else:
				for surface in range(node.mesh.get_surface_count()):
					var original: Material = node.get_active_material(surface)
					if original != null:
						node.set_surface_override_material(surface, _refine_material(original))
	for child in node.get_children():
		_refine_meshes(child)


func _refine_material(original: Material) -> Material:
	if not original is BaseMaterial3D:
		return original
	var material: BaseMaterial3D = original.duplicate()
	var material_name := original.resource_name.to_lower()
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if material.normal_enabled:
		material.normal_scale = minf(material.normal_scale, 1.0) * 0.35
	if material.metallic < 0.5:
		material.roughness = clampf(material.roughness, 0.62, 0.82) - 0.15 * clay_sheen
		material.metallic_specular = 0.32 + 0.2 * clay_sheen
	if material.albedo_color.a >= 0.85 and not material_name.contains("interior") and (material_name.contains("limestone") or material_name == "concrete" or material_name == "v2_stand_concrete"):
		material.albedo_color *= facade_tint
	# Keep each asset's AO UV selection: no second UV bake was established.
	if material.albedo_color.a < 0.85:
		material.ao_enabled = false
	elif material.ao_enabled:
		material.ao_light_affect = 0.35
	if material_name in ["v2_glass_reflection", "transparent blue glass", "opaque tinted glazing"]:
		material.emission_enabled = true
		material.emission = Color(1.0, 0.65, 0.36)
		material.emission_energy_multiplier = 1.4 * window_glow
		if material.albedo_texture != null:
			material.emission_texture = material.albedo_texture
	if material_name.contains("leaf") or material_name.contains("leaves") or material_name.contains("blossom"):
		material.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
		material.roughness = 0.85
	return material
