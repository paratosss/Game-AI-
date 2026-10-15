extends SceneTree
var failures=0
func check(ok:bool,message:String):
 if not ok:failures+=1;push_error(message)
func _initialize():call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate();root.add_child(game)
 await create_timer(.2).timeout;game.initialized=false
 for actor in game.actors:actor.set_physics_process(false)
 for i in range(3):
  var actor=game.actors[i];var human=actor.model.skin
  check(human.skeleton.get_bone_count()>50,"Humanoid requires an authored continuous skeleton")
  var skins=human.skeleton.find_children("*","MeshInstance3D",true,false)
  var clothes=0;var hair=0
  for mesh in skins:
   if mesh.material_override is ShaderMaterial:clothes+=1
  for mesh in human.head_anchor.find_children("*","MeshInstance3D",true,false):
   if mesh.mesh is ArrayMesh:hair+=1
  check(clothes==1,"Exactly one continuous clothed body per guest")
  check(hair>=1,"Hair must follow the head attachment")
  for j in range(120):
   human.tick(1./60,true,1.4,"walk",null,Vector3.ZERO)
   for foot in human.ground_feet:check(foot.y>.04 and foot.y<.23,"Walking foot has plausible clearance")
  for pose in ["idle","guitar","kick","wave","happy","eat","cough","gag","dislike","getup"]:
   human.tick(.2,false,0,pose,actor.guitar,Vector3.ZERO,.3)
   for bone in range(human.skeleton.get_bone_count()):check(human.skeleton.get_bone_global_pose(bone).origin.is_finite(),"Finite bone transform: "+pose)
 var alina=game.actors[0]
 for i in range(120):alina.model.skin.tick(1./60,false,0,"guitar",alina.guitar,Vector3.ZERO)
 check(alina.model.skin.arm_error<.02,"Guitar wrist target error under 2 cm")
 var dog=game.actors[3].model.dog_skin
 check(dog.skeleton.get_bone_count()>=20,"Dog has independent limb chains and tail")
 var body=dog.get_children().filter(func(n):return n is MeshInstance3D)
 check(body.size()>15,"Dog preserves anatomical surface and facial details")
 var first=body[0].mesh.surface_get_arrays(0);var weights=first[Mesh.ARRAY_WEIGHTS];var bindings=first[Mesh.ARRAY_BONES];var used={}
 for i in range(bindings.size()):
  if weights[i]>.01:used[bindings[i]]=true
 check(used.size()>=10,"Dog body must deform through many bones, not move rigidly")
 for i in range(180):
  dog.tick(1./60,true,3,"walk")
  for foot in dog.contacts:check(foot.y>=-.002 and foot.y<.15,"Dog paw clearance")
 print("RIG_VALIDATION_04_", "PASS" if failures==0 else "FAIL"," failures=",failures," guitar_error=",alina.model.skin.arm_error," dog_body_bones=",used.size())
 game.clean_quit(0 if failures==0 else 1)
