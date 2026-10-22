from pathlib import Path
import numpy as np,json
import argparse
from glb_geometry_review import GLB
root=Path(__file__).resolve().parents[1]
cli=argparse.ArgumentParser(description='Offline diagnostic of preserved anatomical geometry; no asset mutation.')
cli.add_argument('--output-dir',type=Path,default=root/'docs/stages/evidence/anatomy-review-10')
args=cli.parse_args();out=args.output_dir;out.mkdir(parents=True,exist_ok=True)
def segment_triangle(a,b,tri):
 direction=b-a;e1=tri[1]-tri[0];e2=tri[2]-tri[0];h=np.cross(direction,e2);det=np.dot(e1,h)
 if abs(det)<1e-14:return None
 inv=1/det;s=a-tri[0];u=inv*np.dot(s,h)
 if u<1e-7 or u>1-1e-7:return None
 q=np.cross(s,e1);v=inv*np.dot(direction,q)
 if v<1e-7 or u+v>1-1e-7:return None
 t=inv*np.dot(e2,q)
 return a+t*direction if 1e-7<t<1-1e-7 else None
control_triangle=np.array([[0.,0.,0.],[1.,0.,0.],[0.,1.,0.]])
assert np.allclose(segment_triangle(np.array([.2,.2,-1.]),np.array([.2,.2,1.]),control_triangle),[.2,.2,0.])
assert segment_triangle(np.array([2.,2.,-1.]),np.array([2.,2.,1.]),control_triangle) is None
assert segment_triangle(np.array([.2,.2,1.]),np.array([.2,.2,2.]),control_triangle) is None
assert segment_triangle(np.array([.2,.2,0.]),np.array([.3,.3,0.]),control_triangle) is None
results=[]
for file in ['AlternativeHeadStudy.glb','AlinaRevision.glb','AlinaAnatomy09.glb']:
 g=GLB(root/'game/assets/characters/studies'/file)
 idx,node=next((i,n) for i,n in enumerate(g.doc['nodes']) if 'mesh' in n and any(g.doc['materials'][p['material']]['name'].startswith('Head') for p in g.doc['meshes'][n['mesh']]['primitives']))
 primitive=next(p for p in g.doc['meshes'][node['mesh']]['primitives'] if g.doc['materials'][p['material']]['name'].startswith('Head'))
 p=g.array(primitive['attributes']['POSITION']);p=(g.world[idx]@np.column_stack([p,np.ones(len(p))]).T).T[:,:3];faces=g.array(primitive['indices']).reshape(-1,3);tri=p[faces]
 low=tri.min(1);high=tri.max(1)
 selected=np.flatnonzero((high[:,1]>1.30)&(low[:,1]<1.365)&(low[:,2]<.085)&(high[:,2]>-.01))
 _,weld=np.unique(np.round(p,6),axis=0,return_inverse=True);wfaces=weld[faces]
 hits=[];tested=0
 for i in selected:
  candidates=selected[(selected>i)&np.all(low[selected]<=high[i]+1e-10,1)&np.all(high[selected]>=low[i]-1e-10,1)]
  for j in candidates:
   if np.isin(wfaces[i],wfaces[j]).any():continue
   tested+=1;points=[]
   for a,b in [(0,1),(1,2),(2,0)]:
    hit=segment_triangle(tri[i,a],tri[i,b],tri[j])
    if hit is not None:points.append(hit.tolist())
    hit=segment_triangle(tri[j,a],tri[j,b],tri[i])
    if hit is not None:points.append(hit.tolist())
   if points:hits.append({'triangles':[int(i),int(j)],'intersection_points':points})
 record={'file':file,'tested_nonadjacent_triangle_pairs':tested,'strict_intersection_pairs':len(hits),'hits':hits}
 results.append(record);print(file,'tested',tested,'strict intersections',len(hits),flush=True)
(out/'neck-intersections.json').write_text(json.dumps({'method':'Strict segment/triangle intersections within anterior neck ROI y=1.30..1.365m, z=-.01...085m. Ignore triangle pairs sharing vertices welded at 1 micrometer; exclude coplanar/edge-only contact. Static GLB world geometry, no animation. This is a localized geometry diagnostic, not a whole mesh watertightness test.','results':results},indent=2)+'\n')
