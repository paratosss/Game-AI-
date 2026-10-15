extends SceneTree
func _initialize():call_deferred("run")
func cropped(source:MeshInstance3D,offset:Vector3,cut:float)->ArrayMesh:
 var result=ArrayMesh.new()
 for surface in range(source.mesh.get_surface_count()):
  var old=source.mesh.surface_get_arrays(surface);var vertices=old[Mesh.ARRAY_VERTEX];var indices=old[Mesh.ARRAY_INDEX]
  if indices==null or indices.is_empty():indices=PackedInt32Array(range(vertices.size()))
  var kept=PackedInt32Array();var map={};var verts=PackedVector3Array();var norms=PackedVector3Array();var uvs=PackedVector2Array();var tangents=PackedFloat32Array()
  for i in range(0,indices.size(),3):
   if vertices[indices[i]].y<cut or vertices[indices[i+1]].y<cut or vertices[indices[i+2]].y<cut:continue
   for k in range(3):
    var index=indices[i+k]
    if not map.has(index):
     map[index]=verts.size();verts.append(vertices[index]-offset);norms.append(old[Mesh.ARRAY_NORMAL][index]);uvs.append(old[Mesh.ARRAY_TEX_UV][index])
     if old[Mesh.ARRAY_TANGENT]!=null:
      for t in range(4):tangents.append(old[Mesh.ARRAY_TANGENT][index*4+t])
    kept.append(map[index])
  if kept.is_empty():continue
  var arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=verts;arrays[Mesh.ARRAY_NORMAL]=norms;arrays[Mesh.ARRAY_TEX_UV]=uvs;arrays[Mesh.ARRAY_INDEX]=kept
  if not tangents.is_empty():arrays[Mesh.ARRAY_TANGENT]=tangents
  result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
  result.surface_set_material(result.get_surface_count()-1,source.get_active_material(surface))
 return result
func run():
 for who in ["Female","Male"]:
  var scene=load("res://assets/characters/Superhero_"+who+"_FullBody.gltf").instantiate();root.add_child(scene)
  var offset=Vector3(0,1.63 if who=="Female" else 1.68,0)
  var index=0
  for n in scene.find_children("*","MeshInstance3D",true,false):
   var mesh=cropped(n,offset,1.48 if who=="Female" else 1.54);ResourceSaver.save(mesh,"res://assets/characters/"+who+"_Head_"+str(index)+".res");index+=1
  scene.queue_free()
 for hairstyle in ["Hair_Long","Hair_SimpleParted","Hair_Buzzed","Hair_Beard"]:
  var scene=load("res://assets/characters/"+hairstyle+".gltf").instantiate();root.add_child(scene)
  var n=scene.find_children("*","MeshInstance3D",true,false)[0];var offset=Vector3(0,1.63 if hairstyle=="Hair_Long" else 1.68,0)
  ResourceSaver.save(cropped(n,offset,1.20),"res://assets/characters/"+hairstyle+"_Head.res");scene.queue_free()
 print("Native model heads and hair extracted; original CC0 license preserved")
 quit()
