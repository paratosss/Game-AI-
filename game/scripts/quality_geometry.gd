extends RefCounted
## Retain existing props. Extra grass is visual; shoreline trees move with their colliders.

static func rock_mesh(bounds:AABB,seed_value:int)->ArrayMesh:
 var rng=RandomNumberGenerator.new()
 rng.seed=seed_value
 var planes:Array[Vector3]=[]
 for index in range(9):
  planes.append(Vector3(rng.randf_range(-1.0,1.0),rng.randf_range(-0.7,1.0),rng.randf_range(-1.0,1.0)).normalized())
 var sphere=SphereMesh.new()
 sphere.radius=0.5
 sphere.height=1.0
 sphere.radial_segments=24
 sphere.rings=12
 var arrays=sphere.get_mesh_arrays()
 var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
 var minimum=Vector3.ONE*1000.0
 var maximum=-minimum
 for index in range(vertices.size()):
  var direction=vertices[index].normalized()
  var radius=1.0
  for plane in planes:
   if direction.dot(plane)>0.0:radius=minf(radius,0.79/direction.dot(plane))
  var point=direction*radius
  # Broad planar breaks replace the inflated sphere silhouette.
  point.y=clampf(point.y,-0.72,0.85)
  vertices[index]=point
  minimum=minimum.min(point)
  maximum=maximum.max(point)
 for index in range(vertices.size()):
  vertices[index]=bounds.position+(vertices[index]-minimum)/(maximum-minimum)*bounds.size
 arrays[Mesh.ARRAY_VERTEX]=vertices
 var mesh=ArrayMesh.new()
 mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 var surface=SurfaceTool.new()
 surface.create_from(mesh,0)
 surface.generate_normals()
 return surface.commit()

static func blade_point(index:int,t:float,side:float)->Vector3:
 var azimuth=index*2.399963
 var forward=Vector3(cos(azimuth),0.0,sin(azimuth))
 var right=Vector3(-forward.z,0.0,forward.x)
 var height=0.09+float(index%6)*0.017
 var center=forward*(0.024+0.055*t*t)+Vector3(0.0,height*t,0.0)
 var half_width=0.0035*(1.0-t)*(0.65+0.35*sin(t*PI))
 return center+right*half_width*side+Vector3(0.0,0.0008*(1.0-absf(side))*sin(t*PI),0.0)

static func grass_mesh()->ArrayMesh:
 var surface=SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for blade in range(9):
  surface.set_smooth_group(blade)
  for segment in range(3):
   var lower=segment/3.0
   var upper=(segment+1)/3.0
   for uv in [Vector2(-1.0,lower),Vector2(1.0,lower),Vector2(-1.0,upper),Vector2(1.0,lower),Vector2(1.0,upper),Vector2(-1.0,upper)]:
    surface.set_uv(Vector2(uv.x*0.5+0.5,uv.y))
    surface.add_vertex(blade_point(blade,uv.y,uv.x))
 surface.generate_normals()
 return surface.commit()

static func birch_point(point:Vector3)->Vector3:
 var spread=1.0+0.35*smoothstep(1.4,3.0,point.y)
 return Vector3(point.x*spread,point.y*1.45,point.z*spread)

static func distant_birch_mesh(bark:Material)->ArrayMesh:
 var temporary=Node3D.new()
 DemoNature.birch(temporary,2471,bark)
 var source:Mesh
 for node in temporary.get_children():
  if node is MeshInstance3D and not node.is_queued_for_deletion():source=node.mesh
 var arrays=source.surface_get_arrays(0)
 var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
 var bounds=source.get_aabb()
 for index in range(vertices.size()):
  var point=vertices[index]
  point.x*=2.0
  point.z*=2.0
  point.y=(point.y-bounds.position.y)/bounds.size.y*5.5-2.75
  vertices[index]=point
 arrays[Mesh.ARRAY_VERTEX]=vertices
 var mesh=ArrayMesh.new()
 mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 var surface=SurfaceTool.new()
 surface.create_from(mesh,0)
 surface.generate_normals()
 temporary.free()
 return surface.commit()

