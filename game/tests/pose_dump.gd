extends SceneTree
func _initialize():call_deferred('run')
func run():
 var game=load('res://main.tscn').instantiate();root.add_child(game)
 await create_timer(.1).timeout;game.initialized=false
 for a in game.actors:a.set_physics_process(false)
 var a=game.actors[0];var s=a.model.skin
 for i in range(120):s.tick(1./60,false,0,'guitar',a.guitar,Vector3.ZERO)
 for f in ['index','middle','ring','pinky','thumb']:
  for j in ['01','02','03','04_leaf']:
   var n=f+'_'+j+'_l'
   print(n,' ',a.guitar.to_local(s.to_global(s.global_pose(n).origin)))
 game.clean_quit()
