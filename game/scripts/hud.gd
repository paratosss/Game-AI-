extends CanvasLayer
class_name DemoHUD
var root:Control
var help_panel:Panel
var score:Label
var prompt:Label
var prompt_panel:Panel
var notice:Label
var notice_panel:Panel
var tutorial_label:Label
var tutorial_panel:Panel
var cooking_panel:Panel
var cooking_title:Label
var marinade_icon:TextureRect
var food_icons:Array=[]
var food_dots:Array=[]
var bars:Array=[]
var bar_labels:Array=[]
var cards:Array=[]
var game_ref:Node3D
static func style(fill:Color,border:Color=Color("425458"))->StyleBoxFlat:
 var s=StyleBoxFlat.new();s.bg_color=fill;s.border_color=border;s.set_border_width_all(1);s.set_corner_radius_all(10);s.content_margin_left=12;s.content_margin_right=12;return s
func panel(pos:Vector2,size:Vector2,parent:Control=null)->Panel:
 var p=Panel.new();(parent if parent else root).add_child(p);p.position=pos;p.size=size;p.add_theme_stylebox_override("panel",style(Color(.055,.078,.09,.93)));p.mouse_filter=Control.MOUSE_FILTER_IGNORE;return p
func label(parent:Control,text:String,pos:Vector2,size:int=17)->Label:
 var l=Label.new();parent.add_child(l);l.text=text;l.position=pos;l.add_theme_font_size_override("font_size",size);l.add_theme_color_override("font_color",Color("e2e6de"));l.mouse_filter=Control.MOUSE_FILTER_IGNORE;return l
func icon(parent:Control,key:String,pos:Vector2,size:float=32)->TextureRect:
 var n=TextureRect.new();parent.add_child(n);n.texture=load("res://assets/ui/"+key+".svg");n.position=pos;n.size=Vector2.ONE*size;n.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;n.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;n.mouse_filter=Control.MOUSE_FILTER_IGNORE;return n
func build(game:Node3D):
 game_ref=game;root=Control.new();add_child(root);root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var title=panel(Vector2(20,18),Vector2(225,36));label(title,"ШАШЛЫК У ПРУДА",Vector2(14,7),16)
 var sc=panel(Vector2(1130,18),Vector2(130,36));score=label(sc,"Очки  0",Vector2(15,7),16)
 var cross=label(root,"·",Vector2(634,344),25);cross.add_theme_color_override("font_shadow_color",Color.BLACK);cross.add_theme_constant_override("shadow_offset_x",1);cross.add_theme_constant_override("shadow_offset_y",1)
 for i in range(4):
  var a=game.actors[i];var p=panel(Vector2(20,66),Vector2(240,123));var title_label=label(p,a.profile.name,Vector2(12,9),19)
  icon(p,a.profile.meat,Vector2(11,41),34);icon(p,a.profile.marinade,Vector2(70,41),28);icon(p,a.profile.veg,Vector2(153,41),34)
  label(p,"+",Vector2(127,45),18)
  label(p,game.labels[a.profile.marinade],Vector2(11,82),12)
  var dots=[]
  for j in range(6):
   var d=ColorRect.new();p.add_child(d);d.position=Vector2(14+(j%3)*21+(115 if j>=3 else 0),102);d.size=Vector2(14,5);d.color=Color("38484c");dots.append(d)
  p.visible=false;cards.append({"panel":p,"dots":dots,"title":title_label})
 prompt_panel=panel(Vector2(355,638),Vector2(570,48));prompt=label(prompt_panel,"",Vector2(18,11),18)
 notice_panel=panel(Vector2(385,24),Vector2(510,41));notice=label(notice_panel,"",Vector2(14,10),16);notice_panel.visible=false
 tutorial_panel=panel(Vector2(20,613),Vector2(295,73));tutorial_label=label(tutorial_panel,"",Vector2(12,12),16)
 label(root,"F1  Управление   •   M  Звук",Vector2(1035,692),13)
 cooking_panel=panel(Vector2(947,503),Vector2(313,179));cooking_title=label(cooking_panel,"Шампур",Vector2(14,11),17)
 marinade_icon=icon(cooking_panel,"onion",Vector2(263,7),27);marinade_icon.visible=false
 for i in range(6):
  food_icons.append(icon(cooking_panel,"pork",Vector2(14+i*45,40),31))
  var d=ColorRect.new();cooking_panel.add_child(d);d.position=Vector2(20+i*45,77);d.size=Vector2(20,4);food_dots.append(d)
 for i in range(2):
  var l=label(cooking_panel,"",Vector2(14,92+i*37),13);bar_labels.append(l)
  var b=ProgressBar.new();cooking_panel.add_child(b);b.position=Vector2(14,113+i*37);b.size=Vector2(282,6);b.max_value=1.4;b.show_percentage=false;b.add_theme_stylebox_override("background",style(Color("303e41"),Color("303e41")));bars.append(b)
 help_panel=panel(Vector2(380,167),Vector2(520,365));label(help_panel,"Толя на поляне",Vector2(24,18),27)
 label(help_panel,"WASD — ходить     Мышь — смотреть\nSpace — прыжок\n\nE — взять / добавить / мариновать / подать\nE над мангалом — положить на подсветку\nR — перевернуть в руке или на мангале\nQ — отпустить    G — бросить\nЛКМ — махать опахалом рядом с углями\n\nEsc — курсор   Клик — вернуться в игру\nF5 — новая игра    F1 — закрыть помощь\n\nEtirwer — Kistol • CC0",Vector2(24,66),16)
 help_panel.visible=false
