extends SceneTree
## Interactive entry point for the visual study, including the unchanged self-test.
func _initialize():call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 load("res://scripts/graphics_quality.gd").apply(game)
 print("GRAPHICS_QUALITY_APPLIED renderer=",RenderingServer.get_current_rendering_method())
