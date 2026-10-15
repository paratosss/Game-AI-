extends CharacterBody3D
class_name DemoActor
var profile:Dictionary
var state=""
var target=Vector3.ZERO
var model:Dictionary
var phase=0.0
var guitar:Node3D
var reaction_time=0.0
var course={"meat":0,"veg":0}
var ordered=false
var completed=false
var animation:AnimationPlayer
var action_time=0.0
var action_name=""
var facing=Vector3.ZERO
var standing=false
var crumbs:CPUParticles3D
func build(p:Dictionary,col:Color):
 profile=p;state=p.activity;add_to_group("guests")
 model=DemoRig.dog(self) if p.get("dog",false) else DemoRig.human(self,p.name,col)
 var c=CollisionShape3D.new();var s=CapsuleShape3D.new();s.radius=.15 if p.get("dog",false) else .22;s.height=.56 if p.get("dog",false) else 1.57 if p.name=="Алина" else 1.78 if p.name=="Круглик" else 1.82;c.shape=s;c.position.y=s.height/2;add_child(c)
 if p.activity=="GUITAR":
  guitar=DemoVisual.guitar(model.visual);guitar.position=Vector3(-.12,.760,.205);guitar.rotation=Vector3(-.08,0,-1.26)
 animation=AnimationPlayer.new();animation.name="AnimationPlayer";add_child(animation)
 var lib=AnimationLibrary.new();animation.add_animation_library("",lib)
 var dog=p.get("dog",false)
 for n in ["idle","walk","guitar","kick","wave","eat","happy","gag","cough","spit","dislike","bark","getup"]:
  var clip=make_animation(n,dog);lib.add_animation(n,clip)
 animation.play("idle")
 if not p.get("dog",false):
  crumbs=CPUParticles3D.new();model.head.add_child(crumbs);crumbs.position=Vector3(0,.06,.13);crumbs.amount=16;crumbs.lifetime=.65;crumbs.one_shot=true;crumbs.explosiveness=.75;crumbs.direction=Vector3(0,-.25,1);crumbs.spread=18;crumbs.initial_velocity_min=.4;crumbs.initial_velocity_max=.8;crumbs.gravity=Vector3(0,-2,0);crumbs.local_coords=false
  var m=SphereMesh.new();m.radius=.009;m.height=.018;m.radial_segments=6;m.rings=3;crumbs.mesh=m;crumbs.material_override=DemoVisual.mat(Color("839164"));crumbs.emitting=false
func add_track(clip:Animation,node:Node3D,prop:String,keys:Array):
 var idx=clip.add_track(Animation.TYPE_VALUE);clip.track_set_path(idx,NodePath(str(get_path_to(node))+":"+prop));clip.track_set_interpolation_type(idx,Animation.INTERPOLATION_CUBIC)
 for i in range(keys.size()):clip.track_insert_key(idx,clip.length*i/(keys.size()-1),keys[i])
