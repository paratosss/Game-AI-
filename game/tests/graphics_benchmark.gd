extends SceneTree
var game
var output:String
var high=false
var initial_actor_transforms=[]
var capture_metadata=[]

func _initialize():call_deferred("run")

func apply_profile():
 var environment=game.world_data.environment.environment
 environment.tonemap_mode=Environment.TONE_MAPPER_AGX
 environment.tonemap_exposure=1.0
 environment.ambient_light_source=Environment.AMBIENT_SOURCE_SKY
 environment.ambient_light_energy=.40
 environment.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
 root.use_taa=true
 environment.ssao_enabled=true
 environment.ssao_radius=.35
 environment.ssao_intensity=1.0
 environment.ssao_detail=.35
 environment.ssil_enabled=true
 environment.ssil_radius=2.0
 environment.ssil_intensity=.6
 environment.ssr_enabled=true
 environment.ssr_max_steps=64
 for light in game.find_children("*","DirectionalLight3D",true,false):
  light.light_energy=1.65
  light.light_color=Color("fff5e8")
  light.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
  light.directional_shadow_max_distance=45
 for mesh in game.find_children("*","MeshInstance3D",true,false):
  var material=mesh.material_override
  if material is ShaderMaterial:
   if material.shader.resource_path.ends_with("/wood.gdshader"):
    var replacement=ShaderMaterial.new()
    replacement.shader=load("res://assets/shaders/wood_quality.gdshader")
    for key in ["wood_color","wood_normal","wood_rough","grain_offset"]:
     replacement.set_shader_parameter(key,material.get_shader_parameter(key))
    mesh.material_override=replacement
   elif material.shader.resource_path.ends_with("/water.gdshader"):
    var replacement=ShaderMaterial.new()
    replacement.shader=load("res://assets/shaders/water_quality.gdshader")
    mesh.material_override=replacement

func shot(name:String,position:Vector3,target:Vector3):
 game.player.position=position-Vector3(0,1.62,0)
 game.camera.look_at(target,Vector3.UP)
 # Explicit draws keep one-shot high-quality rendering practical on the
 # cloud's software GPU. These captures do not measure gameplay frame rate.
 for warm_frame in range(12):
  await process_frame
  RenderingServer.force_draw()
 var result=root.get_texture().get_image().save_png(output.path_join(name+".png"))
 if result!=OK:push_error("Could not save benchmark frame");quit(1)
 for idx in range(game.actors.size()):
  if not game.actors[idx].transform.is_equal_approx(initial_actor_transforms[idx]):
   push_error("An actor moved during a controlled comparison")
   quit(1)
 capture_metadata.append({"name":name,"camera_position":[position.x,position.y,position.z],"target":[target.x,target.y,target.z],"width":root.size.x,"height":root.size.y})
 print("GRAPHICS_BENCHMARK_FRAME ",name)

func save_metadata():
 var file=FileAccess.open(output.path_join("capture-metadata.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify({"high":high,"renderer":RenderingServer.get_current_rendering_method(),"actor_transforms_stable":true,"benchmark_sha256":FileAccess.get_sha256("res://tests/graphics_benchmark.gd"),"captures":capture_metadata},"  "))

func run():
 seed(20261015)
 output=OS.get_environment("SHASHLIK_CAPTURE_DIR")
 high="--graphics-high" in OS.get_cmdline_user_args()
 if output.is_empty():quit(1);return
 DirAccess.make_dir_recursive_absolute(output)
 game=load("res://main.tscn").instantiate()
 root.add_child(game)
 paused=true
 game.initialized=false
 game.set_physics_process(false)
 game.ui.visible=false
 var positions=[Vector3(0,0,-3.2),Vector3(3.5,0,3.6),Vector3(6.5,0,2.5),Vector3(5,0,2)]
 for idx in range(game.actors.size()):
  var actor=game.actors[idx]
  actor.set_physics_process(false)
  actor.position=positions[idx]
  actor.rotation=Vector3.ZERO
  initial_actor_transforms.append(actor.transform)
 for frame in range(120):
  for idx in range(3):
   var actor=game.actors[idx]
   actor.model.skin.tick(1.0/60,false,0,"guitar" if idx==0 else "idle",actor.guitar,Vector3.ZERO)
  game.actors[3].model.dog_skin.tick(1.0/60,false,0,"idle")
 if high:apply_profile()
 print("GRAPHICS_BENCHMARK_READY high=",high," renderer=",RenderingServer.get_current_rendering_method())
 await shot("overview",Vector3(-4.1,1.9,4.8),Vector3(1,.5,-1.5))
 if "--overview-only" in OS.get_cmdline_user_args():
  save_metadata()
  print("GRAPHICS_BENCHMARK_COMPLETE high=",high," overview_only=true")
  quit()
  return
 await shot("table",Vector3(-3.0,1.4,3.9),Vector3(-3.2,.88,2.9))
 await shot("grill",Vector3(-1.3,1.2,1.25),game.grill_pos+Vector3(0,.77,0))
 await shot("alina",Vector3(.9,1.62,-1.5),Vector3(0,1.02,-3.2))
 await shot("pond",Vector3(3.1,1.65,-2.2),Vector3(7,.3,-6))
 save_metadata()
 print("GRAPHICS_BENCHMARK_COMPLETE high=",high)
 quit()
