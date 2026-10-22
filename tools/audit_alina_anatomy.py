"""Inspect the exported anatomy overlay independently of its Blender generator."""
from pathlib import Path
import argparse,json,struct,hashlib
import numpy as np
root=Path(__file__).resolve().parents[1]
class GLB:
 def __init__(self,path):
  self.path=path;self.raw=path.read_bytes();n=struct.unpack_from('<I',self.raw,12)[0];self.doc=json.loads(self.raw[20:20+n]);self.binary=self.raw[28+n:];self.world={}
  def visit(i,parent):
   node=self.doc['nodes'][i]
   if 'matrix' in node:m=np.array(node['matrix']).reshape(4,4).T
   else:
    x,y,z,w=node.get('rotation',[0,0,0,1]);m=np.eye(4);m[:3,:3]=np.array([[1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w)],[2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w)],[2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y)]])@np.diag(node.get('scale',[1,1,1]));m[:3,3]=node.get('translation',[0,0,0])
   self.world[i]=parent@m
   for child in node.get('children',[]):visit(child,self.world[i])
  for i in self.doc['scenes'][self.doc.get('scene',0)]['nodes']:visit(i,np.eye(4))
 def view(self,view,component,count,width,offset=0):
  v=self.doc['bufferViews'][view];dt=np.dtype({5121:'u1',5123:'<u2',5125:'<u4',5126:'<f4'}[component]);return np.ndarray((count,width),dtype=dt,buffer=self.binary,offset=v.get('byteOffset',0)+offset,strides=(v.get('byteStride',dt.itemsize*width),dt.itemsize))
 def array(self,index):
  a=self.doc['accessors'][index];width={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']]
  result=self.view(a['bufferView'],a['componentType'],a['count'],width,a.get('byteOffset',0)).copy() if 'bufferView' in a else np.zeros((a['count'],width),dtype=np.float32)
  if 'sparse' in a:
   s=a['sparse'];i=s['indices'];v=s['values'];idx=self.view(i['bufferView'],i['componentType'],s['count'],1,i.get('byteOffset',0)).ravel();result[idx]=self.view(v['bufferView'],a['componentType'],s['count'],width,v.get('byteOffset',0))
  return result
 def node(self,name):return next((i,n) for i,n in enumerate(self.doc['nodes']) if n.get('name')==name)
 def mesh(self,name):return self.doc['meshes'][self.node(name)[1]['mesh']]
 def bindings(self,name):
  s=self.doc['skins'][self.node(name)[1]['skin']];m=self.array(s['inverseBindMatrices']);return {self.doc['nodes'][j]['name']:m[i] for i,j in enumerate(s['joints'])}

source=GLB(root/'game/assets/characters/studies/AlinaRevision.glb');body_old=GLB(root/'game/assets/characters/studies/AlinaBody06.glb');overlay=GLB(root/'game/assets/characters/studies/AlinaAnatomy09.glb')
assert not overlay.doc.get('animations'),'The overlay must not replace the preserved animation library'
checks={};expected_shapes={};samples=[]
for name,old in [('Human',body_old),('AlinaRevisionHead',source),('Human_female_casualsuit01',source)]:
 if name=='Human_female_casualsuit01':name='Human.female_casualsuit01'
 m=overlay.mesh(name);o=old.mesh(name);bindings=overlay.bindings(name);old_bindings=old.bindings(name)
 for b,v in old_bindings.items():assert np.max(np.abs(v-bindings[b]))<1e-5,(name,b)
 assert len(bindings)==67
 assert len(m['primitives'])==len(o['primitives'])
 shapes=m.get('extras',{}).get('targetNames',[]);original_shapes=o.get('extras',{}).get('targetNames',[])
 assert shapes[:len(original_shapes)]==original_shapes
 assert len(shapes)==len(original_shapes)+(2 if name=='Human' else 0)
 displacement=0.;changed=0;face_protected=True
 for primitive,previous in zip(m['primitives'],o['primitives']):
  p=overlay.array(primitive['attributes']['POSITION']);q=old.array(previous['attributes']['POSITION']);assert p.shape==q.shape
  diff=np.linalg.norm(p-q,axis=1);displacement=max(displacement,float(diff.max()));changed+=int((diff>1e-6).sum())
  weights=overlay.array(primitive['attributes']['WEIGHTS_0']);joints=overlay.array(primitive['attributes']['JOINTS_0'])
  if 'WEIGHTS_1' in primitive['attributes']:
   weights=np.concatenate([weights,overlay.array(primitive['attributes']['WEIGHTS_1'])],axis=1);joints=np.concatenate([joints,overlay.array(primitive['attributes']['JOINTS_1'])],axis=1)
  assert np.isfinite(p).all() and np.max(abs(weights.sum(1)-1))<1e-5
  if 'TEXCOORD_0' in primitive['attributes']:
   assert np.max(np.abs(overlay.array(primitive['attributes']['TEXCOORD_0'])-old.array(previous['attributes']['TEXCOORD_0'])))<1e-6,'UV coordinates must be preserved'
  if name=='AlinaRevisionHead':
   material=old.doc['materials'][previous['material']]['name']
   if material!='Head':assert diff.max()<1e-6,'Hair, eyes, mouth and lashes must be unchanged'
   ni,_=old.node(name);world=(old.world[ni]@np.column_stack([q,np.ones(len(q))]).T).T[:,:3];protected=world[:,1]>1.382
   assert np.max(diff[protected],initial=0)<1e-6,'Face/hair above the cervical edit must be unchanged'
   for target,old_target in zip(primitive.get('targets',[]),previous.get('targets',[])):
    a=overlay.array(target['POSITION']);b=old.array(old_target['POSITION']);assert np.max(np.linalg.norm(a-b,axis=1)[protected],initial=0)<1e-6
  if name=='Human':
   skin=overlay.doc['skins'][overlay.node(name)[1]['skin']];joint_names=[overlay.doc['nodes'][j]['name'] for j in skin['joints']]
   for shape in ['anatomyElbowFlex_l','anatomyElbowFlex_r']:
    side=shape[-1];index=shapes.index(shape);delta=overlay.array(primitive['targets'][index]['POSITION']);lengths=np.linalg.norm(delta,axis=1);affected=lengths>1e-7
    assert lengths.max()>.0008 and lengths.max()<.003
    upper=sum(np.where(joints==joint_names.index('upperarm_'+side),weights,0).T)
    lower=sum(np.where(np.isin(joints,[joint_names.index(n) for n in ['lowerarm_'+side,'forearm_twist_mid_'+side,'forearm_twist_end_'+side]]),weights,0).T)
    assert np.max(lower[affected])<.85,'Corrective must remain in the elbow blend zone, outside the shaft/hand contact samples'
    assert np.min(upper[affected])>.19 and np.min(lower[affected])>.19
    checks[shape]={'affected_export_vertices':int(affected.sum()),'maximum_delta_m':float(lengths.max()),'maximum_forearm_weight':float(lower[affected].max())}
    # Export diagnostic anchors from the actual GLB, not the generator's formulas.
    node_idx=skin['joints'][joint_names.index('lowerarm_'+side)];elbow=overlay.world[node_idx][:3,3]
    radial=p-elbow;dot=(delta*radial).sum(axis=1)
    for label,mask in [('inner',dot<0),('outer',dot>0)]:
     candidates=np.flatnonzero(affected&mask);selected=candidates[np.argsort(lengths[candidates])[-6:]]
     for i in selected:samples.append({'surface':0,'position':p[i].tolist(),'delta':delta[i].tolist(),'shape':shape,'region':label})
 checks[name]={'changed_export_vertices':changed,'maximum_base_delta_m':displacement,'shape_count':len(shapes),'named_bindings':len(bindings)}
receipt={'status':'PASS','source_sha256':hashlib.sha256(overlay.raw).hexdigest(),'checks':checks,'probes':samples,'limitations':'Export and selected geometric checks; not certification of whole-body anatomy or artistic acceptance.'}
parser=argparse.ArgumentParser();parser.add_argument('--output',type=Path);args=parser.parse_args()
if args.output:args.output.write_text(json.dumps(receipt,indent=2)+'\n')
print(json.dumps({k:v for k,v in receipt.items() if k!='probes'},indent=2))
