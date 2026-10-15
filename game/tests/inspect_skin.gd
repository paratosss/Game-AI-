extends SceneTree
func _initialize():call_deferred("run")
func run():
 var a=load("res://assets/characters/Superhero_Female_FullBody.gltf").instantiate();root.add_child(a);a.print_tree_pretty()
 var s=a.find_children("*","Skeleton3D",true,false)[0]
 for n in ["pelvis","spine_03","neck_01","Head","upperarm_l","lowerarm_l","hand_l","thigh_l","calf_l","foot_l"]:
  var b=s.find_bone(n);print(n," ",s.get_bone_global_rest(b)," local=",s.get_bone_rest(b))
 for m in a.find_children("*","MeshInstance3D",true,false):print(m.name," skeleton path=",m.skeleton," mat=",m.mesh.surface_get_material(0))
 a.queue_free();quit()
