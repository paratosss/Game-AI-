import bpy,json
from pathlib import Path
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath='/workspace/Game-AI-/game/assets/characters/studies/AlinaRevision.glb')
head=bpy.data.objects['AlinaRevisionHead'];used={v for p in head.data.polygons if head.data.materials[p.material_index].name=='Head' for v in p.vertices};world=[head.matrix_world@head.data.vertices[i].co for i in used]
rows=[]
for h in [1.29,1.31,1.33,1.35,1.37]:
 points=[p for p in world if abs(p.z-h)<.006 and abs(p.x)<.032]
 if points:
  f=[-p.y for p in points];rows.append({'height_m':h,'vertices':len(points),'front_m':max(f),'back_m':min(f),'midpoint_m':(max(f)+min(f))*.5})
r=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
bones={n:{'head':list(r.matrix_world@r.data.bones[n].head_local),'tail':list(r.matrix_world@r.data.bones[n].tail_local)} for n in ['spine_03','neck_01','Head']}
report={'kind':'rest mesh samples, not a posed or anatomical measurement','neck_sections':rows,'bones':bones}
Path('/workspace/shashlik-development/posture-review-07/neck-sections.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
