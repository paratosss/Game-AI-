extends RefCounted
## A separate, incomplete geometry study of the existing location.
const Terrain=preload("res://scripts/lakeside_terrain.gd")

static func tree_material()->ShaderMaterial:
 var material=ShaderMaterial.new()
 material.shader=load("res://assets/shaders/birch_scan.gdshader")
 material.set_shader_parameter("bark_color",load("res://assets/textures/birch_scan/color_8k.jpg"))
 material.set_shader_parameter("bark_normal",load("res://assets/textures/birch_scan/normal_8k.jpg"))
 material.set_shader_parameter("bark_rough",load("res://assets/textures/birch_scan/roughness_8k.jpg"))
 return material

static func replace_trees(game:Node3D):
 var bark=tree_material()
 var leaves=ShaderMaterial.new()
 leaves.shader=load("res://assets/shaders/birch_leaf.gdshader")
 var templates=[]
 for index in range(1,4):
  templates.append(load("res://assets/nature/birch_%02d.glb"%index))
 var rng=RandomNumberGenerator.new()
 rng.seed=20261016
 var count=0
 for tree in game.get_children():
  if not tree.has_meta("crown_tips"):continue
  for child in tree.get_children():
   if child is GeometryInstance3D:child.visible=false
  # Keep the original trunk body/collision and tree count.
  var offset=Vector2(tree.position.x-7.0,tree.position.z+6.0)
  if offset.length()<4.5:
   var moved=offset.normalized()*4.7
   tree.position.x=7.0+moved.x
   tree.position.z=-6.0+moved.y
  var replacement=templates[count%3].instantiate()
  tree.add_child(replacement)
  replacement.scale=Vector3.ONE*rng.randf_range(0.92,1.15)
  for mesh in replacement.find_children("*","MeshInstance3D",true,false):
   mesh.material_override=leaves if "Leaves" in mesh.name else bark
  count+=1
 var far_source:MultiMeshInstance3D
 var far_count=0
 for node in game.find_children("*","MultiMeshInstance3D",true,false):
  if node.name=="BirchCrowns":node.visible=false
  elif node.material_override is ShaderMaterial and node.material_override.shader.resource_path.ends_with("/birch.gdshader"):
   far_source=node
   node.visible=false
  elif node.material_override is StandardMaterial3D and node.material_override.albedo_texture and node.material_override.albedo_texture.resource_path.ends_with("/birch-twig.svg"):
   node.visible=false
 if far_source:
  var old=far_source.multimesh
  far_count=old.instance_count
  # Group each source variant; all 85 existing distant tree positions are retained.
  for variant in range(3):
   var template=load("res://assets/nature/birch_%02d_far.glb"%(variant+1)).instantiate()
   for source_mesh in template.find_children("*","MeshInstance3D",true,false):
    var mm=MultiMesh.new()
    mm.transform_format=MultiMesh.TRANSFORM_3D
    mm.mesh=source_mesh.mesh
    var transforms=[]
    for index in range(old.instance_count):
     if index%3!=variant:continue
     var original=old.get_instance_transform(index)
     var height=original.basis.y.length()
     var base=original.origin-Vector3.UP*2.75*height
     var radius=Vector2(base.x,base.z).length()
     var mapped=18.0+clampf((radius-22.0)/31.0,0.0,1.0)*17.0
     base.x*=mapped/radius
     base.z*=mapped/radius
     base.y=Terrain.visible_height_at(base.x,base.z)
     var scale_factor=rng.randf_range(0.90,1.35)
     transforms.append(Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*scale_factor),base))
    mm.instance_count=transforms.size()
    for index in range(transforms.size()):mm.set_instance_transform(index,transforms[index])
    var node=MultiMeshInstance3D.new()
    game.add_child(node)
    node.name="LakesideFarBirches"+str(variant)+source_mesh.name
    node.multimesh=mm
    node.layers=8
    node.material_override=leaves if "Leaves" in source_mesh.name else bark
   template.free()
 print("LAKESIDE_TREES_APPLIED near=",count," far=",far_count)

