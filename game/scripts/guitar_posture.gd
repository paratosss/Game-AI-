extends RefCounted
## A coordinated seated pose for the revised Alina only. The instrument is
## supported by the deformed garment, rather than a fixed root-space height.
static func prepare(skin):
 var samples=[]
 var thigh:Vector3=skin.rest.thigh_r.origin
 var axis:Vector3=skin.rest.calf_r.origin-thigh
 for mesh in skin.find_children("*","MeshInstance3D",true,false):
  if not "female_casualsuit" in str(mesh.name):continue
  for surface in range(mesh.mesh.get_surface_count()):
   var arrays=mesh.mesh.surface_get_arrays(surface)
   var vertices=arrays[Mesh.ARRAY_VERTEX];var bones=arrays[Mesh.ARRAY_BONES];var weights=arrays[Mesh.ARRAY_WEIGHTS]
   var stride=weights.size()/vertices.size()
   for vertex in range(vertices.size()):
    var t=(vertices[vertex]-thigh).dot(axis)/axis.length_squared()
    if t<.05 or t>.85:continue
    var influences=[];var thigh_weight=0.0
    for j in range(stride):
     var offset=vertex*stride+j;var weight=weights[offset]
     if weight<=0:continue
     var bind=bones[offset];var name=str(mesh.skin.get_bind_name(bind))
     influences.append([skin.indices[name],mesh.skin.get_bind_pose(bind)*vertices[vertex],weight])
     if name=="thigh_r":thigh_weight+=weight
    if thigh_weight>.65:samples.append(influences)
 skin.set_meta("guitar_thigh_samples",samples)

static func blend_basis(skin,bone:String,basis:Basis,weight:float):
 var current:Quaternion=skin.global_pose(bone).basis.get_rotation_quaternion()
 skin.set_bone_global_basis(bone,Basis(current.slerp(basis.get_rotation_quaternion(),weight)))

static func torso(skin,weight:float):
 for entry in [["spine_01",.035],["spine_02",.105],["spine_03",.18]]:
  var frame=Basis(Vector3.UP,.025)*Basis(Vector3.RIGHT,entry[1])
  blend_basis(skin,entry[0],frame*skin.rest[entry[0]].basis,weight)
 for bone in ["clavicle_l","clavicle_r"]:
  if not skin.indices.has(bone):continue
  var idx=skin.indices[bone];var parent=skin.skeleton.get_bone_parent(idx)
  var local:Basis=skin.skeleton.get_bone_rest(idx).basis
  blend_basis(skin,bone,skin.skeleton.get_bone_global_pose(parent).basis*local,weight)

static func place(skin,guitar:Node3D,weight:float):
 var playing=Basis.from_euler(Vector3(.14,-.035,-1.15))
 guitar.basis=Basis(guitar.basis.get_rotation_quaternion().slerp(playing.get_rotation_quaternion(),weight))
 var hip:Vector3=skin.global_pose("thigh_r").origin
 var knee:Vector3=skin.global_pose("calf_r").origin
 var desired=hip.lerp(knee,.50)+Vector3(0,.072,0)
 var support=desired;var distance=INF
 var poses=[]
 for bone in range(skin.skeleton.get_bone_count()):poses.append(skin.skeleton.get_bone_global_pose(bone))
 var points=[]
 for influences in skin.get_meta("guitar_thigh_samples",[]):
  var point=Vector3.ZERO
  for influence in influences:point+=(poses[influence[0]]*influence[1])*influence[2]
  points.append(point)
  var d=point.distance_squared_to(desired)
  if d<distance:distance=d;support=point
 var waist=Vector3(.111,.082,-.020)
 for point in guitar.get_meta("outline"):
  if point.x>0 and point.y>.045 and point.y<.115 and point.x<waist.x:waist=Vector3(point.x,point.y,-.020)
 var supported=support-guitar.basis*waist
 var inverse=guitar.basis.inverse();var up=inverse*Vector3.UP
 var outline:PackedVector2Array=guitar.get_meta("outline")
 # The narrow waist alone is insufficient: a curved thigh can enter the
 # adjacent lower bout. Lift to the first non-penetrating garment contact.
 for iteration in range(3):
  var lift=0.0
  for point in points:
   var local=inverse*(point-supported)
   if not inside_body(local,outline):continue
   var low=0.0;var high=.12
   for step in range(12):
    var middle=(low+high)*.5
    if inside_body(local-up*middle,outline):low=middle
    else:high=middle
   if high>lift:lift=high;support=point
  if lift==0:break
  supported+=Vector3.UP*(lift+.0003)
 guitar.position=guitar.position.lerp(supported,weight)
 guitar.set_meta("support_local",inverse*(support-supported))
 guitar.set_meta("thigh_support",support)
 guitar.set_meta("posture_version",8)

static func inside_body(point:Vector3,outline:PackedVector2Array)->bool:
 return point.z>-.047 and point.z<.048 and Geometry2D.is_point_in_polygon(Vector2(point.x,point.y),outline)

static func head(skin,weight:float,look:Vector3,dt:float):
 # Set global attitudes to remove the exaggerated native sit-neck bend; let
 # the gaze descend towards the playing area without collapsing the neck.
 var target=Vector2(.22,.40)
 if look.length()>.1:
  var direction:Vector3=skin.to_local(look)-skin.global_pose("Head").origin
  target=Vector2(clampf(atan2(direction.x,direction.z),-.40,.40),clampf(atan2(-direction.y,Vector2(direction.x,direction.z).length()),-.15,.45))
 skin.guitar_gaze=skin.guitar_gaze.lerp(target,1.0-exp(-dt*7.0))
 blend_basis(skin,"neck_01",Basis(Vector3.UP,skin.guitar_gaze.x*.25)*Basis(Vector3.RIGHT,skin.guitar_gaze.y*.1875)*skin.rest.neck_01.basis,weight)
 blend_basis(skin,"Head",Basis(Vector3.UP,skin.guitar_gaze.x)*Basis(Vector3.RIGHT,skin.guitar_gaze.y)*Basis(Vector3.FORWARD,.025)*skin.rest.Head.basis,weight)
