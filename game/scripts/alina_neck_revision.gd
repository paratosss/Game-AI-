extends RefCounted
## Replace only the cervical/head geometry. Original animation and materials stay.
static func apply(instance:Node3D):
 var skeleton:Skeleton3D=instance.find_children("*","Skeleton3D",true,false)[0]
 var candidate=load("res://assets/characters/studies/AlinaNeck11.glb").instantiate()
 var rig:Skeleton3D=candidate.find_children("*","Skeleton3D",true,false)[0]
 for i in range(skeleton.get_bone_count()):
  var j=rig.find_bone(skeleton.get_bone_name(i))
  assert(j>=0 and skeleton.get_bone_global_rest(i).is_equal_approx(rig.get_bone_global_rest(j)),"Neck reconstruction changed the animation rest rig")
 var source:MeshInstance3D=candidate.find_children("AlinaRevisionHead","MeshInstance3D",true,false)[0]
 var target:MeshInstance3D=instance.find_children("AlinaRevisionHead","MeshInstance3D",true,false)[0]
 assert(source.mesh.get_surface_count()==target.mesh.get_surface_count() and source.mesh.get_blend_shape_count()==63)
 var materials=[]
 for i in range(target.mesh.get_surface_count()):materials.append(target.get_active_material(i))
 target.mesh=source.mesh.duplicate();target.skin=source.skin
 for i in range(target.mesh.get_surface_count()):target.set_surface_override_material(i,materials[i])
 target.set_meta("neck_revision",11)
 candidate.free()
