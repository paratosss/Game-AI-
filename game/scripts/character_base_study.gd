extends Node3D
## An inspection scene for a candidate head. It does not replace the gameplay actor.
var camera:Camera3D
var subject:Node3D
var yaw=0.0
var pitch=0.0
var distance=0.74
var dragging=false
var target=Vector3(0,1.455,0.10)

func pose(values:Dictionary):
 for mesh in subject.find_children("*","MeshInstance3D",true,false):
  for index in range(mesh.mesh.get_blend_shape_count()):
   mesh.set_blend_shape_value(index,values.get(mesh.mesh.get_blend_shape_name(index),0.0))

func camera_position():
 camera.position=target+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*distance
 camera.look_at(target,Vector3.UP)

func _ready():
 if RenderingServer.get_current_rendering_method()=="forward_plus":get_viewport().use_taa=true
 subject=load("res://assets/characters/studies/AlternativeHeadStudy.glb").instantiate()
 add_child(subject)
 load("res://scripts/head_study_materials.gd").apply(subject)
 pose({})
 var environment=WorldEnvironment.new()
 environment.environment=Environment.new()
 environment.environment.background_mode=Environment.BG_COLOR
 environment.environment.background_color=Color("777c82")
 environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 environment.environment.ambient_light_color=Color.WHITE
 environment.environment.ambient_light_energy=0.40
 environment.environment.tonemap_mode=Environment.TONE_MAPPER_AGX
 add_child(environment)
 for settings in [[Vector3(-38,-35,0),1.4],[Vector3(-25,135,0),0.50]]:
  var light=DirectionalLight3D.new()
  light.rotation_degrees=settings[0]
  light.light_energy=settings[1]
  light.shadow_enabled=true
  add_child(light)
 camera=Camera3D.new()
 add_child(camera)
 camera.current=true
 camera.fov=30
 camera_position()
 var canvas=CanvasLayer.new()
 add_child(canvas)
 var panel=VBoxContainer.new()
 canvas.add_child(panel)
 panel.position=Vector2(18,16)
 var title=Label.new()
 title.text="Кандидат новой основы — исследование лица и волос"
 panel.add_child(title)
 var hint=Label.new()
 hint.text="ЛКМ и движение мыши — поворот · колёсико — расстояние\nОбраз, тело и интеграция Алины ещё в работе."
 panel.add_child(hint)
 var buttons=HBoxContainer.new()
 panel.add_child(buttons)
 for entry in [["Нейтрально",{}],["Моргание",{"eyeBlinkLeft":1.0,"eyeBlinkRight":1.0}],["Улыбка",{"mouthSmileLeft":0.65,"mouthSmileRight":0.65}],["Челюсть",{"jawOpen":0.65}]]:
  var button=Button.new()
  button.text=entry[0]
  button.pressed.connect(pose.bind(entry[1]))
  buttons.add_child(button)
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 print("CHARACTER_BASE_STUDY_READY")

func _unhandled_input(event):
 if event is InputEventMouseButton:
  if event.button_index==MOUSE_BUTTON_LEFT:dragging=event.pressed
  if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
   distance=clampf(distance*(0.90 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.10),0.38,1.50)
   camera_position()
 elif event is InputEventMouseMotion and dragging:
  yaw-=event.relative.x*0.009
  pitch=clampf(pitch+event.relative.y*0.006,-0.65,0.65)
  camera_position()
