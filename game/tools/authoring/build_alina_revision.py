"""Build a reversible full-character study from the preserved CC0 body and head.

Blender 4.5.3. No downloaded source is overwritten. Existing body rig/clips are
retained while the old head/hair are removed. This does not certify anatomy or
contact quality; render the seated character and inspect the deformation.
"""
from pathlib import Path
import bpy,bmesh,hashlib,json,math
from mathutils import Vector

root=Path(__file__).resolve().parents[2]
body_file=root/'assets/characters/Refined_Alina.glb'
head_file=root/'assets/characters/studies/AlternativeHeadStudy.glb'
assert hashlib.sha256(body_file.read_bytes()).hexdigest()=='fb44fcd95d0896420133922dd5498f4036cf32f94dbca6e321eeaae3777eb813'
assert hashlib.sha256(head_file.read_bytes()).hexdigest()=='d25b7b4a8c2eb8ff8f5c2245089afb63b235a8d022353ff5a7abbbdae5734436'
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(body_file))
rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
assert len(rig.data.bones)==63
body=bpy.data.objects['Human']
old_count=len(body.data.polygons)
bm=bmesh.new();bm.from_mesh(body.data)
bmesh.ops.delete(bm,geom=[f for f in bm.faces if any(v.co.z>1.316 or (v.co.z>1.26 and abs(v.co.x)<0.105) for v in f.verts)],context='FACES')
bm.to_mesh(body.data);bm.free()
# Old head-only objects cannot remain under or around the replacement.
for ob in list(bpy.context.scene.objects):
 if ob.type=='MESH' and ob not in [body,bpy.data.objects.get('Human.female_casualsuit01'),bpy.data.objects.get('Human.shoes05')]:
  bpy.data.objects.remove(ob,do_unlink=True)
# Give the existing garment real material thickness at its open edges. Apply
# before skinning so the exported new vertices inherit the original weights.
clothes=bpy.data.objects['Human.female_casualsuit01']
armatures=[(m.name,m.object)for m in clothes.modifiers if m.type=='ARMATURE']
for m in list(clothes.modifiers):
 if m.type=='ARMATURE':clothes.modifiers.remove(m)
bpy.context.view_layer.objects.active=clothes
solid=clothes.modifiers.new('FabricThickness','SOLIDIFY');solid.thickness=0.0014;solid.offset=0.0;solid.use_rim=True
bpy.ops.object.modifier_apply(modifier=solid.name)
for name,ob in armatures:
 m=clothes.modifiers.new(name,'ARMATURE');m.object=ob
before=set(bpy.context.scene.objects)
bpy.ops.import_scene.gltf(filepath=str(head_file))
head=next(o for o in bpy.context.scene.objects if o not in before and o.type=='MESH')
head.name='AlinaRevisionHead'
# Lift both upper lids slightly in the neutral base, retaining exact closed-lid
# endpoints and the original names used by the existing expression controller.
keys=head.data.shape_keys.key_blocks
wide_l=keys['eyeWideLeft'];wide_r=keys['eyeWideRight'];basis=keys[0]
for i in range(len(basis.data)):
 neutral_l=(wide_l.data[i].co-basis.data[i].co)*0.16
 neutral_r=(wide_r.data[i].co-basis.data[i].co)*0.16
 for key in list(keys)[1:]:
  if key.name in ['eyeBlinkLeft','eyeWideLeft']:key.data[i].co+=neutral_r
  elif key.name in ['eyeBlinkRight','eyeWideRight']:key.data[i].co+=neutral_l
  else:key.data[i].co+=neutral_l+neutral_r
 basis.data[i].co+=neutral_l+neutral_r
# Fit the source bust's lower neck to the actual garment opening. Measured
# sections put the source neck about 5 cm behind the body neck at the collar.
# Keep the face/chin and hair unchanged; deform all key endpoints equally.
def smooth(a,b,x):
 t=max(0.,min(1.,(x-a)/(b-a)));return t*t*(3-2*t)
