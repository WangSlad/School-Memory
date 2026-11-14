extends SceneTree
func _initialize():
 run.call_deferred()
func run():
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 var campus = game.get_node("World").get_child(0)
 var actor = game.get_node("StudentCharacter")
 actor.set_physics_process(false)
 var errors = 0
 var event = InputEventAction.new()
 event.action = "interact"
 event.pressed = true
 for n in ["Science1", "Science2", "Chunhui", "Auditorium", "Gym", "Canteen", "GirlsDorm1", "GirlsDorm2", "BoysDorm1", "BoysDorm2", "BoysDorm3", "BoysDorm4", "TrackOutside", "TrackInside"]:
  var area = campus.get_node(n if n.begins_with("Track") else n + "Entrance")
  actor.global_position = area.global_position - Vector3(0, 0.4, 0)
  for i in range(5): await physics_frame
  game._physics_process(0)
  if not area.is_available(actor) or game._selected != area:
   print("FAIL selection ", n); errors += 1
  game._unhandled_input(event)
  if n.begins_with("Track"):
   for i in range(5): await physics_frame
   actor.set_physics_process(false)
   var target = area.get_node(area.local_teleport_target)
   if actor.global_position.distance_to(target.global_position) > 0.3:
    print("FAIL teleport ", n); errors += 1
  elif not game._notice.visible:
   print("FAIL notice ", n); errors += 1
 print("FACILITY_CHECK failures=", errors)
 quit(errors)
