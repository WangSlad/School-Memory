extends Node3D

# Shared soft bounce for all five floors, matching the approved spring sample.
# Ambient light supplies covered areas; a second shadowless sun provides bounce.
func _ready() -> void:
	var bounce := DirectionalLight3D.new()
	bounce.name = "SkyBounce"
	bounce.rotation_degrees = Vector3(48, 145, 0)
	bounce.light_color = Color(1, 0.93, 0.83)
	bounce.light_energy = 0.4
	bounce.shadow_enabled = false
	add_child(bounce)
	get_viewport().use_taa = true
	RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)
	RenderingServer.directional_shadow_atlas_set_size(4096, false)
