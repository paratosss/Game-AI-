extends SceneTree
## Deterministic pose snapshots of the imported, skinned revision in neutral light.
## These snapshots inspect deformation; they are not a real-time animation video.
var stage:Node3D
var actor:Node3D
var skin:DemoHumanSkin
var camera:Camera3D
var output:String
var metadata={}
func _initialize():call_deferred("run")
func capture(label:String,position:Vector3,target:Vector3,fov:float):
 camera.position=position;camera.look_at(target,Vector3.UP);camera.fov=fov
 for i in range(8):
  await process_frame
  RenderingServer.force_draw()
 var file=output.path_join(label+".png")
 if root.get_texture().get_image().save_png(file)!=OK:
  push_error("Pose capture failed: "+label);quit(1);return
 metadata.captures.append({"name":label,"camera":[position.x,position.y,position.z],"target":[target.x,target.y,target.z],"fov":fov,"width":root.size.x,"height":root.size.y,"head_transform":str(skin.global_pose("Head")),"mouth_position":str(skin.global_pose("Head")*skin.revision_mouth_local)})
 print("ALINA_POSE_FRAME ",label)
func simulate(pose:String,frames:int,look:Vector3=Vector3.ZERO):
 for i in range(frames):skin.tick(1.0/60.0,false,0.0,pose,null,look)
func run():
 output=OS.get_environment("SHASHLIK_CAPTURE_DIR")
 if output.is_empty():quit(1);return
 DirAccess.make_dir_recursive_absolute(output)
 stage=Node3D.new();stage.set_meta("alina_revision",true);root.add_child(stage)
 actor=Node3D.new();stage.add_child(actor)
 skin=DemoHumanSkin.new();actor.add_child(skin);skin.setup("Алина",Color.WHITE)
 var env=WorldEnvironment.new();env.environment=Environment.new()
 env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("777c82")
 env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=.4
 env.environment.tonemap_mode=Environment.TONE_MAPPER_AGX;stage.add_child(env)
 for value in [[Vector3(-38,-35,0),1.4],[Vector3(-25,135,0),.5]]:
  var light=DirectionalLight3D.new();light.rotation_degrees=value[0];light.light_energy=value[1];light.shadow_enabled=true;stage.add_child(light)
 camera=Camera3D.new();camera.current=true;stage.add_child(camera)
 if RenderingServer.get_current_rendering_method()=="forward_plus":root.use_taa=true
 metadata={"renderer":RenderingServer.get_current_rendering_method(),"taa":root.use_taa,"captures":[],"dependencies_sha256":{}}
 for path in ["res://scripts/alina_body_revision.gd","res://assets/characters/studies/AlinaBody06.glb","res://assets/characters/studies/AlinaBody06.glb.import","res://assets/characters/studies/ALINA_BODY_06_MANIFEST.json"]:
  metadata.dependencies_sha256[path]=FileAccess.get_sha256(path)
 for path in ["res://tests/alina_pose_review.gd","res://scripts/human_skin.gd","res://scripts/alina_revision_materials.gd","res://scripts/head_study_materials.gd","res://assets/characters/studies/AlinaRevision.glb","res://assets/shaders/study_eye.gdshader","res://assets/shaders/study_skin.gdshader","res://assets/shaders/cloth_quality.gdshader"]:
  metadata.dependencies_sha256[path]=FileAccess.get_sha256(path)
 simulate("idle",180)
 await capture("standing",Vector3(0,1.0,2.9),Vector3(0,.83,0),36)
 await capture("face-front",Vector3(0,1.48,.82),Vector3(0,1.46,.10),30)
 simulate("idle",90,Vector3(2.5,1.5,2.0))
 await capture("face-turned",Vector3(0,1.48,.82),Vector3(0,1.46,.10),30)
 simulate("eat",40)
 await capture("eating",Vector3(.62,1.40,.95),Vector3(0,1.28,.07),40)
 var file=FileAccess.open(output.path_join("metadata.json"),FileAccess.WRITE);file.store_string(JSON.stringify(metadata,"  "))
 print("ALINA_POSE_REVIEW_COMPLETE")
 quit()
