extends RefCounted
class_name DemoVisual

static var materials:Dictionary = {}
static func mat(color:Color,metal:float=0.0) -> StandardMaterial3D:
 var key = str(color)+str(metal)
 if materials.has(key): return materials[key]
 var m = StandardMaterial3D.new()
 m.albedo_color=color
 m.roughness=0.82 if metal==0.0 else 0.3
 m.metallic=metal
 materials[key]=m
 return m
static func mesh(parent:Node3D,geometry:Mesh,color:Color,pos:Vector3=Vector3.ZERO,metal:float=0.0) -> MeshInstance3D:
 var n=MeshInstance3D.new()
 n.mesh=geometry
 n.material_override=mat(color,metal)
 n.position=pos
 parent.add_child(n)
 return n
static func box(parent:Node3D,size:Vector3,color:Color,pos:Vector3=Vector3.ZERO) -> MeshInstance3D:
 var m=BoxMesh.new();m.size=size
 return mesh(parent,m,color,pos)
static func sphere(parent:Node3D,radius:float,color:Color,pos:Vector3=Vector3.ZERO,stretch:Vector3=Vector3.ONE) -> MeshInstance3D:
 var m=SphereMesh.new();m.radius=radius;m.height=radius*2;m.radial_segments=20;m.rings=10
 var n=mesh(parent,m,color,pos);n.scale=stretch
 return n
static func cylinder(parent:Node3D,r:float,h:float,color:Color,pos:Vector3=Vector3.ZERO) -> MeshInstance3D:
 var m=CylinderMesh.new();m.top_radius=r;m.bottom_radius=r;m.height=h;m.radial_segments=32
 return mesh(parent,m,color,pos)
static func tag(parent:Node3D,text:String,pos:Vector3,size:int=24) -> Label3D:
 var l=Label3D.new();l.text=text;l.position=pos;l.font_size=size;l.pixel_size=0.006;l.billboard=BaseMaterial3D.BILLBOARD_ENABLED;l.modulate=Color("fcf4de");l.outline_modulate=Color("263d2b");l.outline_size=6
 parent.add_child(l);return l
static func collider(parent:CollisionObject3D,size:Vector3,pos:Vector3=Vector3.ZERO) -> CollisionShape3D:
 var c=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=size;c.shape=shape;c.position=pos;parent.add_child(c);return c
static func food(parent:Node3D,p:Dictionary,pos:Vector3=Vector3.ZERO) -> Node3D:
 var g=Node3D.new();parent.add_child(g);g.position=pos
 var color:Color=DemoRules.FOODS[p.food].color
 var amt=maxf(p.sides[0],p.sides[1]);color=color.lerp(Color("29261e") if amt>1.35 else Color("84512c"),0.9 if amt>1.35 else minf(amt*0.5,0.75))
 match p.food:
  "zucchini":
   var a=cylinder(g,.045,.055,Color("667c3e").lerp(Color("695633"),minf(amt*.38,.7)));a.rotation.x=PI/2
   var b=cylinder(g,.035,.058,Color("c2cba1").lerp(Color("aa9063"),minf(amt*.22,.6)));b.rotation.x=PI/2
   for i in range(6):
    var angle=i*TAU/6;var seed=sphere(g,.003,Color("b4be93"),Vector3(cos(angle)*.016,sin(angle)*.016,.030),Vector3(.70,1.9,.32));seed.rotation.z=-angle
  "mushroom":
   cylinder(g,.02,.06,Color("e5d8b9"),Vector3(0,-.015,0))
   var cap=sphere(g,.047,Color("c5b995").lerp(Color("76583a"),minf(amt*.38,.7)),Vector3(0,.025,0),Vector3(1,.65,1))
   cap.material_override=mat(Color("c5b995")).duplicate();cap.material_override.roughness=.74
   for i in range(16):
    var angle=i*TAU/16;rod(g,Vector3(cos(angle)*.023,.014,sin(angle)*.023),Vector3(cos(angle)*.042,.014,sin(angle)*.042),.0008,Color("988366"))
  "chicken","pork":
   var piece=mesh(g,protein_geometry(),color)
   var material=ShaderMaterial.new();material.shader=load("res://assets/shaders/food.gdshader")
   material.set_shader_parameter("raw_tint",Color("bb7568") if p.food=="pork" else Color("c9a495"))
   material.set_shader_parameter("pork",1.0 if p.food=="pork" else 0.0)
   material.set_shader_parameter("cook_top",p.sides[0]);material.set_shader_parameter("cook_bottom",p.sides[1]);piece.material_override=material
  "pepper":
   var red=rounded_box(g,Vector3(.077,.039,.070),color,Vector3.ZERO,.011);red.rotation.z=.15
   rounded_box(g,Vector3(.054,.005,.048),Color("d0bc83"),Vector3(0,.022,0),.002)
  _:
   sphere(g,.049,color,Vector3.ZERO,Vector3(1,.72,1.1))
 if p.dirty: sphere(g,.012,Color("68553a"),Vector3(.025,.033,.015))
 return g
