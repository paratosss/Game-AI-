extends SceneTree
var failures=0
func check(ok:bool,label:String):
 if not ok:failures+=1;push_error(label)
func _initialize():call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate();root.add_child(game)
 await create_timer(.1).timeout;game.initialized=false
 for actor in game.actors:actor.set_physics_process(false)
 var alina=game.actors[0];var guitar=alina.guitar;var skin=alina.model.skin
 for i in range(120):skin.tick(1./60,false,0,"guitar",guitar,Vector3.ZERO)
 var neck=guitar.global_basis.y.normalized()
 check(neck.dot(alina.global_basis.x)>.8,"Guitar neck points towards the player's anatomical left")
 check(neck.dot(Vector3.UP)>.20 and neck.dot(Vector3.UP)<.55,"Guitar neck has a moderate upward angle")
 check(guitar.position.x<-.05,"Guitar body sits over right thigh")
 check(guitar.position.y>.70 and guitar.position.y<.78,"Seated guitar height")
 for i in range(120):
  skin.tick(1./60,false,0,"guitar",guitar,Vector3.ZERO)
  # Anatomical surface normal from wrist/MCP locations; the new rig's local
  # bone X axis is not the old model's palm normal.
  var long=(skin.global_pose("middle_01_r").origin-skin.global_pose("hand_r").origin).normalized()
  var width=(skin.global_pose("index_01_r").origin-skin.global_pose("pinky_01_r").origin).normalized()
  var palm=-(skin.global_transform.basis*long.cross(width)).normalized()
  check(palm.dot(-guitar.global_basis.z.normalized())>.90,"Right palm faces the guitar throughout the strum")
  var grip=guitar.to_local(skin.to_global(skin.global_pose("hand_l").origin))
  check(grip.x>.04,"Fretting wrist stays below the neck, with an underhand grip")
  check(skin.arm_error<.02,"Both wrist targets remain reachable across a strum cycle")
  check(skin.guitar_elbows[0].y<skin.global_pose("upperarm_l").origin.y,"Fretting elbow stays below shoulder")
 for finger in ["index_04_leaf_l","middle_04_leaf_l","ring_04_leaf_l"]:
   var local=guitar.to_local(skin.to_global(skin.global_pose(finger).origin))
   check(absf(local.x)<.035,"Fretting fingers stay inside neck width")
   check(local.z>.045 and local.z<.085,"Fretting fingertips stay near the front surface")
 var thumb=guitar.to_local(skin.to_global(skin.global_pose("thumb_04_leaf_l").origin))
 check(thumb.z<.035,"Fretting thumb supports the back/side of the neck")
 for phase in ["idle","guitar","walk","guitar"]:
  for frame in range(60):
   skin.tick(1./60,phase=="walk",1.4 if phase=="walk" else 0,phase,guitar,Vector3.ZERO)
   for bone in ["hand_l","hand_r","foot_l","foot_r"]:
    var b=skin.global_pose(bone)
    check(b.origin.is_finite() and b.basis.is_finite(),"Finite limb transforms during pose transitions")
 var mesh=DemoVisual.rounded_geometry(Vector3(.09,.06,.10),.014);var arrays=mesh.surface_get_arrays(0);var vertices=arrays[Mesh.ARRAY_VERTEX];var normals=arrays[Mesh.ARRAY_NORMAL];var indices=arrays[Mesh.ARRAY_INDEX]
 for i in range(0,indices.size(),3):
  var a=indices[i];var b=indices[i+1];var c=indices[i+2]
  var cross=(vertices[b]-vertices[a]).cross(vertices[c]-vertices[a])
  if cross.length_squared()>.000000001:check(cross.dot(normals[a]+normals[b]+normals[c])<0,"Rounded mesh front faces use clockwise winding")
 print("HERO_VALIDATION_04_", "PASS" if failures==0 else "FAIL"," failures=",failures)
 game.clean_quit(0 if failures==0 else 1)