static func birches(game:Node3D):
 var trees:Array[Node3D]=[]
 var old_transforms=[]
 var relocated=0
 for tree in game.get_children():
  if not tree.has_meta("crown_tips"):continue
  trees.append(tree)
  old_transforms.append(tree.global_transform)
  var offset=Vector2(tree.position.x-7.0,tree.position.z+6.0)
  if offset.length()<4.5:
   var bank=offset.normalized()*4.7
   tree.position.x=7.0+bank.x
   tree.position.z=-6.0+bank.y
   relocated+=1
  for node in tree.get_children():
   if not node is MeshInstance3D or node.is_queued_for_deletion():continue
   var arrays=node.mesh.surface_get_arrays(0)
   var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
   for index in range(vertices.size()):vertices[index]=birch_point(vertices[index])
   arrays[Mesh.ARRAY_VERTEX]=vertices
   var mesh=ArrayMesh.new()
   mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
   var surface=SurfaceTool.new()
   surface.create_from(mesh,0)
   surface.generate_normals()
   node.mesh=surface.commit()
 # Reuse the original leaf drawing, with mip levels for this profile only.
 var leaf_image=load("res://assets/textures/birch-twig.svg").get_image()
 leaf_image.generate_mipmaps()
 var leaf_texture=ImageTexture.create_from_image(leaf_image)
 var far_trunks:MultiMeshInstance3D
 var far_crown:MultiMeshInstance3D
 for node in game.find_children("*","MultiMeshInstance3D",true,false):
  if node.name=="BirchCrowns":
   var old=node.multimesh
   var leaves=MultiMesh.new()
   leaves.transform_format=MultiMesh.TRANSFORM_3D
   leaves.use_colors=true
   leaves.use_custom_data=true
   leaves.mesh=old.mesh
   leaves.instance_count=old.instance_count*3
   var rng=RandomNumberGenerator.new()
   rng.seed=20261016
   var tree_index=0
   var next_tree=trees[0].get_meta("crown_tips").size()*13
   for index in range(old.instance_count):
    while index>=next_tree and tree_index+1<trees.size():
     tree_index+=1
     next_tree+=trees[tree_index].get_meta("crown_tips").size()*13
    var tree=trees[tree_index]
    var original=old.get_instance_transform(index)
    var local=old_transforms[tree_index].affine_inverse()*original.origin
    for copy in range(3):
     var transform=original
     var jitter=Vector3.ZERO if copy==0 else Vector3(rng.randf_range(-0.13,0.13),rng.randf_range(-0.13,0.13),rng.randf_range(-0.13,0.13))
     transform.origin=tree.to_global(birch_point(local)+jitter)
     if copy>0:transform.basis=transform.basis.rotated(Vector3.UP,rng.randf_range(-1.0,1.0))
     leaves.set_instance_transform(index*3+copy,transform)
     leaves.set_instance_color(index*3+copy,old.get_instance_color(index))
     leaves.set_instance_custom_data(index*3+copy,old.get_instance_custom_data(index))
   node.multimesh=leaves
   node.material_override=node.material_override.duplicate()
   node.material_override.set_shader_parameter("leaf_texture",leaf_texture)
  elif node.material_override is ShaderMaterial and node.material_override.shader.resource_path.ends_with("/birch.gdshader"):
   far_trunks=node
  elif node.material_override is StandardMaterial3D and node.material_override.albedo_texture and node.material_override.albedo_texture.resource_path.ends_with("/birch-twig.svg"):
   far_crown=node
 if far_trunks and far_crown:
  far_trunks.multimesh.mesh=distant_birch_mesh(far_trunks.material_override)
  var crowns=MultiMesh.new()
  crowns.transform_format=MultiMesh.TRANSFORM_3D
  crowns.use_colors=true
  var card=QuadMesh.new()
  card.size=Vector2(0.32,0.37)
  crowns.mesh=card
  var leaves_per_tree=2400
  crowns.instance_count=far_trunks.multimesh.instance_count*leaves_per_tree
  var rng=RandomNumberGenerator.new()
  rng.seed=1637
  for index in range(far_trunks.multimesh.instance_count):
   var trunk=far_trunks.multimesh.get_instance_transform(index)
   var height=trunk.basis.y.length()
   var base=trunk.origin-Vector3.UP*2.75*height
   trunk.basis=trunk.basis.scaled(Vector3(1.0,1.6,1.0))
   trunk.origin=base+Vector3.UP*4.4*height
   far_trunks.multimesh.set_instance_transform(index,trunk)
   var width=rng.randf_range(2.6,3.2)
   for leaf in range(leaves_per_tree):
    var t=rng.randf_range(0.02,0.98)
    var radius=sqrt(rng.randf())*width*pow(sin(t*PI),0.65)
    var angle=rng.randf()*TAU
    var point=base+Vector3(cos(angle)*radius,(4.8+4.7*t)*height,sin(angle)*radius)
    var basis=Basis.from_euler(Vector3(rng.randf_range(-1.2,1.2),rng.randf()*TAU,rng.randf_range(-0.8,0.8)))
    crowns.set_instance_transform(index*leaves_per_tree+leaf,Transform3D(basis,point))
    crowns.set_instance_color(index*leaves_per_tree+leaf,Color(0.80,0.90,0.76)*rng.randf_range(0.85,1.08))
  far_crown.multimesh=crowns
  far_crown.material_override=far_crown.material_override.duplicate()
  far_crown.material_override.albedo_texture=leaf_texture
  far_crown.material_override.alpha_scissor_threshold=0.20
 print("QUALITY_BIRCHES_APPLIED near=",trees.size()," far=",far_trunks.multimesh.instance_count if far_trunks else 0," moved_from_water=",relocated)

