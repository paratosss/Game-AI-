extends RefCounted
## Reversible geometry overlay. Original rig, animation library and materials
## remain owned by the full-character integration from iterations 04/06.
static func apply(instance:Node3D):
 var skeleton:Skeleton3D=instance.find_children("*","Skeleton3D",true,false)[0]
 var candidate=load("res://assets/characters/studies/AlinaAnatomy09.glb").instantiate()
 var rig:Skeleton3D=candidate.find_children("*","Skeleton3D",true,false)[0]
 for i in range(skeleton.get_bone_count()):
  var j=rig.find_bone(skeleton.get_bone_name(i))
  assert(j>=0 and skeleton.get_bone_global_rest(i).is_equal_approx(rig.get_bone_global_rest(j)),"Anatomy overlay changed the preserved rest rig")
 for name in ["Human","Human_female_casualsuit01","AlinaRevisionHead"]:
  var source:MeshInstance3D=candidate.find_children(name,"MeshInstance3D",true,false)[0]
  var target:MeshInstance3D=instance.find_children(name,"MeshInstance3D",true,false)[0]
  var mesh=source.mesh.duplicate()
  assert(mesh.get_surface_count()==target.mesh.get_surface_count(),"Anatomy overlay changed material slots")
  var expected=target.mesh.get_blend_shape_count()+(2 if name=="Human" else 0)
  assert(mesh.get_blend_shape_count()==expected,"Anatomy overlay lost facial channels or elbow correctives")
  var materials=[]
  for i in range(mesh.get_surface_count()):materials.append(target.get_active_material(i))
  target.mesh=mesh;target.skin=source.skin
  for i in range(mesh.get_surface_count()):target.set_surface_override_material(i,materials[i])
  target.set_meta("anatomy_revision",9)
 candidate.free()
