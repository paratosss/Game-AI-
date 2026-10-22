"""Reconstruct the cervical surface from the preserved, unfolded source bust.

Blender 4.5.3. The fit translates complete horizontal sections, independent of
depth, so its Jacobian never reverses the anterior skin. Old exports stay intact.
"""
from pathlib import Path
import sys,hashlib,json,math
import bpy
import numpy as np
from mathutils import Vector
from mathutils.kdtree import KDTree

root=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(root/'tools'))
from glb_geometry_review import GLB
assets=root/'game/assets/characters/studies'
old_file=assets/'AlinaAnatomy09.glb';source_file=assets/'AlternativeHeadStudy.glb'
assert hashlib.sha256(old_file.read_bytes()).hexdigest()=='2db1ac961d16a6c5edf0f2b867a6b47ac357b301e91067a9088271cdcdc6c266'
assert hashlib.sha256(source_file.read_bytes()).hexdigest()=='d25b7b4a8c2eb8ff8f5c2245089afb63b235a8d022353ff5a7abbbdae5734436'
old=GLB(old_file);source=GLB(source_file)
oi,on=old.node('AlinaRevisionHead');si,sn=source.node('AlternativeHeadStudy')
op=old.mesh('AlinaRevisionHead')['primitives'][0];sp=source.mesh('AlternativeHeadStudy')['primitives'][0]
assert np.array_equal(old.array(op['indices']),source.array(sp['indices']))
assert np.array_equal(old.array(op['attributes']['TEXCOORD_0']),source.array(sp['attributes']['TEXCOORD_0']))
def world_positions(g,i,primitive):
 p=g.array(primitive['attributes']['POSITION'])
 return (g.world[i]@np.column_stack([p,np.ones(len(p))]).T).T[:,:3]
current=world_positions(old,oi,op);original=world_positions(source,si,sp)
# The source bust has an oblique open lower boundary, especially high at the
# nape. Extend that boundary under the garment instead of exposing its cut edge.
triangles=source.array(sp['indices']).reshape(-1,3)
_,weld=np.unique(np.round(original,6),axis=0,return_inverse=True)
edges=np.sort(np.concatenate([weld[triangles[:,[0,1]]],weld[triangles[:,[1,2]]],weld[triangles[:,[2,0]]]]),axis=1)
unique_edges,edge_counts=np.unique(edges,axis=0,return_counts=True)
boundary_ids=np.unique(unique_edges[edge_counts==1])
rim=np.array([original[np.flatnonzero(weld==i)[0]] for i in boundary_ids])
rim=rim[rim[:,1]<1.315]
assert len(rim)==68
design=np.column_stack([np.ones(len(rim)),rim[:,2],abs(rim[:,0])])
rim_fit=np.linalg.lstsq(design,rim[:,1],rcond=None)[0]
assert np.max(abs(design@rim_fit-rim[:,1]))<.003
tree=KDTree(len(current))
for i,p in enumerate(current):tree.insert(Vector(p),i)
tree.balance()

def smooth(a,b,value):
 t=max(0.,min(1.,(value-a)/(b-a)));return t*t*(3.-2.*t)

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(old_file))
rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
head=bpy.data.objects['AlinaRevisionHead'];head.animation_data_clear();rig.animation_data_clear()
for bone in rig.pose.bones:bone.matrix_basis.identity()
bpy.context.view_layer.update()
skin_vertices={v for f in head.data.polygons if head.data.materials[f.material_index].name.startswith('Head_') for v in f.vertices}
inverse=head.matrix_world.inverted();keys=head.data.shape_keys.key_blocks
changed=0;maximum=0.;mapping_error=0.;changes=[]
for vertex in head.data.vertices:
 p=head.matrix_world@keys[0].data[vertex.index].co
 if vertex.index not in skin_vertices or p.z>=1.395:continue
 _,index,distance=tree.find(Vector((p.x,p.z,-p.y)));mapping_error=max(mapping_error,distance)
 assert distance<2e-6
 src=original[index];q=Vector((src[0],-src[2],src[1]))
 lower=rim_fit[0]+rim_fit[1]*src[2]+rim_fit[2]*abs(src[0])
 if q.z<1.325:
  # This height map has positive d(height')/d(height) and blends with unit
  # derivative at the upper join; it cannot fold the source back on itself.
  q.z-=(lower-1.240)*(1.-smooth(lower,1.325,q.z))
 # Complete sections move together. y-up in glTF becomes Blender z-up.
 # Unlike the old depth mask, this warp is one-to-one throughout the neck.
 q.y-=.048*(1.-smooth(1.275,1.365,q.z))
 offset=inverse@q-keys[0].data[vertex.index].co
 for key in keys:key.data[vertex.index].co+=offset
 changed+=int(offset.length>1e-6);maximum=max(maximum,offset.length)
 changes.append((vertex.index,q.copy()))

# Replace the depth/side-dependent abrupt mask with broad height bands. Facial
# skin above the cervical region and all separate facial materials stay rigid.
head.vertex_groups.clear()
groups={name:head.vertex_groups.new(name=name) for name in ['spine_03','neck_01','Head']}
for vertex in head.data.vertices:
 p=head.matrix_world@keys[0].data[vertex.index].co
 h=smooth(1.300,1.365,p.z) if vertex.index in skin_vertices else 1.
 n=(1.-h)*smooth(1.265,1.315,p.z)
 for name,value in [('Head',h),('neck_01',n),('spine_03',1.-h-n)]:
  if value>1e-7:groups[name].add([vertex.index],value,'REPLACE')
head.data.update()
for face in head.data.polygons:face.use_smooth=True
bpy.ops.object.select_all(action='DESELECT')
rig.select_set(True);head.select_set(True);bpy.context.view_layer.objects.active=rig
output=assets/'AlinaNeck11.glb'
bpy.ops.export_scene.gltf(filepath=str(output),export_format='GLB',use_selection=True,export_animations=False,export_skins=True,export_all_influences=True,export_try_sparse_sk=True,export_try_omit_sparse_sk=True)
receipt={'source_unfolded':source_file.name,'source_unfolded_sha256':hashlib.sha256(source_file.read_bytes()).hexdigest(),'previous_overlay':old_file.name,'previous_overlay_sha256':hashlib.sha256(old_file.read_bytes()).hexdigest(),'file':str(output.relative_to(root/'game')),'bytes':output.stat().st_size,'sha256':hashlib.sha256(output.read_bytes()).hexdigest(),'bones':len(rig.data.bones),'facial_shapes':len(keys)-1,'changed_vertices':changed,'maximum_base_displacement_m':maximum,'source_mapping_error_m':mapping_error,'fit':'Oblique lower bust boundary smoothly extended to 1.240 m, under the shirt; then whole horizontal sections translated by up to 48 mm, smooth height falloff 1.275..1.365 m. Both maps preserve orientation. Facial morph offsets retained.','lower_boundary_fit_coefficients':rim_fit.tolist(),'weights':'Head smoothstep 1.300..1.365 m; remaining influence smoothly shared neck/spine over 1.265..1.315 m. Separate eyes/mouth/hair remain rigid.','scope':'Cervical reconstruction and weights. Body/clothing from iteration 09 unchanged; full anatomy not certified.'}
(assets/'ALINA_NECK_11_MANIFEST.json').write_text(json.dumps(receipt,indent=2)+'\n')
print('NECK_11_EXPORTED',json.dumps(receipt),flush=True)
