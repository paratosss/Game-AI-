"""First anatomical surface pass on the preserved rig, not a new body scan.

Blender 4.5.3. A geometry-only overlay keeps all original textures, clips and
rest matrices. The old full-character/body exports are never overwritten.
"""
from pathlib import Path
import bpy,math,json,hashlib
from mathutils import Vector
root=Path(__file__).resolve().parents[2]
full=root/'assets/characters/studies/AlinaRevision.glb';body_file=root/'assets/characters/studies/AlinaBody06.glb'
assert hashlib.sha256(full.read_bytes()).hexdigest()=='53358b0f8daeb64b573579212eeca4b5edf0345e49df1fe5beb326528069102a'
assert hashlib.sha256(body_file.read_bytes()).hexdigest()=='686b0bae92b6c4743bfe4664af55d777a102f08907bb99fd15c393ab9fc1dfb3'
bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(full))
rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
head=bpy.data.objects['AlinaRevisionHead'];garment=bpy.data.objects['Human.female_casualsuit01'];old_body=bpy.data.objects['Human']
old_material=old_body.data.materials[0]
before=set(bpy.context.scene.objects);bpy.ops.import_scene.gltf(filepath=str(body_file))
created=set(bpy.context.scene.objects)-before;source_rig=next(o for o in created if o.type=='ARMATURE');body=next(o for o in created if o.type=='MESH' and o.name.startswith('Human'))
for bone in rig.data.bones:
 assert max(abs(a-b) for ra,rb in zip(bone.matrix_local,source_rig.data.bones[bone.name].matrix_local) for a,b in zip(ra,rb))<1e-5
bpy.context.view_layer.objects.active=rig;bpy.ops.object.mode_set(mode='EDIT')
for side in ['l','r']:
 for level in ['mid','end']:
  name='forearm_twist_'+level+'_'+side;src=source_rig.data.bones[name]
  bone=rig.data.edit_bones.new(name);bone.head=src.head_local;bone.tail=src.tail_local;bone.matrix=src.matrix_local;bone.length=src.length;bone.parent=rig.data.edit_bones['lowerarm_'+side]
bpy.ops.object.mode_set(mode='OBJECT')
world=body.matrix_world.copy();body.parent=rig;body.matrix_world=world
for m in body.modifiers:
 if m.type=='ARMATURE':m.object=rig
bpy.data.objects.remove(old_body,do_unlink=True);body.name='Human';body.data.materials.clear();body.data.materials.append(old_material)
rig.animation_data_clear()
for pose in rig.pose.bones:pose.matrix_basis.identity()
bpy.context.view_layer.update()

def smooth(a,b,x):
 t=max(0.,min(1.,(x-a)/(b-a)));return t*t*(3-2*t)
def gaussian(x,center,width):return math.exp(-((x-center)/width)**2)

def neck_form(p):
 # Keep the face/hair/jaw rigid, taper the cervical column and remove part of
 # the earlier forward-only collar fit. Broad attachment at both ends stays.
 x,y,z=p
 mask=smooth(1.265,1.285,z)*(1-smooth(1.345,1.382,z))*(1-smooth(.065,.090,-y))
 taper=gaussian(z,1.320,.037)*mask
 x*=1-.105*taper
 y+=.014*mask
 # Paired sternocleidomastoid relief, restrained under ordinary skin lighting.
 t=max(0,min(1,(z-1.285)/.085));line=.013+.026*t
 scm=.0018*gaussian(abs(x),line,.006)*smooth(-.005,.030,-y)*math.sin(math.pi*t)*mask
 y-=scm
 # Soft suprasternal hollow between the sternal heads, not a painted shadow.
 y+=.0025*gaussian(x,0,.012)*gaussian(z,1.292,.015)*smooth(-.005,.030,-y)*mask
 return Vector((x,y,z))

def body_form(p,weights):
 delta=Vector((0,0,0))
 for side in ['l','r']:
  for segment in ['upperarm','lowerarm']:
   name=segment+'_'+side;weight=weights.get(name,0)
   if segment=='lowerarm':weight+=weights.get('forearm_twist_mid_'+side,0)+weights.get('forearm_twist_end_'+side,0)
   if weight<1e-6:continue
   bone=rig.data.bones[name];origin=bone.head_local;axis=(bone.tail_local-origin).normalized();length=bone.length
   t=(p-origin).dot(axis)/length
   if t<0 or t>1:continue
   radial=p-origin-axis*(p-origin).dot(axis)
   if radial.length<1e-6:continue
   anterior=Vector((0,-1,0));anterior=(anterior-axis*anterior.dot(axis)).normalized()
   facing=radial.normalized().dot(anterior)
   ends=smooth(.03,.12,t)*(1-smooth(.88,.99,t))
   if segment=='upperarm':
    # Separate anterior biceps belly and posterior triceps mass, keeping the
    # elbow and wrist joint centers untouched.
    factor=(.11*gaussian(t,.50,.23)*max(facing,0)+.055*gaussian(t,.45,.28)*max(-facing,0))*ends
   else:
    # Proximal flexor/extensor mass and distal taper, not uniform inflation.
    factor=(.12*gaussian(t,.28,.23)-.07*gaussian(t,.76,.17))*ends
   delta+=radial*factor*weight
 return p+delta

