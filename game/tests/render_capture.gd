extends SceneTree
func _initialize():call_deferred("capture")
func capture():
 var output=OS.get_environment("SHASHLIK_CAPTURE_DIR")
 if output.is_empty():output=ProjectSettings.globalize_path("user://captures")
 DirAccess.make_dir_recursive_absolute(output)
 var scene=load("res://main.tscn").instantiate();root.add_child(scene)
 await create_timer(1.5).timeout
 scene.player.position=Vector3(-4.1,0,4.8);scene.player.rotation.y=-.35;scene.camera.rotation.x=-.23
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(output.path_join("v02-overview.png"))
 scene.player.position=Vector3(.9,0,-1.5);scene.camera.look_at(Vector3(0,1.05,-3.2));scene.ui.visible=false
 await create_timer(.3).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(output.path_join("v02-alina.png"))
 scene.ui.visible=true;scene.player.position=Vector3(-2,0,1.7);scene.player.rotation.y=0;scene.camera.rotation=Vector3(-.43,0,0)
 scene.pick(scene.props[0])
 for i in range(6):scene.held.pieces.append(DemoRules.piece("pork"))
 scene.held.refresh();scene.tutorial=2;scene.clock=25;scene.tick_orders()
 await create_timer(.3).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(output.path_join("v02-placement.png"))
 scene.clean_quit()
