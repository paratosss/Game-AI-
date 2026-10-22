extends SceneTree
## Independent measurements of the skinned garment, arm and actual prop envelope.
## These bounds detect contact/transition regressions; they do not grade artistry.
var skin:DemoHumanSkin
var guitar:Node3D
var groups={"garment":[],"thigh":[],"forearm":[]}
var failures=[]
var outline:PackedVector2Array
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 if not ok and label not in failures:failures.append(label)
func prepare():
 for mesh in skin.find_children("*","MeshInstance3D",true,false):
  var garment="female_casualsuit" in str(mesh.name)
  if not garment and mesh.name!="Human":continue
  for surface in range(mesh.mesh.get_surface_count()):
   var arrays=mesh.mesh.surface_get_arrays(surface)
   var vertices=arrays[Mesh.ARRAY_VERTEX];var weights=arrays[Mesh.ARRAY_WEIGHTS];var bones=arrays[Mesh.ARRAY_BONES]
   var stride=weights.size()/vertices.size()
   for vertex in range(vertices.size()):
    var influences=[];var thigh=0.0;var forearm=0.0
    for j in range(stride):
     var idx=vertex*stride+j;var weight=weights[idx]
     if weight<=0:continue
     var bind=bones[idx];var name=str(mesh.skin.get_bind_name(bind))
     influences.append([skin.indices[name],mesh.skin.get_bind_pose(bind)*vertices[vertex],weight])
     if name=="thigh_r":thigh+=weight
     if name in ["lowerarm_r","forearm_twist_mid_r","forearm_twist_end_r"]:forearm+=weight
    if garment:groups.garment.append(influences)
    if garment and thigh>.65:groups.thigh.append(influences)
    if not garment and forearm>.85:groups.forearm.append(influences)
func distance_to_body(point:Vector3)->float:
 var xy=Vector2(point.x,point.y);var edge=INF
 for j in range(outline.size()):edge=minf(edge,xy.distance_to(Geometry2D.get_closest_point_to_segment(xy,outline[j],outline[(j+1)%outline.size()])))
 if Geometry2D.is_point_in_polygon(xy,outline):edge=-edge
 var depth=absf(point.z-.0005)-.0475
 return Vector2(maxf(edge,0),maxf(depth,0)).length()+minf(maxf(edge,depth),0)
func snapshot()->Dictionary:
 var result={}
 for name in ["Head","neck_01","spine_03","hand_l","hand_r","index_01_l","index_02_l","index_03_l","middle_01_l","ring_01_l"]:result[name]=skin.global_pose(name)
 result.guitar=guitar.transform
 return result