static func skewer(parent:Node3D) -> void:
 var b=BoxMesh.new();b.size=Vector3(.022,.006,.78)
 mesh(parent,b,Color("c4ccc5"),Vector3(0,0,-.025),.6)
 var tip=PrismMesh.new();tip.size=Vector3(.022,.006,.06)
 var t=mesh(parent,tip,Color("c4ccc5"),Vector3(0,0,-.43),.6);t.rotation.y=PI
 var loop=TorusMesh.new();loop.inner_radius=.023;loop.outer_radius=.031;loop.rings=12;loop.ring_segments=8
 var l=mesh(parent,loop,Color("c4ccc5"),Vector3(0,0,.41),.6);l.scale=Vector3(1,1,1.5)
static func guitar(parent:Node3D) -> Node3D:
 var g=Node3D.new();g.name="AcousticGuitar";parent.add_child(g)
 var half=[Vector2(0,-.285),Vector2(.095,-.26),Vector2(.165,-.20),Vector2(.190,-.105),Vector2(.175,-.015),Vector2(.120,.075),Vector2(.115,.125),Vector2(.145,.20),Vector2(.132,.26),Vector2(.080,.305),Vector2(0,.312)]
 var outline=[]
 for point in half:outline.append(point)
 for i in range(half.size()-2,0,-1):outline.append(Vector2(-half[i].x,half[i].y))
 var curve=[]
 for i in range(outline.size()):
  var a=outline[posmod(i-1,outline.size())];var b=outline[i];var c=outline[(i+1)%outline.size()];var d=outline[(i+2)%outline.size()]
  for j in range(6):
   var t=j/6.;curve.append(.5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t))
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for side in [-1,1]:
  for i in range(curve.size()):
   var a=curve[i];var b=curve[(i+1)%curve.size()]
   for v in [Vector3(0,.02,side*.047),Vector3(a.x,a.y,side*.047),Vector3(b.x,b.y,side*.047)]:st.set_normal(Vector3(0,0,side));st.set_uv(Vector2(v.x/.4+.5,v.y/.6+.5));st.add_vertex(v)
 var front=MeshInstance3D.new();front.mesh=st.commit();g.add_child(front)
 var top=ShaderMaterial.new();top.shader=load("res://assets/shaders/guitar_wood.gdshader");front.material_override=top
 st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in range(curve.size()):
  var a=curve[i];var b=curve[(i+1)%curve.size()]
  for v in [Vector3(a.x,a.y,-.047),Vector3(a.x,a.y,.047),Vector3(b.x,b.y,-.047),Vector3(b.x,b.y,-.047),Vector3(a.x,a.y,.047),Vector3(b.x,b.y,.047)]:st.add_vertex(v)
 st.generate_normals();var edges=MeshInstance3D.new();edges.mesh=st.commit();edges.material_override=mat(Color("4d3020"));edges.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED;g.add_child(edges)
 for i in range(curve.size()):
  var a=curve[i];var b=curve[(i+1)%curve.size()];rod(g,Vector3(a.x,a.y,.048),Vector3(b.x,b.y,.048),.0018,Color("c4a675"))
 var hole=cylinder(g,.052,.003,Color("171719"),Vector3(0,.105,.050));hole.rotation.x=PI/2
 var rim=TorusMesh.new();rim.inner_radius=.052;rim.outer_radius=.058;rim.rings=48;rim.ring_segments=8
 var ring=mesh(g,rim,Color("9d7b4e"),Vector3(0,.105,.052));ring.rotation.x=PI/2
 rounded_box(g,Vector3(.062,.435,.03),Color("65412c"),Vector3(0,.507,.032),.006)
 rounded_box(g,Vector3(.056,.445,.008),Color("292323"),Vector3(0,.50,.052),.003)
 var head=rounded_box(g,Vector3(.078,.142,.022),Color("6c452c"),Vector3(0,.79,.038),.007);head.rotation.z=-.08
 rounded_box(g,Vector3(.114,.029,.012),Color("33251e"),Vector3(0,-.034,.057),.003)
 box(g,Vector3(.080,.003,.007),Color("b9a68b"),Vector3(0,-.028,.065))
 for fret in range(1,17):
  var y=.728-.444*(1-pow(2,-fret/12.))
  box(g,Vector3(.058,.0018,.002),Color("b4b6b0"),Vector3(0,y,.058))
 for i in range(6):
  rod(g,Vector3((i-2.5)*.007,-.028,.066),Vector3((i-2.5)*.006,.739,.062),.00035 if i<3 else .0006,Color("a6a29a"),.7)
  var side=-1 if i<3 else 1;var y=.756+(i%3)*.038
  rod(g,Vector3(side*.03,y,.035),Vector3(side*.050,y,.035),.003,Color("9c9b8e"),.7);sphere(g,.006,Color("aaa99e"),Vector3(side*.056,y,.035),Vector3(.7,1.3,.55))
 return g

