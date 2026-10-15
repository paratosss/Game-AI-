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
 await create_timer(.8).timeout
 game.initialized=false;game.set_physics_process(false)
 for a in game.actors:a.set_physics_process(false)
 game.ui.visible=false
 var alina=game.actors[0]
 for i in range(70):alina.model.skin.tick(1./60,false,0,"guitar",alina.guitar,Vector3.ZERO)
 await shot("v04-alina",Vector3(.9,1.62,-1.5),Vector3(0,1.02,-3.2))
 var dog=game.actors[3];dog.position=Vector3(3.8,0,1.8);dog.rotation.y=.55
 dog.model.dog_skin.tick(.01,false,0,"idle")
 await shot("v04-dog",Vector3(4.6,.8,3.1),dog.position+Vector3(0,.36,0))
 for idx in [1,2]:
  var actor=game.actors[idx];actor.rotation.y=0;actor.model.skin.tick(.01,false,0,"idle",null,Vector3.ZERO)
  await shot("v04-human-"+str(idx),actor.position+Vector3(.7,1.5,1.9),actor.position+Vector3(0,1.0,0))
 await shot("v04-overview",Vector3(-4.1,1.9,4.8),Vector3(1,.5,-1.5))
 game.ui.visible=true;game.clock=25;game.tick_orders();game.pick(game.props[0]);game.tutorial=2
 await shot("v04-placement",Vector3(-2,1.62,1.7),Vector3(-2,.88,0))
 game.ui.visible=false
 var person=game.actors[1]
 for i in range(12):
  person.model.skin.tick(.055,true,1.4,"walk",null,Vector3.ZERO)
  dog.model.dog_skin.tick(.055,true,2.5,"walk")
  await shot("walk-"+str(i).pad_zeros(2),Vector3(2.1,1.25,5.6),Vector3(3.5,.75,3.6))
 # Rig diagnostics are recorded alongside images for attachment and IK checks.
 print("VISUAL_DIAGNOSTICS: guitar wrist error=",alina.model.skin.arm_error," foot positions=",alina.model.skin.ground_feet)
 game.clean_quit()
