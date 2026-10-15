extends SceneTree
func _initialize():call_deferred("run")
func run():
 for name in ["Superhero_Female_FullBody","Superhero_Male_FullBody","Hair_Long"]:
  var n=load("res://assets/characters/"+name+".gltf").instantiate();root.add_child(n)
  print("MODEL ",name)
  for c in n.find_children("*","MeshInstance3D",true,false):print(c.name," box=",c.get_aabb()," transform=",c.global_transform," surfaces=",c.mesh.get_surface_count())
  for c in n.find_children("*","Skeleton3D",true,false):
   for b in range(c.get_bone_count()):
    if c.get_bone_name(b) in ["Head","neck_01"]:print("bone ",c.get_bone_name(b)," global rest=",c.get_bone_global_rest(b))
  n.queue_free()
 quit()