static func bank_point(segment:int,ring:int)->Vector3:
 var angle=segment*TAU/128.0
 var variation=0.11*sin(angle*3.0+0.7)+0.07*sin(angle*7.0-0.3)+0.04*cos(angle*11.0)
 var radii=[3.27,3.61,3.97,4.40]
 var heights=[0.020,0.032,0.040,-0.009]
 var radius=radii[ring]+variation
 # The old bank node origin is y=-0.004. The water surface stays at y=0.029.
 return Vector3(cos(angle)*radius,heights[ring]+0.004,sin(angle)*radius)

static func shoreline(game:Node3D,earth:ShaderMaterial,rock_material:Material):
 var pond=Vector3(7.0,0.0,-6.0)
 var rng=RandomNumberGenerator.new()
 rng.seed=4823
 var shore_rocks=0
 for node in game.find_children("*","MeshInstance3D",true,false):
  if node.mesh is CylinderMesh and is_equal_approx(node.mesh.top_radius,4.05) and node.position.distance_to(Vector3(7.0,-0.004,-6.0))<0.01:
   var surface=SurfaceTool.new()
   surface.begin(Mesh.PRIMITIVE_TRIANGLES)
   for ring in range(3):
    for segment in range(128):
     for offset in [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
      surface.add_vertex(bank_point(segment+offset.x,ring+offset.y))
   surface.generate_normals()
   node.mesh=surface.commit()
   var bank=earth.duplicate()
   bank.set_shader_parameter("turf_coverage",0.12)
   bank.set_shader_parameter("shore_wetness",0.70)
   node.material_override=bank
  elif node.material_override==rock_material:
   var delta=node.global_position-pond
   if Vector2(delta.x,delta.z).length()<4.35 and Vector2(delta.x,delta.z).length()>3.5:
    # Retain the existing stones, but break the evenly spaced necklace.
    var group=floor(shore_rocks/5.0)
    var angle=group*0.79+rng.randf_range(-0.16,0.16)
    var radius=4.0+0.11*sin(angle*3.0+0.7)+rng.randf_range(-0.05,0.20)
    node.position.x=pond.x+cos(angle)*radius
    node.position.z=pond.z+sin(angle)*radius
    shore_rocks+=1
 print("QUALITY_SHORE_APPLIED repositioned_stones=",shore_rocks)

static func grass_allowed(point:Vector3)->bool:
 if absf(point.x+2.5)<1.4 and point.z>-0.9 and point.z<5.0:return false
 if Vector2(point.x-7.0,point.z+6.0).length()<4.1:return false
 return point.x>-17.0 and point.x<17.0 and point.z>-14.0 and point.z<14.0

static func grass_patches(game:Node3D,node:MultiMeshInstance3D):
 var mesh=grass_mesh()
 var material=ShaderMaterial.new()
 material.shader=load("res://assets/shaders/grass_quality.gdshader")
 var patches=[]
 for index in range(9):patches.append([])
 var rng=RandomNumberGenerator.new()
 rng.seed=3926
 var old=node.multimesh
 for index in range(old.instance_count):
  var original=old.get_instance_transform(index)
  if original.origin.y<0.0:continue
  for copy in range(6):
   var transform=original
   if copy>0:
    transform.origin+=Vector3(rng.randf_range(-0.40,0.40),0.0,rng.randf_range(-0.40,0.40))
    transform.basis=transform.basis.rotated(Vector3.UP,rng.randf()*TAU)
   if not grass_allowed(transform.origin):continue
   var column=clampi(int((transform.origin.x+18.0)/12.0),0,2)
   var row=clampi(int((transform.origin.z+15.0)/10.0),0,2)
   patches[row*3+column].append([transform,old.get_instance_color(index),Color(rng.randf(),0.0,0.0,1.0)])
 var total=0
 for index in range(patches.size()):
  var mm=MultiMesh.new()
  mm.transform_format=MultiMesh.TRANSFORM_3D
  mm.use_colors=true
  mm.use_custom_data=true
  mm.mesh=mesh
  mm.instance_count=patches[index].size()
  for instance in range(mm.instance_count):
   mm.set_instance_transform(instance,patches[index][instance][0])
   mm.set_instance_color(instance,patches[index][instance][1])
   mm.set_instance_custom_data(instance,patches[index][instance][2])
  var chunk=node if index==0 else MultiMeshInstance3D.new()
  if index>0:
   game.add_child(chunk)
   chunk.transform=node.transform
  chunk.name="QualityGrassPatch"+str(index)
  chunk.multimesh=mm
  chunk.material_override=material
  chunk.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  total+=mm.instance_count
 print("QUALITY_GRASS_APPLIED clumps=",total," patches=",patches.size())

static func apply(game:Node3D,rock_material:Material,earth:ShaderMaterial,replace_birches:bool=true):
 var rock_count=0
 for node in game.find_children("*","MeshInstance3D",true,false):
  if not node.material_override is StandardMaterial3D:continue
  var color=node.material_override.albedo_color
  if color.is_equal_approx(Color("676d61")) or (node.mesh is SphereMesh and color.is_equal_approx(Color("52685b"))):
   node.mesh=rock_mesh(node.mesh.get_aabb(),881+rock_count*17)
   node.material_override=rock_material
   rock_count+=1
 for node in game.find_children("*","MultiMeshInstance3D",true,false):
  if node.material_override is ShaderMaterial and node.material_override.shader.resource_path.ends_with("/grass.gdshader"):
   grass_patches(game,node)
 print("QUALITY_GEOMETRY_APPLIED rocks=",rock_count)
 if replace_birches:birches(game)
 shoreline(game,earth,rock_material)
