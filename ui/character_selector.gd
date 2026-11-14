extends Control
## Hold Tab, move the mouse left/right or use the wheel, then release to choose.

const GIRL := preload("res://assets/characters/student_spritesheet.png")
const BOY := preload("res://assets/characters/student_boy_spritesheet.png")
const RADIUS := 155.0
var player: CharacterBody3D
var selected := 0
var active := false
var pointer := Vector2.ZERO
var previous_mouse_mode: Input.MouseMode

func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 hide()

func _input(event: InputEvent) -> void:
 if event.is_action_pressed("character_select") and not event.is_echo():
  if get_parent().get_parent().get("_transitioning"):
   return
  active = true
  selected = 1 if player.get_node("Sprite3D").texture == BOY else 0
  pointer = Vector2.ZERO
  previous_mouse_mode = Input.mouse_mode
  Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
  show()
  queue_redraw()
  get_viewport().set_input_as_handled()
 elif active and event.is_action_released("character_select"):
  player.get_node("Sprite3D").texture = GIRL if selected == 0 else BOY
  active = false
  hide()
  Input.mouse_mode = previous_mouse_mode
  get_viewport().set_input_as_handled()
 elif active and event is InputEventMouseMotion:
  pointer += event.relative
  pointer = pointer.limit_length(RADIUS)
  if absf(pointer.x) > 12.0:
   selected = 0 if pointer.x < 0.0 else 1
  queue_redraw()
  get_viewport().set_input_as_handled()
 elif active and event is InputEventMouseButton:
  if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
   selected = 1 - selected
   queue_redraw()
  get_viewport().set_input_as_handled()

func _draw() -> void:
 var center := size * 0.5
 draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.09, 0.48))
 draw_circle(center, RADIUS + 8.0, Color(0.06, 0.09, 0.12, 0.85))
 for i in range(2):
  var start := PI * 0.5 if i == 0 else -PI * 0.5
  var points := PackedVector2Array([center])
  for j in range(33):
   var angle := start + PI * float(j) / 32.0
   points.append(center + Vector2(cos(angle), sin(angle)) * RADIUS)
  draw_colored_polygon(points, Color("668f89") if selected == i else Color("344b50"))
  var item_center := center + Vector2(-78 if i == 0 else 78, -12)
  var texture: Texture2D = GIRL if i == 0 else BOY
  var cell := Vector2(texture.get_width() / 5.0, texture.get_height() / 3.0)
  draw_texture_rect_region(texture, Rect2(item_center - Vector2(76, 76), Vector2(152, 152)), Rect2(Vector2.ZERO, cell))
  var font := ThemeDB.fallback_font
  var label := "女生" if i == 0 else "男生"
  var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
  draw_string(font, item_center + Vector2(-width / 2, 86), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
 var title := "移动鼠标或滚轮选择 · 松开 Tab 切换"
 var font := ThemeDB.fallback_font
 var width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
 draw_string(font, center + Vector2(-width / 2, RADIUS + 48), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
