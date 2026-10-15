extends RefCounted
class_name DemoWorld
static func shader(path:String)->ShaderMaterial:
 var m=ShaderMaterial.new();m.shader=load("res://assets/shaders/"+path+".gdshader")
 if path=="wood":
  m.set_shader_parameter("wood_color",load("res://assets/textures/wood_table_diff.jpg"));m.set_shader_parameter("wood_normal",load("res://assets/textures/wood_table_normal.jpg"));m.set_shader_parameter("wood_rough",load("res://assets/textures/wood_table_rough.jpg"))
 if path=="ground":
  m.set_shader_parameter("earth_color",load("res://assets/textures/forest_ground_diff.jpg"));m.set_shader_parameter("earth_normal",load("res://assets/textures/forest_ground_normal.jpg"));m.set_shader_parameter("earth_rough",load("res://assets/textures/forest_ground_rough.jpg"))
 if path=="steel":
  m.set_shader_parameter("steel_color",load("res://assets/textures/pbr/rusty_metal_04_diff.jpg"));m.set_shader_parameter("steel_normal",load("res://assets/textures/pbr/rusty_metal_04_nor_gl.jpg"));m.set_shader_parameter("steel_rough",load("res://assets/textures/pbr/rusty_metal_04_rough.jpg"))
 if path=="birch":
  m.set_shader_parameter("bark_color",load("res://assets/textures/pbr/bark_brown_01_diff.jpg"));m.set_shader_parameter("bark_normal",load("res://assets/textures/pbr/bark_brown_01_nor_gl.jpg"));m.set_shader_parameter("bark_rough",load("res://assets/textures/pbr/bark_brown_01_rough.jpg"))
 return m
static func wood(parent:Node3D,size:Vector3,pos:Vector3):
 var n=DemoVisual.rounded_box(parent,size,Color("624833"),pos,.004);n.material_override=shader("wood")
 n.material_override.set_shader_parameter("grain_offset",Vector2(pos.y*2.13+pos.z*1.87,pos.x*.371+pos.z*1.17))
 return n
static func bench(game:Node3D,pos:Vector3)->StaticBody3D:
 var n=StaticBody3D.new();game.add_child(n);n.position=pos
 for z in [-.14,0,.14]:wood(n,Vector3(1.9,.045,.125),Vector3(0,.46,z))
 for x in [-.72,.72]:
  DemoVisual.box(n,Vector3(.065,.44,.4),Color("293b39"),Vector3(x,.22,0))
  DemoVisual.box(n,Vector3(.065,.9,.055),Color("293b39"),Vector3(x,.48,-.21))
 for y in [.72,.86]:wood(n,Vector3(1.9,.105,.04),Vector3(0,y,-.21))
 DemoVisual.collider(n,Vector3(1.9,.5,.46),Vector3(0,.25,0));return n