func make_animation(n:String,dog:bool)->Animation:
 var a=Animation.new();a.length=.85 if n=="walk" else (1.8 if n in ["idle","guitar"] else .7);a.loop_mode=Animation.LOOP_NONE if n in ["kick","getup"] else Animation.LOOP_LINEAR
 if not dog or model.has("dog_skin"):return a
 var y=.32
 if n=="guitar" and not dog:y=.53
 add_track(a,model.hips,"position:y",[.53,.70,.91] if n=="getup" else [y,y+(.017 if n in ["idle","walk"] else .05 if n=="happy" else 0),y,y+.01,y])
 add_track(a,model.head,"rotation:y",[0,.05,0,-.05,0] if n=="idle" else [0,-.35,.35,-.35,0] if n=="dislike" else [0,0,0])
 add_track(a,model.head,"rotation:x",[.05,.12,.05] if n=="guitar" else [0,.35,0] if n in ["gag","eat","spit"] else [0,0,0])
 if dog:
  add_track(a,model.jaw,"rotation:x",[0,.45,0,.38,0] if n=="bark" else [0,.14,0])
  add_track(a,model.tail,"rotation:z",[-.22,.22,-.22])
 else:
  add_track(a,model.torso,"rotation:x",[0,.45,.12,.3,0] if n in ["gag","cough","spit"] else [0,.025,0])
 for i in range(model.legs.size()):
  var leg=model.legs[i];var knee=model.knees[i];var angles=[0.0,0.0,0.0];var bend=[.08,.08,.08]
  if n=="walk":
   var s=1 if (i%2==0 if not dog else i in [0,3]) else -1
   angles=[.48*s,0,-.48*s,0,.48*s];bend=[.1,.5 if s>0 else .06,.1,.06 if s>0 else .5,.1]
  if n=="guitar" and not dog:angles=[-1.48,-1.48,-1.48];bend=[1.5,1.5,1.5]
  if n=="getup":angles=[-1.48,-.65,0];bend=[1.5,.65,.08]
  if n=="kick" and i==0:angles=[0,.6,-1.0,0];bend=[.08,.5,.03,.08]
  add_track(a,leg,"rotation:x",angles);add_track(a,knee,"rotation:x",bend)
 for i in range(model.arms.size()):
  var s=-1 if i==0 else 1;var ax=[0.0,0.0,0.0];var ay=[0.0,0.0,0.0];var az=[s*.08,s*.08,s*.08];var ex=[-.08,-.08,-.08]
  if n=="walk":ax=[s*.35,0,-s*.35,0,s*.35]
  if n=="guitar":
   ax=[-.51,-.56,-.51,-.56,-.51] if i==0 else [-1.22,-1.22,-1.22];ay=[.52,.52,.52] if i==0 else [.16,.16,.16];az=[0,0,0];ex=[-1.31,-1.31,-1.31] if i==0 else [-1.56,-1.56,-1.56]
  if n in ["wave","happy"] and i==1:az=[-2.35,-2.65,-2.35];ex=[-.5,-.85,-.5]
  if n in ["gag","cough","eat","spit"] and i==1:ax=[-1.38,-1.45,-1.38];ay=[-.96,-.96,-.96];ex=[-1.75,-1.75,-1.75];az=[0,0,0]
  add_track(a,model.arms[i],"rotation:x",ax);add_track(a,model.arms[i],"rotation:y",ay);add_track(a,model.arms[i],"rotation:z",az);add_track(a,model.elbows[i],"rotation:x",ex)
 return a
func action(n:String,t:float=1.8):
 action_name=n;action_time=t;reaction_time=t;animation.play(n,.13)
 if crumbs and n in ["spit","gag"]:crumbs.restart()
func _physics_process(dt):
 phase+=dt;reaction_time=maxf(0,reaction_time-dt);action_time=maxf(0,action_time-dt)
 var d=target-global_position;d.y=0
 var moving=d.length()>.16 and not (action_time>0 and action_name in ["getup","wave","kick"])
 var direction=d.normalized()
 if moving:
  for other in get_tree().get_nodes_in_group("guests"):
   if other==self:continue
   var gap=global_position-other.global_position;gap.y=0
   if gap.length()<.7 and gap.length()>.02:direction+=gap.normalized()*(.7-gap.length())*2
  var speed=3.0 if profile.get("dog",false) else 1.4
  var desired_velocity=direction.normalized()*minf(speed,d.length()*4)
  var acceleration=10 if profile.get("dog",false) else 4
  velocity.x=move_toward(velocity.x,desired_velocity.x,dt*acceleration);velocity.z=move_toward(velocity.z,desired_velocity.z,dt*acceleration)
  rotation.y=lerp_angle(rotation.y,atan2(direction.x,direction.z),minf(dt*7,1))
 else:
  velocity.x=move_toward(velocity.x,0,dt*8);velocity.z=move_toward(velocity.z,0,dt*8)
  if state=="GUITAR":rotation.y=lerp_angle(rotation.y,0,dt*5)
  elif facing!=Vector3.ZERO:
   var look=facing-global_position;rotation.y=lerp_angle(rotation.y,atan2(look.x,look.z),dt*4)
 velocity.y-=9.8*dt;move_and_slide()
 var desired=action_name if action_time>0 else ("walk" if moving else "guitar" if state=="GUITAR" and not standing else "eat" if state=="EAT" else "idle")
 if animation.current_animation!=desired:animation.play(desired,.38 if desired=="guitar" else .18)
 if model.has("skin"):
  model.skin.tick(dt,moving,Vector2(velocity.x,velocity.z).length(),desired,guitar,facing,animation.current_animation_position)
  if desired=="getup":position+=global_basis.z*model.skin.frame_root_delta
 if model.has("dog_skin"):model.dog_skin.tick(dt,moving,Vector2(velocity.x,velocity.z).length(),desired)
 if guitar:guitar.visible=state=="GUITAR" and not moving
