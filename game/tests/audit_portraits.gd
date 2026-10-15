extends SceneTree
var game
var output:String

func _initialize():call_deferred("run")

func shot(name:String,position:Vector3,target:Vector3,fov:float=45):
 game.camera.fov=fov
 game.player.position=position-Vector3(0,1.62,0)
 game.camera.look_at(target,Vector3.UP)
 await process_frame
 await RenderingServer.frame_post_draw
 if root.get_texture().get_image().save_png(output.path_join(name+".png"))!=OK:
  push_error("Could not save audit frame "+name)
  game.clean_quit(1)

func run():
 seed(20261015)
 output=OS.get_environment("SHASHLIK_CAPTURE_DIR")
 if output.is_empty():quit(1);return
 DirAccess.make_dir_recursive_absolute(output)
 game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.initialized=false
 game.set_physics_process(false)
 game.ui.visible=false
 var original=[]
 for actor in game.actors:
  original.append(actor.transform)
  actor.set_physics_process(false)
  actor.visible=false
 for idx in range(3):
  var actor=game.actors[idx]
  var skin=actor.model.skin
  actor.visible=true
  actor.rotation=Vector3.ZERO
  actor.position=Vector3(0,0,-3.2) if idx==0 else Vector3(0,0,-1)
  var pose="guitar" if idx==0 else "idle"
  for frame in range(120):skin.tick(1.0/60,false,0,pose,actor.guitar,Vector3.ZERO)
  if actor.guitar:actor.guitar.visible=true
  var head=skin.to_global(skin.global_pose("Head").origin+Vector3(0,.055,.065))
  await shot(str(idx)+"-face-front",head+Vector3(0,.015,.65),head)
  await shot(str(idx)+"-face-profile",head+Vector3(.63,.015,.04),head)
  await shot(str(idx)+"-face-three-quarter",head+Vector3(.43,.025,.50),head)
  await shot(str(idx)+"-full",actor.position+Vector3(.8,1.40,2.6),actor.position+Vector3(0,.95,0),50)
  var poses=["eat","happy","gag","cough","spit","dislike"]
  if idx>0:poses.append("wave");poses.append("kick")
  if actor.guitar:actor.guitar.visible=false
  for action in poses:
   for frame in range(60):skin.tick(1.0/60,false,0,"idle",null,Vector3.ZERO)
   for frame in range(36):
    skin.tick(1.0/60,false,0,action,actor.guitar,Vector3.ZERO)
    if frame in [11,35]:
     await shot(str(idx)+"-"+action+"-"+str(frame),actor.position+Vector3(.65,1.35,2.25),actor.position+Vector3(0,1.02,0),50)
  actor.visible=false
 for idx in range(4):
  game.actors[idx].transform=original[idx]
  game.actors[idx].visible=true
 await shot("location-overview",Vector3(-4.1,1.9,4.8),Vector3(1,.5,-1.5),70)
 await shot("location-water",Vector3(3.1,1.65,-2.2),Vector3(7,.3,-6),65)
 await shot("location-grill",Vector3(-1.3,1.2,1.25),game.grill_pos+Vector3(0,.77,0),65)
 await shot("location-table",Vector3(-3.0,1.4,3.9),Vector3(-3.2,.88,2.9),65)
 print("PORTRAIT_AUDIT_COMPLETE")
 game.clean_quit()
