"""Independent export regression audit for the reconstructed cervical skin."""
from pathlib import Path
import argparse,hashlib,json,numpy as np
from glb_geometry_review import GLB
from neck_geometry_checks import self_intersections
root=Path(__file__).resolve().parents[1];assets=root/'game/assets/characters/studies'
cli=argparse.ArgumentParser();cli.add_argument('--output',type=Path);args=cli.parse_args()
old=GLB(assets/'AlinaAnatomy09.glb');new=GLB(assets/'AlinaNeck11.glb')
assert hashlib.sha256(old.raw).hexdigest()=='2db1ac961d16a6c5edf0f2b867a6b47ac357b301e91067a9088271cdcdc6c266'
assert not new.doc.get('animations')
old_mesh=old.mesh('AlinaRevisionHead');mesh=new.mesh('AlinaRevisionHead')
assert old_mesh['extras']['targetNames']==mesh['extras']['targetNames'] and len(mesh['extras']['targetNames'])==63
assert len(mesh['primitives'])==len(old_mesh['primitives'])==7
bindings=new.bindings('AlinaRevisionHead');assert len(bindings)==67
for name,matrix in old.bindings('AlinaRevisionHead').items():assert np.max(abs(matrix-bindings[name]))<1e-5
changed=0;maximum=0.;maximum_morph_error=0.;maximum_face_error=0.
for index,(p,q) in enumerate(zip(mesh['primitives'],old_mesh['primitives'])):
 a=new.array(p['attributes']['POSITION']);b=old.array(q['attributes']['POSITION'])
 assert np.array_equal(new.array(p['indices']),old.array(q['indices']))
 assert np.array_equal(new.array(p['attributes']['TEXCOORD_0']),old.array(q['attributes']['TEXCOORD_0']))
 assert a.shape==b.shape
 diff=np.linalg.norm(a-b,axis=1);changed+=int((diff>1e-6).sum());maximum=max(maximum,float(diff.max()))
 protected=b[:,1]>=1.395 if index==0 else np.ones(len(b),dtype=bool)
 error=float(np.max(diff[protected],initial=0));maximum_face_error=max(maximum_face_error,error);assert error<1e-6
 for s,t in zip(p['targets'],q['targets']):
  error=float(np.max(abs(new.array(s['POSITION'])-old.array(t['POSITION']))));maximum_morph_error=max(maximum_morph_error,error);assert error<1e-6
 weights=new.array(p['attributes']['WEIGHTS_0']);assert np.max(abs(weights.sum(1)-1))<1e-5
 assert np.all(weights>=0)
p=mesh['primitives'][0];positions=new.array(p['attributes']['POSITION']);faces=new.array(p['indices']).reshape(-1,3)
tri=positions[faces];selection=np.flatnonzero((tri.min(1)[:,1]<1.365)&(tri.max(1)[:,1]>1.235))
collision=self_intersections(positions,faces,selection)
assert collision['pairs']==0,collision
# Weight continuity is measured on actual edges, rather than checking a formula.
skin=new.doc['skins'][new.node('AlinaRevisionHead')[1]['skin']];names=[new.doc['nodes'][i]['name'] for i in skin['joints']]
joints=new.array(p['attributes']['JOINTS_0']);weights=new.array(p['attributes']['WEIGHTS_0'])
head_weight=np.where(joints==names.index('Head'),weights,0).sum(1)
edges=np.unique(np.sort(np.concatenate([faces[:,[0,1]],faces[:,[1,2]],faces[:,[2,0]]]),1),axis=0)
a,b=edges.T;zone=(positions[a,1]>1.29)&(positions[a,1]<1.39)&(positions[b,1]>1.29)&(positions[b,1]<1.39)&(positions[a,2]>.02)&(positions[b,2]>.02)
jump=float(np.max(abs(head_weight[a]-head_weight[b])[zone]));assert jump<.25
_,weld=np.unique(np.round(positions,6),axis=0,return_inverse=True)
we=np.sort(np.concatenate([weld[faces[:,[0,1]]],weld[faces[:,[1,2]]],weld[faces[:,[2,0]]]]),1);ue,counts=np.unique(we,axis=0,return_counts=True)
boundary=np.unique(ue[counts==1]);rim=np.array([positions[np.flatnonzero(weld==i)[0]] for i in boundary]);rim=rim[rim[:,1]<1.315]
assert len(rim)==68 and rim[:,1].max()<1.250,'Lower bust boundary must lie under the collar'
report={'status':'PASS','source_sha256':hashlib.sha256(new.raw).hexdigest(),'bones':67,'facial_channels':63,'unchanged_topology_uv_and_morph_deltas':True,'maximum_morph_delta_error_m':maximum_morph_error,'maximum_protected_face_hair_error_m':maximum_face_error,'changed_export_vertices':changed,'maximum_displacement_m':maximum,'static_neck_intersections':collision,'maximum_adjacent_head_weight_jump_anterior_roi':jump,'lower_open_boundary_vertices':len(rim),'lower_boundary_height_range_m':[float(rim[:,1].min()),float(rim[:,1].max())],'limitation':'Localized geometry and compatibility checks. Not full character anatomical acceptance.'}
if args.output:args.output.write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2));print('NECK_EXPORT_AUDIT_11_PASS')
