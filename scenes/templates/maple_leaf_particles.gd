@tool
extends GPUParticles3D

const MOTION_SHADER = preload("res://scenes/templates/maple_leaf_motion.gdshader")
const DRAW_SHADER = preload("res://scenes/templates/maple_leaf_draw.gdshader")
const LEAF_SHEET = preload("res://assets/effects/maple_leaf_spritesheet.png")

## 发射区域在本地 XZ 平面上的宽度和深度，单位为米。
@export var emission_area := Vector2(20.0, 20.0):
	set(value):
		emission_area = Vector2(maxf(value.x, 0.01), maxf(value.y, 0.01))
		_queue_update()
## 平均下落速度，单位为米/秒。
@export_range(0.05, 10.0, 0.05, "or_greater") var fall_speed := 1.5:
	set(value):
		fall_speed = maxf(value, 0.05)
		_queue_update()
## X 和 Y 分别控制水平 X 和 Z 方向的风速，单位为米/秒。
@export var wind := Vector2(0.6, 0.15):
	set(value):
		wind = value
		_queue_update()
## 水平方向的周期性扰动，单位为米/秒。
@export_range(0.0, 5.0, 0.05, "or_greater") var turbulence := 0.4:
	set(value):
		turbulence = maxf(value, 0.0)
		_queue_update()
@export_range(1, 2000, 1, "or_greater") var particle_count := 120:
	set(value):
		particle_count = maxi(value, 1)
		_queue_update()
## 0 为均匀排列，1 为完全随机发射。
@export_range(0.0, 1.0, 0.01) var position_randomness := 1.0:
	set(value):
		position_randomness = clampf(value, 0.0, 1.0)
		_queue_update()
## 序列动画的每秒循环次数。
@export_range(0.0, 5.0, 0.05, "or_greater") var rotation_speed := 1.0:
	set(value):
		rotation_speed = maxf(value, 0.0)
		_queue_update()
## 枫叶的显示宽度，单位为米。
@export_range(0.01, 2.0, 0.01, "or_greater") var leaf_size := 0.35:
	set(value):
		leaf_size = maxf(value, 0.01)
		_queue_update()
## 0 为统一大小，1 为基础大小的 50%–150%。
@export_range(0.0, 1.0, 0.01) var size_randomness := 0.35:
	set(value):
		size_randomness = clampf(value, 0.0, 1.0)
		_queue_update()
## 每片枫叶从生成到消失的时间，单位为秒。
@export_range(0.5, 30.0, 0.5, "or_greater") var particle_lifetime := 12.0:
	set(value):
		particle_lifetime = maxf(value, 0.5)
		_queue_update()
## 0 为统一速度，1 为基础速度的 50%–150%。
@export_range(0.0, 1.0, 0.01) var speed_randomness := 0.3:
	set(value):
		speed_randomness = clampf(value, 0.0, 1.0)
		_queue_update()

var _update_queued := false
var _motion_material: ShaderMaterial


func _ready() -> void:
	_motion_material = ShaderMaterial.new()
	_motion_material.shader = MOTION_SHADER
	process_material = _motion_material

	var draw_material := ShaderMaterial.new()
	draw_material.shader = DRAW_SHADER
	draw_material.set_shader_parameter("leaf_sheet", LEAF_SHEET)
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 0.935)
	quad.material = draw_material
	draw_pass_1 = quad

	local_coords = true
	fixed_fps = 30
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_apply_settings()
	emitting = true


func _queue_update() -> void:
	if is_node_ready() and not _update_queued:
		_update_queued = true
		_apply_settings.call_deferred()


func _apply_settings() -> void:
	_update_queued = false
	if _motion_material == null:
		return
	_motion_material.set_shader_parameter("emission_area", emission_area)
	_motion_material.set_shader_parameter("position_randomness", position_randomness)
	_motion_material.set_shader_parameter("fall_speed", fall_speed)
	_motion_material.set_shader_parameter("wind", wind)
	_motion_material.set_shader_parameter("turbulence", turbulence)
	_motion_material.set_shader_parameter("rotation_speed", rotation_speed)
	_motion_material.set_shader_parameter("leaf_size", leaf_size)
	_motion_material.set_shader_parameter("size_randomness", size_randomness)
	_motion_material.set_shader_parameter("speed_randomness", speed_randomness)
	_motion_material.set_shader_parameter("particle_count", float(particle_count))
	if amount != particle_count:
		amount = particle_count
	if not is_equal_approx(lifetime, particle_lifetime):
		lifetime = particle_lifetime
	preprocess = particle_lifetime

	var max_fall := fall_speed * (1.0 + speed_randomness * 0.5) * particle_lifetime
	var max_drift := (wind.abs() + Vector2.ONE * turbulence) * particle_lifetime
	var margin := leaf_size * (1.0 + size_randomness * 0.5)
	visibility_aabb = AABB(
		Vector3(-emission_area.x * 0.5 - max_drift.x - margin, -max_fall - margin, -emission_area.y * 0.5 - max_drift.y - margin),
		Vector3(emission_area.x + 2.0 * (max_drift.x + margin), max_fall + 2.0 * margin, emission_area.y + 2.0 * (max_drift.y + margin)))