func update_game(game:Node3D):
 score.text="Очки  %d"%game.points
 var row=0
 for i in range(4):
  var a=game.actors[i];var card=cards[i];card.panel.visible=a.state=="ORDER"
  if not card.panel.visible:continue
  card.panel.position.y=66+row*132;row+=1
  for j in range(6):card.dots[j].color=Color("81af9d") if j%3<a.course["meat" if j<3 else "veg"] else Color("38484c")
 notice_panel.visible=game.notification_time>0;notice.text=game.log_text
 var target=game.ray_target;var text=""
 if game.placement_aimed:text="E  Положить на мангал" if game.candidate>=0 else "Место занято — наведи на соседнюю выемку"
 elif target is DemoProp:
  text="E  "+target.title+" — взять" if not game.held else "Q  Отпустить    G  Бросить"
  if target.kind=="skewer" and target.placed_slot>=0 and not game.held:text+="     R  Перевернуть"
 elif target is DemoActor:
  text="E  Подать — "+target.profile.name if game.held and game.held.kind=="skewer" else target.profile.name
 elif target and target.has_meta("title"):
  text="E  "+target.get_meta("title") if game.held and game.held.kind=="skewer" else target.get_meta("title")+" — нужен шампур"
 elif game.held:
  text="ЛКМ  Махать опахалом" if game.held.kind=="fan" else "Q  Отпустить    G  Бросить"+("    R  Перевернуть" if game.held.kind=="skewer" else "")
 prompt.text=text;prompt_panel.visible=not text.is_empty()
 tutorial_panel.visible=game.tutorial<3 and not help_panel.visible
 tutorial_label.text=["Начнём шашлык\nВозьми шампур со стола — E","Насади кусочки — E по продуктам\nМаринад — по желанию","Подойди к мангалу\nНаведи на выемку и нажми E"][mini(game.tutorial,2)]
 var sk=game.held if game.held and game.held.kind=="skewer" else target if target is DemoProp and target.kind=="skewer" else null
 cooking_panel.visible=sk!=null and sk.pieces.size()>0 and not help_panel.visible
 if not cooking_panel.visible:return
 var pieces=sk.pieces
 var marinade=""
 for p in pieces:
  if not p.marinade.is_empty():marinade=p.marinade;break
 marinade_icon.visible=not marinade.is_empty()
 if marinade_icon.visible:marinade_icon.texture=load("res://assets/ui/"+marinade+".svg")
 cooking_title.text="Шампур"+("  •  на мангале" if sk.placed_slot>=0 else "")
 for i in range(6):
  food_icons[i].visible=i<pieces.size();food_dots[i].visible=i<pieces.size()
  if i<pieces.size():
   food_icons[i].texture=load("res://assets/ui/"+pieces[i].food+".svg")
   food_dots[i].color=Color("8bb49a") if DemoRules.state(pieces[i])=="ready" and not pieces[i].dirty else Color("b76d52") if DemoRules.state(pieces[i]) in ["over","burnt"] or pieces[i].dirty else Color("a5afa8")
 for side in range(2):
  var total=0.0;var least=99.0;var most=0.0
  for p in pieces:total+=p.sides[side];least=minf(least,p.sides[side]);most=maxf(most,p.sides[side])
  bars[side].value=total/pieces.size()
  var word="Сырая" if least<.78 else "Готова";var col=Color("7a9bb0") if least<.78 else Color("83af99")
  if most>1.15:word="Подгорает";col=Color("be7751")
  if most>1.35:word="Сгорела";col=Color("a7544f")
  if least<.78 and most>.78:word="Неравномерно"
  bars[side].add_theme_stylebox_override("fill",style(col,col));bar_labels[side].text="Сторона %d  •  %s"%[side+1,word]
