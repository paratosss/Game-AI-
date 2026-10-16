extends Node
func _ready():call_deferred("apply_profile")
func apply_profile():load("res://scripts/lakeside_quality.gd").apply(get_parent())
