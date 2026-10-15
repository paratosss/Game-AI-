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
 var a=game.actors[0];a.visible=true
 for i in range(70):a.model.skin.tick(1./60,false,0,"guitar",a.guitar,Vector3.ZERO)
 await shot("hands",Vector3(.38,1.14,-2.35),Vector3(.12,.99,-2.96))
 a.model.skin.motion_time=4.6+.085
 a.model.skin.tick(0,false,0,"guitar",a.guitar,Vector3.ZERO)
 await shot("blink",Vector3(.14,1.34,-2.5),Vector3(0,1.31,-3.15))
 a.guitar.visible=false
 for i in range(22):
  a.model.skin.tick(1./24,false,0,"getup",a.guitar,Vector3.ZERO)
  a.position+=a.global_basis.z*a.model.skin.frame_root_delta
  await shot("rise-"+str(i).pad_zeros(2),Vector3(-1.15,1.05,-1.7),Vector3(0,.83,-3.2))
 a.position.z=-1.2
 for i in range(32):
  a.model.skin.tick(1./24,true,1.4,"walk",null,Vector3.ZERO)
  await shot("walk-"+str(i).pad_zeros(2),Vector3(.8,1.05,.85),Vector3(0,.80,-1.2))
 a.visible=false
 for idx in [1,2]:
  a=game.actors[idx];a.visible=true;a.position=Vector3(0,0,-1.2);a.rotation.y=0
  for frame in range(24):a.model.skin.tick(1./24,false,0,"idle",null,Vector3.ZERO)
  await shot("person-"+str(idx),Vector3(.55,1.6,-.13),Vector3(0,1.55,-1.2))
  await shot("person-body-"+str(idx),Vector3(.95,1.3,1.4),Vector3(0,1.0,-1.2))
  for frame in range(18):
   a.model.skin.tick(1./24,true,1.4,"walk",null,Vector3.ZERO)
   await shot("person-"+str(idx)+"-walk-"+str(frame).pad_zeros(2),Vector3(.9,1.1,1.2),Vector3(0,1,-1.2))
  a.visible=false
 game.clean_quit()
