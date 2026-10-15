extends SceneTree
var game
var out:String
func _initialize():call_deferred("run")
func shot(n:String,p:Vector3,t:Vector3):
 game.player.position=p-Vector3(0,1.62,0);game.camera.look_at(t,Vector3.UP)
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out.path_join(n+".png"))
func run():
 out=OS.get_environment("SHASHLIK_CAPTURE_DIR");DirAccess.make_dir_recursive_absolute(out)
 game=load("res://main.tscn").instantiate();root.add_child(game)
 await create_timer(.3).timeout;game.initialized=false;game.set_physics_process(false);game.ui.visible=false
 for a in game.actors:a.set_physics_process(false);a.visible=false
 var a=game.actors[0];a.visible=true
 for i in range(60):a.model.skin.tick(1.0/60,false,0,"guitar",a.guitar,Vector3.ZERO)
 for i in range(30):
  a.model.skin.tick(1.0/24,false,0,"guitar",a.guitar,Vector3.ZERO)
  await shot("guitar-"+str(i).pad_zeros(3),Vector3(.1,1.04,-2.25),Vector3(0,.91,-3.05))
 a.guitar.visible=false
 for i in range(22):
  a.model.skin.tick(1.0/24,false,0,"getup",a.guitar,Vector3.ZERO)
  a.position+=a.global_basis.z*a.model.skin.frame_root_delta
  await shot("rise-"+str(i).pad_zeros(3),Vector3(-1.1,1.15,-1.45),Vector3(0,.9,-3.0))
 a.position=Vector3(0,0,-3.2)
 for i in range(24):
  a.model.skin.tick(1.0/24,false,0,"guitar",a.guitar,Vector3.ZERO)
  a.guitar.visible=a.model.skin.guitar_weight>.7
  await shot("sit-"+str(i).pad_zeros(3),Vector3(-1.1,1.15,-1.45),Vector3(0,.9,-3.0))
 a.visible=false
 for idx in range(3):
  var person=game.actors[idx];person.visible=true;person.position=Vector3((idx-1)*.95,0,0);person.rotation.y=0
 for frame in range(26):
  for idx in range(3):
   var person=game.actors[idx];person.position.z+=1.4/24
   person.model.skin.tick(1.0/24,true,1.4,"walk",null,Vector3.ZERO)
  var z=frame*1.4/24
  await shot("humans-"+str(frame).pad_zeros(3),Vector3(2.7,1.6,3.6+z),Vector3(0,1,0+z))
 for actor in game.actors:actor.visible=false
 a=game.actors[1];a.visible=true;a.position=Vector3(4,0,3);a.rotation.y=0
 for i in range(18):
  a.model.skin.tick(1.0/30,false,0,"kick",null,Vector3(4,0,3.6))
  await shot("kick-"+str(i).pad_zeros(3),Vector3(5.2,1.4,5.1),Vector3(4,.9,3))
 a.visible=false
 var dog=game.actors[3];dog.visible=true;dog.rotation.y=0
 for gait in [["walk",.55],["trot",1.2],["run",2.5]]:
  dog.position=Vector3(3.8,0,1.8);dog.model.dog_skin.motion_phase=0;dog.model.dog_skin.foot_locked=[false,false,false,false];dog.model.dog_skin.foot_weights=[0.0,0.0,0.0,0.0]
  for i in range(26):
   dog.position.z+=gait[1]/24
   dog.model.dog_skin.tick(1.0/24,true,gait[1],"walk")
   await shot("dog-"+gait[0]+"-"+str(i).pad_zeros(3),dog.position+Vector3(1.05,.65,.75),dog.position+Vector3(0,.28,0))
 print("MOTION_06_CAPTURE_COMPLETE")
 game.clean_quit()
