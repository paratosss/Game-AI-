extends SceneTree
func _initialize():call_deferred("run")
func run():
 for who in ["Алина","Круглик","Крысюк"]:
  var skin=DemoHumanSkin.new();root.add_child(skin);skin.setup(who,Color.WHITE)
  skin.native_animation.play("walk");skin.native_animation.advance(1.0)
  var rows=[]
  for i in range(150):
   skin.native_animation.advance(.01)
   var l=skin.global_pose("foot_l").origin;var r=skin.global_pose("foot_r").origin
   rows.append([l.x,l.y,l.z,r.x,r.y,r.z])
  print("WALK_MEASURE ",JSON.stringify({"who":who,"rest":skin.rest.foot_l.origin.y,"length":skin.native_animation.get_animation("walk").length,"samples":rows}))
  skin.queue_free()
 quit()
