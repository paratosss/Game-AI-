extends SceneTree
func _initialize():call_deferred("run")
func run():
 var scene=load("res://main.tscn").instantiate();root.add_child(scene)
 var dog=load("res://assets/characters/Artorias_Source.glb").instantiate();scene.add_child(dog);dog.rotation.y=-PI/2;dog.scale=Vector3.ONE*1.65;dog.position=Vector3(1,0,0)
 scene.player.position=Vector3(1.9,-.80,1.4);scene.camera.look_at(Vector3(1,.30,0));scene.ui.visible=false
 await create_timer(1.5).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(OS.get_environment("SHASHLIK_CAPTURE_DIR").path_join("dog-source.png"))
 scene.clean_quit()
