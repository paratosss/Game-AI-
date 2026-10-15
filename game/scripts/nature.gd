extends RefCounted
class_name DemoNature

static func tapered_branch(parent:Node3D,a:Vector3,b:Vector3,r0:float,r1:float,material:Material):
 var mesh=CylinderMesh.new();mesh.bottom_radius=r0;mesh.top_radius=r1;mesh.height=a.distance_to(b);mesh.radial_segments=10
 var n=MeshInstance3D.new();n.mesh=mesh;n.material_override=material;n.position=(a+b)*.5;n.quaternion=Quaternion(Vector3.UP,(b-a).normalized());parent.add_child(n)

static func birch(tree:Node3D,seed:int,bark:Material):
 var rng=RandomNumberGenerator.new();rng.seed=seed
 var tips=[];var height=rng.randf_range(4.3,5.3);var bend=Vector2(rng.randf_range(-.23,.23),rng.randf_range(-.16,.16))
 var last=Vector3.ZERO
 for j in range(8):
  var t=(j+1)/8.0;var p=Vector3(bend.x*t*t,height*t,bend.y*t*t)
  tapered_branch(tree,last,p,.105*(1-j/9.0),.105*(1-(j+1)/9.0),bark);last=p
 for j in range(13):
  var t=.43+j*.039;var az=j*2.399+rng.randf_range(-.3,.3)
  var start=Vector3(bend.x*t*t,height*t,bend.y*t*t)
  var length=rng.randf_range(.80,1.40)*(1-absf(t-.63)*1.2)
  var side=Vector3(cos(az),0,sin(az));var mid=start+side*length*.55+Vector3(0,.26,0)
  var end=start+side*length+Vector3(0,.48+rng.randf()*.32,0)
  tapered_branch(tree,start,mid,.026*(1-t*.55),.010,bark);tapered_branch(tree,mid,end,.010,.003,bark)
  tips.append(end)
  for k in range(3):
   var f=.40+k*.22;var root=mid.lerp(end,f)
   var tip=root+side.rotated(Vector3.UP,(-1 if k%2==0 else 1)*.8)*.35+Vector3(0,.10,0)
   tapered_branch(tree,root,tip,.004,.0015,bark);tips.append(tip)
 tips.append(last)
 tree.set_meta("crown_tips",tips)
 # Branches do not move independently: one mesh per existing tree reduces draws.
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for node in tree.get_children():
  if node is MeshInstance3D:
   st.append_from(node.mesh,0,node.transform);node.queue_free()
 var crown_support=MeshInstance3D.new();crown_support.mesh=st.commit();crown_support.material_override=bark;tree.add_child(crown_support)

static func foliage(game:Node3D):
 var quad=QuadMesh.new();quad.size=Vector2(.25,.29)
 var list=[];var rng=RandomNumberGenerator.new();rng.seed=713
 for tree in game.get_children():
  if not tree.has_meta("crown_tips"):continue
  for tip in tree.get_meta("crown_tips"):
   for j in range(13):
    var offset=Vector3(rng.randf_range(-.30,.30),rng.randf_range(-.25,.32),rng.randf_range(-.30,.30))
    var size=rng.randf_range(.70,1.30)
    var basis=Basis.from_euler(Vector3(rng.randf_range(-1.1,1.1),rng.randf()*TAU,rng.randf_range(-.65,.65))).scaled(Vector3.ONE*size)
    list.append([Transform3D(tree.global_basis*basis,tree.to_global(tip+offset)),Color(rng.randf_range(.78,.97),rng.randf_range(.85,1),rng.randf_range(.78,.96)),rng.randf()])
 var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.use_colors=true;mm.use_custom_data=true;mm.mesh=quad;mm.instance_count=list.size()
 for i in range(list.size()):
  mm.set_instance_transform(i,list[i][0]);mm.set_instance_color(i,list[i][1]);mm.set_instance_custom_data(i,Color(list[i][2],0,0,1))
 var mat=ShaderMaterial.new();mat.shader=load("res://assets/shaders/foliage.gdshader");mat.set_shader_parameter("leaf_texture",load("res://assets/textures/birch-twig.svg"))
 var n=MultiMeshInstance3D.new();n.name="BirchCrowns";n.multimesh=mm;n.material_override=mat;game.add_child(n)

static func bowl(parent:Node3D,radius:float,height:float,col:Color,pos:Vector3)->MeshInstance3D:
 var profile=[Vector2(0,0),Vector2(radius*.73,0),Vector2(radius*.98,height*.30),Vector2(radius,height),Vector2(radius*.88,height),Vector2(radius*.82,height*.34),Vector2(0,height*.25)]
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for j in range(profile.size()-1):
  for i in range(48):
   for off in [Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
    var q=profile[j+int(off.y)];var a=(i+off.x)*TAU/48.0;var p=Vector3(cos(a)*q.x,q.y,sin(a)*q.x)
    st.set_uv(Vector2((i+off.x)/48.0,(j+off.y)/profile.size()));st.add_vertex(p)
 st.generate_normals();var n=DemoVisual.mesh(parent,st.commit(),col,pos);n.material_override=DemoVisual.mat(col).duplicate();n.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED;n.material_override.roughness=.32
 return n
