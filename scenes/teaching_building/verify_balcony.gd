extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var world = load("res://scenes/teaching_building/teaching_building_test.tscn").instantiate()
 root.add_child(world)
 await physics_frame
 await physics_frame
 var space = world.get_world_3d().direct_space_state
 for i in range(5):
  var h=i*4.32
  var query=PhysicsRayQueryParameters3D.create(Vector3(.8,h+.6,2.4),Vector3(-.4,h+.6,2.4),1)
  var hit=space.intersect_ray(query)
  if hit.is_empty(): print("BALCONY_RAIL_MISSING ",i+1); quit(1); return
 print("BALCONY_RAIL_OK floors=5")
 print("CAMERA_SCRIPT=",world.get_node("StudentCharacter/CameraPivot").get_script().resource_path)
 quit()