func run():
 var stage=Node3D.new();stage.set_meta("alina_revision",true);root.add_child(stage)
 var actor=Node3D.new();stage.add_child(actor)
 skin=DemoHumanSkin.new();actor.add_child(skin);skin.setup("Алина",Color.WHITE)
 guitar=load("res://scripts/guitar_quality.gd").build(skin);outline=guitar.get_meta("outline")
 prepare()
 check(groups.thigh.size()>100 and groups.forearm.size()>100,"Actual skinned thigh and forearm must be sampled")
 for i in range(120):skin.tick(1./60,false,0,"guitar",guitar,Vector3.ZERO)
 check(guitar.get_meta("posture_version",0)==8,"The revised posture driver actually ran")
 var penetration_detail={};var min_forearm=INF;var min_garment=INF;var max_support_gap=0.0;var max_arm_gap=0.0;var wrist=[0.0,0.0];var max_pip=0.0;var max_dip=0.0
 for frame in range(120):
  skin.tick(1./60,false,0,"guitar",guitar,Vector3.ZERO)
  for side in ["_l","_r"]:
   var i=0 if side=="_l" else 1
   var forearm=skin.global_pose("hand"+side).origin-skin.global_pose("lowerarm"+side).origin
   var palm=skin.global_pose("middle_01"+side).origin-skin.global_pose("hand"+side).origin
   wrist[i]=maxf(wrist[i],rad_to_deg(forearm.angle_to(palm)))
   for finger in (["index","middle","ring","pinky"] if i==0 else ["index"]):
    var p=[]
    for level in ["01","02","03","04_leaf"]:p.append(skin.global_pose(finger+"_"+level+side).origin)
    max_pip=maxf(max_pip,rad_to_deg((p[1]-p[0]).angle_to(p[2]-p[1])))
    max_dip=maxf(max_dip,rad_to_deg((p[2]-p[1]).angle_to(p[3]-p[2])))
  if frame%30!=0:continue
  var poses=[]
  for bone in range(skin.skeleton.get_bone_count()):poses.append(skin.skeleton.get_bone_global_pose(bone))
  var support_gap=INF;var arm_gap=INF
  for name in groups:
   for influences in groups[name]:
    var point=Vector3.ZERO
    for influence in influences:point+=(poses[influence[0]]*influence[1])*influence[2]
    point=guitar.to_local(skin.skeleton.to_global(point))
    var distance=distance_to_body(point)
    if name=="garment" and distance<min_garment:
     min_garment=distance
     penetration_detail={"point":str(point),"influences":influences.map(func(v):return [skin.skeleton.get_bone_name(v[0]),v[2]])}
    if name=="thigh":support_gap=minf(support_gap,absf(distance))
    if name=="forearm":
     arm_gap=minf(arm_gap,absf(distance));min_forearm=minf(min_forearm,distance)
  max_support_gap=maxf(max_support_gap,support_gap);max_arm_gap=maxf(max_arm_gap,arm_gap)
 check(min_garment>=-.003,"Garment avoids penetration deeper than 3 mm into the instrument envelope")
 check(max_support_gap<.006,"Skinned thigh reaches the instrument envelope within 6 mm")
 check(min_forearm>=-.003,"Right forearm avoids penetration deeper than 3 mm")
 check(max_arm_gap<.015,"Right forearm reaches the instrument within 15 mm")
 check(wrist[0]<60 and wrist[1]<40,"Wrist bends stay within a moderate working range")
 check(max_pip<115 and max_dip<85,"Playing fingers avoid extreme interphalangeal folds")
 var worst_angle="";var max_step=0.0;var max_angle=0.0;var worst="";var last=snapshot()
 for entry in [["getup",60],["idle",60],["walk",60],["idle",30],["guitar",120]]:
  for frame in range(entry[1]):
   skin.tick(1./60,entry[0]=="walk",1.4 if entry[0]=="walk" else 0,entry[0],guitar,Vector3.ZERO)
   var current=snapshot()
   for name in current:
    var t:Transform3D=current[name];var previous:Transform3D=last[name]
    check(t.origin.is_finite() and t.basis.is_finite(),"Finite poses in seated/getup/walk/return sequence")
    var step=t.origin.distance_to(previous.origin)
    if step>max_step:max_step=step;worst=entry[0]+"/"+name+"/"+str(frame)
    var angle=t.basis.get_rotation_quaternion().angle_to(previous.basis.get_rotation_quaternion())
    if angle>max_angle:max_angle=angle;worst_angle=entry[0]+"/"+name+"/"+str(frame)
    if step>.065:print("TRANSITION_STEP ",entry[0]," ",frame," ",name," m=",step," weight=",skin.guitar_weight)
   last=current
 check(max_step<.065,"Pose transitions avoid single-frame translations over 65 mm")
 check(max_angle<.65,"Pose transitions avoid single-frame bone turns over 37 degrees")
 # A newly supplied look target must produce a gradual, finite head turn.
 var head_before=skin.global_pose("Head").basis.get_rotation_quaternion()
 var head_last=head_before;var look_step=0.0
 for frame in range(90):
  skin.tick(1./60,false,0,"guitar",guitar,skin.to_global(Vector3(-1.0,1.35,2.0)))
  var head_now=skin.global_pose("Head").basis.get_rotation_quaternion()
  look_step=maxf(look_step,head_last.angle_to(head_now));head_last=head_now
 check(head_before.angle_to(head_last)>.15 and look_step<.12,"Head follows a supplied gaze target without an instant turn")
 var report={"status":"PASS" if failures.is_empty() else "FAIL","failures":failures,"sample_counts":{},"minimum_garment_envelope_distance_m":min_garment,"penetration_detail":penetration_detail,"worst_turn":worst_angle,"maximum_thigh_support_gap_m":max_support_gap,"maximum_forearm_contact_gap_m":max_arm_gap,"minimum_forearm_envelope_distance_m":min_forearm,"maximum_wrist_bends_deg":wrist,"maximum_PIP_deg":max_pip,"maximum_DIP_deg":max_dip,"maximum_transition_step_m":max_step,"worst_transition":worst,"maximum_transition_turn_rad":max_angle,"maximum_gaze_step_rad":look_step}
 for name in groups:report.sample_counts[name]=groups[name].size()
 print(JSON.stringify(report,"  "))
 var path=OS.get_environment("SHASHLIK_POSTURE_REPORT")
 if not path.is_empty():FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
 print("POSTURE_CONTACTS_08_",report.status)
 quit(0 if failures.is_empty() else 1)
