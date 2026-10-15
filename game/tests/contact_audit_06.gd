extends SceneTree
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
 if not ok:failures+=1;push_error(message)
func run():
 var game=load("res://main.tscn").instantiate();root.add_child(game)
 await create_timer(.2).timeout;game.initialized=false;game.set_physics_process(false)
 for a in game.actors:a.set_physics_process(false)
 for idx in range(3):
  var a=game.actors[idx];var skin=a.model.skin;a.position=Vector3(idx*2,0,0);a.rotation.y=0
  for frame in range(180):
   a.position.z+=1.4/60;skin.tick(1.0/60,true,1.4,"walk",null,Vector3.ZERO)
   for bone in range(skin.skeleton.get_bone_count()):check(skin.skeleton.get_bone_global_pose(bone).origin.is_finite(),"Human non-finite transform")
  for action in ["getup","guitar","eat","gag","cough","spit","kick","idle"]:
   for frame in range(60):skin.tick(1.0/60,false,0,action,a.guitar,Vector3.ZERO)
   for foot in skin.ground_feet:check(foot.y>-.03 and foot.y<.24,"Human foot outside ground clearance: "+action)
 var dog=game.actors[3];var skin=dog.model.dog_skin
 for speed in [.55,1.2,2.5]:
  dog.position=Vector3.ZERO;skin.motion_phase=0;skin.foot_locked=[false,false,false,false];skin.foot_weights=[0.0,0.0,0.0,0.0]
  var min_y=10.0;var max_y=-10.0;var slip=0.0;var previous=[]
  for frame in range(240):
   dog.position.z+=speed/60;skin.tick(1.0/60,true,speed,"walk")
   var current=[]
   for i in range(4):
    var p=skin.to_global(skin.contacts[i]);current.append(p);min_y=minf(min_y,p.y);max_y=maxf(max_y,p.y)
    if frame>0 and skin.foot_weights[i]>.95 and skin.foot_locked[i]:slip=maxf(slip,p.distance_to(previous[i]))
    check(p.is_finite(),"Dog non-finite paw")
   previous=current
  print("DOG_CONTACT speed=",speed," min_y=",min_y," max_y=",max_y," planted_frame_drift=",slip)
  check(min_y>-.008 and max_y<.15,"Dog ground clearance")
 print("CONTACT_AUDIT_06_", "PASS" if failures==0 else "FAIL"," failures=",failures)
 game.clean_quit(0 if failures==0 else 1)
