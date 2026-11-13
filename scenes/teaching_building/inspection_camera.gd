extends "res://scenes/templates/student_camera.gd"
## The F6 inspection scene uses the same limits as the live teaching world.

func _ready() -> void:
	super._ready()
	configure_world(get_parent().get_parent())
