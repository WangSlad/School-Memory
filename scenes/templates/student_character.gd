@tool
extends CharacterBody3D

const FRAME_TIME := 0.14
const PIXEL_SIZE := 0.01
const COLLIDER_RADIUS := 0.28
const COLLIDER_HEIGHT := 1.55
const FRAME_BOTTOMS := [250.0, 244.0, 239.0]
const FRAME_HEIGHT := 333.0

@export_range(0.1, 20.0, 0.1, "or_greater") var movement_speed := 4.0
## 按住 Shift 时的速度倍率。
@export_range(1.0, 4.0, 0.1, "or_greater") var sprint_multiplier := 1.8

## 缩放以脚底中心为基准，同时调整人物画面和碰撞体。
@export_range(0.1, 4.0, 0.01, "or_greater") var character_scale := 1.0:
	set(value):
		character_scale = maxf(value, 0.1)
		if is_node_ready():
			_update_dimensions()

@export_group("Rendering")
## Treat the animated sprite like an upright image plate.
@export var soften_materials := false:
	set(value):
		soften_materials = value
		if is_node_ready():
			_update_rendering()
@export var plate_tint := Color.WHITE:
	set(value):
		plate_tint = value
		if is_node_ready():
			_update_rendering()

var _original_shaded := false
var _original_modulate := Color.WHITE

var _direction_row := 0
var _walk_frame := 0
var _animation_time := 0.0
var _capsule: CapsuleShape3D

@onready var _sprite: Sprite3D = $Sprite3D
@onready var _collision: CollisionShape3D = $CollisionShape3D
@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _footsteps: AudioStreamPlayer = $Footsteps


func _ready() -> void:
	_original_shaded = _sprite.get_draw_flag(SpriteBase3D.FLAG_SHADED)
	_original_modulate = _sprite.modulate
	_update_rendering()
	_capsule = CapsuleShape3D.new()
	_collision.shape = _capsule
	_update_dimensions()
	_update_sprite()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	var input := Input.get_vector("character_left", "character_right", "character_forward", "character_back")
	var camera_right := _camera_pivot.global_basis.x
	var camera_back := _camera_pivot.global_basis.z
	camera_right.y = 0.0
	camera_back.y = 0.0
	camera_right = camera_right.normalized()
	camera_back = camera_back.normalized()
	var direction := camera_right * input.x + camera_back * input.y

	var speed := movement_speed
	if Input.is_action_pressed("character_sprint"):
		speed *= sprint_multiplier
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)) * delta
	else:
		velocity.y = -0.1
	var previous_position := global_position
	move_and_slide()
	var displacement := global_position - previous_position
	displacement.y = 0.0
	var movement_ratio := displacement.length() / (delta * movement_speed)

	if is_on_floor() and movement_ratio > 0.01:
		if absf(input.x) > absf(input.y):
			_direction_row = 1
			_sprite.flip_h = input.x > 0.0
		else:
			_direction_row = 2 if input.y < 0.0 else 0
			_sprite.flip_h = false
		_animation_time += delta * movement_ratio
		while _animation_time >= FRAME_TIME:
			_animation_time -= FRAME_TIME
			_walk_frame = _walk_frame % 4 + 1
			if _walk_frame == 1 or _walk_frame == 3:
				_footsteps.play()
	else:
		_animation_time = 0.0
		_walk_frame = 0
	_update_sprite()


func _update_dimensions() -> void:
	_capsule.radius = COLLIDER_RADIUS * character_scale
	_capsule.height = COLLIDER_HEIGHT * character_scale
	_collision.position.y = _capsule.height * 0.5
	_camera_pivot.position.y = 1.0 * character_scale
	_sprite.pixel_size = PIXEL_SIZE * character_scale
	_update_sprite()


func _update_sprite() -> void:
	_sprite.frame = _direction_row * 5 + _walk_frame
	# The supplied frames have transparent space under the character's feet.
	_sprite.position.y = ((FRAME_BOTTOMS[_direction_row] - FRAME_HEIGHT * 0.5) * PIXEL_SIZE + 0.02) * character_scale


func _update_rendering() -> void:
	_sprite.set_draw_flag(SpriteBase3D.FLAG_SHADED, false if soften_materials else _original_shaded)
	_sprite.modulate = _original_modulate * plate_tint
	_sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
