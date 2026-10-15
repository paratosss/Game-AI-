extends Node3D
class_name DemoDogSkin
var skeleton:Skeleton3D
var bones={}
var rest={}
var phase=0.0
var time=0.0
var gait=0.0
var head_anchor:BoneAttachment3D
var contacts=[]
var motion_clips:Dictionary={}
var motion_phase=0.0
var gait_name="idle"
var foot_anchors=[Vector3.ZERO,Vector3.ZERO,Vector3.ZERO,Vector3.ZERO]
var foot_locked=[false,false,false,false]
var foot_weights=[0.0,0.0,0.0,0.0]
var smooth_rotations={}
var body_height=0.0
var recovery_remaining=[0.0,0.0,0.0,0.0]
var recovery_from=[Vector3.ZERO,Vector3.ZERO,Vector3.ZERO,Vector3.ZERO]
var recovery_to=[Vector3.ZERO,Vector3.ZERO,Vector3.ZERO,Vector3.ZERO]
var previous_world_position=Vector3.ZERO
var has_previous_world_position=false
var recovery_steps=0
const RECOVERY_DURATION=.10
const MAX_SUPPORT_CROUCH=.065
func pair(a:String,b:String,weight:float)->Array:
 return [bones[a],bones[b],0,0,clampf(weight,0,1),1-clampf(weight,0,1),0.0,0.0]
func chain_weights(p:Vector3,names:Array)->Array:
 var distance=100.0;var result=[]
 for i in range(names.size()-1):
  var a:Vector3=rest[names[i]].origin;var b:Vector3=rest[names[i+1]].origin
  var t=clampf((p-a).dot(b-a)/(b-a).length_squared(),0,1)
  var d=p.distance_squared_to(a.lerp(b,t))
  if d<distance:distance=d;result=pair(names[i],names[i+1],1-t)
 return result
func bone(n:String,parent:String,p:Vector3):
 var i=skeleton.get_bone_count();skeleton.add_bone(n);bones[n]=i;rest[n]=Transform3D(Basis.IDENTITY,p)
 if not parent.is_empty():skeleton.set_bone_parent(i,bones[parent]);p-=rest[parent].origin
 skeleton.set_bone_rest(i,Transform3D(Basis.IDENTITY,p))
func weights(p:Vector3,label:String)->Array:
 var side=0 if p.x<0 else 1
 var front=p.z>-.03
 var i=(2 if front else 0)+side
 if "paw" in label.to_lower() or "toe" in label.to_lower():return pair("paw"+str(i),"hock"+str(i),1)
 if "ear" in label.to_lower():return pair("ear"+str(side),"head",smoothstep(.505,.565,p.y))
 if label=="Tail":return chain_weights(p,["tail","tail2","tail3"])
 if "Mouth" in label:return pair("jaw","head",1-smoothstep(.413,.43,p.y))
 if label not in ["Continuous anatomical skin","Short coat"]:return pair("head","neck",1)
 # Separate the narrow leg volumes from the belly, blend weights at the joints.
 if p.y<.25 and absf(p.x)>.025 and (absf(p.z-.145)<.095 if front else absf(p.z+.20)<.095):
  var n=str(i)
  return chain_weights(p,["upper"+n,"lower"+n,"hock"+n,"paw"+n])
 if p.z<-.28 and p.y>.33 and absf(p.x)<.032:
  return chain_weights(p,["tail","tail2","tail3"])
 if p.z>.19 and p.y>.35:
  if p.z>.28 and p.y<.42:return pair("jaw","head",clampf((.42-p.y)/.025,0,1))
  return pair("head","neck",smoothstep(.17,.23,p.z))
 if p.z>.10 and p.y>.34:return pair("neck","chest",smoothstep(.34,.43,p.y))
 return pair("hips","chest",1-smoothstep(-.12,.10,p.z))
