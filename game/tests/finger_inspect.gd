extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);g.initialized=false
 for a in g.actors:a.set_physics_process(false)
 var a=g.actors[0];var h=a.model.skin
 for i in range(120):h.tick(1./60,false,0,"guitar",a.guitar,Vector3.ZERO)
 print("FINGER REST ",h.rest.index_01_l.basis," HAND REST ",h.rest.hand_l.basis)
 for n in ["hand_l","index_04_leaf_l","middle_04_leaf_l","ring_04_leaf_l","pinky_04_leaf_l","thumb_04_leaf_l"]:
  print(n,": ",a.guitar.to_local(h.to_global(h.global_pose(n).origin)))
 g.clean_quit()