for i in range(len(basis.data)):
 world=head.matrix_world@basis.data[i].co
 forward=-world.y
 weight=(1-smooth(1.325,1.395,world.z))*(1-smooth(.025,.070,forward))
 offset=Vector((0.,-.052*weight,0.))
 for key in keys:key.data[i].co+=offset
# Projection coordinates for the iris are fixed on the mesh, so skeletal motion
# cannot slide the procedural eye color over the eyeball. Other UVs stay intact.
uv=head.data.uv_layers.active
sclera={i for i,m in enumerate(head.data.materials)if m and m.name.startswith('Tiny Sclera')}
for face in head.data.polygons:
 if face.material_index not in sclera:continue
 for loop_index in face.loop_indices:
  v=head.data.vertices[head.data.loops[loop_index].vertex_index].co
  center=Vector((-.0265063522 if v.x<0 else .0258339928,.0603648629*-1,.0177822113))
  direction=v-center
  # glTF Y-up conversion turns Blender -Y into the forward eye axis.
  xy=Vector((direction.x/.0125,direction.z/.0125))
  uv.data[loop_index].uv=(xy.x*.5+.5,xy.y*.5+.5+(2.0 if direction.y>0 else 0.0))
# Blend the bottom of the neck between neck/head. All face/hair vertices remain
# rigid to the head, while facial deformation is supplied by the retained keys.
head.vertex_groups.clear()
groups={n:head.vertex_groups.new(name=n)for n in ['spine_03','neck_01','Head']}
rigid_vertices={index for face in head.data.polygons if head.data.materials[face.material_index].name!='Head' for index in face.vertices}
for v in head.data.vertices:
 world=head.matrix_world@v.co
 forward=-world.y
 t=smooth(1.325,1.38,world.z)
 face=smooth(1.325,1.34,world.z)*max(smooth(.015,.040,forward),smooth(.020,.035,abs(world.x)))
 t=1.0 if v.index in rigid_vertices else max(t,face)
 neck=max(0.,min(1.,(world.z-1.27)/.055));neck=neck*neck*(3-2*neck)
 weights={'Head':t,'neck_01':(1-t)*neck,'spine_03':(1-t)*(1-neck)}
 for name,weight in weights.items():
  if weight>0.000001:groups[name].add([v.index],weight,'REPLACE')
world=head.matrix_world.copy();head.parent=rig;head.matrix_world=world
modifier=head.modifiers.new('CharacterSkin','ARMATURE');modifier.object=rig
# Keep the original action library and rig names: all nine gameplay clips must
# be present after export. The source animation is not baked into a pose.
for action in bpy.data.actions:
 action.use_fake_user=True
bpy.ops.object.select_all(action='SELECT')
bpy.context.view_layer.objects.active=rig
output=root/'assets/characters/studies/AlinaRevision.glb'
bpy.ops.export_scene.gltf(filepath=str(output),export_format='GLB',use_selection=True,
 export_animations=True,export_skins=True,export_extras=False,
 export_all_vertex_colors=False,export_active_vertex_color_when_no_material=False,
 export_try_sparse_sk=True,export_try_omit_sparse_sk=True)
receipt={'body_source':str(body_file.relative_to(root)),'body_sha256':hashlib.sha256(body_file.read_bytes()).hexdigest(),
 'head_source':str(head_file.relative_to(root)),'head_sha256':hashlib.sha256(head_file.read_bytes()).hexdigest(),
 'output':str(output.relative_to(root)),'bytes':output.stat().st_size,'sha256':hashlib.sha256(output.read_bytes()).hexdigest(),
 'bones':len(rig.data.bones),'facial_shapes':len(keys)-1,'old_body_faces':old_count,'remaining_body_faces':len(body.data.polygons),
 'neutral_eye_wide':.16,'cloth_thickness_m':.0014,'lower_neck_forward_fit_m':.052,'rigid_mouth_eyes_hair':True,'status':'integration study; requires seated and animated inspection'}
(root/'assets/characters/studies/ALINA_REVISION_MANIFEST.json').write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n')
print('ALINA_REVISION_EXPORTED',receipt,flush=True)
