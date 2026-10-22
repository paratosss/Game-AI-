extends "res://tests/alina_pose_review.gd"
## Matched neck reconstruction review. --previous disables only the new neck/pose. --quick captures eight exposed neck views.
var saved_materials=[]
var hair_hidden=false
func run():
 output=OS.get_environment("SHASHLIK_CAPTURE_DIR")
 if output.is_empty():quit(1);return
 DirAccess.make_dir_recursive_absolute(output)
 stage=Node3D.new();stage.set_meta("alina_revision",true);stage.set_meta("neck_revision",not "--previous" in OS.get_cmdline_user_args());root.add_child(stage)
 actor=Node3D.new();stage.add_child(actor)
 skin=DemoHumanSkin.new();actor.add_child(skin);skin.setup("Алина",Color.WHITE)
 skin.native_animation.stop()
 for i in range(skin.skeleton.get_bone_count()):skin.skeleton.reset_bone_pose(i)
 skin.skeleton.force_update_all_bone_transforms()
 var environment=WorldEnvironment.new();environment.environment=Environment.new()
 environment.environment.background_mode=Environment.BG_COLOR
 environment.environment.background_color=Color("777c82")
 environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 environment.environment.ambient_light_color=Color.WHITE;environment.environment.ambient_light_energy=.4
 environment.environment.tonemap_mode=Environment.TONE_MAPPER_AGX;stage.add_child(environment)
 for value in [[Vector3(-38,-35,0),1.4],[Vector3(-25,135,0),.5]]:
  var light=DirectionalLight3D.new();light.rotation_degrees=value[0];light.light_energy=value[1]
  light.shadow_enabled=true;stage.add_child(light)
 var clay=StandardMaterial3D.new();clay.albedo_color=Color("a6a8aa");clay.roughness=.85
 for mesh in skin.find_children("*","MeshInstance3D",true,false):
  for surface in range(mesh.mesh.get_surface_count()):
   var label=mesh.mesh.surface_get_material(surface).resource_name
   if mesh.name in ["Human","Human_female_casualsuit01","Human_shoes05"] or label in ["Head","Head_Anatomy09"]:mesh.set_surface_override_material(surface,clay)
   if label.begins_with("Hair") or label.begins_with("Eye Lashes") or label.begins_with("Eye Bros"):
    saved_materials.append([mesh,surface,mesh.get_active_material(surface)])
 camera=Camera3D.new();camera.current=true;camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 stage.add_child(camera)
 metadata={"neck_revision":skin.uses_neck,"renderer":RenderingServer.get_current_rendering_method(),"captures":[],"dependencies_sha256":{},"diagnostic_only":true,"clay_skin_and_clothes":true,"poses":{}}
 for path in ["res://tests/anatomy_orbit_review.gd","res://tests/alina_pose_review.gd","res://scripts/human_skin.gd","res://scripts/guitar_posture.gd","res://scripts/alina_anatomy_revision.gd","res://scripts/alina_body_revision.gd","res://scripts/alina_revision_materials.gd","res://assets/characters/studies/AlinaAnatomy09.glb","res://assets/characters/studies/AlinaRevision.glb","res://assets/characters/studies/AlinaBody06.glb"]:
  metadata.dependencies_sha256[path]=FileAccess.get_sha256(path)
 for path in ["res://tests/neck_review.gd","res://tests/neck_review_cameras.json","res://scripts/alina_neck_revision.gd","res://assets/characters/studies/AlinaNeck11.glb","res://assets/characters/studies/AlinaNeck11.glb.import","res://assets/characters/studies/ALINA_NECK_11_MANIFEST.json"]:
  metadata.dependencies_sha256[path]=FileAccess.get_sha256(path)
 await orbit_pose("neutral")
 var guitar=load("res://scripts/guitar_quality.gd").build(skin)
 for frame in range(120):skin.tick(1./60.,false,0.,"guitar",guitar,Vector3.ZERO)
 await orbit_pose("guitar")
 if "--stress" in OS.get_cmdline_user_args():
  var data=JSON.parse_string(FileAccess.get_file_as_string("res://tests/neck_review_cameras.json"))
  var t=data.targets.guitar;var target=Vector3(t[0],t[1],t[2])
  camera.size=.58;set_hair_hidden(true)
  for value in [["left",Vector3(-2,1.3,2)],["right",Vector3(2,1.3,2)],["up",Vector3(0,3.,2)],["down",Vector3(0,0,2)],["diagonal",Vector3(2,0,2)]]:
   for frame in range(120):skin.tick(1./60.,false,0.,"guitar",guitar,value[1])
   for step in [0,2,6]:
    var angle=step*PI/4.
    await capture("stress-"+value[0]+"-%03d"%(step*45),target+Vector3(sin(angle),0,cos(angle))*3.,target,35)
    metadata.captures[-1].orthographic_size=camera.size
    metadata.captures[-1].hair_hidden=true
  set_hair_hidden(false)
 FileAccess.open(output.path_join("metadata.json"),FileAccess.WRITE).store_string(JSON.stringify(metadata,"  "))
 print("NECK_REVIEW_11_COMPLETE frames=",metadata.captures.size())
 quit()

