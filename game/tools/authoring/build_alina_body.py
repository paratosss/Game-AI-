"""Rebuild the study body without overwriting the preserved full-character GLB.

Blender 4.5.3. Original 63-bone animation rig is kept; four auxiliary forearm
bindings distribute axial rotation. No downloaded model or texture is added.
"""
from pathlib import Path
import bpy,bmesh,hashlib,json
from mathutils import Vector

root=Path(__file__).resolve().parents[2]
source=root/'assets/characters/studies/AlinaRevision.glb'
assert hashlib.sha256(source.read_bytes()).hexdigest()=='53358b0f8daeb64b573579212eeca4b5edf0345e49df1fe5beb326528069102a'
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(source))
body=bpy.data.objects['Human'];rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
original_vertices=len(body.data.vertices)
# These surviving old face channels are exactly zero after removal of the old
# head. Keep their names on the rebuilt topology, rather than dropping tracks.
shape_names=[k.name for k in body.data.shape_keys.key_blocks]
basis=body.data.shape_keys.key_blocks[0]
for key in body.data.shape_keys.key_blocks:
 assert max((key.data[i].co-basis.data[i].co).length for i in range(len(body.data.vertices)))<1e-8
body.shape_key_clear()
for modifier in list(body.modifiers):body.modifiers.remove(modifier)
bpy.context.view_layer.objects.active=body
bm=bmesh.new();bm.from_mesh(body.data)
bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6)
bmesh.ops.join_triangles(bm,faces=list(bm.faces),angle_face_threshold=.18,angle_shape_threshold=.8,cmp_uvs=True,cmp_materials=True,cmp_seam=True,cmp_sharp=True)
quad_faces=sum(len(f.verts)==4 for f in bm.faces)
bm.to_mesh(body.data);bm.free()
sub=body.modifiers.new('BodySurface','SUBSURF');sub.subdivision_type='CATMULL_CLARK';sub.levels=2;sub.render_levels=2
bpy.ops.object.modifier_apply(modifier=sub.name)
for polygon in body.data.polygons:polygon.use_smooth=True
for name in shape_names:body.shape_key_add(name=name,from_mix=False)
# Branch bones share the lower-arm rest matrix. Existing hand/finger hierarchy
# and every original animation target remain unchanged.
bpy.context.view_layer.objects.active=rig
bpy.ops.object.mode_set(mode='EDIT')
for side in ['l','r']:
 parent=rig.data.edit_bones['lowerarm_'+side]
 for level in ['mid','end']:
  bone=rig.data.edit_bones.new('forearm_twist_'+level+'_'+side)
  bone.head=parent.head;bone.tail=parent.tail;bone.roll=parent.roll;bone.parent=parent;bone.use_connect=False
bpy.ops.object.mode_set(mode='OBJECT')
for side in ['l','r']:
 parent=rig.data.bones['lowerarm_'+side];origin=parent.head_local;axis=(parent.tail_local-origin).normalized();length=parent.length
 lower=body.vertex_groups['lowerarm_'+side]
 mid=body.vertex_groups.new(name='forearm_twist_mid_'+side);end=body.vertex_groups.new(name='forearm_twist_end_'+side)
 for vertex in body.data.vertices:
  weight=next((g.weight for g in vertex.groups if g.group==lower.index),0.)
  if weight<=1e-7:continue
  t=max(0.,min(1.,(vertex.co-origin).dot(axis)/length))
  # Plateau at each end protects the elbow/wrist seams. Adjacent matrices
  # differ by half the requested roll, reducing linear-skinning volume loss.
  t=max(0.,min(1.,(t-.06)/.88));t=t*t*(3-2*t)
  weights=[max(0.,1-2*t),1-abs(2*t-1),max(0.,2*t-1)]
  for group,factor in zip([lower,mid,end],weights):
   if factor>1e-7:group.add([vertex.index],weight*factor,'REPLACE')
   elif group==lower:group.remove([vertex.index])
modifier=body.modifiers.new('BodySkin','ARMATURE');modifier.object=rig
bpy.ops.object.select_all(action='DESELECT');body.select_set(True);rig.select_set(True);bpy.context.view_layer.objects.active=rig
output=root/'assets/characters/studies/AlinaBody06.glb'
bpy.ops.export_scene.gltf(filepath=str(output),export_format='GLB',use_selection=True,
 export_animations=False,export_skins=True,export_materials='NONE',export_all_influences=True,
 export_try_sparse_sk=True,export_try_omit_sparse_sk=True)
receipt={'source':str(source.relative_to(root)),'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),
 'output':str(output.relative_to(root)),'bytes':output.stat().st_size,'sha256':hashlib.sha256(output.read_bytes()).hexdigest(),
 'original_vertices':original_vertices,'recovered_quads':quad_faces,'vertices':len(body.data.vertices),'polygons':len(body.data.polygons),
 'bones':len(rig.data.bones),'auxiliary_bones':['forearm_twist_'+level+'_'+side for side in ['l','r'] for level in ['mid','end']],
 'preserved_zero_shape_names':shape_names,'subdivision_levels':2,'materials':'reuse the original body material at runtime; no duplicate texture pack',
 'status':'candidate: inspect deformation and body/cloth/string clearances before acceptance'}
(output.parent/'ALINA_BODY_06_MANIFEST.json').write_text(json.dumps(receipt,indent=2)+'\n')
print('ALINA_BODY_06_EXPORTED',json.dumps(receipt),flush=True)
