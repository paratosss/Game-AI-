extends Node3D
var player:CharacterBody3D
var camera:Camera3D
var hand:Node3D
var grip:Node3D
var held:DemoProp
var ball:DemoProp
var props:Array=[]
var actors:Array=[]
var clock=0.0
var points=0
var log_text=""
var notification_time=0.0
var sport_timer=0.0
var steal_timer=0.0
var bark_timer=0.0
var steals=0
var dog_cooldown=0.0
var order_count=0
var snack_count=0
var fan_heat=0.0
var music:AudioStreamPlayer3D
var bark:AudioStreamPlayer3D
var stations:Dictionary={}
var grill_pos=Vector3(-2,0,0)
var ray_target:Node
var labels={"onion":"Луковый","kefir":"Кефирный"}
var initialized=false
var ui:DemoHUD
var slots:Array=[]
var ghosts:Array=[]
var candidate=-1
var placement_aimed=false
var tutorial=0
var finished=false
var world_data:Dictionary
func solid(pos:Vector3,size:Vector3,color:Color)->StaticBody3D:
 var n=StaticBody3D.new();add_child(n);n.position=pos;DemoVisual.box(n,size,color);DemoVisual.collider(n,size);return n
func station(pos:Vector3,title:String,action:String,value:String):
 var n=StaticBody3D.new();add_child(n);n.position=pos;n.set_meta("action",action);n.set_meta("value",value);n.set_meta("title",title);stations[value]=n
 if action=="food":
  DemoVisual.rounded_box(n,Vector3(.51,.024,.38),Color("c1c6be"),Vector3.ZERO,.012);DemoVisual.collider(n,Vector3(.51,.075,.38),Vector3(0,.025,0))
  for z in [-.19,.19]:DemoVisual.rounded_box(n,Vector3(.49,.030,.014),Color("b2b8b1"),Vector3(0,.019,z),.006)
  for x in [-.25,.25]:DemoVisual.rounded_box(n,Vector3(.014,.030,.36),Color("b2b8b1"),Vector3(x,.019,0),.006)
  for i in range(6):DemoVisual.food(n,DemoRules.piece(value),Vector3((i%3-1)*.115,.052,(i/3-.5)*.115))
 else:
  DemoVisual.cylinder(n,.068,.19,Color("a89973") if value=="onion" else Color("acaea1"))
  var lid=DemoVisual.cylinder(n,.068,.023,Color("a4aba5"),Vector3(0,.106,0));lid.material_override=DemoVisual.mat(Color("a4aba5"),.5)
  for j in range(24):DemoVisual.cylinder(n,.0015,.018,Color("828983"),Vector3(cos(j*TAU/24)*.067,.106,sin(j*TAU/24)*.067))
  DemoVisual.cylinder(n,.069,.055,Color("557469") if value=="onion" else Color("567385"))
  DemoVisual.collider(n,Vector3(.145,.23,.145))
func prop(kind:String,title:String,pos:Vector3)->DemoProp:
 var p=DemoProp.new();add_child(p);p.build(kind,title);p.position=pos;props.append(p);return p
func notify(text:String):
 log_text=text;notification_time=4
