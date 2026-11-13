extends Node3D
## A world-space interaction badge and ground ring.
const BOOK := preload("res://assets/ui/teaching_book.svg")
const BADGE_HEIGHT := 0.65
var icon_texture: Texture2D = BOOK
var badge_name := "BookBadge"
var _badge := Sprite3D.new()
var _ring := StandardMaterial3D.new()
var _time := 0.0

func _ready() -> void:
	var area := get_parent() as Area3D
	_badge.name = badge_name
	_badge.texture = icon_texture
	_badge.pixel_size = 0.00225
	_badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_badge.shaded = false
	_badge.double_sided = true
	_badge.position.y = BADGE_HEIGHT
	_badge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_badge.visibility_range_end = 35.0
	add_child(_badge)
	_ring.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring.albedo_color = Color("8bdec1")
	_ring.emission_enabled = true
	_ring.emission = Color("8bdec1")
	var torus := TorusMesh.new()
	torus.inner_radius = area.interaction_range - 0.025
	torus.outer_radius = area.interaction_range + 0.025
	torus.rings = 64
	torus.ring_segments = 8
	torus.material = _ring
	var ring := MeshInstance3D.new()
	ring.name = "InteractionRing"
	ring.mesh = torus
	# Campus ground is y=0; Area3D centers are raised to detect the player capsule.
	ring.position.y = 0.035 - area.position.y
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.visibility_range_end = 35.0
	add_child(ring)
	_snap_ring_to_ground.call_deferred()

func _snap_ring_to_ground() -> void:
	# Entrances can be on raised steps; wait for campus collision to sync.
	if not is_inside_tree():
		return
	await get_tree().physics_frame
	if not is_inside_tree():
		return
	await get_tree().physics_frame
	if not is_inside_tree():
		return
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.5, global_position - Vector3.UP * 2.0, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		$InteractionRing.global_position.y = hit.position.y + 0.035

func _process(delta: float) -> void:
	_time += delta
	var active := not (get_parent() as Area3D).get_overlapping_bodies().is_empty()
	_badge.position.y = BADGE_HEIGHT + sin(_time * 2.0) * 0.07
	_badge.modulate = Color.WHITE if active else Color(0.82, 0.91, 0.86, 0.9)
	_ring.emission_energy_multiplier = 1.2 if active else 0.35
