extends SceneTree
## Sample actual deformed hand vertices as well as joints: wrist-only checks
## previously missed fingers passing through the soundboard.
var failures=[]
var skin:DemoHumanSkin
var guitar:Node3D
var body:MeshInstance3D
var samples=[]
func check(ok:bool,label:String):
 if not ok and label not in failures:failures.append(label)
func _initialize():call_deferred("run")
func prepare_samples():
 body=skin.find_children("Human","MeshInstance3D",true,false)[0]
 for surface in range(body.mesh.get_surface_count()):
  var arrays=body.mesh.surface_get_arrays(surface);var vertices=arrays[Mesh.ARRAY_VERTEX];var weights=arrays[Mesh.ARRAY_WEIGHTS];var bones=arrays[Mesh.ARRAY_BONES]
  var stride=weights.size()/vertices.size()
  for vertex in range(vertices.size()):
   var total=0.0;var influences=[]
   for j in range(stride):
    var index=vertex*stride+j;var weight=weights[index]
    if weight<=0:continue
    var bind=bones[index];var name=str(body.skin.get_bind_name(bind))
    influences.append([skin.indices[name],body.skin.get_bind_pose(bind)*vertices[vertex],weight])
    if name.ends_with("_r") and (name.begins_with("hand") or name.contains("thumb") or name.contains("index") or name.contains("middle") or name.contains("ring") or name.contains("pinky")):total+=weight
   if total>.98:samples.append(influences)
func run():
 var stage=Node3D.new();stage.set_meta("alina_revision",true);root.add_child(stage)
 var actor=Node3D.new();stage.add_child(actor)
 skin=DemoHumanSkin.new();actor.add_child(skin);skin.setup("Алина",Color.WHITE)
 guitar=load("res://scripts/guitar_quality.gd").build(skin)
 prepare_samples();check(samples.size()>100,"Actual weighted hand vertices must be sampled")
 var string=guitar.get_node("String0");var nut=string.position+string.basis.y*string.mesh.height*.5;var saddle=string.position-string.basis.y*string.mesh.height*.5
 check(absf(absf(nut.y-saddle.y)-.648)<.0001,"String has an actual 648 mm scale")
 check(absf(guitar.get_node("Fret12").position.y-(nut.y+saddle.y)*.5)<.0001,"Twelfth fret bisects the actual string")
 var min_mesh_z=INF;var min_string_gap=INF;var max_arm_error=0.0;var max_stopped_error=0.0;var visited=0
 for i in range(120):skin.tick(1.0/60.0,false,0,"guitar",guitar,Vector3.ZERO)
 for frame in range(144):
  skin.tick(1.0/60.0,false,0,"guitar",guitar,Vector3.ZERO)
  max_arm_error=maxf(max_arm_error,skin.arm_error)
  for entry in [["middle",-.010,.568],["ring",-.003,.559]]:
   var tip=guitar.to_local(skin.to_global(skin.global_pose(entry[0]+"_04_leaf_l").origin))
   max_stopped_error=maxf(max_stopped_error,tip.distance_to(Vector3(entry[1],entry[2],.064)))
   check(tip.y>guitar.get_node("Fret02").position.y and tip.y<guitar.get_node("Fret01").position.y,"E minor fingers stop the second fret from the nut side")
  if frame%6!=0:continue
  var poses=[]
  for bone in range(skin.skeleton.get_bone_count()):poses.append(skin.skeleton.get_bone_global_pose(bone))
  for influences in samples:
   var point=Vector3.ZERO
   for influence in influences:point+=(poses[influence[0]]*influence[1])*influence[2]
   point=guitar.to_local(skin.skeleton.to_global(point))
   if Geometry2D.is_point_in_polygon(Vector2(point.x,point.y),guitar.get_meta("outline")):
    min_mesh_z=minf(min_mesh_z,point.z);visited+=1
    if absf(point.x)<.022 and absf(point.y-.100)<.050:min_string_gap=minf(min_string_gap,point.z-load("res://scripts/guitar_quality.gd").string_z_at(point.y))
 check(visited>1000,"Right hand is actually measured over the instrument")
 check(min_mesh_z>=.047,"Deformed right hand stays in front of the soundboard")
 check(min_string_gap>=-.002,"Deformed right hand avoids deep string penetration")
 check(min_string_gap<=.0015,"Strumming finger actually reaches the strings")
 check(max_stopped_error<.002,"Stopped fingers remain reachable without stretching")
 check(max_arm_error<.020,"Both wrists remain reachable over multiple strums")
 # Bone lengths must survive all pose transitions without scaling.
 var max_length_error=0.0
 for phase in ["idle","guitar","walk","guitar"]:
  for frame in range(45):
   skin.tick(1.0/60.0,phase=="walk",1.4 if phase=="walk" else 0,phase,guitar,Vector3.ZERO)
   for side in ["_l","_r"]:
    for finger in ["thumb","index","middle","ring","pinky"]:
     var names=[finger+"_01"+side,finger+"_02"+side,finger+"_03"+side,finger+"_04_leaf"+side]
     for j in range(3):
      var length=skin.global_pose(names[j]).origin.distance_to(skin.global_pose(names[j+1]).origin)
      max_length_error=maxf(max_length_error,absf(length-skin.rest[names[j]].origin.distance_to(skin.rest[names[j+1]].origin)))
 check(max_length_error<.00005,"Finger bones retain their lengths in transitions")
 var report={"status":"PASS" if failures.is_empty() else "FAIL","failures":failures,"sampled_hand_vertices":samples.size(),"sampled_poses":24,"right_hand_min_soundboard_z_m":min_mesh_z,"right_hand_min_string_gap_m":min_string_gap,"max_wrist_error_m":max_arm_error,"max_stopped_finger_error_m":max_stopped_error,"max_finger_length_error_m":max_length_error}
 print(JSON.stringify(report,"  "))
 var path=OS.get_environment("SHASHLIK_CONTACT_REPORT")
 if not path.is_empty():
  var file=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "))
 print("GUITAR_CONTACTS_05_",report.status," failures=",failures.size())
 quit(0 if failures.is_empty() else 1)