func _ready():
 world_data=DemoWorld.build(self)
 for i in range(3):
  slots.append(grill_pos+Vector3((i-1)*.45,.90,0))
  var ghost=Node3D.new();add_child(ghost);ghost.position=slots[i];DemoVisual.skewer(ghost)
  for mesh in ghost.get_children():
   var mat=StandardMaterial3D.new();mat.albedo_color=Color(.22,.78,.82,.45);mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mesh.material_override=mat;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  ghost.visible=false;ghosts.append(ghost)
  # Permanent shallow grooves on the rails, never collider boxes over slots.
  for z in [-.345,.345]:DemoVisual.box(self,Vector3(.044,.013,.044),Color("687979"),grill_pos+Vector3((i-1)*.45,.874,z))
 solid(Vector3(-2.6,.835,3.24),Vector3(.97,.025,.44),Color("485448"))
 for i in range(3):
  var p=prop("skewer","Шампур",Vector3(-2.6,.89,3.1+i*.14));p.rotation.y=PI/2
 prop("fan","Опахало",Vector3(-1.8,.88,3.22))
 ball=prop("ball","Мяч",Vector3(4.7,.35,2.8))
 for i in range(4):
  var a=DemoActor.new();add_child(a);a.position=[Vector3(0,0,-3.2),Vector3(3.5,0,3.6),Vector3(6.5,0,2.5),Vector3(5,0,2)][i];a.build(DemoRules.PROFILES[i],[Color("926258"),Color("947445"),Color("3f5967"),Color.WHITE][i]);a.target=a.position;actors.append(a)
  if i==0:a.add_collision_exception_with(world_data.bench)
 actors[0].add_collision_exception_with(world_data.bench)
 music=AudioStreamPlayer3D.new();actors[0].add_child(music);music.stream=load("res://assets/audio/guitar.ogg");music.volume_db=-17;music.max_distance=16;music.unit_size=3;music.stream.loop=true
 bark=AudioStreamPlayer3D.new();actors[3].add_child(bark);bark.stream=load("res://assets/audio/bark.wav");bark.volume_db=-13;bark.max_distance=18;bark.unit_size=2
 player=CharacterBody3D.new();add_child(player);player.position=Vector3(-2.6,0,4.4)
 var c=CollisionShape3D.new();var cap=CapsuleShape3D.new();cap.radius=.24;cap.height=1.7;c.shape=cap;c.position.y=.85;player.add_child(c)
 camera=Camera3D.new();player.add_child(camera);camera.position.y=1.62;camera.fov=70;camera.rotation.x=-.30;camera.current=true;camera.look_at(Vector3(-2.6,.86,3.1))
 hand=Node3D.new();camera.add_child(hand);hand.position=Vector3(.045,-.22,-.93)
 grip=Node3D.new();hand.add_child(grip);grip.position=Vector3(0,-.034,.36)
 DemoVisual.sphere(grip,.045,Color("b79079"),Vector3.ZERO,Vector3(.8,.8,1.2));DemoVisual.sphere(grip,.03,Color("b79079"),Vector3(.027,.023,0),Vector3(.7,.6,1.35));grip.visible=false
 ui=DemoHUD.new();add_child(ui);ui.build(self)
 Input.mouse_mode=Input.MOUSE_MODE_CAPTURED;initialized=true
 if "--self-test" in OS.get_cmdline_user_args():call_deferred("self_test")
 if "--audit" in OS.get_cmdline_user_args():call_deferred("audit")
func _unhandled_input(event):
 if event is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
  player.rotation.y-=event.relative.x*.0022;camera.rotation.x=clampf(camera.rotation.x-event.relative.y*.0022,-1.35,1.35)
 if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
  if Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED:Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
  elif held and held.kind=="fan":
   hand.rotation.z=.7
   if held.global_position.distance_to(grill_pos+Vector3(0,.8,0))<1.8:fan_heat=1.7
 if event is InputEventKey and event.pressed and not event.echo:
  match event.physical_keycode:
   KEY_ESCAPE:Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
   KEY_F1:ui.help_panel.visible=not ui.help_panel.visible
   KEY_SPACE:
    if player.is_on_floor() and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:player.velocity.y=4.0
   KEY_M:AudioServer.set_bus_mute(0,not AudioServer.is_bus_mute(0))
   KEY_F5:get_tree().reload_current_scene()
   KEY_E:interact()
   KEY_Q:release(false)
   KEY_G:release(true)
   KEY_R:
    var p=held if held and held.kind=="skewer" else ray_target if ray_target is DemoProp and ray_target.kind=="skewer" else null
    if p:flip(p)
func target()->Node:
 var q=PhysicsRayQueryParameters3D.create(camera.global_position,camera.global_position-camera.global_basis.z*2.5);q.exclude=[player.get_rid()]
 if held:q.exclude.append(held.get_rid())
 var hit=get_world_3d().direct_space_state.intersect_ray(q)
 return hit.get("collider")