func orbit_pose(pose:String):
 var bones={}
 for name in ["pelvis","spine_01","spine_02","spine_03","neck_01","Head","clavicle_l","clavicle_r"]:
  if skin.indices.has(name):bones[name]=str(skin.global_pose(name))
 metadata.poses[pose]=bones
 var neck=skin.to_global(skin.global_pose("neck_01").origin)
 var head=skin.to_global(skin.global_pose("Head").origin)
 var camera_data=JSON.parse_string(FileAccess.get_file_as_string("res://tests/neck_review_cameras.json"))
 var t=camera_data.targets[pose]
 var neck_target=Vector3(t[0],t[1],t[2])
 if "--quick" in OS.get_cmdline_user_args():
  camera.size=.58;set_hair_hidden(true)
  for step in [0,2,4,6]:
   var angle=step*PI/4.
   await capture(pose+"-neck-exposed-%03d"%(step*45),neck_target+Vector3(sin(angle),0,cos(angle))*3.,neck_target,35)
   metadata.captures[-1].orthographic_size=camera.size
   metadata.captures[-1].hair_hidden=true
  set_hair_hidden(false);return
 var regions=["neck"] if "--neck-only" in OS.get_cmdline_user_args() else ["full","neck"]
 for region in regions:
  camera.size=1.85 if region=="full" else .58
  var target=Vector3(0,.82,0) if region=="full" else neck_target
  for step in range(8):
   var angle=step*PI/4.
   var direction=Vector3(sin(angle),0,cos(angle))
   await capture(pose+"-"+region+"-%03d"%(step*45),target+direction*3.,target,35)
   metadata.captures[-1].orthographic_size=camera.size
   metadata.captures[-1].hair_hidden=false
 camera.size=.58
 for elevation in [-25.,25.]:
  var angle=deg_to_rad(elevation)
  await capture(pose+"-neck-elevation-%s"%str(int(elevation)),neck_target+Vector3(0,sin(angle),cos(angle))*3.,neck_target,35)
  metadata.captures[-1].orthographic_size=camera.size
  metadata.captures[-1].hair_hidden=false
 set_hair_hidden(true)
 for step in [0,2,4,6]:
  var angle=step*PI/4.
  await capture(pose+"-neck-exposed-%03d"%(step*45),neck_target+Vector3(sin(angle),0,cos(angle))*3.,neck_target,35)
  metadata.captures[-1].orthographic_size=camera.size
  metadata.captures[-1].hair_hidden=true
 set_hair_hidden(false)

func set_hair_hidden(hidden:bool):
 var shader=Shader.new();shader.code="shader_type spatial; void fragment(){discard;}"
 var material=ShaderMaterial.new();material.shader=shader
 for item in saved_materials:item[0].set_surface_override_material(item[1],material if hidden else item[2])
