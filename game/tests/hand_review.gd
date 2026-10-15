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
 await create_timer(.4).timeout;game.initialized=false;game.set_physics_process(false)
 for a in game.actors:a.set_physics_process(false)
 game.ui.visible=false
 var alina=game.actors[0]
 for i in range(70):alina.model.skin.tick(1./60,false,0,"guitar",alina.guitar,Vector3.ZERO)
 await shot("hero-alina",Vector3(.65,1.38,-1.55),Vector3(0,.98,-3.2))
 await shot("hero-alina-side",Vector3(-1.25,1.25,-2.15),Vector3(0,.88,-3.2))
 await shot("alina-hands",Vector3(.38,1.14,-2.35),Vector3(.12,.99,-2.96))
 await shot("alina-left",Vector3(1.15,1.20,-2.80),Vector3(.35,.97,-2.96))
 await shot("hero-grill",Vector3(-3.35,1.35,1.35),Vector3(-2,.72,0))
 await shot("hero-table",Vector3(-4.75,1.37,4.23),Vector3(-3.2,.85,2.75))
 var dog=game.actors[3];dog.position=Vector3(-.3,0,-1.05);dog.rotation.y=-.25;dog.model.dog_skin.tick(.1,false,0,"idle")
 await shot("hero-artorias",Vector3(.45,.72,.08),dog.position+Vector3(0,.3,.10))
 await shot("hero-zone",Vector3(-4.7,1.65,1.95),Vector3(-.7,.65,-2.0))
 # Real consecutive updates of pose calculations; render 24 frames for motion review.
 for i in range(72):
  alina.model.skin.tick(1./24,false,0,"guitar",alina.guitar,Vector3.ZERO)
  await shot("guitar-"+str(i).pad_zeros(2),Vector3(.52,1.35,-1.55),Vector3(0,1.0,-3.2))
 print("HERO_REVIEW: wrist error=",alina.model.skin.arm_error," elbow positions=",alina.model.skin.guitar_elbows)
 game.clean_quit()