static func grass_on_terrain(game:Node3D):
 var rng=RandomNumberGenerator.new()
 rng.seed=6603
 var count=0
 for node in game.find_children("QualityGrassPatch*","MultiMeshInstance3D",true,false):
  var original=node.multimesh
  var mm=MultiMesh.new()
  mm.transform_format=MultiMesh.TRANSFORM_3D
  mm.use_colors=true
  mm.use_custom_data=true
  mm.mesh=original.mesh
  mm.instance_count=original.instance_count*3
  for index in range(original.instance_count):
   for copy in range(3):
    var transform=original.get_instance_transform(index)
    if copy>0:transform.origin+=Vector3(rng.randf_range(-0.09,0.09),0.0,rng.randf_range(-0.09,0.09))
    transform.origin.y=Terrain.height_at(transform.origin.x,transform.origin.z)+0.01
    transform.basis=transform.basis.scaled(Vector3(1.0,1.65,1.0))
    mm.set_instance_transform(index*3+copy,transform)
    mm.set_instance_color(index*3+copy,original.get_instance_color(index))
    mm.set_instance_custom_data(index*3+copy,original.get_instance_custom_data(index))
  node.multimesh=mm
  node.layers=4
  count+=mm.instance_count
 print("LAKESIDE_GRASS_APPLIED clumps=",count)

static func pond(game:Node3D):
 for mesh in game.find_children("*","MeshInstance3D",true,false):
  if mesh.material_override is ShaderMaterial and mesh.material_override.shader.resource_path.ends_with("/water_quality.gdshader"):
   var surface=SurfaceTool.new()
   surface.begin(Mesh.PRIMITIVE_TRIANGLES)
   for segment in range(128):
    for index in [-1,segment,segment+1]:
     var point=Vector3(0,0.014,0) if index<0 else Vector3(cos(index*TAU/128.0)*3.7,0.014,sin(index*TAU/128.0)*3.7)
     surface.set_normal(Vector3.UP)
     surface.add_vertex(point)
   mesh.mesh=surface.commit()
   var water=ShaderMaterial.new()
   water.shader=load("res://assets/shaders/pond_depth.gdshader")
   mesh.material_override=water
   mesh.layers=2
   mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var probe=ReflectionProbe.new()
 game.add_child(probe)
 probe.name="LakesidePondReflection"
 probe.position=Vector3(7.0,1.2,-6.0)
 probe.size=Vector3(34.0,14.0,30.0)
 probe.max_distance=35.0
 probe.mesh_lod_threshold=2.0
 probe.cull_mask=9
 probe.reflection_mask=2
 probe.ambient_mode=ReflectionProbe.AMBIENT_DISABLED
 probe.update_mode=ReflectionProbe.UPDATE_ONCE

static func apply(game:Node3D):
 load("res://scripts/graphics_quality.gd").apply(game,false)
 var environment=game.world_data.environment.environment
 environment.ambient_light_energy=0.35
 environment.tonemap_exposure=0.80
 var earth:ShaderMaterial
 for mesh in game.find_children("*","MeshInstance3D",true,false):
  if mesh.material_override is ShaderMaterial and mesh.material_override.shader.resource_path.ends_with("/ground_pbr.gdshader"):
   earth=mesh.material_override
   break
 var rock=load("res://scripts/graphics_quality.gd").material("rock_pbr",{"rock_color":"rock_05_diff_4k.jpg","rock_normal":"rock_05_nor_gl_4k.jpg","rock_rough":"rock_05_rough_4k.jpg"})
 load("res://scripts/quality_geometry.gd").apply(game,rock,earth,false)
 replace_trees(game)
 load("res://scripts/lakeside_terrain.gd").apply(game,earth)
 grass_on_terrain(game)
 pond(game)
 print("LAKESIDE_STUDY_READY")
