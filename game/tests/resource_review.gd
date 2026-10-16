extends SceneTree
## Controlled resource inspection, without gameplay lighting or animation corrections.
var stage:Node3D
var camera:Camera3D
var output:String
var asset:String
var metadata:Dictionary={}

func _initialize():call_deferred("run")

func capture(label:String,position:Vector3,target:Vector3,fov:float):
 camera.position=position
 camera.look_at(target,Vector3.UP)
 camera.fov=fov
 for frame in range(8):
  await process_frame
  RenderingServer.force_draw()
 var result=root.get_texture().get_image().save_png(output.path_join(label+".png"))
 if result!=OK:
  push_error("Resource capture failed: "+label)
  quit(1)
  return
 metadata.captures.append({"name":label,"camera":[position.x,position.y,position.z],"target":[target.x,target.y,target.z],"fov":fov,"width":root.size.x,"height":root.size.y})
 print("RESOURCE_REVIEW_FRAME ",label)

func run():
 output=OS.get_environment("SHASHLIK_CAPTURE_DIR")
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--asset="):asset=arg.trim_prefix("--asset=")
 if output.is_empty() or asset.is_empty():
  push_error("Set SHASHLIK_CAPTURE_DIR and --asset=res://path.glb")
  quit(1)
  return
 DirAccess.make_dir_recursive_absolute(output)
 stage=Node3D.new()
 root.add_child(stage)
 var environment=WorldEnvironment.new()
 environment.environment=Environment.new()
 environment.environment.background_mode=Environment.BG_COLOR
 environment.environment.background_color=Color("777c82")
 environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 environment.environment.ambient_light_color=Color.WHITE
 environment.environment.ambient_light_energy=0.40
 environment.environment.tonemap_mode=Environment.TONE_MAPPER_AGX
 stage.add_child(environment)
 var key=DirectionalLight3D.new()
 key.rotation_degrees=Vector3(-38,-35,0)
 key.light_energy=1.4
 key.shadow_enabled=true
 stage.add_child(key)
 var fill=DirectionalLight3D.new()
 fill.rotation_degrees=Vector3(-25,135,0)
 fill.light_energy=0.50
 stage.add_child(fill)
 camera=Camera3D.new()
 camera.current=true
 stage.add_child(camera)
 var instance=load(asset).instantiate()
 stage.add_child(instance)
 if "--head-materials" in OS.get_cmdline_user_args():
  load("res://scripts/head_study_materials.gd").apply(instance)
 var rig=instance.find_children("*","Skeleton3D",true,false)
 var animations=instance.find_children("*","AnimationPlayer",true,false)
 metadata={"asset":asset,"sha256":FileAccess.get_sha256(asset),"review_script_sha256":FileAccess.get_sha256("res://tests/resource_review.gd"),"renderer":RenderingServer.get_current_rendering_method(),"bones":rig[0].get_bone_count() if not rig.is_empty() else 0,"clips":[],"captures":[],"head_materials":"--head-materials" in OS.get_cmdline_user_args()}
 if metadata.head_materials:
  metadata["material_script_sha256"]=FileAccess.get_sha256("res://scripts/head_study_materials.gd")
  metadata["eye_shader_sha256"]=FileAccess.get_sha256("res://assets/shaders/study_eye.gdshader")
  metadata["skin_shader_sha256"]=FileAccess.get_sha256("res://assets/shaders/study_skin.gdshader")
 for player in animations:
  metadata.clips=Array(player.get_animation_list())
  player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
  if "--rest" in OS.get_cmdline_user_args():
   player.stop()
  elif player.has_animation("idle"):
   player.play("idle")
   player.advance(1.0)
 if "--rest" in OS.get_cmdline_user_args():
  for skeleton in rig:skeleton.reset_bone_poses()
 metadata["rest_pose"]="--rest" in OS.get_cmdline_user_args()
 var head=Vector3(0,1.455,0.10)
 await capture("front",head+Vector3(0,0,0.72),head,30)
 await capture("profile",head+Vector3(0.70,0,0.015),head,30)
 await capture("three-quarter",head+Vector3(0.49,0,0.54),head,30)
 await capture("full",Vector3(0,0.95,3.2),Vector3(0,0.84,0),36)
 if "--expressions" in OS.get_cmdline_user_args():
  for expression in ["eyeBlinkLeft","eyeBlinkRight","mouthSmileLeft","jawOpen"]:
   var affected=0
   for mesh in instance.find_children("*","MeshInstance3D",true,false):
    for index in range(mesh.mesh.get_blend_shape_count()):
     if mesh.mesh.get_blend_shape_name(index)==expression:
      mesh.set_blend_shape_value(index,1.0 if "Blink" in expression else 0.65)
      affected+=1
   if affected==0:
    push_error("Missing required facial shape: "+expression)
    quit(1)
    return
   await capture(expression,head+Vector3(0,0,0.72),head,30)
   for mesh in instance.find_children("*","MeshInstance3D",true,false):
    for index in range(mesh.mesh.get_blend_shape_count()):mesh.set_blend_shape_value(index,0.0)
 var file=FileAccess.open(output.path_join("metadata.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify(metadata,"  "))
 print("RESOURCE_REVIEW_COMPLETE bones=",metadata.bones," clips=",metadata.clips.size())
 quit()