func occupied(index:int)->bool:
 for p in props:
  if p!=held and p.kind=="skewer" and p.global_position.distance_to(slots[index])<.17:return true
 return false
func placement():
 candidate=-1;placement_aimed=false
 for ghost in ghosts:ghost.visible=false
 if not held or held.kind!="skewer":return
 var direction=-camera.global_basis.z
 if direction.y>=-.035:return
 var t=(.90-camera.global_position.y)/direction.y
 if t<0 or t>2.5:return
 var aim=camera.global_position+direction*t;var local=aim-grill_pos
 if absf(local.x)>.80 or absf(local.z)>.48:return
 var query=PhysicsRayQueryParameters3D.create(camera.global_position,aim);query.exclude=[player.get_rid(),held.get_rid()]
 var blocker=get_world_3d().direct_space_state.intersect_ray(query)
 if blocker:
  var body=blocker.collider
  if not body is DemoProp and not (body.has_meta("action") and body.get_meta("action")=="grill"):return
 placement_aimed=true;var index=clampi(int(round(local.x/.45))+1,0,2)
 for i in range(3):
  if not occupied(i):
   ghosts[i].visible=true
   for mesh in ghosts[i].get_children():mesh.material_override.albedo_color=Color(.20,.77,.82,.55 if i==index else .16)
 if occupied(index):return
 candidate=index;ghosts[index].visible=true
func interact():
 placement()
 if placement_aimed:
  if candidate>=0:place_skewer(candidate)
  else:notify("Это место занято")
  return
 var n=target()
 if not n:return
 if n is DemoActor:
  if held and held.kind=="skewer":serve(n)
 elif n.has_meta("action") and held and held.kind=="skewer":
  if n.get_meta("action")=="food":
   if held.pieces.size()<6:held.pieces.append(DemoRules.piece(n.get_meta("value")));held.refresh();tutorial=maxi(tutorial,2)
   else:notify("Шесть кусочков — шампур заполнен")
  elif n.get_meta("action")=="marinade":
   for p in held.pieces:p.marinade=n.get_meta("value");p.late=p.late or maxf(p.sides[0],p.sides[1])>.05
   held.refresh();notify(n.get_meta("title"))
 elif n is DemoProp and not held:pick(n)
func pick(p:DemoProp):
 if p==ball and steal_timer>0:steal_timer=0;dog_cooldown=6
 held=p;p.placed_slot=-1;p.freeze=true;p.collision_layer=0;p.reparent(hand);p.position=Vector3.ZERO;p.rotation=Vector3(0,0,PI*p.side)
 if p.kind=="skewer":tutorial=maxi(tutorial,1)
func release(thrown:bool):
 if not held:return
 var p=held;held=null;p.reparent(self);p.freeze=false;p.collision_layer=1;p.placed_slot=-1;p.linear_velocity=-camera.global_basis.z*(7 if thrown else .2);p.angular_velocity=Vector3(1,0,2) if thrown else Vector3.ZERO
func place_skewer(index:int)->bool:
 if not held or held.kind!="skewer" or occupied(index):return false
 var p=held;held=null;p.reparent(self);p.freeze=true;p.collision_layer=1;p.global_position=slots[index];p.global_rotation=Vector3(0,0,PI*p.side);p.linear_velocity=Vector3.ZERO;p.angular_velocity=Vector3.ZERO;p.placed_slot=index;tutorial=maxi(tutorial,3)
 thaw.call_deferred(p);return true
func thaw(p:DemoProp):
 await get_tree().physics_frame
 if is_instance_valid(p) and p!=held:p.freeze=false
func flip(p:DemoProp):
 p.side=1-p.side
 if p==held:
  create_tween().tween_property(p,"rotation:z",PI*p.side,.22)
 elif p.placed_slot>=0:
  p.freeze=true
  var tw=create_tween();tw.tween_property(p,"rotation:z",p.rotation.z+PI,.22);tw.finished.connect(func():thaw(p))
 else:notify("Сначала возьми шампур")
