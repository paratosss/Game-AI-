extends RefCounted
## An opt-in visual study. Cooking stations, tools and actors keep their gameplay positions.

const TEXTURES = "res://assets/textures/quality/"
const SUN_DIRECTION = Vector3(0.5545620063,0.7419804117,0.3767307391)

static func material(shader_name:String,bindings:Dictionary)->ShaderMaterial:
 var result=ShaderMaterial.new()
 result.shader=load("res://assets/shaders/"+shader_name+".gdshader")
 for key in bindings:
  result.set_shader_parameter(key,load(TEXTURES+bindings[key]))
 return result

static func apply(game:Node3D,geometry_enabled:bool=true):
 var environment=game.world_data.environment.environment
 var sky=Sky.new()
 sky.radiance_size=Sky.RADIANCE_SIZE_512
 sky.process_mode=Sky.PROCESS_MODE_QUALITY
 sky.sky_material=material("photographic_sky",{"panorama":"kloofendal_48d_partly_cloudy_puresky_2k.hdr"})
 sky.sky_material.set_shader_parameter("sky_energy",0.85)
 environment.sky=sky
 environment.ambient_light_source=Environment.AMBIENT_SOURCE_SKY
 environment.ambient_light_energy=0.16
 environment.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
 environment.tonemap_mode=Environment.TONE_MAPPER_ACES
 environment.tonemap_exposure=0.65
 environment.fog_enabled=false
 var forward=RenderingServer.get_current_rendering_method()=="forward_plus"
 if forward:
  game.get_viewport().use_taa=true
  environment.ssao_enabled=true
  environment.ssao_radius=0.28
  environment.ssao_intensity=1.1
  environment.ssao_detail=0.35
  environment.ssil_enabled=true
  environment.ssil_radius=2.0
  environment.ssil_intensity=0.5
  environment.ssr_enabled=true
  environment.ssr_max_steps=64
 for light in game.find_children("*","DirectionalLight3D",true,false):
  # Derived from the brightest sun pixel in this HDRI and the same equirectangular projection.
  light.look_at_from_position(Vector3.ZERO,-SUN_DIRECTION,Vector3.UP)
  light.light_color=Color("fff5e8")
  light.light_energy=0.90
  light.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
  light.directional_shadow_max_distance=55.0
 var earth=material("ground_pbr",{
  "earth_color":"forest_ground_04_diff_4k.jpg","earth_normal":"forest_ground_04_nor_gl_4k.jpg","earth_rough":"forest_ground_04_rough_4k.jpg",
  "turf_color":"leafy_grass_diff_4k.jpg","turf_normal":"leafy_grass_nor_gl_4k.jpg","turf_rough":"leafy_grass_rough_4k.jpg"})
 for mesh in game.find_children("*","MeshInstance3D",true,false):
  var old=mesh.material_override
  if not old is ShaderMaterial:continue
  var path=old.shader.resource_path
  if path.ends_with("/wood.gdshader"):
   var wood=material("wood_pbr",{"wood_color":"wood_table_worn_diff_4k.jpg","wood_normal":"wood_table_worn_nor_gl_4k.jpg","wood_rough":"wood_table_worn_rough_4k.jpg"})
   wood.set_shader_parameter("grain_offset",old.get_shader_parameter("grain_offset"))
   mesh.material_override=wood
  elif path.ends_with("/ground.gdshader"):
   mesh.material_override=earth
  elif path.ends_with("/water.gdshader"):
   if mesh.mesh is CylinderMesh:
    mesh.mesh=mesh.mesh.duplicate()
    mesh.mesh.radial_segments=128
   var water=ShaderMaterial.new()
   water.shader=load("res://assets/shaders/water_quality.gdshader")
   mesh.material_override=water
 if geometry_enabled:
  var rock=material("rock_pbr",{"rock_color":"rock_05_diff_4k.jpg","rock_normal":"rock_05_nor_gl_4k.jpg","rock_rough":"rock_05_rough_4k.jpg"})
  load("res://scripts/quality_geometry.gd").apply(game,rock,earth)
