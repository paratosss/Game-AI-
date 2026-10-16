extends RefCounted
## One shared height function for visible ground, the playable collider and plant roots.
const POND=Vector2(7.0,-6.0)

static func height_at(x:float,z:float)->float:
 var radius=Vector2(x,z).length()
 var edge=maxf(absf(x)-7.8,maxf(z-6.2,-z-4.5))
 var border=smoothstep(0.0,5.0,edge)
 var undulation=0.16+0.12*sin(x*0.43+z*0.31)+0.09*cos(x*0.79-z*0.23)
 var clearing=-0.01+border*undulation
 var original_backdrop=-0.14+clampf((radius-17.0)/12.0,0.0,1.0)*(1.8+sin(x*0.10)*1.3+cos(z*0.12)*0.8)
 var result=lerpf(clearing,original_backdrop,smoothstep(15.0,30.0,radius))
 var distance=Vector2(x-7.0,z+6.0).length()
 if distance<4.3:
  var bed=-0.52+0.56*smoothstep(0.0,4.05,distance)
  result=lerpf(bed,result,smoothstep(3.95,4.3,distance))
 return result

static func point(x:float,z:float)->Vector3:return Vector3(x,height_at(x,z),z)

static func normal_at(x:float,z:float)->Vector3:
 var dx=(height_at(x+0.04,z)-height_at(x-0.04,z))/0.08
 var dz=(height_at(x,z+0.04)-height_at(x,z-0.04))/0.08
 return Vector3(-dx,1.0,-dz).normalized()

static func mesh_grid(half_x:int,half_z:int,step:float,outer:bool=false)->ArrayMesh:
 var surface=SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for row in range(-half_z,half_z):
  for column in range(-half_x,half_x):
   if outer and column>=-6 and column<6 and row>=-5 and row<5:continue
   for offset in [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
    var x=(column+offset.x)*step
    var z=(row+offset.y)*step
    surface.set_normal(normal_at(x,z))
    surface.set_uv(Vector2(x,z))
    surface.add_vertex(point(x,z))
 surface.index()
 surface.generate_tangents()
 return surface.commit()

static func apply(game:Node3D,earth:ShaderMaterial):
 for mesh in game.find_children("*","MeshInstance3D",true,false):
  if mesh.material_override is ShaderMaterial and mesh.material_override.shader.resource_path.ends_with("/ground_pbr.gdshader"):
   mesh.visible=false
   if mesh.get_parent() is StaticBody3D:
    for child in mesh.get_parent().get_children():
     if child is CollisionShape3D and child.shape is BoxShape3D and child.shape.size.is_equal_approx(Vector3(36,0.3,30)):
      child.disabled=true
 var body=StaticBody3D.new()
 body.name="LakesideGround"
 game.add_child(body)
 var ground=MeshInstance3D.new()
 ground.name="SculptedGround"
 body.add_child(ground)
 ground.mesh=mesh_grid(36,30,0.5)
 ground.material_override=earth.duplicate()
 ground.material_override.set_shader_parameter("turf_coverage",0.50)
 ground.material_override.set_shader_parameter("shore_wetness",0.85)
 var shape=CollisionShape3D.new()
 body.add_child(shape)
 shape.shape=ground.mesh.create_trimesh_shape()
 var backdrop=MeshInstance3D.new()
 game.add_child(backdrop)
 backdrop.name="LakesideBackdrop"
 backdrop.mesh=mesh_grid(20,20,3.0,true)
 backdrop.material_override=ground.material_override
 for tree in game.get_children():
  if tree.has_meta("crown_tips"):tree.position.y=height_at(tree.position.x,tree.position.z)+0.01
 for mesh in game.find_children("*","MeshInstance3D",true,false):
  if mesh.material_override is ShaderMaterial and mesh.material_override.shader.resource_path.ends_with("/rock_pbr.gdshader"):
   mesh.position.y+=height_at(mesh.position.x,mesh.position.z)+0.01
 print("LAKESIDE_TERRAIN_APPLIED triangles=",ground.mesh.surface_get_array_index_len(0)/3," center_depth=",0.029-height_at(7.0,-6.0))
