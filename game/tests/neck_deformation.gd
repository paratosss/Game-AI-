extends SceneTree
## Export actual animated bone transforms and facial channels for the independent
## GLB surface collision audit. No mesh edits or dummy-renderer blend-array reads.
var skin:DemoHumanSkin
var guitar:Node3D
var cases=[]
func _initialize():call_deferred("run")
func transform_array(t:Transform3D):
 return [[t.basis.x.x,t.basis.x.y,t.basis.x.z],[t.basis.y.x,t.basis.y.y,t.basis.y.z],[t.basis.z.x,t.basis.z.y,t.basis.z.z],[t.origin.x,t.origin.y,t.origin.z]]
func snapshot(label:String):
 var bones={}
 for i in range(skin.skeleton.get_bone_count()):bones[skin.skeleton.get_bone_name(i)]=transform_array(skin.skeleton.get_bone_global_pose(i))
 var mesh=skin.find_children("AlinaRevisionHead","MeshInstance3D",true,false)[0]
 var morphs={}
 for i in range(mesh.mesh.get_blend_shape_count()):
  var value=mesh.get_blend_shape_value(i)
  if absf(value)>1e-8:morphs[mesh.mesh.get_blend_shape_name(i)]=value
 cases.append({"name":label,"bones":bones,"morphs":morphs})
func run():
 var path=OS.get_environment("SHASHLIK_NECK_POSES")
 if path.is_empty():push_error("SHASHLIK_NECK_POSES is required");quit(1);return
 var stage=Node3D.new();stage.set_meta("alina_revision",true);root.add_child(stage)
 var actor=Node3D.new();stage.add_child(actor)
 skin=DemoHumanSkin.new();actor.add_child(skin);skin.setup("Алина",Color.WHITE)
 var head=skin.find_children("AlinaRevisionHead","MeshInstance3D",true,false)[0]
 if not skin.uses_neck or head.get_meta("neck_revision",0)!=11:push_error("New neck did not load");quit(1);return
 skin.native_animation.stop()
 for i in range(skin.skeleton.get_bone_count()):skin.skeleton.reset_bone_pose(i)
 skin.skeleton.force_update_all_bone_transforms();snapshot("rest")
 guitar=load("res://scripts/guitar_quality.gd").build(skin)
 for pose in ["idle","eat","wave","walk","guitar"]:
  for frame in range(120):skin.tick(1./60.,pose=="walk",.63 if pose=="walk" else 0.,pose,guitar,Vector3.ZERO)
  snapshot(pose)
 for value in [["guitar-left",Vector3(-2,1.3,2)],["guitar-right",Vector3(2,1.3,2)],["guitar-up",Vector3(0,3.,2)],["guitar-down",Vector3(0,0,2)],["guitar-diagonal",Vector3(2,0,2)]]:
  for frame in range(120):skin.tick(1./60.,false,0.,"guitar",guitar,value[1])
  snapshot(value[0])
 var result={"source_sha256":FileAccess.get_sha256("res://assets/characters/studies/AlinaNeck11.glb"),"bone_count":skin.skeleton.get_bone_count(),"shape_count":head.mesh.get_blend_shape_count(),"cases":cases,"limitation":"Selected settled native actions and gaze limits, not a full motion or anatomical acceptance."}
 FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
 print("NECK_LIVE_POSES_11_COMPLETE cases=",cases.size()," bones=",skin.skeleton.get_bone_count()," facial_shapes=",head.mesh.get_blend_shape_count())
 quit()
