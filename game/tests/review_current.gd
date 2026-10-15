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
 for a in game.actors:a.set_physics_process(false)
 var alina=game.actors[0]
 for i in range(80):alina.model.skin.tick(1.0/60,false,0,"guitar",alina.guitar,Vector3.ZERO)
 await shot("alina-face",Vector3(.23,1.35,-2.45),Vector3(0,1.30,-3.16))
 await shot("alina-profile",Vector3(.9,1.38,-3.05),Vector3(0,1.30,-3.16))
 await shot("guitar-front",Vector3(.1,1.04,-2.25),Vector3(0,.91,-3.05))
 await shot("guitar-side",Vector3(-1.1,1.2,-2.8),Vector3(0,.87,-3.03))
 await shot("alina-full",Vector3(.9,1.62,-1.5),Vector3(0,1.02,-3.2))
 var original_positions=[game.actors[1].position,game.actors[2].position]
 for idx in [1,2]:
  var a=game.actors[idx];a.position=Vector3(4,0,3);a.rotation.y=0
  for i in range(60):a.model.skin.tick(1.0/60,false,0,"idle",null,Vector3.ZERO)
  await shot("human-"+str(idx),Vector3(4.3,1.65,3.9),Vector3(4,1.61,3))
 for idx in [1,2]:game.actors[idx].position=original_positions[idx-1]
 var dog=game.actors[3];dog.position=Vector3(3.8,0,1.8);dog.rotation.y=0
 for i in range(60):dog.model.dog_skin.tick(1.0/60,false,0,"idle")
 await shot("dog-front",Vector3(3.95,.5,2.9),dog.position+Vector3(0,.30,.09))
 await shot("dog-side",Vector3(5.0,.65,1.9),dog.position+Vector3(0,.28,0))
 await shot("overview",Vector3(-4.1,1.9,4.8),Vector3(1,.5,-1.5))
 await shot("grill",Vector3(-1.3,1.2,1.25),game.grill_pos+Vector3(0,.77,0))
 await shot("food",Vector3(-3.0,1.4,3.9),Vector3(-3.2,.88,2.9))
 game.clean_quit()