func setup()->Dictionary:
 name="ArtoriasMesh";skeleton=Skeleton3D.new();skeleton.name="DogSkeleton";add_child(skeleton)
 bone("hips","",Vector3(0,.30,-.13));bone("chest","hips",Vector3(0,.325,.08));bone("neck","chest",Vector3(0,.40,.14));bone("head","neck",Vector3(0,.45,.23));bone("jaw","head",Vector3(0,.415,.29))
 bone("tail","hips",Vector3(0,.35,-.28));bone("tail2","tail",Vector3(0,.43,-.38));bone("tail3","tail2",Vector3(0,.51,-.46))
 bone("ear0","head",Vector3(-.044,.51,.215));bone("ear1","head",Vector3(.044,.51,.215))
 for i in range(4):
  var sign=-1 if i%2==0 else 1;var front=i>=2;var n=str(i)
  bone("upper"+n,"chest" if front else "hips",Vector3(sign*.074,.31,.135 if front else -.185))
  bone("lower"+n,"upper"+n,Vector3(sign*.074,.185,.112 if front else -.135))
  bone("hock"+n,"lower"+n,Vector3(sign*.074,.058,.140 if front else -.217))
  bone("paw"+n,"hock"+n,Vector3(sign*.074,.021,.145 if front else -.202))
 var source=load("res://assets/characters/Artorias_Anatomical.glb").instantiate();add_child(source)
 var orientation=Basis.IDENTITY
 var skin=Skin.new()
 for n in bones:skin.add_bind(bones[n],rest[n].affine_inverse())
 for node in source.find_children("*","MeshInstance3D",true,false):
  var transform=Transform3D(orientation,Vector3.ZERO)*(global_transform.affine_inverse()*node.global_transform)
  var mesh=ArrayMesh.new()
  for surface in range(node.mesh.get_surface_count()):
   var arrays=node.mesh.surface_get_arrays(surface);var vertices=arrays[Mesh.ARRAY_VERTEX];var normals=arrays[Mesh.ARRAY_NORMAL];var bindings=PackedInt32Array();var ws=PackedFloat32Array();var colors=PackedColorArray()
   for i in range(vertices.size()):
    vertices[i]=transform*vertices[i];normals[i]=(transform.basis*normals[i]).normalized()
    var pair=weights(vertices[i],str(node.name))
    var v=vertices[i];var patch=clampf((.285-v.y)*6,0,.65) if v.z>.01 else 0.0
    var shade=.96+.04*sin(v.z*21+v.y*37)
    var light=smoothstep(.10,.30,v.z)*(1-smoothstep(.28,.41,v.y))*.52+patch*.74
    colors.append((Color("987145").lerp(Color("c7b28d"),clampf(light,0,.75)))*Color(shade,shade,shade))
    bindings.append_array(PackedInt32Array(pair.slice(0,4)));ws.append_array(PackedFloat32Array(pair.slice(4,8)))
   arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_BONES]=bindings;arrays[Mesh.ARRAY_WEIGHTS]=ws;arrays[Mesh.ARRAY_TANGENT]=null;arrays[Mesh.ARRAY_COLOR]=colors
   mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
   var mat=node.get_active_material(surface).duplicate()
   if mat is StandardMaterial3D:
    mat.metallic=0
    if "eye" in str(node.name).to_lower():mat.roughness=.13
    elif node.name=="Nose":mat.roughness=.32
   if node.name in ["Continuous anatomical skin","Short coat"]:
    var fur=ShaderMaterial.new();fur.shader=load("res://assets/shaders/fur.gdshader");mat=fur
   mesh.surface_set_material(surface,mat)
  var m=MeshInstance3D.new();m.mesh=mesh;m.skin=skin;m.skeleton=NodePath("../DogSkeleton");add_child(m)
 source.queue_free()
 motion_clips=JSON.parse_string(FileAccess.get_file_as_string("res://assets/animations/dog_motion.json")).clips
 head_anchor=BoneAttachment3D.new();skeleton.add_child(head_anchor);head_anchor.bone_name="head";head_anchor.bone_idx=bones.head
 var jaw=BoneAttachment3D.new();skeleton.add_child(jaw);jaw.bone_name="jaw";jaw.bone_idx=bones.jaw
 DemoVisual.sphere(jaw,.02,Color("b47777"),Vector3(0,-.025,.032),Vector3(.6,.18,1))
 var collar=BoneAttachment3D.new();skeleton.add_child(collar);collar.bone_name="neck";collar.bone_idx=bones.neck
 var ring=TorusMesh.new();ring.inner_radius=.061;ring.outer_radius=.071;ring.rings=32;ring.ring_segments=10
 var c=DemoVisual.mesh(collar,ring,Color("7d4034"),Vector3(0,-.025,-.009));c.rotation.x=.6
 DemoVisual.sphere(collar,.014,Color("a8a999"),Vector3(0,-.062,.052),Vector3(1,1,.24))
 return {"visual":self,"hips":self,"head":head_anchor,"jaw":jaw,"legs":[],"knees":[],"tail":collar,"arms":[],"elbows":[],"dog_skin":self}
func pose(n:String)->Transform3D:return skeleton.get_bone_global_pose(bones[n])
func set_dog_bone_basis(n:String,basis:Basis):
 var i=bones[n];var parent=skeleton.get_bone_parent(i);var local=basis if parent<0 else skeleton.get_bone_global_pose(parent).basis.inverse()*basis
 skeleton.set_bone_pose_rotation(i,local.orthonormalized().get_rotation_quaternion())
