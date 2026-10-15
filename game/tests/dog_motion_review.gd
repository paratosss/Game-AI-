extends SceneTree
var game
var out:String
func _initialize():call_deferred("run")
func shot(name:String,pos:Vector3,point:Vector3):
 game.player.position=pos-Vector3(0,1.62,0);game.camera.look_at(point,Vector3.UP)
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out.path_join(name+".png"))
func run():
 out=OS.get_environment("SHASHLIK_CAPTURE_DIR");DirAccess.make_dir_recursive_absolute(out)
 game=load("res://main.tscn").instantiate();root.add_child(game)
 await create_timer(.3).timeout;game.initialized=false;game.set_physics_process(false)
 for a in game.actors:a.set_physics_process(false);a.visible=false
 game.ui.visible=false
 var dog=game.actors[3];dog.visible=true;dog.rotation.y=0;dog.position=Vector3(0,0,-1)
 for i in range(45):dog.model.dog_skin.tick(1./60,false,0,"idle")
 await shot("dog-close",dog.position+Vector3(.65,.52,.66),dog.position+Vector3(0,.37,.1))
 await shot("dog-side",dog.position+Vector3(.95,.40,.06),dog.position+Vector3(0,.29,.02))
 for speed in [.6,1.25,3.0]:
  dog.position=Vector3(0,0,-1)
  for frame in range(32):
   dog.position.z+=speed/24
   dog.model.dog_skin.tick(1./24,true,speed,"walk")
   await shot("dog-"+str(speed)+"-"+str(frame).pad_zeros(2),dog.position+Vector3(.95,.40,.65),dog.position+Vector3(0,.3,.04))
  print("DOG_REVIEW ",speed," ",dog.model.dog_skin.gait_name," contacts ",dog.model.dog_skin.contacts)
 game.clean_quit()
