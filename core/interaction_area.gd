extends Area3D
## A reusable interaction target. Leave target_world empty for custom interactions.
signal interacted(actor: Node3D)
@export var prompt := "交互"
@export_file("*.tscn") var target_world_path := ""
@export var spawn_name: StringName = &""
@export_range(0.2, 10.0, 0.1) var interaction_range := 1.5
@export var show_book_marker := false
@export var show_exit_marker := false

func _ready() -> void:
 collision_layer = 0
 collision_mask = 2
 monitoring = true
 add_to_group("interactions")
 var shape := SphereShape3D.new()
 shape.radius = interaction_range
 var collision := CollisionShape3D.new()
 collision.shape = shape
 add_child(collision)
 if show_book_marker or show_exit_marker:
  var marker := Node3D.new()
  marker.set_script(preload("res://core/book_interaction_marker.gd"))
  marker.name = "ExitInteractionMarker" if show_exit_marker else "BookInteractionMarker"
  if show_exit_marker:
   marker.icon_texture = preload("res://assets/ui/teaching_exit.svg")
   marker.badge_name = "ExitBadge"
  add_child(marker)

func is_available(actor: Node3D) -> bool:
 return overlaps_body(actor) and (not target_world_path.is_empty() or interacted.has_connections())

func interact(actor: Node3D) -> void:
 interacted.emit(actor)