static func build(game:Node3D)->Dictionary:
 var env=WorldEnvironment.new();var e=Environment.new();e.background_mode=Environment.BG_SKY
 var sky=Sky.new();var sm=ShaderMaterial.new();sm.shader=load("res://assets/shaders/picnic_sky.gdshader");sky.sky_material=sm;e.sky=sky
 e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color("b0b9bb");e.ambient_light_energy=.53
 e.fog_enabled=true;e.fog_light_color=Color("9ab3c1");e.fog_density=.0018;e.fog_sky_affect=.18
 env.environment=e;game.add_child(env)
 var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-47,-48,0);sun.light_color=Color("fff0dc");sun.light_energy=.80;sun.shadow_enabled=true;sun.directional_shadow_max_distance=30;sun.shadow_blur=2.5;game.add_child(sun)
 var ground=game.solid(Vector3(0,-.16,0),Vector3(36,.3,30),Color("43543c"));ground.get_child(0).material_override=shader("ground")
 # Ground Box UV repeats on sides; top is the playable clearing.
 backdrop(game)
 var water=DemoVisual.cylinder(game,3.7,.028,Color("2c5365"),Vector3(7,.015,-6));water.material_override=shader("water")
 DemoVisual.cylinder(game,4.05,.02,Color("494e3f"),Vector3(7,-.004,-6))
 var rng=RandomNumberGenerator.new();rng.seed=27
 for i in range(40):
  var angle=i*TAU/40;var r=3.8+rng.randf_range(-.1,.4)
  var p=Vector3(7+cos(angle)*r,.08,-6+sin(angle)*r)
  rock(game,p,rng.randf_range(.09,.28),rng)
 for i in range(22):
  var angle=i*TAU/22+.1;var radius=rng.randf_range(9.0,15.0);var p=Vector3(cos(angle)*radius,0,sin(angle)*radius)
  if p.z>5 and absf(p.x)<5:continue
  var tree=Node3D.new();game.add_child(tree);tree.position=p;tree.rotation.y=angle;tree.scale.y=rng.randf_range(.86,1.23)
  DemoNature.birch(tree,i*153+27,shader("birch"))
  var body=StaticBody3D.new();tree.add_child(body);var c=CollisionShape3D.new();var shape=CylinderShape3D.new();shape.radius=.12;shape.height=4.3;c.shape=shape;c.position.y=2.15;body.add_child(c)
  if i%3==0:DemoVisual.sphere(game,.55,Color("52685b"),p+Vector3(.6,.2,.5),Vector3(1,.5,1.5))
 DemoNature.foliage(game)
 grass(game,rng)
 distant_forest(game,rng)
 details(game,rng)
 # Proper furniture with separate planks, legs and metal bracing.
 var table=game.solid(Vector3(-3.2,.78,2.9),Vector3(3.4,.09,1.15),Color("72563f"));table.get_child(0).material_override=shader("wood")
 for x in [-4.55,-1.85]:
  for z in [2.5,3.3]:game.solid(Vector3(x,.37,z),Vector3(.09,.74,.09),Color("384339"))
  DemoVisual.box(game,Vector3(.1,.075,.95),Color("384339"),Vector3(x,.16,2.9))
 for z in [2.35,3.45]:DemoVisual.box(game,Vector3(3.45,.035,.03),Color("323f3c"),Vector3(-3.2,.775,z))
 var fs=DemoRules.FOODS.keys()
 for i in range(fs.size()):game.station(Vector3(-4.48+i*.61,.86,2.62),DemoRules.FOODS[fs[i]].name,"food",fs[i])
 game.station(Vector3(-4.18,.94,3.15),"Луковый маринад","marinade","onion");game.station(Vector3(-3.54,.94,3.15),"Кефирный маринад","marinade","kefir")
 var grill=game.solid(game.grill_pos+Vector3(0,.66,0),Vector3(1.5,.10,.68),Color("252d30"));grill.set_meta("action","grill")
 for z in [-.345,.345]:
  var rail=game.solid(game.grill_pos+Vector3(0,.785,z),Vector3(1.5,.18,.035),Color("343c40"));rail.set_meta("action","grill")
 for x in [-.75,.75]:
  var rail=game.solid(game.grill_pos+Vector3(x,.785,0),Vector3(.025,.18,.69),Color("343c40"));rail.set_meta("action","grill")
 for x in [-.6,.6]:
  for z in [-.26,.26]:game.solid(game.grill_pos+Vector3(x,.33,z),Vector3(.032,.66,.032),Color("343c40"))
  DemoVisual.box(game,Vector3(.04,.035,.56),Color("343c40"),game.grill_pos+Vector3(x,.1,0))
 for i in range(24):
  var p=game.grill_pos+Vector3((i%8-3.5)*.16,.74,(i/8-1)*.16)
  DemoVisual.sphere(game,.069,Color("342f2b"),p,Vector3(1,.55,1))
  if i%3==0:DemoVisual.sphere(game,.022,Color("9b4527"),p+Vector3(0,.035,0),Vector3(1,.3,1))
 for i in range(14):DemoVisual.box(game,Vector3(.035,.025,.007),Color("141d20"),game.grill_pos+Vector3((i-6.5)*.095,.76,.364))
 var led=OmniLight3D.new();game.add_child(led);led.position=game.grill_pos+Vector3(0,.78,0);led.light_color=Color("d18243");led.light_energy=.18;led.omni_range=1.2
 # Side picnic area and props bring scale and life to the clearing.
 var b=bench(game,Vector3(0,0,-3.2))
 bench(game,Vector3(2.5,0,-3.6)).rotation.y=-.35
 var picnic=game.solid(Vector3(1.25,.55,-3.4),Vector3(.65,.08,.55),Color("78604b"));picnic.get_child(0).material_override=shader("wood")
 for x in [.99,1.51]:game.solid(Vector3(x,.27,-3.4),Vector3(.035,.54,.4),Color("354239"))
 DemoNature.bowl(game,.11,.27,Color("c6cbc1"),Vector3(1.35,.605,-3.45))
 DemoNature.bowl(game,.075,.06,Color("e2d9c8"),Vector3(1.05,.60,-3.4))
 for x in [3.3,7.4]:
  DemoVisual.cylinder(game,.025,2.2,Color("777a71"),Vector3(x,1.1,1.1))
  DemoVisual.sphere(game,.05,Color("ae6550"),Vector3(x,2.2,1.1))
 # Narrow boundary cord, behind the sports area, never between kitchen and guests.
 DemoVisual.box(game,Vector3(4.1,.006,.007),Color("8a8a79"),Vector3(5.35,1.85,1.1))
 var smoke=CPUParticles3D.new();game.add_child(smoke);smoke.position=game.grill_pos+Vector3(0,.78,0);smoke.amount=12;smoke.lifetime=2.8;smoke.emission_shape=CPUParticles3D.EMISSION_SHAPE_BOX;smoke.emission_box_extents=Vector3(.53,.02,.21);smoke.direction=Vector3.UP;smoke.spread=18;smoke.gravity=Vector3(.015,.01,0);smoke.initial_velocity_min=.09;smoke.initial_velocity_max=.18;smoke.scale_amount_min=.6;smoke.scale_amount_max=1.4
 var quad=QuadMesh.new();quad.size=Vector2(.23,.23);smoke.mesh=quad
 var mat=StandardMaterial3D.new();mat.albedo_texture=load("res://assets/textures/smoke.svg");mat.albedo_color=Color(.70,.76,.76,.18);mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED;smoke.material_override=mat;smoke.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;smoke.emitting=false
 hero_details(game)
 return {"bench":b,"environment":env,"smoke":smoke}
