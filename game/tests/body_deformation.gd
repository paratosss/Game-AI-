extends SceneTree
## Measure the deformed forearm cross-section, beyond joint target reach.
var failures=[]
func check(ok:bool,label:String):
 if not ok and label not in failures:failures.append(label)
func _initialize():call_deferred("run")
func run():
 var stage=Node3D.new();stage.set_meta("alina_revision",true);root.add_child(stage)
 var actor=Node3D.new();stage.add_child(actor)
 var skin=DemoHumanSkin.new();actor.add_child(skin);skin.setup("Алина",Color.WHITE)
 var guitar=load("res://scripts/guitar_quality.gd").build(skin)
 var body=skin.find_children("Human","MeshInstance3D",true,false)[0]
 check(body.get_meta("body_revision",0)==6 and skin.skeleton.get_bone_count()==67,"Actual revised body and auxiliary bones are loaded")
 var samples=[]
 for surface in range(body.mesh.get_surface_count()):
  var arrays=body.mesh.surface_get_arrays(surface);var vertices=arrays[Mesh.ARRAY_VERTEX];var weights=arrays[Mesh.ARRAY_WEIGHTS];var bones=arrays[Mesh.ARRAY_BONES];var stride=weights.size()/vertices.size()
  check(stride==8,"Five-influence forearm bindings must retain the eight-weight format")
  for i in range(vertices.size()):
   var totals={"l":0.0,"r":0.0};var influences=[]
   for j in range(stride):
    var weight=weights[i*stride+j]
    if weight<=0:continue
    var bind=bones[i*stride+j];var name=str(body.skin.get_bind_name(bind))
    influences.append([skin.indices[name],body.skin.get_bind_pose(bind)*vertices[i],weight])
    for side in ["l","r"]:
     if name=="lowerarm_"+side or name.begins_with("forearm_twist_") and name.ends_with("_"+side):totals[side]+=weight
   for side in ["l","r"]:
    if totals[side]<.98:continue
    var elbow=skin.rest["lowerarm_"+side].origin;var wrist=skin.rest["hand_"+side].origin;var axis=(wrist-elbow).normalized()
    var rest_point=Vector3.ZERO
    for influence in influences:rest_point+=(skin.skeleton.get_bone_global_rest(influence[0])*influence[1])*influence[2]
    var t=(rest_point-elbow).dot(axis)/elbow.distance_to(wrist)
    var radius=(rest_point-elbow-axis*(rest_point-elbow).dot(axis)).length()
    if t>.10 and t<.95 and radius>.004:samples.append([side,radius,influences])
 check(samples.size()>1000,"Sample actual forearm surface vertices")
 for i in range(120):skin.tick(1.0/60.0,false,0,"guitar",guitar,Vector3.ZERO)
 var min_radius_ratio=INF;var max_radius_ratio=0.0;var max_branch_origin_error=0.0;var max_roll_mismatch=0.0;var maximum_applied_roll=0.0
 for frame in range(120):
  skin.tick(1.0/60.0,false,0,"guitar",guitar,Vector3.ZERO)
  if frame%10!=0:continue
  var poses=[]
  for i in range(skin.skeleton.get_bone_count()):poses.append(skin.skeleton.get_bone_global_pose(i))
  for side in ["l","r"]:
   for level in ["mid","end"]:max_branch_origin_error=maxf(max_branch_origin_error,skin.global_pose("forearm_twist_"+level+"_"+side).origin.distance_to(skin.global_pose("lowerarm_"+side).origin))
   var axis=(skin.global_pose("hand_"+side).origin-skin.global_pose("lowerarm_"+side).origin).normalized()
   var lower=skin.global_pose("lowerarm_"+side).basis.x;lower=(lower-axis*lower.dot(axis)).normalized()
   var end=skin.global_pose("forearm_twist_end_"+side).basis.x;end=(end-axis*end.dot(axis)).normalized()
   var hand=skin.global_pose("hand_"+side).basis.x;hand=(hand-axis*hand.dot(axis)).normalized()
   max_roll_mismatch=maxf(max_roll_mismatch,end.angle_to(hand));maximum_applied_roll=maxf(maximum_applied_roll,lower.angle_to(end))
  for sample in samples:
   var point=Vector3.ZERO
   for influence in sample[2]:point+=(poses[influence[0]]*influence[1])*influence[2]
   var elbow=skin.global_pose("lowerarm_"+sample[0]).origin;var axis=(skin.global_pose("hand_"+sample[0]).origin-elbow).normalized()
   var radius=(point-elbow-axis*(point-elbow).dot(axis)).length();var ratio=radius/sample[1]
   min_radius_ratio=minf(min_radius_ratio,ratio);max_radius_ratio=maxf(max_radius_ratio,ratio)
 check(min_radius_ratio>.70 and max_radius_ratio<1.15,"Forearm axial roll preserves most of the actual radial volume")
 check(max_branch_origin_error<.00002,"Auxiliary roll does not detach the arm surface from the elbow")
 check(max_roll_mismatch<.01 and maximum_applied_roll>.20,"Forearm surface actually rolls towards the wrist instead of leaving the helpers inactive")
 for pose in ["idle","guitar","eat","walk","guitar"]:
  for i in range(45):
   skin.tick(1.0/60.0,pose=="walk",1.4 if pose=="walk" else 0,pose,guitar,Vector3.ZERO)
   for bone in range(skin.skeleton.get_bone_count()):
    var p=skin.skeleton.get_bone_global_pose(bone);check(p.origin.is_finite() and p.basis.is_finite(),"All original and auxiliary bones remain finite in transitions")
 var report={"status":"PASS" if failures.is_empty() else "FAIL","failures":failures,"forearm_vertices":samples.size(),"sampled_poses":12,"minimum_radius_ratio":min_radius_ratio,"maximum_radius_ratio":max_radius_ratio,"maximum_branch_origin_error_m":max_branch_origin_error,"maximum_wrist_roll_mismatch_rad":max_roll_mismatch,"maximum_applied_roll_rad":maximum_applied_roll,"limitation":"Forearm shaft volume only; elbow anatomy, cloth intersections and naturalness require separate visual review."}
 print(JSON.stringify(report,"  "))
 var path=OS.get_environment("SHASHLIK_BODY_REPORT")
 if not path.is_empty():
  var file=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "))
 print("BODY_DEFORMATION_06_",report.status," failures=",failures.size());quit(0 if failures.is_empty() else 1)