func serve(a:DemoActor):
 var snack=a.profile.get("dog",false) and a.state!="ORDER"
 if a.state!="ORDER" and not snack:notify(a.profile.name+": «Пока сыт!»");return
 if held.pieces.is_empty():notify("Шампур пустой");return
 var total=0;var reaction="happy";var kept=[]
 for p in held.pieces:
  var r=DemoRules.evaluate(p,a.profile)
  if not snack and a.course[r.type]>=3:kept.append(p);continue
  if snack:
   total+=2 if p.dirty or DemoRules.state(p) in ["raw","burnt"] else 5;snack_count+=1
  else:
   total+=r.points
   if r.accepted:a.course[r.type]+=1
   if r.reaction not in ["happy","like"]:reaction=r.reaction
   elif r.reaction=="like" and reaction=="happy":reaction="like"
 held.pieces=kept;held.refresh();points+=total
 a.action("happy" if reaction=="like" else reaction,2.0)
 var words={"happy":"Вкусно!","like":"Другой заказ, но тоже люблю!","gag":"Кхе… сырое!","spit":"Тьфу, земля!","cough":"Кхе-кхе! Это уголь?","dislike":"Такое не люблю!"}
 notify(a.profile.name+": "+("Ам!" if a.profile.get("dog",false) else words[reaction])+"  %+d"%total)
 if not snack and a.course.meat>=3 and a.course.veg>=3:a.completed=true;a.state="EAT";a.action("eat",4.0)
func _physics_process(dt):
 if not initialized:return
 clock+=dt;notification_time=maxf(0,notification_time-dt);fan_heat=maxf(0,fan_heat-dt);hand.rotation.z=lerpf(hand.rotation.z,0,dt*8)
 if Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
  var input=Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
  var dir=player.basis*Vector3(input.x,0,input.y).normalized();var speed=1.8 if Vector2(player.position.x-7,player.position.z+6).length()<3.7 else 3.1
  player.velocity.x=dir.x*speed;player.velocity.z=dir.z*speed
 else:player.velocity.x=0;player.velocity.z=0
 player.velocity.y-=9.8*dt;player.move_and_slide();grip.visible=held!=null and held.kind!="ball"
 tick_orders();tick_activities(dt)
 var frying=false
 for p in props:
  if p.kind!="skewer":continue
  if p!=held and p.global_position.y<.17:
   var changed=false
   for piece in p.pieces:
    if not piece.dirty:changed=true
    piece.dirty=true
   if changed:p.refresh()
  var d=p.global_position-grill_pos
  if p!=held and absf(d.x)<.79 and absf(d.z)<.4 and d.y>.86 and d.y<.98:
   frying=frying or not p.pieces.is_empty()
   for piece in p.pieces:DemoRules.cook(piece,p.side,dt,1+fan_heat*.4)
   p.refresh_clock+=dt
   if p.refresh_clock>.6:p.refresh_clock=0;p.refresh()
 world_data.smoke.emitting=frying
 ray_target=target();placement();ui.update_game(self)
func tick_orders():
 var active=0
 for a in actors:if a.state in ["ORDER","EAT"]:active+=1
 for i in range(actors.size()):
  var a=actors[i]
  if not a.ordered and clock>=a.profile.delay and active<2:
   a.ordered=true;a.state="ORDER";a.target=Vector3(-.25+i*.62,0,-.60);a.action("getup" if i==0 else "wave",.85);active+=1;order_count+=1;notify(a.profile.name+" проголодался")
  if a.state=="ORDER":a.facing=player.global_position
  if a.state=="EAT" and a.reaction_time<=0:a.state=a.profile.activity
 var done=true
 for a in actors:if not a.completed:done=false
 if done and not finished:finished=true;notify("Все накормлены! Отдыхаем. F5 — новая поляна")
