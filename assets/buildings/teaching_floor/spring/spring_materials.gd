@tool
extends Node
## Visual surface overrides only. The imported mesh and collision are untouched.
## Attach below the imported building root. Disable to restore its original slots.

const BASE := "res://assets/buildings/teaching_floor/spring/materials/"
const MATERIALS := {
	"Soft ivory wall": preload(BASE + "wall.tres"),
	"Warm white concrete": preload(BASE + "concrete.tres"),
	"Stair concrete": preload(BASE + "concrete.tres"),
	"Blue grey floor slab": preload(BASE + "concrete.tres"),
	"Pale ceramic tile": preload(BASE + "floor.tres"),
	"Tile joints": preload(BASE + "grout.tres"),
	"Painted green door": preload(BASE + "door.tres"),
	"Deep green frames": preload(BASE + "frame_wood.tres"),
	"Railing metal": preload(BASE + "frame.tres"),
	"Transparent blue green glass": preload(BASE + "glass.tres"),
	"Window glazing": preload(BASE + "window_glass.tres"),
}

@export var enabled := true:
	set(value):
		enabled = value
		if is_node_ready():
			_rebuild.call_deferred()
@export var floor_height := 3.6
@export var bay_width := 8.0
@export var first_classroom_bay := 2
@export var atlas_floor_count := 1
@export var sign_texture: Texture2D
## Match the source floor's rectangular grout geometry, stretched 1.3x / 2x.
@export var floor_texture_scale := Vector3.ONE
## In the five-storey building the dado has actual depth, so do not also paint
## pink bands onto unrelated rear walls or sides of recessed wall fragments.
@export var solid_dado := false

var _original_slots: Array[Dictionary] = []
var _palette: Dictionary = {}

func _ready() -> void:
	_collect(get_parent())
	_rebuild()

func _collect(node: Node) -> void:
	if node is MeshInstance3D and node.mesh != null:
		for surface in range(node.mesh.get_surface_count()):
			var original: Material = node.get_active_material(surface)
			if original != null:
				_original_slots.append({"node": node, "surface": surface,
					"override": node.get_surface_override_material(surface),
					"material": original, "whole": node.material_override})
	for child in node.get_children():
		if child != self:
			_collect(child)

func _rebuild() -> void:
	_palette = MATERIALS.duplicate()
	# Only these two materials need per-building parameters. All repeated surfaces
	# share one resource per role. No repeated tinting of an already modified slot.
	var origin: Vector3 = get_parent().global_position
	var wall: ShaderMaterial = MATERIALS["Soft ivory wall"].duplicate()
	wall.set_shader_parameter("floor_height", floor_height)
	wall.set_shader_parameter("origin_y", origin.y)
	wall.set_shader_parameter("paint_dado", not solid_dado)
	_palette["Soft ivory wall"] = wall
	var door: ShaderMaterial = MATERIALS["Painted green door"].duplicate()
	door.set_shader_parameter("floor_height", floor_height)
	door.set_shader_parameter("bay_width", bay_width)
	door.set_shader_parameter("building_origin", origin)
	door.set_shader_parameter("first_classroom_bay", float(first_classroom_bay))
	door.set_shader_parameter("atlas_floor_count", float(atlas_floor_count))
	# The source doors remain 2.35m tall even when the floor height is 4.32m.
	door.set_shader_parameter("sign_center_height", 2.052)
	door.set_shader_parameter("sign_height", 0.18)
	if sign_texture != null:
		door.set_shader_parameter("sign_texture", sign_texture)
	_palette["Painted green door"] = door
	if floor_texture_scale != Vector3.ONE:
		var floor_material: StandardMaterial3D = MATERIALS["Pale ceramic tile"].duplicate()
		floor_material.uv1_scale *= floor_texture_scale
		_palette["Pale ceramic tile"] = floor_material
	for slot in _original_slots:
		var mesh_instance: MeshInstance3D = slot.node
		if not is_instance_valid(mesh_instance):
			continue
		var role: String = slot.material.resource_name
		# The one-storey export has Blender's .001 material suffix.
		role = role.split(".")[0]
		if enabled and _palette.has(role) and not slot.material is ShaderMaterial:
			mesh_instance.material_override = null
			mesh_instance.set_surface_override_material(slot.surface, _palette[role])
		else:
			mesh_instance.material_override = slot.whole
			mesh_instance.set_surface_override_material(slot.surface, slot.override)
