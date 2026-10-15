extends SceneTree

func _initialize():call_deferred("run")

func run():
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 await create_timer(.2).timeout
 game.initialized=false
 game.set_physics_process(false)
 for actor in game.actors:actor.set_physics_process(false)
 var actors=[]
 for actor in game.actors:
  var item={"name":actor.profile.name,"activity":actor.profile.activity,"state":actor.state,"position":[actor.position.x,actor.position.y,actor.position.z],"actions":Array(actor.animation.get_animation_list())}
  var skin=actor.model.dog_skin if actor.model.has("dog_skin") else actor.model.skin
  item["bones"]=skin.skeleton.get_bone_count()
  if actor.model.has("skin"):
   item["native_clips"]=Array(skin.native_animation.get_animation_list())
   item["face_meshes"]=skin.face_meshes.size()
  else:item["gait_clips"]=skin.motion_clips.keys()
  actors.append(item)
 var stations=[]
 for key in game.stations:
  var station=game.stations[key]
  stations.append({"key":key,"title":station.get_meta("title"),"action":station.get_meta("action"),"position":[station.position.x,station.position.y,station.position.z]})
 var props=[]
 for p in game.props:props.append({"kind":p.kind,"position":[p.position.x,p.position.y,p.position.z]})
 var multimeshes=[]
 for n in game.find_children("*","MultiMeshInstance3D",true,false):
  multimeshes.append({"node":str(n.name),"instances":n.multimesh.instance_count})
 var meshes=game.find_children("*","MeshInstance3D",true,false)
 var material_kinds={}
 for mesh in meshes:
  for surface in range(mesh.mesh.get_surface_count()):
   var mat=mesh.get_active_material(surface)
   var kind=mat.get_class() if mat else "none"
   material_kinds[kind]=material_kinds.get(kind,0)+1
 var results={"actors":actors,"stations":stations,"props":props,"grill_slots":game.slots.size(),"mesh_nodes":meshes.size(),"material_surfaces_by_type":material_kinds,"multimeshes":multimeshes,"static_bodies":game.find_children("*","StaticBody3D",true,false).size(),"lights":game.find_children("*","Light3D",true,false).size(),"renderer":RenderingServer.get_current_rendering_method()}
 var path=OS.get_environment("SHASHLIK_AUDIT_OUTPUT")
 if path.is_empty():push_error("SHASHLIK_AUDIT_OUTPUT must be set");game.clean_quit(1);return
 var file=FileAccess.open(path,FileAccess.WRITE)
 if not file:push_error("Could not open audit output");game.clean_quit(1);return
 file.store_string(JSON.stringify(results,"  "))
 print("SCENE_AUDIT_COMPLETE actors=",actors.size()," stations=",stations.size()," props=",props.size()," mesh_nodes=",meshes.size())
 game.clean_quit()
