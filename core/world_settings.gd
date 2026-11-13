extends Node3D
## Player proportions are expressed in each world's model units.
@export_range(0.1, 4.0, 0.05, "or_greater") var character_scale := 1.0
@export_range(0.1, 20.0, 0.1, "or_greater") var movement_speed := 4.0
