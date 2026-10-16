extends Node3D
class_name DemoHumanSkin
var skeleton:Skeleton3D
var rest={}
var indices={}
var head_anchor:BoneAttachment3D
var torso_anchor:BoneAttachment3D
var walk_phase=0.0
var blend=0.0
var sit_weight=1.0
var motion_time=0.0
var guitar_weight=0.0
var hand_targets=[]
var guitar_elbows=[]
var ground_feet=[]
var arm_error=0.0
var native_animation:AnimationPlayer
var current_native_clip=""
var face_meshes:Array=[]
var blink_period=4.6
var getup_elapsed=0.0
var previous_pose=""
var pose_elapsed=0.0
var reaction_weight=0.0
var seat_elapsed=1.0
var was_seated=true
var getup_shift=0.0
var frame_root_delta=0.0
var nominal_walk_speed=.6343
var foot_anchors=[Vector3.ZERO,Vector3.ZERO]
var foot_locked=[false,false]
var foot_weights=[0.0,0.0]
var revision_mouth_local=Vector3.ZERO
var uses_revision=false
func setup(who:String,col:Color)->Dictionary:
 name="RealCharacter"
 position.y=.012
 var key={"Алина":"Alina","Круглик":"Kruglik","Крысюк":"Krysyuk"}[who]
 var asset="res://assets/characters/Refined_"+key+".glb"
 var revision=who=="Алина" and get_parent().get_parent().get_meta("alina_revision",false)
 uses_revision=revision
 if revision:asset="res://assets/characters/studies/AlinaRevision.glb"
 var native=load(asset).instantiate();add_child(native)
 if revision:load("res://scripts/alina_revision_materials.gd").apply(native)
 skeleton=native.find_children("*","Skeleton3D",true,false)[0]
 native_animation=native.find_children("*","AnimationPlayer",true,false)[0]
 for m in native.find_children("*","MeshInstance3D",true,false):
  if m.mesh.get_blend_shape_count()>0:face_meshes.append(m)
 motion_time={"Алина":0.0,"Круглик":1.37,"Крысюк":2.74}[who]
 blink_period={"Алина":4.6,"Круглик":5.2,"Крысюк":4.1}[who]
 nominal_walk_speed={"Алина":.6343,"Круглик":.7636,"Крысюк":.7812}[who]
 native_animation.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
 for clip in native_animation.get_animation_list():
  if clip in ["walk","idle","sit","eat"]:native_animation.get_animation(clip).loop_mode=Animation.LOOP_LINEAR
 for i in range(skeleton.get_bone_count()):
  var n=skeleton.get_bone_name(i);indices[n]=i;rest[n]=skeleton.get_bone_global_rest(i)
 head_anchor=attachment("Head");torso_anchor=attachment("spine_03")
 if revision:
  revision_mouth_local=rest.Head.affine_inverse()*Vector3(0,1.386,.102)
  head_anchor.set_meta("mouth_offset",revision_mouth_local)
 if who=="Круглик":
  var hat=Node3D.new();head_anchor.add_child(hat)
  var p=rest.Head.origin+Vector3(0,.145,-.01)
  hat.transform=rest.Head.affine_inverse()*Transform3D(Basis.IDENTITY,p)
  DemoVisual.sphere(hat,.098,Color("40534b"),Vector3.ZERO,Vector3(1,.42,1.15));DemoVisual.rounded_box(hat,Vector3(.18,.008,.105),Color("33473d"),Vector3(0,-.027,.085),.006)
 if who=="Крысюк":
  var glasses=Node3D.new();head_anchor.add_child(glasses)
  glasses.transform=rest.Head.affine_inverse()*Transform3D(Basis.IDENTITY,rest.Head.origin+Vector3(0,.041,.108))
  for sign in [-1,1]:
   for y in [-.014,.016]:DemoVisual.box(glasses,Vector3(.051,.003,.004),Color("29333a"),Vector3(sign*.032,y,0))
   for x in [sign*.007,sign*.058]:DemoVisual.box(glasses,Vector3(.003,.030,.004),Color("29333a"),Vector3(x,.001,0))
  DemoVisual.box(glasses,Vector3(.020,.003,.004),Color("29333a"),Vector3(0,.008,0))
 sit_weight=1 if who=="Алина" else 0
 return {"visual":self,"hips":self,"torso":torso_anchor,"head":head_anchor,"legs":[],"knees":[],"arms":[],"elbows":[],"skin":self}
