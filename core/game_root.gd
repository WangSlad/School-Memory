extends Node3D
## Owns the single player and HUD while worlds come and go.
signal world_changed(world: Node3D)

@onready var world_container: Node3D = $World
@onready var player: CharacterBody3D = $StudentCharacter
@onready var minimap: Control = $HUD/Minimap
var _return_transforms: Dictionary = {}

func _ready() -> void:
	minimap.set_target(player, player.get_node("CameraPivot"))

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
	world_changed.emit(next)
	return true
