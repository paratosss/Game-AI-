extends "res://tests/graphics_benchmark.gd"
## Reuse the controlled scene setup, with a wider view that includes both feet.
func run():
 if not "--overview-only" in OS.get_cmdline_user_args():
  push_error("Contact review requires --overview-only");quit(1);return
 await super.run()
func shot(_label:String,_position:Vector3,_target:Vector3):
 game.camera.fov=45
 await super.shot("seated-contact",Vector3(0,1.45,-.3),Vector3(0,.6,-3.2))
func save_metadata():
 super.save_metadata()
 var path=output.path_join("capture-metadata.json")
 var data=JSON.parse_string(FileAccess.get_file_as_string(path))
 data["contact_review_sha256"]=FileAccess.get_sha256("res://tests/alina_contact_review.gd")
 var file=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(data,"  "))
