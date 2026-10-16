extends Node
func _enter_tree():get_parent().set_meta("alina_revision",true)
func _ready():call_deferred("apply_profile")
func apply_profile():
 var skin=get_parent().actors[0].model.skin
 var has_revision_face=false
 for mesh in skin.face_meshes:
  if mesh.name.begins_with("AlinaRevisionHead") and mesh.mesh.get_blend_shape_count()==63:has_revision_face=true
 if not skin.uses_revision or not has_revision_face:
  push_error("Alina preview did not load the revised character")
  get_tree().quit(1)
  return
 print("ALINA_REVISION_ACTOR_CONFIRMED shapes=63")
 if get_parent().actors[0].guitar.get_meta("geometry_version",0)!=5:
  push_error("Alina preview did not load the revised guitar");get_tree().quit(1);return
 print("GUITAR_REVISION_CONFIRMED geometry_version=5")
 load("res://scripts/lakeside_quality.gd").apply(get_parent())
 print("ALINA_REVISION_PREVIEW_READY")
