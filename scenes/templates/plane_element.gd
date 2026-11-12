@tool
extends Node3D

enum Pivot {
	BOTTOM_CENTER, BOTTOM_LEFT, BOTTOM_RIGHT, CENTER_LEFT, CENTER, CENTER_RIGHT,
	TOP_LEFT, TOP_CENTER, TOP_RIGHT,
}

const ANCHORS := [
	Vector2(0.5, 1.0), Vector2(0.0, 1.0), Vector2(1.0, 1.0),
	Vector2(0.0, 0.5), Vector2(0.5, 0.5), Vector2(1.0, 0.5),
	Vector2(0.0, 0.0), Vector2(0.5, 0.0), Vector2(1.0, 0.0),
]
const PIXELS_PER_METER := 100.0
const COLLISION_THICKNESS := 0.04

@export var texture: Texture2D:
	set(value):
		if texture != null and texture.changed.is_connected(_texture_changed):
			texture.changed.disconnect(_texture_changed)
		texture = value
		if texture != null:
			texture.changed.connect(_texture_changed)
		_texture_changed()
## Every +1 doubles the size. Every -1 halves it. 0 uses 100 pixels per meter.
@export_range(-6.0, 6.0, 0.01) var scale_steps := 0.0:
	set(value):
		scale_steps = value
		_queue_update()
## In ground mode the image bottom edge is the +Z edge.
@export var pivot := Pivot.BOTTOM_CENTER:
	set(value):
		pivot = value
		_queue_update()
@export var mirror_horizontal := false:
	set(value):
		mirror_horizontal = value
		_queue_update()
@export var mirror_vertical := false:
	set(value):
		mirror_vertical = value
		_queue_update()
@export var ground_mode := false:
	set(value):
		ground_mode = value
		_texture_dirty = true
		_queue_update()
## Disable for decorative ground overlays resting on another walkable surface.
@export var collision_enabled := true:
	set(value):
		collision_enabled = value
		_queue_update()

@export_group("Rendering")
@export var soften_materials := false:
	set(value):
		soften_materials = value
		_queue_update()
@export var plate_tint := Color.WHITE:
	set(value):
		plate_tint = value
		_queue_update()

var _update_queued := false
var _texture_dirty := true
var _opaque_rect := Rect2()
var _quad := QuadMesh.new()
var _material := StandardMaterial3D.new()
var _box := BoxShape3D.new()

@onready var _visual: MeshInstance3D = $Visual
@onready var _collision: CollisionShape3D = $StaticBody3D/CollisionShape3D


func _ready() -> void:
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_quad.material = _material
	_update()


func _texture_changed() -> void:
	_texture_dirty = true
	_queue_update()


func _queue_update() -> void:
	if is_node_ready() and not _update_queued:
		_update_queued = true
		_update.call_deferred()


func _update() -> void:
	_update_queued = false
	if texture == null or texture.get_size() == Vector2.ZERO:
		_visual.mesh = null
		_material.albedo_texture = null
		_collision.shape = null
		return

	_material.roughness = 0.9
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if soften_materials and not ground_mode else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	_material.albedo_color = (Color(0.88, 0.84, 0.79) * plate_tint if soften_materials else Color.WHITE) if ground_mode else plate_tint
	_material.metallic_specular = 0.25 if ground_mode and soften_materials else 0.5
	_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if ground_mode and collision_enabled else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var pixels := texture.get_size()
	if _texture_dirty:
		_update_texture()

	var factor := pow(2.0, scale_steps)
	var size := pixels * (factor / PIXELS_PER_METER)
	var anchor: Vector2 = ANCHORS[pivot]
	var visual_offset := (Vector2(0.5, 0.5) - anchor) * size
	var thickness := COLLISION_THICKNESS * factor

	_quad.size = size
	_visual.mesh = _quad
	_visual.position = _image_offset(visual_offset)
	_visual.rotation_degrees.x = -90.0 if ground_mode else 0.0
	_material.uv1_scale = Vector3(-1.0 if mirror_horizontal else 1.0,
		-1.0 if mirror_vertical else 1.0, 1.0)
	_material.uv1_offset = Vector3(float(mirror_horizontal), float(mirror_vertical), 0.0)

	if not collision_enabled or not _opaque_rect.has_area():
		_collision.shape = null
		return
	var collision_center := _opaque_rect.get_center()
	if mirror_horizontal:
		collision_center.x = 1.0 - collision_center.x
	if mirror_vertical:
		collision_center.y = 1.0 - collision_center.y
	var collision_size := _opaque_rect.size * size
	_collision.position = _image_offset((collision_center - anchor) * size)
	if ground_mode:
		_box.size = Vector3(collision_size.x, thickness, collision_size.y)
		_collision.position.y = -thickness * 0.5
	else:
		_box.size = Vector3(collision_size.x, collision_size.y, thickness)
	_collision.shape = _box


func _update_texture() -> void:
	_texture_dirty = false
	_material.albedo_texture = texture
	_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	_opaque_rect = Rect2(Vector2.ZERO, Vector2.ONE)
	var image := texture.get_image()
	if image == null or image.is_empty():
		return
	if image.is_compressed() and image.decompress() != OK:
		return
	if image.detect_alpha() != Image.ALPHA_NONE:
		# Ground overlays must write depth as opaque surfaces. Alpha blending can
		# otherwise sort the large ground quad in front of a transparent Sprite3D.
		_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR if ground_mode else BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
		var used := image.get_used_rect()
		var image_size := Vector2(image.get_size())
		_opaque_rect = Rect2(Vector2(used.position) / image_size, Vector2(used.size) / image_size)


func _image_offset(offset: Vector2) -> Vector3:
	if ground_mode:
		return Vector3(offset.x, 0.0, offset.y)
	return Vector3(offset.x, -offset.y, 0.0)

