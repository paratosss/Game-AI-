extends RigidBody3D
class_name DemoProp
var kind=""
var title=""
var pieces:Array=[]
var side=0
var visuals:Node3D
var refresh_clock=0.0
var placed_slot=-1
func build(k:String,t:String):
 kind=k;title=t;mass=.18 if k=="skewer" else .35;linear_damp=.35;angular_damp=2.0
 visuals=Node3D.new();add_child(visuals)
 if k=="skewer":
  DemoVisual.skewer(visuals);DemoVisual.collider(self,Vector3(.04,.025,.90))
  var pm=PhysicsMaterial.new();pm.friction=1.2;physics_material_override=pm
 elif k=="ball":
  DemoVisual.sphere(visuals,.19,Color("c3c5bd"))
  for i in range(6):
   var g=Node3D.new();visuals.add_child(g);g.rotation=Vector3((i%3)*PI/2,(i/3)*PI,0)
   DemoVisual.sphere(g,.19,Color("365a79") if i%2==0 else Color("54788a"),Vector3(0,0,.006),Vector3(.29,.88,1))
  var c=CollisionShape3D.new();var s=SphereShape3D.new();s.radius=.19;c.shape=s;add_child(c)
  var pm=PhysicsMaterial.new();pm.bounce=.60;pm.friction=.7;physics_material_override=pm;angular_damp=.15
 elif k=="fan":
  DemoVisual.box(visuals,Vector3(.27,.015,.29),Color("936643"))
  for i in range(7):DemoVisual.box(visuals,Vector3(.23,.006,.012),Color("b9956b"),Vector3(0,.010,(i-3)*.038))
  DemoVisual.box(visuals,Vector3(.030,.022,.25),Color("61432e"),Vector3(0,0,.25));DemoVisual.collider(self,Vector3(.27,.025,.55))
func refresh():
 for n in visuals.get_children():
  if n.has_meta("food"):
   visuals.remove_child(n);n.queue_free()
 for c in get_children():
  if c.has_meta("food_hit"):remove_child(c);c.queue_free()
 for i in range(pieces.size()):
  var n=DemoVisual.food(visuals,pieces[i],Vector3(0,.024,(i-(pieces.size()-1)*.5)*.105));n.set_meta("food",true)
  var hit=CollisionShape3D.new();var shape=SphereShape3D.new();shape.radius=.045;hit.shape=shape;hit.position=n.position;hit.set_meta("food_hit",true);add_child(hit)
