extends SceneTree
var failures=0
const Terrain=preload("res://scripts/lakeside_terrain.gd")

func check(ok:bool,label:String):
 if not ok:
  failures+=1
  push_error(label)

func _initialize():call_deferred("run")

func run():
 if RenderingServer.get_current_rendering_method()!="forward_plus":
  push_error("Run this profile check with the Vulkan Forward+ wrapper")
  quit(1)
  return
 seed(20261016)
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.initialized=false
 game.set_physics_process(false)
 for actor in game.actors:actor.set_physics_process(false)
 var station_transforms={}
 for key in game.stations:station_transforms[key]=game.stations[key].global_transform
 var actor_positions=[]
 for actor in game.actors:actor_positions.append(actor.global_transform)
 load("res://scripts/lakeside_quality.gd").apply(game)
 await physics_frame
 await physics_frame
 for key in station_transforms:
  check(game.stations[key].global_transform.is_equal_approx(station_transforms[key]),"Cooking station moved: "+key)
 for index in range(actor_positions.size()):
  check(game.actors[index].global_transform.is_equal_approx(actor_positions[index]),"Actor moved during visual profile installation")
 check(game.actors.size()==4,"Existing cast is preserved")
 var space=game.get_world_3d().direct_space_state
 for point in [Vector2(-5.2,5.7),Vector2(-1.1,-1.2),Vector2(7,-6),Vector2(10.7,-6),Vector2(16.2,13.1)]:
  var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(point.x,5.0,point.y),Vector3(point.x,-2.0,point.y)))
  check(not hit.is_empty(),"Ground collider missing at "+str(point))
  if not hit.is_empty():
   # Mesh triangles interpolate the common height function at a 0.5m grid.
   check(absf(hit.position.y-Terrain.height_at(point.x,point.y))<0.012,"Visible terrain and collider differ at "+str(point))
   check(hit.normal.y>0.75,"Unexpected terrain slope at "+str(point))
 var outside=space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(19.5,5.0,0),Vector3(19.5,-2.0,0)))
 check(outside.is_empty(),"Visual backdrop expanded the playable ground collider")
 print("LAKESIDE_VALIDATION_", "PASS" if failures==0 else "FAIL"," failures=",failures)
 game.clean_quit(0 if failures==0 else 1)
