extends SceneTree
func _initialize():call_deferred('run')
func run():
 var game=load('res://main.tscn').instantiate();root.add_child(game)
 await create_timer(.1).timeout;game.initialized=false;game.set_physics_process(false)
 for a in game.actors:a.set_physics_process(false)
 var actor=game.actors[0];var skin=actor.model.skin
 for frame in range(70):skin.tick(1./60,false,0,'guitar',actor.guitar,Vector3.ZERO)
 print('MODEL ',skin.global_transform,' SKELETON ',skin.skeleton.global_transform)
 for n in ['Root','pelvis','upperarm_l','lowerarm_l','hand_l','thigh_l','calf_l','foot_l']:
  print(n,' origin=',skin.global_pose(n).origin,' rest=',skin.rest[n].origin,' scale=',skin.global_pose(n).basis.get_scale(),' posepos=',skin.skeleton.get_bone_pose_position(skin.indices[n]))
 print('TARGET ',skin.to_local(actor.guitar.to_global(Vector3(.055,.515,.093))))
 print('SIZES ',skin.rest.upperarm_l.origin.distance_to(skin.rest.lowerarm_l.origin),' ',skin.rest.lowerarm_l.origin.distance_to(skin.rest.hand_l.origin))
 for suffix in ['_l','_r']:
  var long=(skin.global_pose('middle_01'+suffix).origin-skin.global_pose('hand'+suffix).origin).normalized()
  var width=(skin.global_pose('index_01'+suffix).origin-skin.global_pose('pinky_01'+suffix).origin).normalized()
  var normal=long.cross(width).normalized()
  var dot=normal.dot(-actor.guitar.global_basis.z.normalized())
  print('PALM ',suffix,' cross ',normal,' dot guitar ',dot,' dot bone x ',normal.dot(skin.global_pose('hand'+suffix).basis.x),' hand ',skin.global_pose('hand'+suffix).origin)
 game.clean_quit()