func rotate_dog_bone(n:String,axis:Vector3,a:float):set_dog_bone_basis(n,Basis(axis,a)*pose(n).basis)
func align(a:String,b:String,direction:Vector3):
 var current=pose(a);var source=(pose(b).origin-current.origin).normalized()
 set_dog_bone_basis(a,Basis(Quaternion(source,direction.normalized()))*current.basis)
func solve_leg(i:int,target:Vector3):
 var n=str(i)
 # The metacarpus/metatarsus keeps the planted paw flat. Solve the two
 # proximal segments in an anatomical plane instead of allowing a free
 # three-link chain to fold into a hook or flip its elbow through the body.
 var ankle_offset:Vector3=rest["paw"+n].origin-rest["hock"+n].origin
 var pole=Vector3(0,0,-1 if i>=2 else 1)
 ik("upper"+n,"lower"+n,"hock"+n,target-ankle_offset,pole)
 set_dog_bone_basis("paw"+n,Basis.IDENTITY)

func foot_motion(i:int,motion:Dictionary)->Vector3:
 var delta:Vector3=motion.feet[i]
 if gait_name=="trot":
  var c=fposmod(motion_phase+(0.0 if i in [0,3] else .5),1)
  var stance=.56
  if c<stance:delta=Vector3(0,0,stance*.5*.44-.44*c)
  else:
   var t=(c-stance)/(1-stance)
   delta=Vector3(0,sin(t*PI)*.055,-stance*.5*.44+stance*.44*(t*t*(3-2*t)))
 elif gait_name=="run":delta=Vector3(delta.x*.4,maxf(delta.y,0)*.50,delta.z*.65)
 else:delta=Vector3(delta.x*.45,maxf(delta.y,0),delta.z)
 return delta
func sample_motion(name:String,phase_value:float)->Dictionary:
 var frames:Array=motion_clips[name].frames
 var f=fposmod(phase_value,1.0)*frames.size();var a:Dictionary=frames[int(f)%frames.size()];var b:Dictionary=frames[(int(f)+1)%frames.size()];var w=f-floor(f)
 var result={"feet":[],"rotations":{},"hip_y":lerpf(a.hip_y,b.hip_y,w)}
 for i in range(4):
  var p=a.feet[i];var q=b.feet[i]
  result.feet.append(Vector3(p[0],p[1],p[2]).lerp(Vector3(q[0],q[1],q[2]),w))
 for key in a.rotations:
  var p=a.rotations[key];var q=b.rotations[key]
  result.rotations[key]=Quaternion(p[0],p[1],p[2],p[3]).slerp(Quaternion(q[0],q[1],q[2],q[3]),w)
 return result
func ik(a:String,b:String,c:String,target:Vector3,pole:Vector3):
 var p=pose(a).origin;var upper=rest[a].origin.distance_to(rest[b].origin);var lower=rest[b].origin.distance_to(rest[c].origin)
 var d=target-p;var length=clampf(d.length(),absf(upper-lower)+.002,upper+lower-.003);var direction=d.normalized();var along=(length*length+upper*upper-lower*lower)/(2*length);var height=sqrt(maxf(upper*upper-along*along,0))
 var middle=p+direction*along+(pole-direction*pole.dot(direction)).normalized()*height
 align(a,b,middle-p);align(b,c,target-pose(b).origin);set_dog_bone_basis(c,Basis.IDENTITY)
