extends RefCounted
## Provisional portable materials for the alternative head, not a completed face pipeline.
static func apply(instance:Node3D):
 for mesh in instance.find_children("*","MeshInstance3D",true,false):
  for index in range(mesh.mesh.get_surface_count()):
   var original=mesh.mesh.surface_get_material(index)
   if original and original.resource_name.begins_with("Tiny Sclera"):
    var eye=ShaderMaterial.new()
    eye.shader=load("res://assets/shaders/study_eye.gdshader")
    eye.set_shader_parameter("use_iris_uv",mesh.name.begins_with("AlinaRevisionHead"))
    mesh.set_surface_override_material(index,eye)
   elif original is StandardMaterial3D and original.resource_name=="Head":
    var skin=ShaderMaterial.new()
    skin.shader=load("res://assets/shaders/study_skin.gdshader")
    skin.set_shader_parameter("skin_color",load("res://assets/characters/studies/AlinaSkinStudy_Generated.png"))
    skin.set_shader_parameter("skin_normal",original.normal_texture)
    skin.set_shader_parameter("skin_roughness",original.roughness_texture)
    var channel=Vector4.ZERO
    channel[mini(original.roughness_texture_channel,3)]=1.0
    skin.set_shader_parameter("roughness_channel",channel)
    mesh.set_surface_override_material(index,skin)
