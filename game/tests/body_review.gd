extends "res://tests/alina_pose_review.gd"
## Reuse deterministic posing/lighting, with arm cameras instead of face views.
func capture(label:String,position:Vector3,target:Vector3,fov:float):
 metadata.dependencies_sha256["res://tests/body_review.gd"]=FileAccess.get_sha256("res://tests/body_review.gd")
 if label=="face-front":
  target=skin.to_global(skin.global_pose("lowerarm_l").origin).lerp(skin.to_global(skin.global_pose("hand_l").origin),.35)
  position=target+Vector3(.5,.10,.55);label="left-elbow";fov=34
 elif label=="face-turned":
  target=skin.to_global(skin.global_pose("hand_r").origin)
  position=target+Vector3(-.35,.08,.48);label="right-wrist";fov=34
 await super.capture(label,position,target,fov)