func tick(dt:float,moving:bool,speed:float,action:String):
 var travel_velocity=Vector3.ZERO
 if has_previous_world_position and dt>0:
  travel_velocity=(global_position-previous_world_position)/dt
  if travel_velocity.length()>6:travel_velocity=global_basis.z*speed
 previous_world_position=global_position
 has_previous_world_position=true
 # The actor may still be braking after its navigation target is reached.
 moving=moving or speed>.05
 time+=dt;gait=move_toward(gait,1 if moving else 0,dt*5)
 gait_name="run" if moving and speed>1.85 else "trot" if moving and speed>.85 else "walk" if moving else "bark" if action=="bark" else "idle"
 var clip="walk" if gait_name=="trot" else gait_name
 var rate=speed/.44 if gait_name=="trot" else speed/(motion_clips.run.nominal_speed*.65)/motion_clips.run.duration if gait_name=="run" else speed/motion_clips.walk.nominal_speed/motion_clips.walk.duration if moving else 1.0/motion_clips[clip].duration
 motion_phase+=dt*rate
 var motion=sample_motion(clip,motion_phase)
 var foot_targets=[]
 for i in range(4):
  if recovery_remaining[i]>0:
   recovery_remaining[i]=maxf(0,recovery_remaining[i]-dt)
   var t=1-recovery_remaining[i]/RECOVERY_DURATION
   var point:Vector3=recovery_from[i].lerp(recovery_to[i],smoothstep(0,1,t))
   point.y+=sin(t*PI)*.045
   foot_weights[i]=0
   foot_locked[i]=false
   if recovery_remaining[i]==0:
    foot_anchors[i]=recovery_to[i]
    foot_weights[i]=1
    foot_locked[i]=true
   foot_targets.append(to_local(point))
   continue
  var delta=foot_motion(i,motion)
  var foot:Vector3=rest["paw"+str(i)].origin+delta*gait
  var contact=moving and delta.y<.010
  if contact and not foot_locked[i]:foot_anchors[i]=to_global(Vector3(foot.x,.021,foot.z))
  foot_locked[i]=contact
  foot_weights[i]=move_toward(foot_weights[i],1.0 if contact else 0.0,dt*(30 if contact else 22))
  if foot_weights[i]>0:foot=foot.lerp(to_local(foot_anchors[i]),foot_weights[i])
  foot_targets.append(foot)
 skeleton.reset_bone_poses()
 var target_height=clampf(motion.hip_y*.35,-.028,.035)-.008*gait
 if gait_name=="trot":target_height=sin(motion_phase*TAU*2)*.006-.022
 elif gait_name=="run":target_height=clampf(motion.hip_y*.20,-.012,.012)-.018
 body_height=lerpf(body_height,target_height,minf(dt*14,1))
 body_height=maxf(body_height,-MAX_SUPPORT_CROUCH)
 var p=skeleton.get_bone_pose_position(bones.hips);p.y+=body_height+sin(time*2)*.0015;skeleton.set_bone_pose_position(bones.hips,p)
 for key in ["hips","chest","neck","head","jaw","tail","tail2","tail3","ear0","ear1"]:
  var strength=.38 if key in ["hips","chest"] else .65 if key in ["neck","head"] else .45 if key.begins_with("ear") else .60
  var desired=Quaternion.IDENTITY.slerp(motion.rotations[key],strength)
  var current=smooth_rotations.get(key,Quaternion.IDENTITY)
  current=current.slerp(desired,minf(dt*12,1));smooth_rotations[key]=current
  set_dog_bone_basis(key,Basis(current))
 var wag=.18 if action in ["happy","bark"] else .10 if moving else pow(maxf(0,sin(time*.23-1)),12)*.08
 rotate_dog_bone("tail",Vector3.FORWARD,sin(time*4.1)*wag)
 rotate_dog_bone("tail2",Vector3.FORWARD,sin(time*4.1-.5)*wag*.5)
 if action=="bark":rotate_dog_bone("jaw",Vector3.RIGHT,.06+.12*maxf(0,sin(time*16)))
 for i in range(2):
  var flick=pow(maxf(0,sin(time*.57+i*2.7)),22)*.09
  rotate_dog_bone("ear"+str(i),Vector3.RIGHT,flick)
 # A planted paw is a world-space support. Lower the body when necessary
 # to keep the ankle reachable with unchanged bone lengths; dragging the
 # support point towards the body would make the foot skate instead.
 var support_drop=0.0
 for i in range(4):
  if foot_weights[i]<=0:continue
  var n=str(i)
  var ankle:Vector3=foot_targets[i]-(rest["paw"+n].origin-rest["hock"+n].origin)
  var origin:Vector3=pose("upper"+n).origin
  var reach=rest["upper"+n].origin.distance_to(rest["lower"+n].origin)+rest["lower"+n].origin.distance_to(rest["hock"+n].origin)-.004
  var horizontal=Vector2(origin.x-ankle.x,origin.z-ankle.z).length_squared()
  var vertical=sqrt(maxf(reach*reach-horizontal,.0001))
  var needed_drop=origin.y-ankle.y-vertical
  if needed_drop>body_height+MAX_SUPPORT_CROUCH or horizontal>=reach*reach:
   # A sharp turn can move a support outside the leg's workspace. Take a
   # short lifted recovery step instead of stretching, skating or collapsing
   # the entire body to preserve an impossible old anchor.
   recovery_remaining[i]=RECOVERY_DURATION
   recovery_from[i]=foot_anchors[i]
   recovery_to[i]=to_global(rest["paw"+n].origin)+travel_velocity*RECOVERY_DURATION
   recovery_to[i].y=global_position.y+.021
   foot_weights[i]=0
   foot_locked[i]=false
   foot_targets[i]=to_local(recovery_from[i])
   recovery_steps+=1
  else:support_drop=maxf(support_drop,needed_drop)
 if support_drop>0:
  body_height-=support_drop
  var hips_position=skeleton.get_bone_pose_position(bones.hips)
  hips_position.y-=support_drop
  skeleton.set_bone_pose_position(bones.hips,hips_position)
 contacts.clear()
 for i in range(4):
  solve_leg(i,foot_targets[i])
  contacts.append(pose("paw"+str(i)).origin)
 skeleton.force_update_all_bone_transforms()
