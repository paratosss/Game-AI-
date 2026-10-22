from pathlib import Path
import json,hashlib,numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import argparse
from glb_geometry_review import GLB
root=Path(__file__).resolve().parents[1]
cli=argparse.ArgumentParser(description='Offline diagnostic of preserved anatomical geometry; no asset mutation.')
cli.add_argument('--output-dir',type=Path,default=root/'docs/stages/evidence/anatomy-review-10')
args=cli.parse_args();out=args.output_dir;out.mkdir(parents=True,exist_ok=True)
records=[]
fig,axes=plt.subplots(1,2,figsize=(10,7),sharey=True)
for file,label,color in [('AlternativeHeadStudy.glb','Source bust before fitting','#777777'),('AlinaRevision.glb','Integrated 04 / used in 08','#b85e0b'),('AlinaAnatomy09.glb','Current 09','#1469af')]:
 g=GLB(root/'game/assets/characters/studies'/file)
 index,node=next((i,n) for i,n in enumerate(g.doc['nodes']) if 'mesh' in n and any(g.doc['materials'][p['material']]['name'].startswith('Head') for p in g.doc['meshes'][n['mesh']]['primitives']))
 primitive=next(p for p in g.doc['meshes'][node['mesh']]['primitives'] if g.doc['materials'][p['material']]['name'].startswith('Head'))
 p=g.array(primitive['attributes']['POSITION']);p=(g.world[index]@np.column_stack([p,np.ones(len(p))]).T).T[:,:3]
 faces=g.array(primitive['indices']).reshape(-1,3);tri=p[faces]
 # Actual center-sagittal cut: intersect each triangle with x=0. No bounding-box shortcut.
 segments=[]
 for triangle in tri:
  points=[]
  for a,b in [(triangle[0],triangle[1]),(triangle[1],triangle[2]),(triangle[2],triangle[0])]:
   if a[0]*b[0]<0:points.append(a+(b-a)*(-a[0]/(b[0]-a[0])))
   elif abs(a[0])<1e-8:points.append(a)
  if len(points)>=2:
   a,b=points[:2]
   if a[1]<1.42 or b[1]<1.42:segments.append([a.tolist(),b.tolist()])
 for ax in axes:
  for a,b in segments:ax.plot([a[2]*1000,b[2]*1000],[a[1]*1000,b[1]*1000],color=color,lw=1.3)
  ax.plot([],[],label=label,color=color)
 axes[0].set_xlim(-85,120);axes[1].set_xlim(-5,85)
 weights={}
 if 'JOINTS_0' in primitive['attributes']:
  skin=g.doc['skins'][node['skin']];names=[g.doc['nodes'][i]['name'] for i in skin['joints']]
  joints=g.array(primitive['attributes']['JOINTS_0']);values=g.array(primitive['attributes']['WEIGHTS_0'])
  if 'JOINTS_1' in primitive['attributes']:joints=np.concatenate([joints,g.array(primitive['attributes']['JOINTS_1'])],1);values=np.concatenate([values,g.array(primitive['attributes']['WEIGHTS_1'])],1)
  # Adjacent vertices on the same anterior cut region; quantify actual discontinuous weights.
  edges=np.unique(np.sort(np.concatenate([faces[:,[0,1]],faces[:,[1,2]],faces[:,[2,0]]]),axis=1),axis=0)
  weight=np.where(joints==names.index('Head'),values,0).sum(1)
  a,b=edges.T;zone=(p[a,1]>1.29)&(p[a,1]<1.39)&(p[b,1]>1.29)&(p[b,1]<1.39)&(p[a,2]>.02)&(p[b,2]>.02)
  distance=np.linalg.norm(p[a]-p[b],axis=1);jump=np.abs(weight[a]-weight[b]);indices=np.flatnonzero(zone&(distance>1e-7))
  order=indices[np.argsort(jump[indices])[-6:]]
  weights={'maximum_adjacent_head_weight_jump':float(jump[indices].max()),'largest_jumps':[{'distance_m':float(distance[i]),'jump':float(jump[i]),'positions':[p[a[i]].tolist(),p[b[i]].tolist()]} for i in order]}
 records.append({'file':file,'sha256':hashlib.sha256(g.raw).hexdigest(),'head_world_bounds':[p.min(0).tolist(),p.max(0).tolist()],'sagittal_segments':segments,'anterior_weight_edges':weights})
for ax in axes:
 ax.set_ylim(1260,1367);ax.grid(alpha=.2);ax.set_xlabel('Forward z, mm');ax.set_aspect('equal');ax.legend(fontsize=8)
axes[0].set_ylabel('Height y, mm');axes[0].set_title('Exact x=0 skin section, rest geometry');axes[1].set_title('Anterior contour detail')
fig.suptitle('Diagnostic geometry comparison; source bust is not an anatomical standard')
fig.tight_layout();fig.savefig(out/'neck-rest-sections.png',dpi=150)
(out/'neck-geometry.json').write_text(json.dumps({'method':'Triangle-plane intersection x=0 of Head skin primitive in GLB world space, without animation or textures. Weight jumps are measured on mesh edges in a specified anterior neck zone, not medical thresholds.','records':records},indent=2)+'\n')
for r in records:print(r['file'],r['anterior_weight_edges'].get('maximum_adjacent_head_weight_jump','unrigged'))