func tick_activities(dt):
 sport_timer-=dt;bark_timer-=dt;dog_cooldown=maxf(0,dog_cooldown-dt)
 var players=[]
 for a in actors:
  if a.state=="BALL":players.append(a)
  if a.state=="GUITAR":a.target=Vector3(0,0,-3.2)
 var dog=actors[3]
 if dog.state=="DOG":
  if held==ball:dog.target=player.position+Vector3(.6,0,.8)
  elif steal_timer>0:
   steal_timer-=dt;ball.global_position=dog.model.head.to_global(Vector3(0,-.032,.20));dog.target=Vector3(7,0,3.5)
   if steal_timer<=0:ball.freeze=false;ball.linear_velocity=Vector3(-2,1.3,-.2)
  else:
   dog.target=ball.position+Vector3(1.6,0,-1) if dog_cooldown>0 else ball.position
   if dog_cooldown<=0 and players.size()>0 and dog.position.distance_to(ball.position)<.66:
    ball.freeze=true;steal_timer=2.7;dog_cooldown=13;steals+=1;dog.action("bark",.7)
    if bark_timer<=0:bark.play();bark_timer=8
  if players.size()>0 and bark_timer<=0 and dog.position.distance_to(ball.position)<2 and ball.linear_velocity.length()>1.5:
   bark.pitch_scale=randf_range(.96,1.05);bark.play();dog.action("bark",.7);bark_timer=9+randf()*5
 elif ball.freeze and held!=ball:ball.freeze=false;steal_timer=0
 for i in range(players.size()):
  var a=players[i]
  if ball.freeze or held==ball:a.target=Vector3(3.6+i*2.4,0,3.5);a.facing=dog.global_position if held!=ball else player.global_position
  elif i==0:a.target=ball.position+Vector3(-.25,0,.45)
  else:
   var near=ball.position.distance_to(a.position)<1.1
   a.target=ball.position+Vector3(.25,0,.40) if near else Vector3(6.2,0,2.6);a.facing=ball.position
 if players.size()>0 and sport_timer<=0 and not ball.freeze and held!=ball:
  var kicker=players[0]
  for a in players:if a.position.distance_to(ball.position)<kicker.position.distance_to(ball.position):kicker=a
  if kicker.position.distance_to(ball.position)<.95:
   var destination=Vector3(4.5,0,3.2) if players.size()==1 else (Vector3(6.2,0,2.6) if kicker==players[0] else Vector3(3.6,0,3.5))
   var direction=destination-ball.position;direction.y=0
   kicker.facing=ball.position
   ball.apply_central_impulse(direction.normalized()*1.15+Vector3(0,.48,0));sport_timer=2.4;kicker.action("kick",.6)
 if ball.position.x>10 or ball.position.x<2 or ball.position.z<1.3 or ball.position.z>7:
  if held!=ball and not ball.freeze:
   # Retrieve stray sports ball physically instead of teleporting it.
   if players.size()>0:players[0].target=ball.position
 if actors[0].state=="GUITAR" and actors[0].position.distance_to(Vector3(0,0,-3.2))<.3:
  if not music.playing:music.play()
 elif music.playing:music.stop()
func clean_quit(code:int=0):
 initialized=false;music.stop();music.stream=null;bark.stop();bark.stream=null
 await get_tree().create_timer(.25).timeout;OS.delay_msec(120);get_tree().quit(code)
func _exit_tree():
 if music:music.stop();music.stream=null
 if bark:bark.stop();bark.stream=null

var test_failures=0
func verify(condition:bool,description:String):
 if not condition:test_failures+=1;push_error("TEST FAILED: "+description)
func press(key:int):
 var event=InputEventKey.new();event.physical_keycode=key;event.pressed=true;_unhandled_input(event)
