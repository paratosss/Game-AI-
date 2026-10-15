extends SceneTree
var game
var out:String
func _initialize():call_deferred('run')
func shot(name:String,pos:Vector3,point:Vector3):
 game.player.position=pos-Vector3(0,1.62,0);game.camera.look_at(point,Vector3.UP)
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out.path_join(name+'.png'))
func run():
 out=OS.get_environment('SHASHLIK_CAPTURE_DIR');DirAccess.make_dir_recursive_absolute(out)
 game=load('res://main.tscn').instantiate();root.add_child(game)
 await create_timer(.2).timeout;game.initialized=false;game.set_physics_process(false)
 for a in game.actors:a.set_physics_process(false);a.visible=false
 game.ui.visible=false
 var character=load('res://assets/characters/Alina_Candidate.glb').instantiate();game.add_child(character)
 character.position=Vector3(0,0,-3.2)
 var animation=character.find_children('*','AnimationPlayer',true,false)[0]
 animation.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
 animation.play('idle');animation.advance(.8)
 var sk=character.find_children('*','Skeleton3D',true,false)[0]
 for name in ['hand_l','hand_r','lowerarm_l','lowerarm_r','foot_l']:
  print('REST ',name,' ',sk.get_bone_global_rest(sk.find_bone(name)))
 print('CANDIDATE: skeleton transform=',sk.transform,' Head=',sk.get_bone_global_rest(sk.find_bone('Head')))
 await shot('candidate-face',Vector3(.05,1.47,-2.35),Vector3(0,1.43,-3.18))
 await shot('candidate-profile',Vector3(.68,1.48,-3.03),Vector3(0,1.43,-3.18))
 await shot('candidate-body',Vector3(1.2,1.28,-.90),Vector3(0,.85,-3.2))
 character.position.z=-1.2
 animation.play('walk')
 for frame in range(24):
  animation.seek(frame/24.,true)
  await shot('walk-'+str(frame).pad_zeros(2),Vector3(.70,.95,1.1),Vector3(0,.78,-1.2))
 game.clean_quit()
