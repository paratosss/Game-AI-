"""Check exported body geometry, actual skin bindings and the preserved rest rig."""
from pathlib import Path
import hashlib,json,struct
import numpy as np

root=Path(__file__).resolve().parents[1]/'game/assets/characters/studies'
def read(path):
    raw=path.read_bytes();length=struct.unpack_from('<I',raw,12)[0]
    doc=json.loads(raw[20:20+length]);binary=raw[28+length:]
    def array(index):
        a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']]
        width={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']]
        dtype=np.dtype({5126:'<f4',5125:'<u4',5123:'<u2',5121:'u1'}[a['componentType']])
        return np.ndarray((a['count'],width),dtype=dtype,buffer=binary,offset=v.get('byteOffset',0)+a.get('byteOffset',0),strides=(v.get('byteStride',width*dtype.itemsize),dtype.itemsize))
    node=next(n for n in doc['nodes'] if n.get('name')=='Human')
    skin=doc['skins'][node['skin']];mesh=doc['meshes'][node['mesh']]
    names=[doc['nodes'][i]['name'] for i in skin['joints']]
    return doc,mesh,names,array,array(skin['inverseBindMatrices'])

path=root/'AlinaBody06.glb';doc,mesh,names,array,binds=read(path)
_,original,old_names,_,old_binds=read(root/'AlinaRevision.glb')
assert len(old_names)==63 and len(names)==67
for i,name in enumerate(old_names):
    assert np.max(np.abs(old_binds[i]-binds[names.index(name)]))<.00002,name
helpers={};vertices=0;max_sum_error=0.;max_influences=0
for primitive in mesh['primitives']:
    a=primitive['attributes'];position=array(a['POSITION']);vertices+=len(position)
    assert np.isfinite(position).all()
    weights=np.concatenate([array(a['WEIGHTS_'+str(i)]) for i in range(2) if 'WEIGHTS_'+str(i) in a],axis=1)
    joints=np.concatenate([array(a['JOINTS_'+str(i)]) for i in range(2) if 'JOINTS_'+str(i) in a],axis=1)
    max_sum_error=max(max_sum_error,float(np.abs(weights.sum(axis=1)-1).max()))
    max_influences=max(max_influences,int((weights>.000001).sum(axis=1).max()))
    assert np.isfinite(weights).all() and weights.min()>=0 and max_sum_error<.0001
    for side in ['l','r']:
        for level in ['mid','end']:
            name=f'forearm_twist_{level}_{side}';index=names.index(name)
            assert np.max(np.abs(binds[index]-binds[names.index('lowerarm_'+side)]))<.00002,name
            weight=np.where(joints==index,weights,0).sum(axis=1);used=weight>.001
            assert used.sum()>100,name
            assert np.all(position[used,0]*(1 if side=='l' else -1)>0),name
            helpers[name]={'weighted_vertices':int(used.sum()),'maximum_weight':float(weight.max())}
assert vertices>50000 and max_influences<=8
assert mesh['extras']['targetNames']==original['extras']['targetNames']
receipt=json.loads((root/'ALINA_BODY_06_MANIFEST.json').read_text())
assert receipt['sha256']==hashlib.sha256(path.read_bytes()).hexdigest()
print(json.dumps({'status':'PASS','sha256':receipt['sha256'],'vertices':vertices,'bones':len(names),'preserved_original_bones':len(old_names),'maximum_weight_sum_error':max_sum_error,'maximum_influences':max_influences,'helpers':helpers,'limitation':'Export and rest-rig integrity; does not certify anatomical or artistic quality.'},indent=2))
