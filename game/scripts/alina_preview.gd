extends Node
func _enter_tree():get_parent().set_meta("alina_revision",true)
func _ready():call_deferred("apply_profile")
func apply_profile():
 load("res://scripts/lakeside_quality.gd").apply(get_parent())
 print("ALINA_REVISION_PREVIEW_READY")