static func grass(game:Node3D,rng:RandomNumberGenerator):
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in range(8):
  var ang=i*2.399;var center=Vector3(cos(ang)*.042,0,sin(ang)*.042)
  var side=Vector3(cos(ang)*.007,0,sin(ang)*.007);var h=.065+(i%3)*.025
  var tip=center+Vector3(.025,h,.014)
  for point in [[center-side,Vector2(0,0)],[center+side,Vector2(1,0)],[tip,Vector2(.5,1)]]:
   st.set_uv(point[1]);st.add_vertex(point[0])
 st.generate_normals();var mesh=st.commit()
 var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.use_colors=true;mm.use_custom_data=true;mm.mesh=mesh;mm.instance_count=6500
 for i in range(6500):
  var pos=Vector3(rng.randf_range(-17,17),0,rng.randf_range(-14,14))
  if absf(pos.x+2.5)<1.4 and pos.z>-.9 and pos.z<5:pos.y=-1
  if pos.distance_to(Vector3(7,0,-6))<4.1:pos.y=-1
  if pos.distance_to(Vector3(5,0,3))<3 and i%3!=0:pos.y=-1
  var size=rng.randf_range(.55,1.3);var basis=Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*size)
  mm.set_instance_transform(i,Transform3D(basis,pos));mm.set_instance_color(i,Color(rng.randf_range(.75,1),rng.randf_range(.85,1),rng.randf_range(.75,.95)));mm.set_instance_custom_data(i,Color(rng.randf(),0,0,1))
 var n=MultiMeshInstance3D.new();n.multimesh=mm;n.material_override=shader("grass");n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;game.add_child(n)

static func leaves(game:Node3D,rng:RandomNumberGenerator):
 var quad=QuadMesh.new();quad.size=Vector2(.38,.34)
 var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.use_colors=true;mm.mesh=quad;mm.instance_count=22*300
 var trees=[]
 for node in game.get_children():
  if node is Node3D and node.get_child_count()>3 and node.get_child(0) is MeshInstance3D and node.get_child(0).material_override is ShaderMaterial:
   if node.get_child(0).material_override.shader==load("res://assets/shaders/birch.gdshader"):trees.append(node)
 var count=0
 for tree in trees:
  for j in range(300):
   var a=rng.randf()*TAU;var h=rng.randf_range(2.9,4.8);var radius=sqrt(rng.randf())*(1.35-absf(h-3.85)*.45)
   var pos=tree.position+Vector3(cos(a)*radius,h,sin(a)*radius)
   var basis=Basis.from_euler(Vector3(rng.randf_range(-.9,.9),rng.randf()*TAU,rng.randf_range(-.4,.4)))
   mm.set_instance_transform(count,Transform3D(basis,pos));mm.set_instance_color(count,Color(rng.randf_range(.7,.95),rng.randf_range(.82,1.0),rng.randf_range(.7,.9)));count+=1
 mm.visible_instance_count=count
 var mat=StandardMaterial3D.new();mat.albedo_color=Color("7d8b55");mat.albedo_texture=load("res://assets/textures/birch-twig.svg");mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR;mat.alpha_scissor_threshold=.4;mat.cull_mode=BaseMaterial3D.CULL_DISABLED;mat.roughness=1.0;mat.vertex_color_use_as_albedo=true
 var n=MultiMeshInstance3D.new();n.multimesh=mm;n.material_override=mat;game.add_child(n)

