"""Geometric diagnostics on exported/live-skinned surfaces, with strict contacts.

Coplanar overlaps and edge-only contacts are outside this localized check.
"""
import numpy as np

def segment_triangle(a,b,tri):
 direction=b-a;e1=tri[1]-tri[0];e2=tri[2]-tri[0];h=np.cross(direction,e2);det=np.dot(e1,h)
 if abs(det)<1e-14:return None
 inv=1/det;s=a-tri[0];u=inv*np.dot(s,h)
 if u<1e-7 or u>1-1e-7:return None
 q=np.cross(s,e1);v=inv*np.dot(direction,q)
 if v<1e-7 or u+v>1-1e-7:return None
 t=inv*np.dot(e2,q)
 return a+t*direction if 1e-7<t<1-1e-7 else None

def self_intersections(positions,faces,selected,weld_positions=None):
 tri=positions[faces];low=tri.min(1);high=tri.max(1)
 _,weld=np.unique(np.round(positions if weld_positions is None else weld_positions,6),axis=0,return_inverse=True)
 wfaces=weld[faces];selected_mask=np.zeros(len(faces),dtype=bool);selected_mask[selected]=True
 all_ids=np.arange(len(faces));hits=[];tested=0
 for i in selected:
  candidates=all_ids[(~selected_mask|(all_ids>i))&np.all(low<=high[i]+1e-10,1)&np.all(high>=low[i]-1e-10,1)]
  for j in candidates:
   if i==j or np.isin(wfaces[i],wfaces[j]).any():continue
   tested+=1;points=[]
   for a,b in [(0,1),(1,2),(2,0)]:
    p=segment_triangle(tri[i,a],tri[i,b],tri[j])
    if p is not None:points.append(p.tolist())
    p=segment_triangle(tri[j,a],tri[j,b],tri[i])
    if p is not None:points.append(p.tolist())
   if points:hits.append({'triangles':[int(i),int(j)],'points':points})
 return {'pairs':len(hits),'tested_pairs':tested,'examples':hits[:12]}
