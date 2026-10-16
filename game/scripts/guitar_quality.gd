extends RefCounted
## Original concert acoustic model. Metres; no brand marks or borrowed mesh.
const SCALE_LENGTH=0.648
const NUT_Y=0.620
const SADDLE_Y=-0.028
const STRING_Z=0.0615
const HOLE=Vector2(0,0.100)
const HOLE_RADIUS=0.048

static func string_z_at(y:float)->float:return lerpf(.0622,.0588,(y-SADDLE_Y)/SCALE_LENGTH)
static func fret_y(number:int)->float:return NUT_Y-SCALE_LENGTH*(1.0-pow(2.0,-number/12.0))
static func wood(color:String,axis:Vector3,coat:float=0.30)->ShaderMaterial:
 var mat=ShaderMaterial.new();mat.shader=load("res://assets/shaders/instrument_wood.gdshader")
 mat.set_shader_parameter("wood_color",Color(color));mat.set_shader_parameter("grain_axis",axis);mat.set_shader_parameter("coat",coat)
 return mat
static func plain(color:String,metal:float=0.0,rough:float=.45)->StandardMaterial3D:
 var mat=StandardMaterial3D.new();mat.albedo_color=Color(color);mat.metallic=metal;mat.roughness=rough;return mat
static func outline()->PackedVector2Array:
 var half=[Vector2(0,-.250),Vector2(.090,-.238),Vector2(.160,-.192),Vector2(.184,-.118),Vector2(.172,-.042),Vector2(.120,.035),Vector2(.110,.090),Vector2(.136,.145),Vector2(.130,.204),Vector2(.075,.238),Vector2(0,.240)]
 var knots=[]
 for p in half:knots.append(p)
 for i in range(half.size()-2,0,-1):knots.append(Vector2(-half[i].x,half[i].y))
 var points=PackedVector2Array()
 for i in range(knots.size()):
  var a=knots[posmod(i-1,knots.size())];var b=knots[i];var c=knots[(i+1)%knots.size()];var d=knots[(i+2)%knots.size()]
  for j in range(10):
   var t=j/10.0;points.append(.5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t))
 return points
static func triangle(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,normal:Vector3,normals:Array=[]):
 # Godot front faces are clockwise. This also prevents a hidden inverted top.
 if (b-a).cross(c-a).dot(normal)>0:
  var swap=b;b=c;c=swap
  if not normals.is_empty():swap=normals[1];normals[1]=normals[2];normals[2]=swap
 var vertices=[a,b,c]
 for i in range(3):
  var p=vertices[i];st.set_normal(normal if normals.is_empty() else normals[i]);st.set_uv(Vector2(p.x,p.y));st.add_vertex(p)
static func surface(parent:Node3D,st:SurfaceTool,material:Material,label:String)->MeshInstance3D:
 st.index();st.generate_tangents()
 var node=MeshInstance3D.new();node.name=label;node.mesh=st.commit();node.material_override=material;parent.add_child(node);return node
static func flat_ring(parent:Node3D,center:Vector2,inner:float,outer:float,z:float,mat:Material,label:String):
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in range(128):
  var a=Vector2(cos(i*TAU/128),sin(i*TAU/128));var b=Vector2(cos((i+1)*TAU/128),sin((i+1)*TAU/128))
  var p=center+a*inner;var q=center+a*outer;var r=center+b*outer;var s=center+b*inner
  triangle(st,Vector3(p.x,p.y,z),Vector3(q.x,q.y,z),Vector3(r.x,r.y,z),Vector3.FORWARD*-1)
  triangle(st,Vector3(p.x,p.y,z),Vector3(r.x,r.y,z),Vector3(s.x,s.y,z),Vector3.FORWARD*-1)
 surface(parent,st,mat,label)
static func rod(parent:Node3D,a:Vector3,b:Vector3,radius:float,material:Material,label:String=""):
 var mesh=CylinderMesh.new();mesh.top_radius=radius;mesh.bottom_radius=radius;mesh.height=a.distance_to(b);mesh.radial_segments=12
 var node=MeshInstance3D.new();node.name=label if not label.is_empty() else "Detail";node.mesh=mesh;node.material_override=material;node.position=(a+b)*.5;node.quaternion=Quaternion(Vector3.UP,(b-a).normalized());parent.add_child(node)
static func rounded(parent:Node3D,size:Vector3,position:Vector3,radius:float,mat:Material,label:String)->MeshInstance3D:
 var node=MeshInstance3D.new();node.mesh=DemoVisual.rounded_geometry(size,radius);node.material_override=mat;node.position=position;node.name=label;parent.add_child(node);return node
