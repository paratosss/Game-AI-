extends Node

func _ready():
 call_deferred("apply_profile")

func apply_profile():
 load("res://scripts/graphics_quality.gd").apply(get_parent())
 print("QUALITY_PREVIEW_READY")
