extends SceneTree
var errors := 0
func _initialize(): run.call_deferred()
func run():
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 var player = game.get_node("StudentCharacter")
 var world = game.get_node("World").get_child(0)
 player.get_node("CameraPivot").set_physics_process(false)
 player.get_node("CameraPivot").rotation = Vector3.ZERO
 # Test a small ledge and a tall wall on open ground using the real controller.
 var body = StaticBody3D.new()
 world.add_child(body)
 var collider = CollisionShape3D.new()
 var box = BoxShape3D.new()
 box.size = Vector3(2, 0.15, 1)
 collider.shape = box
 collider.position = Vector3(-5, 0.075, 31)
 body.add_child(collider)
 player.global_position = Vector3(-5, 0.1, 33)
 for i in range(30): await physics_frame
 Input.action_press("character_forward")
 for i in range(80): await physics_frame
 Input.action_release("character_forward")
 if player.global_position.z > 30.8:
  print("FAIL ledge ", player.global_position); errors += 1
 collider.position = Vector3(-5, 0.5, 31)
 box.size.y = 1.0
 player.global_position = Vector3(-5, 0.1, 33)
 player.velocity = Vector3.ZERO
 for i in range(30): await physics_frame
 Input.action_press("character_forward")
 for i in range(80): await physics_frame
 Input.action_release("character_forward")
 if player.global_position.z < 31.5:
  print("FAIL tall wall ", player.global_position); errors += 1
 for n in ["ChunhuiEntrance", "GymEntrance", "AuditoriumEntrance"]:
  var area = world.get_node(n)
  player.global_position = area.global_position - Vector3(0, 0.4, 0)
  player.velocity = Vector3.ZERO
  for i in range(10): await physics_frame
  if not area.is_available(player) or player.global_position.distance_to(area.global_position) > 0.8:
   print("FAIL entrance ", n, " ", player.global_position); errors += 1
 print("CAMPUS_MOVEMENT_CHECK failures=", errors)
 game.queue_free()
 await process_frame
 quit(errors)
