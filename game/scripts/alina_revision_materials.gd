extends RefCounted
## Materials for the full-character study, isolated from the original actors.
static func apply(instance:Node3D):
 load("res://scripts/alina_body_revision.gd").apply(instance)
 load("res://scripts/head_study_materials.gd").apply(instance)
 for mesh in instance.find_children("*","MeshInstance3D",true,false):
  for index in range(mesh.mesh.get_surface_count()):
   var original=mesh.mesh.surface_get_material(index)
   if not original is StandardMaterial3D:continue
   if "female_casualsuit" in original.resource_name:
    var cloth=ShaderMaterial.new()
    cloth.shader=load("res://assets/shaders/cloth_quality.gdshader")
    cloth.set_shader_parameter("base_color",original.albedo_texture)
    cloth.set_shader_parameter("cloth_normal",original.normal_texture)
    mesh.set_surface_override_material(index,cloth)
   elif original.resource_name=="Human.body":
    var skin=original.duplicate()
    skin.albedo_color=Color("e3c5b5")
    skin.roughness=0.65
    skin.metallic=0.0
    mesh.set_surface_override_material(index,skin)
   elif original.resource_name in ["Hair","Eye Bros","Eye Lashes"]:
    var hair=original.duplicate()
    hair.roughness=0.62
    hair.metallic_specular=0.25
    mesh.set_surface_override_material(index,hair)