func attachment(bone:String)->BoneAttachment3D:
 var node=BoneAttachment3D.new();skeleton.add_child(node);node.bone_name=bone;node.bone_idx=indices[bone];return node
func attach_hair(style:String,color:Color):
 var scene=load("res://assets/characters/"+style+".gltf").instantiate();add_child(scene)
 var mesh=scene.find_children("*","MeshInstance3D",true,false)[0]
 mesh.reparent(head_anchor,false);mesh.transform=rest.Head.affine_inverse();mesh.skin=null;mesh.skeleton=NodePath("")
 var mat=mesh.mesh.surface_get_material(0).duplicate();mat.albedo_color=color;mat.roughness=.9;mesh.material_override=mat
 scene.queue_free()
func global_pose(bone:String)->Transform3D:return skeleton.get_bone_global_pose(indices[bone])
func set_bone_global_basis(bone:String,basis:Basis):
 var idx=indices[bone];var parent=skeleton.get_bone_parent(idx)
 var local=basis if parent<0 else skeleton.get_bone_global_pose(parent).basis.inverse()*basis
 skeleton.set_bone_pose_rotation(idx,local.orthonormalized().get_rotation_quaternion())
func rotate_world(bone:String,axis:Vector3,angle:float):
 var pose=global_pose(bone);set_bone_global_basis(bone,Basis(axis,angle)*pose.basis)
func align_bone(bone:String,end:String,direction:Vector3):
 var current=global_pose(bone)
 var source=(global_pose(end).origin-current.origin).normalized()
 var q=Quaternion(source,direction.normalized())
 set_bone_global_basis(bone,Basis(q)*current.basis)
func solve_limb(a:String,b:String,c:String,target:Vector3,pole:Vector3):
 var origin=global_pose(a).origin
 var upper=rest[a].origin.distance_to(rest[b].origin);var lower=rest[b].origin.distance_to(rest[c].origin)
 var d=target-origin;var length=clampf(d.length(),absf(upper-lower)+.002,upper+lower-.004);var direction=d.normalized()
 var along=(length*length+upper*upper-lower*lower)/(2*length)
 var height=sqrt(maxf(upper*upper-along*along,0))
 var plane=(pole-direction*pole.dot(direction)).normalized()
 var middle=origin+direction*along+plane*height
 align_bone(a,b,middle-origin)
 var current=global_pose(b).origin
 align_bone(b,c,target-current)
func fit_finger(finger:String,target:Vector3,suffix:String="_l",pole_hint:Vector3=Vector3.ZERO):
 # Three phalanges, fixed bone lengths. Keep the initial curved solution as a pole.
 var names=[finger+"_01"+suffix,finger+"_02"+suffix,finger+"_03"+suffix,finger+"_04_leaf"+suffix]
 var points=[];var lengths=[]
 for n in names:points.append(global_pose(n).origin)
 var base:Vector3=points[0]
 for j in range(3):lengths.append(rest[names[j]].origin.distance_to(rest[names[j+1]].origin))
 var direction=(target-base).normalized()
 var outward=to_local(to_global(Vector3(0,0,1)))-to_local(global_position)
 if pole_hint.length_squared()>.01:outward=pole_hint.normalized()
 var pole=(outward-direction*outward.dot(direction)).normalized()
 var reach=lengths[0]+lengths[1]+lengths[2]
 var arc=clampf((reach-base.distance_to(target))*.55,.003,.025)
 for j in [1,2]:points[j]=base.lerp(target,j/3.0)+pole*arc
 for iteration in range(12):
  points[3]=target
  for j in [2,1,0]:points[j]=points[j+1]+(points[j]-points[j+1]).normalized()*lengths[j]
  points[0]=base
  for j in range(3):points[j+1]=points[j]+(points[j+1]-points[j]).normalized()*lengths[j]
 for j in range(3):align_bone(names[j],names[j+1],points[j+1]-points[j])