static func rounded_geometry(size:Vector3,radius:float=.006)->ArrayMesh:
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var h=size*.5;var inner=h-Vector3.ONE*minf(radius,minf(h.x,minf(h.y,h.z))*.8)
 for axis in range(3):
  for sign in [-1,1]:
   for y in range(8):
    for x in range(8):
     for off in ([Vector2(0,0),Vector2(0,1),Vector2(1,0),Vector2(1,0),Vector2(0,1),Vector2(1,1)] if sign==1 else [Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,0),Vector2(1,1),Vector2(0,1)]):
      var p=Vector3.ZERO;p[axis]=h[axis]*sign;p[(axis+1)%3]=((x+off.x)/8.*2-1)*h[(axis+1)%3];p[(axis+2)%3]=((y+off.y)/8.*2-1)*h[(axis+2)%3]
      var q=p.clamp(-inner,inner);var normal=(p-q).normalized();st.set_normal(normal);st.set_uv(Vector2((x+off.x)/8.,(y+off.y)/8.));st.add_vertex(q+normal*radius)
 st.index();st.generate_tangents();return st.commit()
static func rounded_box(parent:Node3D,size:Vector3,col:Color,pos:Vector3=Vector3.ZERO,radius:float=.006)->MeshInstance3D:
 var n=mesh(parent,rounded_geometry(size,radius),col,pos);n.material_override=mat(col).duplicate();n.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED;return n
static func rod(parent:Node3D,a:Vector3,b:Vector3,r:float,col:Color,metal:float=0)->MeshInstance3D:
 var n=cylinder(parent,r,a.distance_to(b),col,(a+b)*.5);n.quaternion=Quaternion(Vector3.UP,(b-a).normalized());n.material_override=mat(col,metal);return n

static var protein_mesh:ArrayMesh
static func protein_geometry()->ArrayMesh:
 if protein_mesh:return protein_mesh
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for y in range(16):
  for x in range(24):
   for off in [Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
    var lat=((y+off.y)/16.0-.5)*PI;var az=(x+off.x)*TAU/24.0
    var v=Vector3(cos(lat)*cos(az),sin(lat),cos(lat)*sin(az))
    for axis in range(3):v[axis]=signf(v[axis])*pow(absf(v[axis]),.66)
    var irregular=.94+.035*sin(v.x*7+v.z*8)+.024*cos(v.y*11-v.z*4)
    v*=Vector3(.043,.030,.048)*irregular
    st.set_uv(Vector2((x+off.x)/24.0,(y+off.y)/16.0));st.add_vertex(v)
 st.index();st.generate_normals();st.generate_tangents();protein_mesh=st.commit();return protein_mesh
