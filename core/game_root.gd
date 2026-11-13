extends Node3D
## Owns the single player and HUD while worlds come and go.
signal world_changed(world: Node3D)

const WORLD_SETTINGS := preload("res://core/world_settings.gd")

@onready var world_container: Node3D = $World
@onready var player: CharacterBody3D = $StudentCharacter
@onready var minimap: Control = $HUD/Minimap
var _return_transforms: Dictionary = {}
var _transitioning := false
var _selected: Area3D
var _suppressed_areas: Array[Area3D] = []
var _prompt: PanelContainer
var _prompt_label: Label
var _fade: ColorRect
var _default_character_scale := 1.0
var _default_movement_speed := 4.0


func _ready() -> void:
 _default_character_scale = player.character_scale
 _default_movement_speed = player.movement_speed
 if world_container.get_child_count():
  _apply_world_settings(world_container.get_child(0))
 minimap.set_target(player, player.get_node("CameraPivot"))
 _create_interaction_ui()

## Explicit entry wins; otherwise restore a previous position or use DefaultSpawn.
## A missing/invalid entry fails without changing the active world or player.
func change_world(scene: PackedScene, spawn_name: StringName = &"") -> bool:
 if scene == null or not is_inside_tree():
  return false
 var instance := scene.instantiate()
 if not instance is Node3D:
  if instance != null:
   instance.free()
  push_warning("World root must be a Node3D")
  return false
 var next := instance as Node3D
 var current := world_container.get_child(0) if world_container.get_child_count() else null
 var current_path: String = current.scene_file_path if current != null else ""
 var destination_path := scene.resource_path
 var saved: Variant = _return_transforms.get(destination_path)
 # Switching to the same world can also restore the position being left.
 if not destination_path.is_empty() and current_path == destination_path:
  saved = player.global_transform
 var marker: Marker3D = null
 if not spawn_name.is_empty():
  marker = next.find_child(String(spawn_name), true, false) as Marker3D
 elif saved == null:
  marker = next.find_child("DefaultSpawn", true, false) as Marker3D
 if (not spawn_name.is_empty() or saved == null) and marker == null:
  push_warning("World is missing the requested Marker3D spawn: %s" % (spawn_name if not spawn_name.is_empty() else &"DefaultSpawn"))
  next.free()
  return false
 # Resolve the marker while detached; all transforms are relative to the world container.
 var entry := Transform3D.IDENTITY
 if marker != null:
  entry = marker.transform
  var ancestor := marker.get_parent()
  while ancestor != null and ancestor != next:
   if ancestor is Node3D:
    entry = ancestor.transform * entry
   ancestor = ancestor.get_parent()
  entry = world_container.global_transform * next.transform * entry
 else:
  entry = saved
 if current != null:
  if not current_path.is_empty():
   _return_transforms[current_path] = player.global_transform
  world_container.remove_child(current)
  current.queue_free()
 world_container.add_child(next)
 player.get_node("CameraPivot/Camera3D").make_current()
 player.global_transform = entry
 player.velocity = Vector3.ZERO
 _apply_world_settings(next)
 world_changed.emit(next)
 return true

func _apply_world_settings(world: Node) -> void:
 var settings := world as WORLD_SETTINGS
 player.character_scale = settings.character_scale if settings != null else _default_character_scale
 player.movement_speed = settings.movement_speed if settings != null else _default_movement_speed
 player.get_node("CameraPivot").configure_world(world)
 minimap.configure_world(world)

func _physics_process(_delta: float) -> void:
 if _transitioning:
  return
 _selected = null
 for area in _suppressed_areas.duplicate():
  if not is_instance_valid(area) or not area.overlaps_body(player):
   _suppressed_areas.erase(area)
 var nearest := INF
 for candidate in get_tree().get_nodes_in_group("interactions"):
  if candidate not in _suppressed_areas and candidate.is_available(player):
   var distance: float = candidate.global_position.distance_squared_to(player.global_position)
   if distance < nearest:
    nearest = distance
    _selected = candidate
 _prompt.visible = is_instance_valid(_selected)
 if _prompt.visible:
  _prompt_label.text = _selected.prompt + "    [ E ]"

func _unhandled_input(event: InputEvent) -> void:
 if not _transitioning and event.is_action_pressed("interact") and not event.is_echo() and is_instance_valid(_selected) and _selected.is_available(player):
  get_viewport().set_input_as_handled()
  var target_path: String = _selected.target_world_path
  var spawn: StringName = _selected.spawn_name
  if not target_path.is_empty():
   _transition_to(target_path, spawn)
  else:
   _selected.interact(player)

func _transition_to(target_path: String, spawn: StringName) -> void:
 _transitioning = true
 _selected = null
 _prompt.hide()
 player.set_physics_process(false)
 player.velocity = Vector3.ZERO
 var tween := create_tween()
 tween.tween_property(_fade, "color:a", 1.0, 0.4)
 await tween.finished
 var target := load(target_path) as PackedScene
 var succeeded := change_world(target, spawn)
 if succeeded:
  await get_tree().process_frame
  await get_tree().physics_frame
  # Arriving within an entrance requires leaving it before it can be used again.
  _suppressed_areas.clear()
  for area in get_tree().get_nodes_in_group("interactions"):
   if area.overlaps_body(player):
    _suppressed_areas.append(area)
 else:
  push_warning("World transition failed: %s" % target_path)
 tween = create_tween()
 tween.tween_property(_fade, "color:a", 0.0, 0.4)
 await tween.finished
 player.set_physics_process(true)
 _transitioning = false

func _create_interaction_ui() -> void:
 var layer := CanvasLayer.new()
 layer.layer = 20
 add_child(layer)
 _prompt = PanelContainer.new()
 _prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
 _prompt.offset_left = -160
 _prompt.offset_right = 160
 _prompt.offset_top = -160
 _prompt.offset_bottom = -105
 _prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var style := StyleBoxFlat.new()
 style.bg_color = Color("f1ede5")
 style.set_corner_radius_all(12)
 style.shadow_color = Color(0.15, 0.18, 0.16, 0.25)
 style.shadow_size = 8
 style.shadow_offset = Vector2(0, 3)
 style.content_margin_left = 20
 style.content_margin_right = 20
 style.content_margin_top = 10
 style.content_margin_bottom = 10
 _prompt.add_theme_stylebox_override("panel", style)
 layer.add_child(_prompt)
 _prompt_label = Label.new()
 _prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 _prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 _prompt_label.add_theme_color_override("font_color", Color("596d68"))
 _prompt_label.add_theme_font_size_override("font_size", 23)
 _prompt.add_child(_prompt_label)
 _prompt.hide()
 _fade = ColorRect.new()
 _fade.color = Color(0.16, 0.16, 0.15, 0.0)
 _fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 _fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
 layer.add_child(_fade)
