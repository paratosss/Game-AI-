from pathlib import Path
import json,numpy as np
from PIL import Image,ImageDraw,ImageFilter
base=Path(__file__).resolve().parents[1]/'assets/characters'
for gender in ['Female','Male']:
 j=json.loads((base/f'Superhero_{gender}_FullBody.gltf').read_text());raw=bytearray((base/j['buffers'][0]['uri']).read_bytes())
 def acc(i):
  a=j['accessors'][i];bv=j['bufferViews'][a['bufferView']];c={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']];dtype={5126:'<f4',5123:'<u2',5125:'<u4',5121:'u1'}[a['componentType']]
  return np.frombuffer(raw,dtype=dtype,count=a['count']*c,offset=bv.get('byteOffset',0)+a.get('byteOffset',0)).reshape(-1,c)
 prim=j['meshes'][2]['primitives'][0];verts=acc(prim['attributes']['POSITION']);normal=acc(prim['attributes']['NORMAL']);uv=acc(prim['attributes']['TEXCOORD_0']);indices=acc(prim['indices']).flatten().reshape(-1,3)
 # Mask in authored bind pose; it deforms with the mesh instead of changing with animation.
 mask=Image.new('L',(2048,2048));draw=ImageDraw.Draw(mask)
 def classify(v):
  x,y,z=v
  if y<.115:return 230
  if y<.955:return 160
  if abs(x)<(.385 if gender=='Female' else .44) and y<(1.55 if gender=='Female' else 1.56):return 80
  return 0
 canvas=np.zeros((2048,2048),dtype=np.uint8)
 for tri in indices:
  pts=uv[tri]*2047
  x0=max(0,int(np.floor(pts[:,0].min())));x1=min(2047,int(np.ceil(pts[:,0].max())))
  y0=max(0,int(np.floor(pts[:,1].min())));y1=min(2047,int(np.ceil(pts[:,1].max())))
  if x1<x0 or y1<y0:continue
  xx,yy=np.meshgrid(np.arange(x0,x1+1)+.5,np.arange(y0,y1+1)+.5)
  a,b,c=pts;den=(b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1])
  if abs(den)<1e-6:continue
  u=((b[1]-c[1])*(xx-c[0])+(c[0]-b[0])*(yy-c[1]))/den
  v=((c[1]-a[1])*(xx-c[0])+(a[0]-c[0])*(yy-c[1]))/den;w=1-u-v
  inside=(u>=-.005)&(v>=-.005)&(w>=-.005)
  point=u[...,None]*verts[tri[0]]+v[...,None]*verts[tri[1]]+w[...,None]*verts[tri[2]]
  px,py,pz=point[:,:,0],point[:,:,1],point[:,:,2]
  region=np.zeros_like(xx,dtype=np.uint8)
  shirt=(py<(1.55 if gender=='Female' else 1.56))&(np.abs(px)<(.385 if gender=='Female' else .44))
  neckline=(1.445 if gender=='Female' else 1.49)+(.115 if gender=='Female' else .07)*(1-np.exp(-(px/.085)**2))
  shirt &= py<neckline
  region[shirt]=80;region[py<.955]=160;region[py<.115]=230
  patch=canvas[y0:y1+1,x0:x1+1];patch[inside]=region[inside]
 mask=Image.fromarray(canvas)
 mask=mask.filter(ImageFilter.MaxFilter(3));mask.save(base/f'Casual_{gender}_Mask.png')
 norm=normal.copy();inflate=np.array([.021 if classify(v)==80 else .014 if classify(v)==160 else .012 if classify(v)==230 else 0 for v in verts])
 verts[:]+=norm*inflate[:,None]
 for item in j['buffers']:item['uri']=f'Casual_{gender}.bin'
 # Preserve skin materials. Clothing regions will be shaded through the dedicated mask.
 (base/f'Casual_{gender}.bin').write_bytes(raw);(base/f'Casual_{gender}.gltf').write_text(json.dumps(j))
print('Casual meshes and stable UV clothing masks created')