changes={}
for ob in [head,body,garment]:
 original=[v.co.copy() for v in ob.data.vertices]
 inv=ob.matrix_world.inverted();offsets=[]
 head_skin={v for f in head.data.polygons if head.data.materials[f.material_index].name=='Head' for v in f.vertices} if ob==head else set()
 for vertex in ob.data.vertices:
  p=ob.matrix_world@vertex.co;q=p.copy()
  weights={ob.vertex_groups[g.group].name:g.weight for g in vertex.groups}
  if ob==head and vertex.index in head_skin:q=neck_form(p)
  elif ob==body:q=body_form(p,weights)
  elif ob==garment:
   # Relax the shoulder cap and collar seam into the upper thorax; preserve
   # the opening, UVs, thickness, lower body and all fitting relationships.
   w=gaussian(abs(p.x),.115,.055)*gaussian(p.z,1.305,.030)
   q.z-=.005*w
  offsets.append(inv@q-vertex.co)
 if ob.data.shape_keys:
  for key in ob.data.shape_keys.key_blocks:
   for point,offset in zip(key.data,offsets):point.co+=offset
 else:
  for vertex,offset in zip(ob.data.vertices,offsets):vertex.co+=offset
 ob.data.update()
 changes[ob.name]={'vertices':len(ob.data.vertices),'moved_vertices':sum(v.length>1e-6 for v in offsets),'maximum_displacement_m':max(v.length for v in offsets),'shape_count':len(ob.data.shape_keys.key_blocks)-1 if ob.data.shape_keys else 0}
 # Keep material slots as small named placeholders. Textures are reused from
 # the preserved full character at runtime, avoiding another embedded pack.
 for i,old in enumerate(list(ob.data.materials)):
  placeholder=bpy.data.materials.new(old.name+'_Anatomy09');placeholder.diffuse_color=(.6,.6,.6,1);ob.data.materials[i]=placeholder
 for face in ob.data.polygons:face.use_smooth=True

# Corrective elbow folds are separate from the neutral anatomy. A bent elbow
# compresses the inner surface while the olecranon keeps a posterior landmark.
correctives={}
for side in ['l','r']:
 name='anatomyElbowFlex_'+side
 shape=body.shape_key_add(name=name,from_mix=False)
 base_points=body.data.shape_keys.key_blocks[0].data
 for point,base_point in zip(shape.data,base_points):point.co=base_point.co
 elbow=rig.data.bones['lowerarm_'+side].head_local
 upper=rig.data.bones['upperarm_'+side]
 axis=(upper.tail_local-upper.head_local).normalized()
 front=Vector((0,-1,0));front=(front-axis*front.dot(axis)).normalized()
 inv=body.matrix_world.inverted().to_3x3()
 moved=0;maximum=0.0
 for v in body.data.vertices:
  weights={body.vertex_groups[g.group].name:g.weight for g in v.groups}
  limb=sum(w for n,w in weights.items() if n in ['upperarm_'+side,'lowerarm_'+side,'forearm_twist_mid_'+side,'forearm_twist_end_'+side])
  upper_weight=weights.get('upperarm_'+side,0)
  lower_weight=sum(w for n,w in weights.items() if n in ['lowerarm_'+side,'forearm_twist_mid_'+side,'forearm_twist_end_'+side])
  # The crease belongs to the joint's transition zone, not the shaft or hand.
  if limb<.75 or upper_weight<.20 or lower_weight<.20:continue
  p=body.matrix_world@base_points[v.index].co;d=p-elbow
  longitudinal=d.dot(axis);radial=d-axis*longitudinal
  radius=radial.length
  if radius<.004:continue
  mask=gaussian(longitudinal,0,.014)*gaussian(d.length,.025,.026)*smooth(.20,.35,upper_weight)*smooth(.20,.35,lower_weight)
  facing=radial.normalized().dot(front)
  inward=.0032*max(0,facing)**2*mask
  posterior=.0020*max(0,-facing)**3*mask
  delta=inv@(radial.normalized()*(posterior-inward))
  shape.data[v.index].co+=delta
  if delta.length>1e-6:moved+=1;maximum=max(maximum,delta.length)
 correctives[name]={'moved_vertices':moved,'maximum_displacement_m':maximum}
changes['Human']['shape_count']=len(body.data.shape_keys.key_blocks)-1

bpy.ops.object.select_all(action='DESELECT')
for o in [rig,head,body,garment]:o.select_set(True)
bpy.context.view_layer.objects.active=rig
output=root/'assets/characters/studies/AlinaAnatomy09.glb'
bpy.ops.export_scene.gltf(filepath=str(output),export_format='GLB',use_selection=True,export_animations=False,export_skins=True,export_all_influences=True,export_try_sparse_sk=True,export_try_omit_sparse_sk=True)
receipt={'source_sha256':hashlib.sha256(full.read_bytes()).hexdigest(),'body_source_sha256':hashlib.sha256(body_file.read_bytes()).hexdigest(),'file':str(output.relative_to(root)),'bytes':output.stat().st_size,'sha256':hashlib.sha256(output.read_bytes()).hexdigest(),'bones':len(rig.data.bones),'changes':changes,'correctives':correctives,'scope':'First cervical/upper-limb surface reshaping on the preserved rig, not a new anatomical full-body sculpt; materials are placeholders replaced at runtime.'}
(output.parent/'ALINA_ANATOMY_09_MANIFEST.json').write_text(json.dumps(receipt,indent=2)+'\n')
print('ANATOMY_09_EXPORTED',json.dumps(receipt),flush=True)