static func backdrop(game:Node3D):
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for z in range(-20,20):
  for x in range(-20,20):
   for off in [Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
    var p=Vector3((x+off.x)*3,0,(z+off.y)*3);var r=Vector2(p.x,p.z).length()
    p.y=-.14+clampf((r-17)/12,0,1)*(1.8+sin(p.x*.10)*1.3+cos(p.z*.12)*.8)
    st.add_vertex(p)
 st.generate_normals();var n=MeshInstance3D.new();n.mesh=st.commit();n.material_override=shader("ground");game.add_child(n)

static func rock(parent:Node3D,p:Vector3,r:float,rng:RandomNumberGenerator):
 var mesh=SphereMesh.new();mesh.radius=r;mesh.height=r*1.45;mesh.radial_segments=12;mesh.rings=7
 var arrays=mesh.get_mesh_arrays();var vertices=arrays[Mesh.ARRAY_VERTEX]
 for i in range(vertices.size()):
  var v=vertices[i];vertices[i]=v*(.92+.14*sin(v.x*31+v.y*27+v.z*23))
 arrays[Mesh.ARRAY_VERTEX]=vertices
 var geo=ArrayMesh.new();geo.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 var n=DemoVisual.mesh(parent,geo,Color("676d61"),p);n.rotation=Vector3(rng.randf()*.3,rng.randf()*TAU,rng.randf()*.2);n.scale=Vector3(1.3,.8,1)
static func details(game:Node3D,rng:RandomNumberGenerator):
 # Reed beds in irregular shoreline groups; food and sports paths remain clear.
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in range(110):
  var angle=rng.randf_range(PI*.45,PI*1.6);var p=Vector3(7+cos(angle)*4.04,0,-6+sin(angle)*4.04)
  var h=rng.randf_range(.3,.67)
  for v in [p+Vector3(-.009,0,0),p+Vector3(.009,0,0),p+Vector3(.055,h,.025)]:st.add_vertex(v)
 st.generate_normals();var reeds=MeshInstance3D.new();reeds.mesh=st.commit();reeds.material_override=DemoVisual.mat(Color("726e41"));game.add_child(reeds)
 # A fallen branch, irregular stones and plants outside the usable clearing.
 for i in range(35):
  var p=Vector3(rng.randf_range(-14,14),.035,rng.randf_range(-12,12))
  if absf(p.x)<8 and p.z>-5 and p.z<6:continue
  rock(game,p,rng.randf_range(.12,.45),rng)
 for i in range(12):
  var p=Vector3(rng.randf_range(-12,12),.02,rng.randf_range(-10,-6))
  for j in range(4):
   var leaf=DemoVisual.sphere(game,.16,Color("506242"),p+Vector3((j%2-.5)*.16,.06,(j/2-.5)*.16),Vector3(1,.24,1.9));leaf.rotation.y=j*.7

static func distant_forest(game:Node3D,rng:RandomNumberGenerator):
 var cylinder=CylinderMesh.new();cylinder.top_radius=.08;cylinder.bottom_radius=.15;cylinder.height=5.5;cylinder.radial_segments=8
 var trunks=MultiMesh.new();trunks.transform_format=MultiMesh.TRANSFORM_3D;trunks.mesh=cylinder;trunks.instance_count=85
 var quad=QuadMesh.new();quad.size=Vector2(.40,.45)
 var foliage=MultiMesh.new();foliage.transform_format=MultiMesh.TRANSFORM_3D;foliage.use_colors=true;foliage.mesh=quad;foliage.instance_count=85*100
 for i in range(85):
  var angle=i*2.399;var radius=rng.randf_range(22,53);var p=Vector3(cos(angle)*radius,0,sin(angle)*radius)
  p.y=-.14+clampf((radius-17)/12,0,1)*(1.8+sin(p.x*.10)*1.3+cos(p.z*.12)*.8)
  var height=rng.randf_range(.85,1.45);trunks.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3(1,height,1)),p+Vector3(0,2.75*height,0)))
  for j in range(100):
   var a=rng.randf()*TAU;var r=sqrt(rng.randf())*1.8;var h=rng.randf_range(3.1,6.0)
   var q=p+Vector3(cos(a)*r,h*height,sin(a)*r)
   foliage.set_instance_transform(i*100+j,Transform3D(Basis.from_euler(Vector3(rng.randf()-.5,rng.randf()*TAU,rng.randf()-.5)),q));foliage.set_instance_color(i*100+j,Color("5c704a"))
 var bark=MultiMeshInstance3D.new();bark.multimesh=trunks;bark.material_override=shader("birch");bark.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;game.add_child(bark)
 var mat=StandardMaterial3D.new();mat.albedo_texture=load("res://assets/textures/birch-twig.svg");mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR;mat.alpha_scissor_threshold=.4;mat.cull_mode=BaseMaterial3D.CULL_DISABLED;mat.roughness=1.0;mat.vertex_color_use_as_albedo=true
 var crown=MultiMeshInstance3D.new();crown.multimesh=foliage;crown.material_override=mat;crown.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;game.add_child(crown)

