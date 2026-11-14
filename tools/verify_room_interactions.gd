extends SceneTree
var failures := 0
func _initialize(): run.call_deferred()
func check(ok: bool, message: String):
 if not ok:
  failures += 1
  push_error(message)
func settle():
 for i in range(5): await physics_frame
func run():
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 var actor = game.get_node("StudentCharacter")
 var event = InputEventAction.new()
 event.action = "interact"
 event.pressed = true
 for building in range(1, 4):
  check(game.change_world(load("res://world/teaching_building%d.tscn" % building)), "world loads")
  var world = game.get_node("World").get_child(0)
  var interactions = world.get_node("Building/RoomInteractions")
  for floor_index in range(1, 6):
   var floor_node = interactions.get_node("Floor_%02d" % floor_index)
   for area in floor_node.get_children():
    if not area is Area3D: continue
    check(area.get_child_count() == 1 and area.get_child(0) is CollisionShape3D, "area must be invisible: " + area.name)
    actor.set_physics_process(false)
    actor.global_position = area.global_position - Vector3(0, 0.7, 0)
    actor.velocity = Vector3.ZERO
    await settle()
    game._physics_process(0)
    check(game._selected == area, "area selection: %d %d %s got %s" % [building, floor_index, area.name, game._selected.name if is_instance_valid(game._selected) else "none"])
    if game._selected != area: continue
    if area.unavailable:
     game._notice.hide()
     game._unhandled_input(event)
     check(game._notice.visible and game._notice.get_child(0).text == "暂未开放，敬请期待~", "notice: " + area.name)
    else:
     var target = area.get_node(area.local_teleport_target)
     game._unhandled_input(event)
     await settle()
     actor.set_physics_process(false)
     check(actor.global_position.distance_to(target.global_position) < 0.3, "landing: " + area.name)
     check(game.get_node("World").get_child(0) == world, "same world")
     var query = PhysicsShapeQueryParameters3D.new()
     query.shape = actor.get_node("CollisionShape3D").shape
     query.transform = Transform3D(Basis.IDENTITY, target.global_position + actor.get_node("CollisionShape3D").position)
     query.collision_mask = 1
     check(world.get_world_3d().direct_space_state.intersect_shape(query).is_empty(), "clear landing: " + area.name)
     var probe = PhysicsRayQueryParameters3D.create(target.global_position + Vector3.UP * 1.0, target.global_position - Vector3.UP * 0.3, 1)
     check(not world.get_world_3d().direct_space_state.intersect_ray(probe).is_empty(), "grounded: " + area.name)
 print("ROOM_INTERACTIONS_CHECK buildings=3 floors=15 failures=", failures)
 game.queue_free()
 await process_frame
 quit(1 if failures else 0)
