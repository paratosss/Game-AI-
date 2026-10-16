extends RefCounted
## Graft only the new body mesh/bindings onto the preserved animated skeleton.
## The head, garment, original 63 bones and their animation tracks stay intact.
static func apply(instance:Node3D):
 var skeleton:Skeleton3D=instance.find_children("*","Skeleton3D",true,false)[0]
 var target:MeshInstance3D=instance.find_children("Human","MeshInstance3D",true,false)[0]
 var candidate=load("res://assets/characters/studies/AlinaBody06.glb").instantiate()
 var source:MeshInstance3D=candidate.find_children("Human","MeshInstance3D",true,false)[0]
 var source_skeleton:Skeleton3D=candidate.find_children("*","Skeleton3D",true,false)[0]
 # Reject a retargeting mismatch rather than hiding it under the new mesh.
 for i in range(skeleton.get_bone_count()):
  var j=source_skeleton.find_bone(skeleton.get_bone_name(i))
  assert(j>=0,"Body revision lost an original bone")
  assert(skeleton.get_bone_global_rest(i).is_equal_approx(source_skeleton.get_bone_global_rest(j)),"Body revision changed the animation rest rig")
 for side in ["l","r"]:
  for level in ["mid","end"]:
   var name="forearm_twist_"+level+"_"+side
   var j=source_skeleton.find_bone(name)
   skeleton.add_bone(name)
   var i=skeleton.find_bone(name)
   skeleton.set_bone_parent(i,skeleton.find_bone("lowerarm_"+side))
   skeleton.set_bone_rest(i,source_skeleton.get_bone_rest(j));skeleton.reset_bone_pose(i)
 var rebuilt=source.mesh.duplicate()
 assert(rebuilt.get_surface_count()==target.mesh.get_surface_count(),"Body revision changed material surfaces")
 for i in range(rebuilt.get_surface_count()):rebuilt.surface_set_material(i,target.mesh.surface_get_material(i))
 target.mesh=rebuilt;target.skin=source.skin
 target.set_meta("body_revision",6)
 skeleton.force_update_all_bone_transforms()
 candidate.free()
