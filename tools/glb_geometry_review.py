"""Small GLB geometry reader for offline anatomical review (including sparse accessors)."""
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