func aim_at(point:Vector3):camera.look_at(point,Vector3.UP)
func self_test():
 await get_tree().create_timer(.3).timeout
 var sk=props[0];player.position=Vector3(-2.7,0,3.9);aim_at(sk.global_position)
 await get_tree().physics_frame
 verify(target()==sk,"ray picking a real skewer");press(KEY_E);verify(held==sk,"E takes the aimed skewer")
 for food in ["chicken","chicken","chicken","mushroom","mushroom","mushroom"]:
  aim_at(stations[food].global_position+Vector3(0,.035,0));await get_tree().physics_frame
  verify(target()==stations[food],"ingredient is accessible: "+food);press(KEY_E)
 verify(sk.pieces.size()==6,"six pieces through actual E interaction")
 aim_at(stations.kefir.global_position);await get_tree().physics_frame;press(KEY_E)
 for p in sk.pieces:verify(p.marinade=="kefir","marinade applied through aim")
 player.position=Vector3(-2,0,1.6);player.rotation=Vector3.ZERO;aim_at(slots[1]);await get_tree().physics_frame;placement()
 verify(candidate==1,"preview identifies middle grill slot");press(KEY_E);verify(held==null and sk.placed_slot==1,"E places, without free-drop guessing")
 for i in range(100):await get_tree().physics_frame
 verify(sk.position.distance_to(slots[1])<.04,"placed skewer remains physically on rails")
 verify(sk.pieces[0].sides[0]>.02,"physical placement actually heats food")
 aim_at(sk.global_position);await get_tree().physics_frame;verify(target()==sk,"can pick skewer from rails");press(KEY_R)
 for i in range(30):await get_tree().physics_frame
 verify(sk.side==1,"R turns skewer directly on grill");verify(sk.pieces[0].sides[1]>.01,"other side receives heat")
 pick(props[1]);aim_at(slots[1]);placement();verify(placement_aimed and candidate==-1,"occupied slot does not overlap skewer");aim_at(slots[0]);placement();verify(candidate==0,"neighbor slot remains selectable");place_skewer(0)
 for i in range(10):await get_tree().physics_frame
 pick(sk)
 clock=21;tick_orders();verify(order_count==1,"only first guest hungry at 21 seconds")
 for p in sk.pieces:p.sides=[1.0,1.0]
 sk.refresh();actors[0].state="ORDER";serve(actors[0]);verify(actors[0].completed and actors[0].state=="EAT","full meal finishes Alina order");verify(sk.pieces.is_empty(),"only served food consumed")
 actors[0].reaction_time=0;tick_orders();verify(actors[0].state=="GUITAR","guest returns to activity after meal")
 var wrong=DemoRules.piece("pork");wrong.sides=[1.0,1.0];verify(DemoRules.evaluate(wrong,actors[0].profile).points==17,"favorite substitute gets reduced points")
 wrong.dirty=true;verify(not DemoRules.evaluate(wrong,actors[0].profile).accepted,"humans refuse dirty food")
 sk.pieces=[wrong];var before=points;actors[3].state="DOG";serve(actors[3]);verify(points==before+2,"dog eats ruined food even between orders")
 serve(actors[3]);verify(points==before+2,"empty skewer gives no points")
 actors[3].state="DOG";dog_cooldown=0;steal_timer=0;ball.freeze=false;ball.position=actors[3].position+Vector3(.1,.2,.1);release(false);var old_steals=steals;tick_activities(.1);verify(steals==old_steals+1,"dog steals ball");tick_activities(3.1);verify(not ball.freeze,"dog releases ball")
 clock=200;tick_orders();var active=0
 for a in actors:if a.state in ["ORDER","EAT"]:active+=1
 verify(active<=2,"at most two simultaneous orders")
 for a in actors:verify(a.animation.has_animation("walk"),"joint-based walking animation exists")
 print("SELF_TEST_04_", "PASS" if test_failures==0 else "FAIL", ": ray actions, ingredients, marinade, ghost, physical placement, flip, neighboring slot, meal, return, favorites, dog snacks, queue; failures=",test_failures)
 clean_quit(0 if test_failures==0 else 1)
func audit():
 for i in range(6600):await get_tree().physics_frame
 verify(order_count==2,"natural staggered orders capped at two")
 verify(actors[2].state=="BALL" and actors[3].state=="DOG","waiting guests continue activities")
 verify(steals>0,"natural ball pursuit produces steals")
 print("INTEGRATION_04_", "PASS" if test_failures==0 else "FAIL", ": 110 seconds, orders=",order_count," steals=",steals)
 clean_quit(0 if test_failures==0 else 1)
