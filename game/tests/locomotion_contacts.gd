extends SceneTree

var failures=0

func check(condition:bool,message:String):
 if not condition:
  failures+=1
  push_error(message)

func _initialize():call_deferred("run")

func run():
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 await create_timer(.1).timeout
 game.initialized=false
 game.set_physics_process(false)
 for actor in game.actors:actor.set_physics_process(false)
 var dog=game.actors[3]
 var skin=dog.model.dog_skin
 for speed in [.55,1.2,2.5,3.0]:
  dog.position=Vector3.ZERO
  dog.rotation=Vector3.ZERO
  skin.motion_phase=0
  skin.foot_locked=[false,false,false,false]
  skin.foot_weights=[0.0,0.0,0.0,0.0]
  var previous=[]
  var previous_planted=[false,false,false,false]
  var samples=0
  var max_drift=0.0
  var max_anchor_error=0.0
  var max_length_error=0.0
  var min_hip_height=1.0
  for frame in range(600):
   # Include a sustained turn, not only straight-line movement.
   if frame>=300:dog.rotation.y+=1.5/60
   dog.position+=dog.basis.z*speed/60
   skin.tick(1.0/60,true,speed,"walk")
   min_hip_height=minf(min_hip_height,skin.pose("hips").origin.y)
   var current=[]
   for i in range(4):
    var paw=skin.to_global(skin.contacts[i])
    current.append(paw)
    check(paw.is_finite(),"Non-finite paw position")
    check(paw.y>=.018,"Paw joint penetrates its ground contact plane")
    var planted=skin.foot_weights[i]>.99 and skin.foot_locked[i]
    if frame>60 and planted:
     max_anchor_error=maxf(max_anchor_error,paw.distance_to(skin.foot_anchors[i]))
     if previous_planted[i]:
      samples+=1
      max_drift=maxf(max_drift,paw.distance_to(previous[i]))
    var names=["upper","lower","hock","paw"]
    for j in range(3):
     var a=names[j]+str(i)
     var b=names[j+1]+str(i)
     var expected=skin.rest[a].origin.distance_to(skin.rest[b].origin)
     max_length_error=maxf(max_length_error,absf(skin.pose(a).origin.distance_to(skin.pose(b).origin)-expected))
    previous_planted[i]=planted
   previous=current
  check(samples>=40,"Gait must contain actual sustained planted contacts")
  check(max_drift<.001,"Planted paw slides by more than 1 mm per frame at speed "+str(speed))
  check(max_anchor_error<.002,"Planted paw loses its world contact by more than 2 mm at speed "+str(speed))
  check(max_length_error<.0001,"Leg solver stretches a bone")
  check(min_hip_height>.18,"Contact correction collapses the body towards the ground")
  print("LOCOMOTION_CONTACT speed=",speed," samples=",samples," max_drift=",max_drift," max_anchor_error=",max_anchor_error," max_length_error=",max_length_error," min_hip_height=",min_hip_height)
 # Match the actor's acceleration and heading response during abrupt turns
 # and braking, where fixed world anchors can become unreachable.
 dog.position=Vector3.ZERO
 dog.rotation=Vector3.ZERO
 skin.has_previous_world_position=false
 skin.foot_locked=[false,false,false,false]
 skin.foot_weights=[0.0,0.0,0.0,0.0]
 skin.recovery_remaining=[0.0,0.0,0.0,0.0]
 var recoveries_before=skin.recovery_steps
 var velocity=Vector3(0,0,3)
 var min_turn_hip=1.0
 for frame in range(480):
  var direction=Vector3(0,0,1) if frame<120 else Vector3(0,0,-1) if frame<240 else Vector3(1,0,0)
  var navigating=frame<360
  velocity=velocity.move_toward(direction*3 if navigating else Vector3.ZERO,(10.0 if navigating else 8.0)/60)
  if navigating:dog.rotation.y=lerp_angle(dog.rotation.y,atan2(direction.x,direction.z),7.0/60)
  dog.position+=velocity/60
  skin.tick(1.0/60,navigating,velocity.length(),"walk" if navigating else "idle")
  min_turn_hip=minf(min_turn_hip,skin.pose("hips").origin.y)
  for paw in skin.contacts:
   check(paw.is_finite(),"Non-finite contact during turning/braking")
   check(paw.y>=.014,"Turning/braking drives a paw through the ground")
 check(min_turn_hip>.22,"Abrupt turn collapses the body instead of triggering a recovery step")
 check(skin.recovery_steps>recoveries_before,"Abrupt-turn scenario must exercise lifted recovery steps")
 check(skin.gait_name=="idle","Braking must finish in the idle gait")
 print("LOCOMOTION_TURNS min_hip_height=",min_turn_hip," recovery_steps=",skin.recovery_steps-recoveries_before," final_gait=",skin.gait_name)
 print("LOCOMOTION_CONTACTS_", "PASS" if failures==0 else "FAIL", " failures=",failures)
 game.clean_quit(0 if failures==0 else 1)
