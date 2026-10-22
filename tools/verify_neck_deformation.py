"""Apply live Godot bone poses to the actual GLB and inspect the cervical skin."""
from pathlib import Path
import argparse,hashlib,json,numpy as np
from glb_geometry_review import GLB
from neck_geometry_checks import self_intersections

root=Path(__file__).resolve().parents[1]
cli=argparse.ArgumentParser();cli.add_argument('--poses',type=Path,required=True);cli.add_argument('--output',type=Path,required=True);args=cli.parse_args()
data=json.loads(args.poses.read_text());g=GLB(root/'game/assets/characters/studies/AlinaNeck11.glb')
assert hashlib.sha256(g.raw).hexdigest()==data['source_sha256']
for resource,digest in data.get('dependencies_sha256',{}).items():assert hashlib.sha256((root/'game'/resource.removeprefix('res://')).read_bytes()).hexdigest()==digest
assert data['bone_count']==67 and data['shape_count']==63
ni,node=g.node('AlinaRevisionHead');mesh=g.mesh('AlinaRevisionHead');primitive=mesh['primitives'][0];names=mesh['extras']['targetNames']
base=g.array(primitive['attributes']['POSITION']).astype(float);faces=g.array(primitive['indices']).reshape(-1,3)
skin=g.doc['skins'][node['skin']];joint_names=[g.doc['nodes'][i]['name'] for i in skin['joints']]
binds=g.array(skin['inverseBindMatrices']).reshape(-1,4,4).transpose(0,2,1)
joints=g.array(primitive['attributes']['JOINTS_0']);weights=g.array(primitive['attributes']['WEIGHTS_0'])
if 'JOINTS_1' in primitive['attributes']:
 joints=np.concatenate([joints,g.array(primitive['attributes']['JOINTS_1'])],1);weights=np.concatenate([weights,g.array(primitive['attributes']['WEIGHTS_1'])],1)
tri=base[faces];selected=np.flatnonzero((tri.min(1)[:,1]<1.365)&(tri.max(1)[:,1]>1.265))
base_area=np.linalg.norm(np.cross(tri[:,1]-tri[:,0],tri[:,2]-tri[:,0]),axis=1)
results=[];failures=[]
for case in data['cases']:
 p=base.copy()
 for name,value in case['morphs'].items():p+=g.array(primitive['targets'][names.index(name)]['POSITION'])*value
 transforms=[]
 for name in joint_names:
  matrix=np.eye(4);matrix[:3,:]=np.array(case['bones'][name]).T;transforms.append(matrix)
 matrices=np.array(transforms)@binds;homogeneous=np.column_stack([p,np.ones(len(p))]);deformed=np.zeros_like(p)
 for column in range(joints.shape[1]):
  deformed+=np.einsum('nij,nj->ni',matrices[joints[:,column],:3,:],homogeneous)*weights[:,column,None]
 assert np.isfinite(deformed).all()
 collision=self_intersections(deformed,faces,selected,base)
 dtri=deformed[faces];area=np.linalg.norm(np.cross(dtri[:,1]-dtri[:,0],dtri[:,2]-dtri[:,0]),axis=1)
 valid=selected[base_area[selected]>1e-12];ratio=area[valid]/base_area[valid]
 result={'name':case['name'],'neck_intersections':collision,'minimum_area_ratio':float(ratio.min()),'maximum_area_ratio':float(ratio.max())}
 if case['name']=='rest':
  error=float(np.linalg.norm(deformed-base,axis=1).max());result['maximum_rest_mapping_error_m']=error
  if error>1e-5:failures.append('Actual Godot rest/bind transforms do not reproduce the GLB: '+str(error))
 if collision['pairs']:failures.append(case['name']+': neck self-intersection')
 if ratio.min()<.30 or ratio.max()>3.:failures.append(case['name']+': excessive selected triangle area distortion')
 results.append(result);print(case['name'],'intersections',collision['pairs'],'area',round(float(ratio.min()),3),round(float(ratio.max()),3),flush=True)
report={'status':'PASS' if not failures else 'FAIL','failures':failures,'source_sha256':data['source_sha256'],'poses_sha256':hashlib.sha256(args.poses.read_bytes()).hexdigest(),'cases':results,'neck_triangles':len(selected),'method':'Actual live Godot global bone transforms plus exported inverse binds, weights and facial morph deltas. Any selected neck triangle is tested against all skin triangles. Weld shared vertices at 1 micrometer; coplanar-only/edge-only contacts excluded.','limitation':'Eleven selected settled poses and gaze limits, not all transitions or proof of full anatomy.'}
args.output.write_text(json.dumps(report,indent=2)+'\n');print('NECK_DEFORMATION_11_'+report['status']);raise SystemExit(bool(failures))
