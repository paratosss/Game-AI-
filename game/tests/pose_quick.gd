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
 for a in game.actors:a.set_physics_process(false)
 game.ui.visible=false
 var alina=game.actors[0]
 for i in range(70):alina.model.skin.tick(1./60,false,0,"guitar",alina.guitar,Vector3.ZERO)
 await shot("alina",Vector3(.65,1.38,-1.55),Vector3(0,.98,-3.2))
 await shot("hands",Vector3(.38,1.14,-2.35),Vector3(.12,.99,-2.96))
 await shot("left",Vector3(1.15,1.20,-2.80),Vector3(.35,.97,-2.96))
 print("POSE_CONTACT",alina.model.skin.arm_error," elbows ",alina.model.skin.guitar_elbows)
 game.clean_quit()
