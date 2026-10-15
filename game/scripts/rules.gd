extends RefCounted
class_name DemoRules

const FOODS = {
 "pork":{"name":"Свинина","time":24.0,"color":Color("d28b75"),"type":"meat"},
 "chicken":{"name":"Курица","time":20.0,"color":Color("e6bb88"),"type":"meat"},
 "pepper":{"name":"Перец","time":15.0,"color":Color("d75c3e"),"type":"veg"},
 "zucchini":{"name":"Кабачок","time":18.0,"color":Color("84a34c"),"type":"veg"},
 "mushroom":{"name":"Шампиньоны","time":17.0,"color":Color("d0bd94"),"type":"veg"}
}
const PROFILES = [
 {"name":"Алина","meat":"chicken","marinade":"kefir","veg":"mushroom","likes":["chicken","pork","mushroom","zucchini"],"activity":"GUITAR","delay":20.0},
 {"name":"Круглик","meat":"pork","marinade":"onion","veg":"pepper","likes":["pork","chicken","pepper","zucchini"],"activity":"BALL","delay":65.0},
 {"name":"Крысюк","meat":"chicken","marinade":"onion","veg":"zucchini","likes":["chicken","pork","zucchini","mushroom"],"activity":"BALL","delay":110.0},
 {"name":"Арториас","meat":"pork","marinade":"onion","veg":"pepper","likes":["pork","chicken","pepper","mushroom","zucchini"],"activity":"DOG","delay":155.0,"dog":true}
]
static func piece(food:String) -> Dictionary:
 return {"food":food,"marinade":"","late":false,"sides":[0.0,0.0],"dirty":false}
static func state(p:Dictionary) -> String:
 if maxf(p.sides[0],p.sides[1]) > 1.35: return "burnt"
 if minf(p.sides[0],p.sides[1]) < 0.78: return "raw"
 if maxf(p.sides[0],p.sides[1]) > 1.15: return "over"
 return "ready"
static func cook(p:Dictionary,side:int,dt:float,heat:float) -> void:
 p.sides[side] += dt * heat / float(FOODS[p.food].time)
static func evaluate(p:Dictionary,profile:Dictionary) -> Dictionary:
 var type:String = FOODS[p.food].type
 var status = state(p)
 var exact = p.food == profile[type] and (type == "veg" or (p.marinade == profile.marinade and not p.late))
 if profile.get("dog",false):
  var bad = p.dirty or status in ["raw","burnt"]
  return {"points":2 if bad else (7 if status=="over" else (34 if exact else 14)),"accepted":true,"reaction":"happy","type":type}
 if p.dirty: return {"points":-5,"accepted":false,"reaction":"spit","type":type}
 if status=="raw": return {"points":-7,"accepted":false,"reaction":"gag","type":type}
 if status=="burnt": return {"points":-4,"accepted":false,"reaction":"cough","type":type}
 if p.food not in profile.likes: return {"points":0,"accepted":false,"reaction":"dislike","type":type}
 return {"points":(34 if exact else 17) if status=="ready" else (20 if exact else 10),"accepted":true,"reaction":"happy" if exact else "like","type":type}
