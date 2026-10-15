"""Original small companion dog mesh. Run with numpy and scikit-image.

Implicit sculpted volumes merge shoulders, torso and legs; semantic surfaces
allow the game's existing skeleton to bind eyes, ears, muzzle and tail.
No downloaded mesh or photographic texture is copied into this geometry.
"""
from pathlib import Path
import json, struct
import numpy as np
from skimage.measure import marching_cubes
from scipy.ndimage import map_coordinates

ROOT=Path(__file__).resolve().parents[1]
STEP=.004
origin=np.array([-.15,-.009,-.54])
axes=[np.arange(origin[i],limit,STEP,dtype=np.float32) for i,limit in enumerate([.15,.61,.425])]
X,Y,Z=np.meshgrid(*axes,indexing='ij',sparse=True)
shape=tuple(len(x) for x in axes)
def ellipsoid(center,radii):
 c=np.asarray(center);r=np.asarray(radii)
 q=np.sqrt(((X-c[0])/r[0])**2+((Y-c[1])/r[1])**2+((Z-c[2])/r[2])**2)
 return (q-1)*min(r)
def smooth_min(a,b,k=.014):
 h=np.maximum(k-np.abs(a-b),0)/k
 return np.minimum(a,b)-h*h*k*.25
def union(parts,k=.014):
 f=np.full(shape,1.,dtype=np.float32)
 for c,r in parts:f=smooth_min(f,ellipsoid(c,r),k)
 return f
body=[((0,.313,-.056),(.091,.101,.225)),((0,.335,.095),(.090,.116,.113)),((0,.30,-.178),(.086,.096,.096)),((0,.396,.152),(.064,.105,.077)),((0,.468,.233),(.072,.073,.082)),((0,.449,.298),(.049,.043,.062)),((0,.432,.340),(.040,.032,.045))]
for s in [-1,1]:
 body += [((s*.074,.240,.131),(.033,.114,.042)),((s*.074,.124,.139),(.020,.096,.024)),((s*.074,.028,.165),(.030,.025,.040)),((s*.074,.244,-.180),(.045,.082,.055)),((s*.074,.156,-.156),(.025,.070,.026)),((s*.074,.074,-.208),(.020,.058,.025)),((s*.074,.028,-.188),(.029,.025,.038))]
 for z in [.165,-.188]:
  for dx in [-.018,0,.018]:body.append(((s*.074+dx,.021,z+.030),(.009,.017,.014)))

surfaces=[('Continuous anatomical skin',union(body),0)]
tail=[]
for t in np.linspace(0,1,20):
 p=(0,.34+.135*t,-.262-.235*t)
 r=.025*(1-t)+.006*t
 tail.append((p,(r,r,r)))
surfaces.append(('Tail',union(tail,.012),0))
for side,s in enumerate([-1,1]):
 ear=[]
 for t in np.linspace(0,1,9):
  ear.append(((s*(.055+.010*t),.505+.063*t,.222-.010*t),(.023*(1-t)+.002,.017,.016*(1-t)+.002)))
 surfaces.append(('ear'+str(side),union(ear,.009),0))
 inner=[]
 for t in np.linspace(0,.82,6):
  inner.append(((s*(.055+.010*t),.515+.054*t,.236-.010*t),(.015*(1-t)+.002,.010,.003)))
 surfaces.append(('ear lining '+str(side),union(inner,.004),3))
 for label,c,r,mat in [('Eye', (s*.049,.482,.296),(.012,.013,.008),1),('Iris',(s*.048,.482,.302),(.007,.008,.004),4),('Pupil',(s*.047,.482,.305),(.0037,.0052,.0025),2)]:
  surfaces.append((label+'_'+str(side),ellipsoid(c,r),mat))
surfaces += [('Nose',ellipsoid((0,.444,.376),(.029,.019,.015)),2),('Mouth lower',ellipsoid((0,.414,.327),(.036,.014,.047)),0)]