func set_bone_origin(bone:String,origin:Vector3):
 var i=indices[bone];var parent=skeleton.get_bone_parent(i)
 var local=origin if parent<0 else skeleton.get_bone_global_pose(parent).affine_inverse()*origin
 skeleton.set_bone_pose_position(i,local)
func tick(dt:float,moving:bool,speed:float,pose:String,guitar:Node3D,look:Vector3,clip_time:float=0):
 motion_time+=dt
 if pose=="getup":getup_elapsed=(0.0 if previous_pose!="getup" else getup_elapsed)+dt
 else:getup_elapsed=0.0
 pose_elapsed=(pose_elapsed+dt if previous_pose==pose else 0.0)
 previous_pose=pose
 reaction_weight=move_toward(reaction_weight,1.0 if pose in ["eat","cough","gag","spit"] else 0.0,dt*5)
 var rising=pose=="getup"
 var rise=smoothstep(0.0,.85,getup_elapsed)
 var next_shift=.42*smoothstep(.18,.80,getup_elapsed) if rising else 0.0
 frame_root_delta=next_shift-getup_shift if rising else 0.0
 getup_shift=next_shift
 blend=move_toward(blend,1 if moving else 0,dt*5)
 var seated=pose=="guitar" and not moving
 if seated:
  seat_elapsed=(seat_elapsed+dt if was_seated else 0.0)
 else:seat_elapsed=0.0
 was_seated=seated
 if not moving:foot_locked=[false,false];foot_weights=[0.0,0.0]
 sit_weight=move_toward(sit_weight,1 if seated else 0,dt*2.0)
 guitar_weight=move_toward(guitar_weight,1 if seated else 0,dt*3)
 walk_phase+=speed*dt/.92
 var cycle=walk_phase*TAU
 var clip="walk" if moving else ("sit_down" if seat_elapsed<.9 else "sit") if seated else pose if native_animation.has_animation(pose) else "idle"
 if clip!=current_native_clip:
  current_native_clip=clip;native_animation.play(clip,.22)
 native_animation.speed_scale=maxf(.15,speed/nominal_walk_speed) if moving else native_animation.get_animation("getup").length/.85 if clip=="getup" else 1.0
 native_animation.advance(dt)
 if guitar:
  guitar.position=Vector3(-.105,1.10-.355*sit_weight,.205)
  guitar.rotation=Vector3(-.07+sin(motion_time*1.1)*.002,0,-1.04+sin(motion_time*.8)*.002)
 var pelvis=global_pose("pelvis").origin
 if not moving:pelvis.z=rest.pelvis.origin.z;set_bone_origin("pelvis",pelvis)
 if seated:
  pelvis.y=lerpf(pelvis.y,.60,sit_weight)
  pelvis.z=lerpf(pelvis.z,rest.pelvis.origin.z,sit_weight);pelvis.x=lerpf(pelvis.x,0,sit_weight)
  set_bone_origin("pelvis",pelvis)
  set_bone_global_basis("pelvis",rest.pelvis.basis)
 elif rising:
  pelvis.y=lerpf(.60,rest.pelvis.origin.y,rise)
  pelvis.z=rest.pelvis.origin.z+sin(rise*PI)*.10;pelvis.x=0
  set_bone_origin("pelvis",pelvis)
 var gaze=to_local(look)-global_pose("Head").origin if look.length()>.1 else Vector3.ZERO
 var head_y=clampf(atan2(gaze.x,gaze.z),-.40,.40) if gaze.length()>.1 else sin(motion_time*.45)*.025
 rotate_world("neck_01",Vector3.UP,head_y*.3);rotate_world("Head",Vector3.UP,head_y*.7)
 if seated:rotate_world("Head",Vector3.RIGHT,.04)
 if pose in ["gag","cough","spit"]:
  rotate_world("spine_02",Vector3.RIGHT,(.10+.025*sin(pose_elapsed*12))*reaction_weight);rotate_world("Head",Vector3.RIGHT,.04*reaction_weight)
 ground_feet.clear()
 if seated or rising:
  for i in range(2):
   var suffix="_l" if i==0 else "_r";var sign=1 if i==0 else -1
   var foot=Vector3(sign*(.18 if i==0 else .16),rest["foot"+suffix].origin.y,.41 if i==0 else .46)
   if rising:
    var shuffle=smoothstep(.77,1.0,rise) if i==0 else smoothstep(.55,.76,rise)
    foot=foot.lerp(rest["foot"+suffix].origin+Vector3(0,0,.42),shuffle)-Vector3(0,0,getup_shift)
    foot.y+=sin(shuffle*PI)*.04
   solve_limb("thigh"+suffix,"calf"+suffix,"foot"+suffix,foot,Vector3(sign*.12,.1,1))
   set_bone_global_basis("foot"+suffix,rest["foot"+suffix].basis)
 elif pose=="kick":
  for i in range(2):
   var suffix="_l" if i==0 else "_r"
   var foot=rest["foot"+suffix].origin
   if i==0:
    var u=clampf(pose_elapsed/.6,0,1);var swing=sin(u*PI)
    foot+=Vector3(0,swing*.105,swing*.26-.055*sin(u*TAU))
   solve_limb("thigh"+suffix,"calf"+suffix,"foot"+suffix,foot,Vector3(.13 if i==0 else -.13,.04,1))
   set_bone_global_basis("foot"+suffix,rest["foot"+suffix].basis)
 elif moving:
  for i in range(2):
   var suffix="_l" if i==0 else "_r";var foot=global_pose("foot"+suffix).origin
   var foot_basis=global_pose("foot"+suffix).basis
   var floor_height=rest["foot"+suffix].origin.y
   var contact=foot.y<floor_height+.030
   if contact and not foot_locked[i]:
    foot_anchors[i]=to_global(Vector3(foot.x,floor_height,foot.z))
   foot_locked[i]=contact
   foot_weights[i]=move_toward(foot_weights[i],1.0 if contact else 0.0,dt*(22 if contact else 15))
   # Match cadence to measured stance speed, then stabilize planted feet in world space.
   foot.y=floor_height+maxf(0,foot.y-floor_height)*.62
   var anchor=to_local(foot_anchors[i])
   if foot_weights[i]>0:foot=foot.lerp(anchor,foot_weights[i])
   solve_limb("thigh"+suffix,"calf"+suffix,"foot"+suffix,foot,Vector3(.08 if i==0 else -.08,.05,1))
   set_bone_global_basis("foot"+suffix,foot_basis)
 else:
  foot_locked=[false,false];foot_weights=[0.0,0.0]
 for suffix in ["_l","_r"]:ground_feet.append(global_pose("foot"+suffix).origin)
 arm_error=0;guitar_elbows.clear()
 for i in range(2):
  var suffix="_l" if i==0 else "_r";var sign=1 if i==0 else -1
  var shoulder=global_pose("upperarm"+suffix).origin
  var target=global_pose("hand"+suffix).origin
  if guitar and guitar_weight>0:
   var point=Vector3(.062,.586,.071) if i==0 else Vector3(-.015+sin(motion_time*5.5)*.030,.145+cos(motion_time*5.5)*.008,.087)
   if uses_revision:point=Vector3(.062,.550,.022) if i==0 else Vector3(-.084+sin(motion_time*5.5)*.015,.106+cos(motion_time*5.5)*.003,.132)
   var desired=to_local(guitar.to_global(point))
   target=target.lerp(desired,guitar_weight)
  if reaction_weight>0 and i==1:
   var mouth_target=global_pose("Head").origin+Vector3(-.015,.035,.14)
   if uses_revision:mouth_target=global_pose("Head")*revision_mouth_local+Vector3(-.015,.025,.035)
   target=target.lerp(mouth_target,reaction_weight)
  if pose in ["happy","wave"] and i==0:target=shoulder+Vector3(.21,.27,.10+sin(motion_time*8)*.06)
  var elbow_pole=Vector3(sign,.05,-.35)
  if guitar:elbow_pole=elbow_pole.lerp(Vector3(.25,-1,.25) if i==0 else Vector3(-.65,.10,-.10),guitar_weight)
  if guitar_weight>0 or reaction_weight>0 or pose=="kick":solve_limb("upperarm"+suffix,"lowerarm"+suffix,"hand"+suffix,target,elbow_pole)
  if seated:guitar_elbows.append(global_pose("lowerarm"+suffix).origin)
  if guitar and guitar_weight>0:
   # Fingers cross the strings, while the palm faces the neck/soundboard.
   var finger_direction=(to_local(guitar.to_global(Vector3(1,0,0)))-to_local(guitar.global_position)).normalized()
   var palm_normal=(to_local(guitar.to_global(Vector3(0,0,-1)))-to_local(guitar.global_position)).normalized()
   var palm_long=(rest["middle_01"+suffix].origin-rest["hand"+suffix].origin).normalized()
   var palm_width=(rest["index_01"+suffix].origin-rest["pinky_01"+suffix].origin).normalized()
   var source_normal=palm_long.cross(palm_width).normalized()
   var normal_hint=rest["hand"+suffix].basis.x*(1 if i==0 else -1)
   if source_normal.dot(normal_hint)<0:source_normal=-source_normal
   var source_frame=Basis(source_normal,palm_long,source_normal.cross(palm_long)).orthonormalized()
   var direction=-finger_direction if i==0 else finger_direction
   var desired_frame=Basis(palm_normal,direction,palm_normal.cross(direction)).orthonormalized()
   if uses_revision and i==0:
    var forward=(to_local(guitar.to_global(Vector3(0,0,1)))-to_local(guitar.global_position)).normalized()
    direction=(-finger_direction*.55+forward*.84).normalized()
    palm_normal=(-forward*.55-finger_direction*.84).normalized()
    desired_frame=Basis(palm_normal,direction,palm_normal.cross(direction)).orthonormalized()
   var wrist_basis=desired_frame*source_frame.inverse()*rest["hand"+suffix].basis
   if i==1:wrist_basis=Basis(-palm_normal,-.045+sin(motion_time*5.5)*.04)*wrist_basis
   # Share axial rotation with the forearm; avoid concentrating all twist at the wrist.
   var forearm_axis=(global_pose("hand"+suffix).origin-global_pose("lowerarm"+suffix).origin).normalized()
   var current_axis=global_pose("lowerarm"+suffix).basis.x
   current_axis=(current_axis-forearm_axis*current_axis.dot(forearm_axis)).normalized()
   var desired_axis=wrist_basis.x
   desired_axis=(desired_axis-forearm_axis*desired_axis.dot(forearm_axis)).normalized()
   var twist=atan2(forearm_axis.dot(current_axis.cross(desired_axis)),current_axis.dot(desired_axis))
   rotate_world("lowerarm"+suffix,forearm_axis,twist*.75*guitar_weight)
   var neutral=global_pose("hand"+suffix).basis.get_rotation_quaternion()
   var playing=wrist_basis.get_rotation_quaternion()
   set_bone_global_basis("hand"+suffix,Basis(neutral.slerp(playing,guitar_weight)))
  if guitar and guitar_weight>.98:arm_error=maxf(arm_error,global_pose("hand"+suffix).origin.distance_to(target))
  # Finger curl gives the resting hand a relaxed shape and wraps around the guitar neck.
  for finger in (["thumb","index","middle","ring","pinky"] if uses_revision else ["index","middle","ring","pinky"]):
   for j in [1,2,3]:
    var bone=finger+"_0"+str(j)+suffix
    var idx=indices.get(bone,-1)
    if idx>=0:
     var q=skeleton.get_bone_pose_rotation(idx)
     var curl=0.0
     if guitar and guitar_weight>0:
      var relaxed=curl
      if uses_revision:curl=[.18,.32,.20][j-1] if i==1 else [.35,.50,.20][j-1]
      else:
       var f=["index","middle","ring","pinky"].find(finger)
       if i==0:curl=[.79,.82,.85,.73][f] if j==1 else [.62,.65,.68,.60][f]
       else:curl=[.20,.27,.34,.39][f] if j==1 else (.30 if j==2 else .18)
      curl=lerpf(relaxed,curl,guitar_weight)
     if uses_revision and guitar and guitar_weight>0:
      var parent=skeleton.get_bone_parent(idx)
      var local_rest=rest[bone].basis
      if parent>=0:local_rest=rest[skeleton.get_bone_name(parent)].basis.inverse()*local_rest
      var playing=local_rest.get_rotation_quaternion()*Quaternion(Vector3.RIGHT,curl)
      skeleton.set_bone_pose_rotation(idx,q.slerp(playing,guitar_weight))
     else:skeleton.set_bone_pose_rotation(idx,q*Quaternion(Vector3.RIGHT,curl))
 if guitar and guitar_weight>0 and uses_revision:
  var front=(to_local(guitar.to_global(Vector3(0,0,1)))-to_local(guitar.global_position)).normalized()
  # Two stopped strings form E minor; the remaining fingers are relaxed.
  for entry in [["index",.0,.596,.087],["middle",-.010,.568,.064],["ring",-.003,.559,.064],["pinky",.014,.521,.093]]:
   var point=Vector3(entry[1],entry[2],entry[3])
   var bone=entry[0]+"_04_leaf_l"
   fit_finger(entry[0],global_pose(bone).origin.lerp(to_local(guitar.to_global(point)),guitar_weight),"_l",front)
  var thumb_target=to_local(guitar.to_global(Vector3(.003,.552,.024)))
  var thumb_pole=(to_local(guitar.to_global(Vector3(.35,0,-1)))-to_local(guitar.global_position)).normalized()
  fit_finger("thumb",global_pose("thumb_04_leaf_l").origin.lerp(thumb_target,guitar_weight),"_l",thumb_pole)
  # The nail of the index finger sweeps the strings; no invisible pick is used.
  var stroke=sin(motion_time*5.5)
  var picking=to_local(guitar.to_global(Vector3(stroke*.024,.100,.062+pow(absf(stroke),6)*.007)))
  fit_finger("index",global_pose("index_04_leaf_r").origin.lerp(picking,guitar_weight),"_r",front)
 if guitar and guitar_weight>0 and not uses_revision:
  # Distinct string contacts: fingertips form an arch rather than a closed fist.
  var fingers=["index","middle","ring","pinky"]
  for f in range(4):
   var root_point=guitar.to_local(to_global(global_pose(fingers[f]+"_01_l").origin))
   var release=pow(maxf(0,sin(motion_time*1.7+f*.22)),12)*.007
   var contact=Vector3([-.007,.008,.017,.021][f],root_point.y+[.006,.010,-.003,-.008][f],.065+release)
   var neutral_tip=global_pose(fingers[f]+"_04_leaf_l").origin
   fit_finger(fingers[f],neutral_tip.lerp(to_local(guitar.to_global(contact)),guitar_weight))
  var thumb_base=to_local(guitar.to_global(Vector3(.040,.617,.034)))
  thumb_base=global_pose("thumb_03_l").origin.lerp(thumb_base,guitar_weight)
  solve_limb("thumb_01_l","thumb_02_l","thumb_03_l",thumb_base,Vector3(0,-.1,0))
  var tip=to_local(guitar.to_global(Vector3(.027,.616,.018)))
  tip=global_pose("thumb_04_leaf_l").origin.lerp(tip,guitar_weight)
  align_bone("thumb_03_l","thumb_04_leaf_l",tip-global_pose("thumb_03_l").origin)
 skeleton.force_update_all_bone_transforms()
 var blink_phase=fposmod(motion_time,blink_period)
 var blink=sin(blink_phase/.17*PI) if blink_phase<.17 else 0.0
 for mesh in face_meshes:
  for i in range(mesh.mesh.get_blend_shape_count()):
   var name=mesh.mesh.get_blend_shape_name(i)
   var value=blink if name in ["eyeBlinkLeft","eyeBlinkRight"] else .26 if pose=="happy" and name in ["mouthSmileLeft","mouthSmileRight"] else (.075*(.5+.5*sin(motion_time*8)) if pose=="eat" else .18*reaction_weight) if pose in ["eat","cough","gag","spit"] and name=="jawOpen" else 0.0
   mesh.set_blend_shape_value(i,value)
