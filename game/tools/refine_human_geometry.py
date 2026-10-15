"""Reproducible GLB edits; preserve rigs, UVs, animation and facial morphs."""
from pathlib import Path
import json,struct,numpy as np
root=Path(__file__).resolve().parents[1]/'assets/characters'
for name in ['Alina','Kruglik','Krysyuk']:
 p=root/('Real_'+name+'.glb');raw=p.read_bytes();length=struct.unpack_from('<I',raw,12)[0]
 doc=json.loads(raw[20:20+length]);binary=bytearray(raw[28+length:])
 def array(i):
  a=doc['accessors'][i];v=doc['bufferViews'][a['bufferView']];width={'VEC3':3,'SCALAR':1}[a['type']];dt={5126:'<f4',5125:'<u4',5123:'<u2'}[a['componentType']]
  return np.ndarray((a['count'],width),dtype=dt,buffer=binary,offset=v.get('byteOffset',0)+a.get('byteOffset',0),strides=(v.get('byteStride',np.dtype(dt).itemsize*width),np.dtype(dt).itemsize))
 for mat in doc['materials']:
  key=mat.get('name','').lower();pbr=mat.setdefault('pbrMetallicRoughness',{});pbr['metallicFactor']=0
  pbr['roughnessFactor']=.14 if 'high-poly' in key else .78 if 'casual' in key else .86 if 'shoes' in key else .68 if any(k in key for k in ['long01','short0']) else .57
 if name=='Alina':
  for mesh in doc['meshes']:
   if mesh['name']!='base.001':continue
   for pr in mesh['primitives']:
    v=array(pr['attributes']['POSITION']);before=v.copy()
    w=np.exp(-((v[:,0]/.043)**2+((v[:,1]-1.397)/.024)**2+((v[:,2]-.127)/.048)**2)*1.6)
    v[:,0]*=(1-.045*w);v[:,1]+=.006*w;v[:,2]-=.007*w
    a=doc['accessors'][pr['attributes']['POSITION']];a['min']=v.min(0).tolist();a['max']=v.max(0).tolist()
    # Recompute the surface normals of the changed geometry.
    idx=array(pr['indices']).ravel().astype(int).reshape(-1,3);normals=np.zeros_like(v)
    face=np.cross(v[idx[:,1]]-v[idx[:,0]],v[idx[:,2]]-v[idx[:,0]])
    for k in range(3):np.add.at(normals,idx[:,k],face)
    normals/=np.maximum(np.linalg.norm(normals,axis=1,keepdims=True),1e-8)
    oldn=array(pr['attributes']['NORMAL']);normals*=np.where(np.sum(normals*oldn,axis=1,keepdims=True)<0,-1,1);oldn[:]=normals
    # The morphs store deltas; the same new base remains valid for small expressions.
    print(name,'sculpted vertices',int((w>.02).sum()),'max movement',float(np.linalg.norm(v-before,axis=1).max()))
 doc['asset']['generator']=doc['asset'].get('generator','')+'; Shashlik geometry/material refinement 06'
 j=json.dumps(doc,separators=(',',':')).encode();j+=b' '*((-len(j))%4)
 dest=root/('Refined_'+name+'.glb');dest.write_bytes(struct.pack('<4sII',b'glTF',2,12+8+len(j)+8+len(binary))+struct.pack('<I4s',len(j),b'JSON')+j+struct.pack('<I4s',len(binary),b'BIN\0')+binary)
 print('Written',dest.name)
