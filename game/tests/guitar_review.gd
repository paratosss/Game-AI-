extends SceneTree
## Actual Godot captures in neutral light; individual poses, not animation video.
var stage:Node3D
var skin:DemoHumanSkin
var guitar:Node3D
var camera:Camera3D
var output:String
var metadata={"captures":[],"dependencies_sha256":{}}
func _initialize():call_deferred("run")
func capture(label:String,position:Vector3,target:Vector3,fov:float):
 camera.position=position;camera.look_at(target,Vector3.UP);camera.fov=fov
 for i in range(8):
  await process_frame
  RenderingServer.force_draw()
 var path=output.path_join(label+".png")
 if root.get_texture().get_image().save_png(path)!=OK:push_error("Guitar capture failed");quit(1);return
 metadata.captures.append({"name":label,"camera":str(position),"target":str(target),"fov":fov,"width":root.size.x,"height":root.size.y,"motion_time":skin.motion_time,"guitar_transform":str(guitar.global_transform)})
 print("GUITAR_REVIEW_FRAME ",label)
func run():
 output=OS.get_environment("SHASHLIK_CAPTURE_DIR")
 if output.is_empty():push_error("Set SHASHLIK_CAPTURE_DIR");quit(1);return
 DirAccess.make_dir_recursive_absolute(output)
 stage=Node3D.new();stage.set_meta("alina_revision",true);root.add_child(stage)
 var actor=Node3D.new();stage.add_child(actor)
 skin=DemoHumanSkin.new();actor.add_child(skin);skin.setup("Алина",Color.WHITE)
 guitar=load("res://scripts/guitar_quality.gd").build(skin)
 var env=WorldEnvironment.new();env.environment=Environment.new();stage.add_child(env)
 env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("777c82")
 env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=.4
 env.environment.tonemap_mode=Environment.TONE_MAPPER_AGX
 for value in [[Vector3(-38,-35,0),1.4],[Vector3(-25,135,0),.5]]:
  var light=DirectionalLight3D.new();light.rotation_degrees=value[0];light.light_energy=value[1];light.shadow_enabled=true;stage.add_child(light)
 camera=Camera3D.new();camera.current=true;stage.add_child(camera)
 if RenderingServer.get_current_rendering_method()=="forward_plus":root.use_taa=true
 metadata.renderer=RenderingServer.get_current_rendering_method();metadata.taa=root.use_taa
 for path in ["res://scripts/alina_body_revision.gd","res://assets/characters/studies/AlinaBody06.glb","res://assets/characters/studies/AlinaBody06.glb.import","res://assets/characters/studies/ALINA_BODY_06_MANIFEST.json"]:
  metadata.dependencies_sha256[path]=FileAccess.get_sha256(path)
 for path in ["res://tests/guitar_review.gd","res://scripts/human_skin.gd","res://scripts/guitar_quality.gd","res://assets/shaders/instrument_wood.gdshader","res://scripts/alina_revision_materials.gd","res://assets/characters/studies/AlinaRevision.glb"]:
  metadata.dependencies_sha256[path]=FileAccess.get_sha256(path)
 for i in range(120):skin.tick(1.0/60.0,false,0.0,"guitar",guitar,Vector3.ZERO)
 await capture("seated-neutral",Vector3(.15,1.12,1.9),Vector3(.03,.87,.12),40)
 await capture("fretting-hand",guitar.to_global(Vector3(.07,.55,.40)),guitar.to_global(Vector3(.0,.55,.055)),36)
 await capture("strumming-hand",guitar.to_global(Vector3(-.07,.11,.44)),guitar.to_global(Vector3(-.02,.10,.065)),40)
 # Separate unposed prop exposes construction without the character hiding it.
 guitar.reparent(stage);skin.visible=false;guitar.transform=Transform3D.IDENTITY
 await capture("instrument",Vector3(.65,.33,1.48),Vector3(0,.25,0),43)
 await capture("instrument-side",Vector3(.75,.34,.70),Vector3(0,.25,0),57)
 var file=FileAccess.open(output.path_join("metadata.json"),FileAccess.WRITE);file.store_string(JSON.stringify(metadata,"  "))
 print("GUITAR_REVIEW_COMPLETE");quit()