materials=[{'name':'Short warm coat','pbrMetallicRoughness':{'baseColorFactor':[.48,.31,.17,1],'roughnessFactor':.87}}, {'name':'Eye sclera','pbrMetallicRoughness':{'baseColorFactor':[.15,.105,.075,1],'roughnessFactor':.12}}, {'name':'Wet dark nose','pbrMetallicRoughness':{'baseColorFactor':[.045,.040,.033,1],'roughnessFactor':.30}}, {'name':'Ear lining','pbrMetallicRoughness':{'baseColorFactor':[.38,.22,.16,1],'roughnessFactor':.92}}, {'name':'Amber iris','pbrMetallicRoughness':{'baseColorFactor':[.22,.12,.042,1],'roughnessFactor':.16}}]
doc={'asset':{'version':'2.0','generator':'Shashlik original implicit sculpt 06'},'scene':0,'scenes':[{'nodes':[]}],'nodes':[],'meshes':[],'materials':materials,'buffers':[{'byteLength':0}],'bufferViews':[],'accessors':[]}
binary=bytearray()
def accessor(data,kind):
 a=np.asarray(data,dtype='<u4' if kind=='SCALAR' else '<f4');start=len(binary);binary.extend(a.tobytes())
 while len(binary)%4:binary.append(0)
 doc['bufferViews'].append({'buffer':0,'byteOffset':start,'byteLength':a.nbytes})
 d={'bufferView':len(doc['bufferViews'])-1,'componentType':5125 if kind=='SCALAR' else 5126,'count':len(a),'type':kind}
 if kind=='VEC3':d.update(min=a.min(0).tolist(),max=a.max(0).tolist())
 doc['accessors'].append(d);return len(doc['accessors'])-1
for label,field,mat in surfaces:
 if field.min()>=0:continue
 vertices,faces,normals,_=marching_cubes(field,level=0,spacing=(STEP,)*3)
 vertices=vertices+origin
 # Gradient points toward the exterior; orient the triangles consistently.
 grad=np.gradient(field,STEP)
 grid=np.rint((vertices-origin)/STEP).astype(int)
 grid=np.maximum(0,np.minimum(grid,np.array(shape)-1))
 normals=np.stack([map_coordinates(g,((vertices-origin)/STEP).T,order=1,mode='nearest') for g in grad],axis=1)
 normals/=np.maximum(np.linalg.norm(normals,axis=1,keepdims=True),1e-8)
 v0,v1,v2=vertices[faces[:,0]],vertices[faces[:,1]],vertices[faces[:,2]]
 if np.mean(np.sum(np.cross(v1-v0,v2-v0)*normals[faces[:,0]],axis=1))<0:faces=faces[:,[0,2,1]]
 uv=np.column_stack((vertices[:,2]*1.3,vertices[:,1]*1.8))
 primitive={'attributes':{'POSITION':accessor(vertices,'VEC3'),'NORMAL':accessor(normals,'VEC3'),'TEXCOORD_0':accessor(uv,'VEC2')},'indices':accessor(faces.reshape(-1),'SCALAR'),'material':mat}
 idx=len(doc['meshes']);doc['meshes'].append({'name':label,'primitives':[primitive]});doc['nodes'].append({'name':label,'mesh':idx});doc['scenes'][0]['nodes'].append(idx)
 print(label,len(vertices),'vertices',flush=True)
 if label=='Continuous anatomical skin':
  rng=np.random.default_rng(147);points=[];fiber_normals=[];fiber_uv=[]
  candidates=np.where((vertices[:,1]>.21)&(vertices[:,2]<.265)&(normals[:,1]>-.55))[0]
  for i in rng.choice(candidates,min(1800,len(candidates)),replace=False):
   p=vertices[i];normal=normals[i];tangent=np.cross(normal,[0,1,0])
   if np.linalg.norm(tangent)<.05:tangent=np.cross(normal,[1,0,0])
   tangent/=np.linalg.norm(tangent);length=float(rng.uniform(.002,.0045))
   tip=p+normal*length+np.array([0,-.0006,-.0008]);width=.0005
   points.extend([p-tangent*width,p+tangent*width,tip]);fiber_normals.extend([normal]*3);fiber_uv.extend([[0,0],[1,0],[.5,1]])
  pr={'attributes':{'POSITION':accessor(points,'VEC3'),'NORMAL':accessor(fiber_normals,'VEC3'),'TEXCOORD_0':accessor(fiber_uv,'VEC2')},'indices':accessor(np.arange(len(points)),'SCALAR'),'material':0}
  idx=len(doc['meshes']);doc['meshes'].append({'name':'Short coat','primitives':[pr]});doc['nodes'].append({'name':'Short coat','mesh':idx});doc['scenes'][0]['nodes'].append(idx)
doc['buffers'][0]['byteLength']=len(binary)
j=json.dumps(doc,separators=(',',':')).encode();j+=b' '*((-len(j))%4)
target=ROOT/'assets/characters/Artorias_Anatomical.glb'
target.write_bytes(struct.pack('<4sII',b'glTF',2,12+8+len(j)+8+len(binary))+struct.pack('<I4s',len(j),b'JSON')+j+struct.pack('<I4s',len(binary),b'BIN\0')+binary)
print('Written',target,target.stat().st_size)