static func build(parent:Node3D)->Node3D:
 var guitar=Node3D.new();guitar.name="ConcertAcoustic";parent.add_child(guitar)
 guitar.set_meta("scale_length_m",SCALE_LENGTH);guitar.set_meta("nut_y",NUT_Y);guitar.set_meta("saddle_y",SADDLE_Y);guitar.set_meta("string_z",STRING_Z)
 var spruce=wood("d3aa68",Vector3.RIGHT,.38);var walnut=wood("67402c",Vector3(0,0,1),.30);var back=wood("754a31",Vector3.RIGHT,.30)
 var inside=wood("493122",Vector3.RIGHT,.0);var ebony=wood("29201d",Vector3.RIGHT,.12);var neckwood=wood("77503c",Vector3.RIGHT,.24)
 var binding=plain("d8c5a0",0,.38);var dark=plain("211713",0,.65);var metal=plain("b8bab7",.88,.22)
 var points=outline();guitar.set_meta("outline",points)
 # Annular soundboard: the sound hole is an opening, never a black disk.
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in range(points.size()):
  var a=points[i];var b=points[(i+1)%points.size()];var ia=HOLE+(a-HOLE).normalized()*HOLE_RADIUS;var ib=HOLE+(b-HOLE).normalized()*HOLE_RADIUS
  triangle(st,Vector3(a.x,a.y,.047),Vector3(b.x,b.y,.047),Vector3(ib.x,ib.y,.048),Vector3(0,0,1))
  triangle(st,Vector3(a.x,a.y,.047),Vector3(ib.x,ib.y,.048),Vector3(ia.x,ia.y,.048),Vector3(0,0,1))
 surface(guitar,st,spruce,"Soundboard")
 for spec in [[-.047,Vector3(0,0,-1),back,"Back"],[-.044,Vector3(0,0,1),inside,"CavityBack"]]:
  st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
  for i in range(points.size()):
   var a=points[i];var b=points[(i+1)%points.size()]
   triangle(st,Vector3(0,0,spec[0]),Vector3(a.x,a.y,spec[0]),Vector3(b.x,b.y,spec[0]),spec[1])
  surface(guitar,st,spec[2],spec[3])
 for inner in [false,true]:
  st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
  var depth=.044 if inner else .047
  for i in range(points.size()):
   var a=points[i];var b=points[(i+1)%points.size()]
   var ea=(b-points[posmod(i-1,points.size())]).normalized();var eb=(points[(i+2)%points.size()]-a).normalized()
   var na=Vector3(ea.y,-ea.x,0)*(-1 if inner else 1);var nb=Vector3(eb.y,-eb.x,0)*(-1 if inner else 1);var normal=(na+nb).normalized()
   triangle(st,Vector3(a.x,a.y,-depth),Vector3(b.x,b.y,-depth),Vector3(b.x,b.y,depth),normal,[na,nb,nb])
   triangle(st,Vector3(a.x,a.y,-depth),Vector3(b.x,b.y,depth),Vector3(a.x,a.y,depth),normal,[na,nb,na])
  surface(guitar,st,inside if inner else walnut,"CavitySides" if inner else "BodySides")
 for side in [-1,1]:
  st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
  for i in range(points.size()):
   var a=points[i];var b=points[(i+1)%points.size()];var na=(a-HOLE).normalized();var nb=(b-HOLE).normalized();var ia=a-na*.0016;var ib=b-nb*.0016
   triangle(st,Vector3(a.x,a.y,side*.0474),Vector3(b.x,b.y,side*.0474),Vector3(ib.x,ib.y,side*.0474),Vector3(0,0,side))
   triangle(st,Vector3(a.x,a.y,side*.0474),Vector3(ib.x,ib.y,side*.0474),Vector3(ia.x,ia.y,side*.0474),Vector3(0,0,side))
  surface(guitar,st,binding,"Binding"+str(side))
 # The cut edge of the top makes the opening readable at oblique angles.
 st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in range(128):
  var a=Vector2(cos(i*TAU/128),sin(i*TAU/128));var b=Vector2(cos((i+1)*TAU/128),sin((i+1)*TAU/128));var pa=HOLE+a*HOLE_RADIUS;var pb=HOLE+b*HOLE_RADIUS;var n=Vector3(-a.x,-a.y,0)
  triangle(st,Vector3(pa.x,pa.y,.048),Vector3(pb.x,pb.y,.048),Vector3(pb.x,pb.y,.0448),n)
  triangle(st,Vector3(pa.x,pa.y,.048),Vector3(pb.x,pb.y,.0448),Vector3(pa.x,pa.y,.0448),n)
 surface(guitar,st,inside,"SoundHoleEdge")
 for ring in [[.0484,.0494,dark],[.0494,.0505,binding],[.0505,.0512,dark],[.0512,.0534,back],[.0534,.0540,binding],[.0540,.0545,dark]]:
  flat_ring(guitar,HOLE,ring[0],ring[1],.0484,ring[2],"Rosette")
 # D-section neck, tapered from the heel to the nut.
 st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for y_index in range(18):
  var y0=lerpf(.226,NUT_Y,y_index/18.0);var y1=lerpf(.226,NUT_Y,(y_index+1)/18.0)
  for a_index in range(24):
   var vertices=[];var normals=[]
   for pair in [[y0,a_index],[y1,a_index],[y1,a_index+1],[y0,a_index+1]]:
    var u=(pair[0]-.226)/(NUT_Y-.226);var angle=PI+pair[1]*PI/24.0;var width=lerpf(.028,.0215,u)
    vertices.append(Vector3(cos(angle)*width,pair[0],.050+sin(angle)*lerpf(.032,.020,u)));normals.append(Vector3(cos(angle),0,sin(angle)).normalized())
   triangle(st,vertices[0],vertices[1],vertices[2],(normals[0]+normals[1]+normals[2]).normalized(),[normals[0],normals[1],normals[2]])
   triangle(st,vertices[0],vertices[2],vertices[3],(normals[0]+normals[2]+normals[3]).normalized(),[normals[0],normals[2],normals[3]])
 surface(guitar,st,neckwood,"NeckBack")
 # Fingerboard follows the same scale/fret law as all six strings.
 st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var bottom=fret_y(20)-.005
 var a=Vector3(-.028,bottom,.056);var b=Vector3(.028,bottom,.056);var c=Vector3(.0215,NUT_Y,.056);var d=Vector3(-.0215,NUT_Y,.056)
 triangle(st,a,b,c,Vector3(0,0,1));triangle(st,a,c,d,Vector3(0,0,1))
 var board=[a,b,c,d]
 for i in range(4):
  var p=board[i];var q=board[(i+1)%4];var e=(q-p).normalized();var n=Vector3(e.y,-e.x,0)
  triangle(st,p,q,Vector3(q.x,q.y,.050),n);triangle(st,p,Vector3(q.x,q.y,.050),Vector3(p.x,p.y,.050),n)
 surface(guitar,st,ebony,"Fingerboard")
 for fret in range(1,21):
  var y=fret_y(fret);var width=lerpf(.0215,.028,(NUT_Y-y)/(NUT_Y-bottom))
  rod(guitar,Vector3(-width,y,.057),Vector3(width,y,.057),.0008,metal,"Fret%02d"%fret)
 for fret in [3,5,7,9,12,15,17]:
  var y=(fret_y(fret)+fret_y(fret-1))*.5
  for x in [-.006,.006] if fret==12 else [0.0]:
   rod(guitar,Vector3(x,y,.0562),Vector3(x,y,.0566),.0022,binding,"Inlay")
 var head=rounded(guitar,Vector3(.076,.125,.018),Vector3(0,.686,.034),.006,neckwood,"Headstock");head.rotation.x=-.18
 rounded(guitar,Vector3(.046,.005,.006),Vector3(0,NUT_Y,.0558),.001,binding,"Nut")
 rounded(guitar,Vector3(.140,.033,.012),Vector3(0,-.046,.053),.005,ebony,"Bridge")
 var saddle=rounded(guitar,Vector3(.078,.0025,.006),Vector3(0,SADDLE_Y,.0592),.0008,binding,"Saddle");saddle.rotation.z=-.025
 for i in range(6):
  var x=(i-2.5)*.007
  rod(guitar,Vector3(x,-.053,.058),Vector3(x,-.053,.061),.0024,dark,"BridgePin")
  rod(guitar,Vector3(x,-.053,.061),Vector3(x,-.053,.0617),.0007,binding,"PinDot")
  var material=plain("b9a075" if i<3 else "bcc0bf",.90,.24)
  var radius=[.00058,.00046,.00036,.00024,.00018,.00013][i]
  rod(guitar,Vector3(x,-.053,.0618),Vector3(x,SADDLE_Y,.0622),radius,material,"StringAnchor%d"%i)
  rod(guitar,Vector3(x,SADDLE_Y,.0622),Vector3((i-2.5)*.006,NUT_Y,.0588),radius,material,"String%d"%i)
  var side=-1 if i<3 else 1;var y=.653+(i%3)*.033;var post=Vector3(side*.024,y,.049-(y-.653)*.18)
  rod(guitar,Vector3((i-2.5)*.006,NUT_Y,.0588),post,radius,material,"StringToPost%d"%i)
  rod(guitar,post-Vector3(0,0,.009),post+Vector3(0,0,.004),.003,metal,"TuningPost")
  rod(guitar,Vector3(side*.032,y,post.z-.012),Vector3(side*.047,y,post.z-.012),.0028,metal,"TunerShaft")
  rounded(guitar,Vector3(.012,.019,.006),Vector3(side*.052,y,post.z-.012),.0025,metal,"TunerButton")
 rounded(guitar,Vector3(.014,.025,.0015),Vector3(0,.642,.052),.003,dark,"TrussRodCover")
 guitar.set_meta("geometry_version",5)
 return guitar