static func hero_details(game:Node3D):
 # Keep collision and action surfaces unchanged; replace the visible surfaces.
 for node in game.get_children():
  if node is StaticBody3D and node.get_child_count()>0 and node.get_child(0) is MeshInstance3D:
   var m=node.get_child(0)
   if node.position.distance_to(Vector3(-3.2,.78,2.9))<.01:m.visible=false
   if node.has_meta("action") and node.get_meta("action")=="grill":
    if m.mesh is BoxMesh:m.mesh=DemoVisual.rounded_geometry(m.mesh.size,.008)
    var steel=shader("steel");m.material_override=steel
 var t=Node3D.new();t.name="CraftedTable";game.add_child(t)
 # Seven individual boards with seams, end grain, softened edges and fasteners.
 for j in range(7):
  var board=wood(t,Vector3(3.40,.048,.159),Vector3(-3.2,.802,2.9+(j-3)*.164))
  for x in [-4.52,-1.88]:
   var bolt=DemoVisual.cylinder(t,.006,.002,Color("696965"),Vector3(x,.827,2.9+(j-3)*.164));bolt.material_override=DemoVisual.mat(Color("7b7c76"),.6)
 for x in [-4.55,-1.85]:
  for z in [2.5,3.3]:
   DemoVisual.rounded_box(t,Vector3(.108,.75,.108),Color("4b4a41"),Vector3(x,.37,z),.006)
  DemoVisual.rod(t,Vector3(x-.19,.15,2.51),Vector3(x+.19,.60,3.29),.012,Color("3c4444"),.5)
 var fill=OmniLight3D.new();game.add_child(fill);fill.position=Vector3(-.8,2.8,-.4);fill.light_color=Color("d9e7eb");fill.light_energy=.25;fill.omni_range=6.5
 var g=game.grill_pos
 for side in [-1,1]:
  DemoVisual.rod(game,g+Vector3(side*.61,.1,-.27),g+Vector3(side*.61,.57,.27),.012,Color("42464a"),.6)
  DemoVisual.rod(game,g+Vector3(side*.61,.1,.27),g+Vector3(side*.61,.57,-.27),.012,Color("42464a"),.6)
  var handle=Node3D.new();game.add_child(handle);handle.position=g+Vector3(side*.80,.78,0)
  DemoVisual.rod(handle,Vector3(0,0,-.11),Vector3(side*.06,0,-.11),.012,Color("64686a"),.7)
  DemoVisual.rod(handle,Vector3(0,0,.11),Vector3(side*.06,0,.11),.012,Color("64686a"),.7)
  DemoVisual.rod(handle,Vector3(side*.06,0,-.11),Vector3(side*.06,0,.11),.015,Color("333a3c"),.4)
 for x in range(11):DemoVisual.rod(game,g+Vector3((x-5)*.107,.13,-.27),g+Vector3((x-5)*.107,.13,.27),.005,Color("44494b"),.6)
 # Irregular charcoal, small embers and ash; never a uniform row of spheres.
 var rng=RandomNumberGenerator.new();rng.seed=412
 for i in range(45):
  var pos=g+Vector3(rng.randf_range(-.64,.64),.763,rng.randf_range(-.23,.23))
  var coal=DemoVisual.rounded_box(game,Vector3(rng.randf_range(.06,.11),rng.randf_range(.025,.05),rng.randf_range(.05,.09)),Color("292826"),pos,.012);coal.rotation=Vector3(rng.randf()*.3,rng.randf()*TAU,rng.randf()*.25)
  var mat=DemoVisual.mat(Color("33312e")).duplicate();mat.roughness=1;coal.material_override=mat
  if i%5==0:
   var ember=DemoVisual.sphere(game,.012,Color("b15427"),pos+Vector3(.015,.025,0),Vector3(1,.30,1));var glow=DemoVisual.mat(Color("a44b23")).duplicate();glow.emission_enabled=true;glow.emission=Color("b84816");glow.emission_energy_multiplier=.35;ember.material_override=glow
