extends "res://tests/alina_pose_review.gd"
## Fixed neutral views for anatomical shape/proportion assessment, no idle pose.
func run():
 output=OS.get_environment("SHASHLIK_CAPTURE_DIR")
 if output.is_empty():quit(1);return
 DirAccess.make_dir_recursive_absolute(output)
 stage=Node3D.new();stage.set_meta("alina_revision",true);root.add_child(stage)
 stage.set_meta("anatomy_revision",not "--baseline" in OS.get_cmdline_user_args())
 actor=Node3D.new();stage.add_child(actor)
 skin=DemoHumanSkin.new();actor.add_child(skin);skin.setup("Алина",Color.WHITE)
 skin.native_animation.stop()
 for i in range(skin.skeleton.get_bone_count()):skin.skeleton.reset_bone_pose(i)
 skin.skeleton.force_update_all_bone_transforms()
 var env=WorldEnvironment.new();env.environment=Environment.new()
 env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("777c82")
 env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=.4
 env.environment.tonemap_mode=Environment.TONE_MAPPER_AGX;stage.add_child(env)
 for value in [[Vector3(-38,-35,0),1.4],[Vector3(-25,135,0),.5]]:
  var light=DirectionalLight3D.new();light.rotation_degrees=value[0];light.light_energy=value[1];light.shadow_enabled=true;stage.add_child(light)
 camera=Camera3D.new();camera.current=true;stage.add_child(camera)
 camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=1.85
 metadata={"renderer":RenderingServer.get_current_rendering_method(),"captures":[],"dependencies_sha256":{}}
 metadata.anatomy_revision=skin.uses_anatomy
 metadata.clay_skin_and_clothes="--clay" in OS.get_cmdline_user_args()
 if metadata.clay_skin_and_clothes:
  var clay=StandardMaterial3D.new();clay.albedo_color=Color("a6a8aa");clay.roughness=.85
  for mesh in skin.find_children("*","MeshInstance3D",true,false):
   for i in range(mesh.mesh.get_surface_count()):
    var name=mesh.mesh.surface_get_material(i).resource_name
    if mesh.name in ["Human","Human_female_casualsuit01","Human_shoes05"] or name in ["Head","Head_Anatomy09"]:mesh.set_surface_override_material(i,clay)
 for path in ["res://tests/anatomy_review.gd","res://scripts/human_skin.gd","res://scripts/alina_revision_materials.gd","res://scripts/alina_body_revision.gd","res://assets/characters/studies/AlinaRevision.glb","res://assets/characters/studies/AlinaBody06.glb"]:metadata.dependencies_sha256[path]=FileAccess.get_sha256(path)
 if stage.get_meta("anatomy_revision"):
  for path in ["res://scripts/alina_anatomy_revision.gd","res://assets/characters/studies/AlinaAnatomy09.glb","res://assets/characters/studies/AlinaAnatomy09.glb.import","res://assets/characters/studies/ALINA_ANATOMY_09_MANIFEST.json"]:metadata.dependencies_sha256[path]=FileAccess.get_sha256(path)
 if "--elbow-only" in OS.get_cmdline_user_args():
  var guitar=load("res://scripts/guitar_quality.gd").build(skin)
  for i in range(120):skin.tick(1./60,false,0,"guitar",guitar,Vector3.ZERO)
  camera.projection=Camera3D.PROJECTION_PERSPECTIVE
  var elbow=skin.to_global(skin.global_pose("lowerarm_l").origin)
  await capture("elbow-flex-front",elbow+Vector3(.45,.08,.48),elbow,34)
  await capture("elbow-flex-back",elbow+Vector3(.42,.12,-.44),elbow,34)
  FileAccess.open(output.path_join("metadata.json"),FileAccess.WRITE).store_string(JSON.stringify(metadata,"  "))
  print("ANATOMY_ELBOW_REVIEW_09_COMPLETE");quit();return
 await capture("neutral-front",Vector3(0,.81,3),Vector3(0,.81,0),35)
 await capture("neutral-side",Vector3(3,.81,0),Vector3(0,.81,0),35)
 camera.size=.62
 await capture("neck-front",Vector3(0,1.34,2),Vector3(0,1.34,0),35)
 await capture("neck-side",Vector3(2,1.34,0),Vector3(0,1.34,0),35)
 FileAccess.open(output.path_join("metadata.json"),FileAccess.WRITE).store_string(JSON.stringify(metadata,"  "))
 print("ANATOMY_REVIEW_09_COMPLETE");quit()
