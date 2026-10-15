extends RefCounted
class_name DemoRig
static func pivot(parent:Node3D,n:String,p:Vector3)->Node3D:
 var b=Node3D.new();b.name=n;b.position=p;parent.add_child(b);return b
static func segment(parent:Node3D,r:float,h:float,col:Color,pos:Vector3):
 var m=CapsuleMesh.new();m.radius=r;m.height=h;m.radial_segments=12;m.rings=4
 return DemoVisual.mesh(parent,m,col,pos)
static func human(parent:Node3D,who:String,col:Color)->Dictionary:
 var skin=DemoHumanSkin.new();parent.add_child(skin);return skin.setup(who,col)
static func dog(parent:Node3D)->Dictionary:
 var skin=DemoDogSkin.new();parent.add_child(skin);return skin.setup()
