extends Node3D
## Owns the single player and HUD while worlds come and go.
signal world_changed(world: Node3D)

@onready var world_container: Node3D = $World
@onready var player: CharacterBody3D = $StudentCharacter
@onready var minimap: Control = $HUD/Minimap
var _return_transforms: Dictionary = {}

func _ready() -> void:
	minimap.set_target(player, player.get_node("CameraPivot"))

## Switch to a packed world. A named Marker3D in its tree can supply an entry point.
## Without a marker, a previously visited world's saved position is restored.
func change_world(scene: PackedScene, spawn_name: StringName = &"") -> bool:
	if scene == null:
		return false
	var instance := scene.instantiate()
	if not instance is Node3D:
		instance.free()
		push_error("World root must be a Node3D")
		return false
	var next := instance as Node3D
	var current := world_container.get_child(0) if world_container.get_child_count() else null
	if current != null:
		_return_transforms[current.scene_file_path] = player.global_transform
		world_container.remove_child(current)
		current.queue_free()
	world_container.add_child(next)
	var marker := next.find_child(String(spawn_name), true, false) as Node3D if not spawn_name.is_empty() else null
	if marker != null:
		player.global_transform = marker.global_transform
	elif _return_transforms.has(scene.resource_path):
		player.global_transform = _return_transforms[scene.resource_path]
	player.velocity = Vector3.ZERO
	world_changed.emit(next)
	return true
