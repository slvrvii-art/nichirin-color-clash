class_name EmberpanCardGame
extends Control

signal screen_changed(screen_name: String)
signal battle_finished(victory: bool)
const DB := preload("res://scripts/card_database.gd")
const FACE := preload("res://scripts/card_face.gd")
const LAYOUT := preload("res://scripts/battle_layout.gd")
const ATOMIC := preload("res://scripts/atomic_json_file.gd")
const LICENSES := preload("res://scripts/manus/open_source_licenses.gd")
const ATTACK_SLASH_FRAMES := preload("res://assets/interface/attack_slash_frames.tres")
const COIN_UI := preload("res://scripts/coin_flip_animation.gd")
const BODY := preload("res://assets/template/fonts/ui_regular.tres")
const MEDIUM := preload("res://assets/template/fonts/ui_medium.tres")
const DISPLAY := preload("res://assets/template/fonts/display/card_title.tres")
const INK := Color("#0a111d")
const PANEL := Color("#121d2c")
const CREAM := Color("#f4ebd9")
const GOLD := Color("#c8ac72")
const MUTED := Color("#8e9aae")
const RED := Color("#cf5145")
const SAVE_PATH := "user://nichirin_collection_v1.json"

var screen_name := "home"
var root_ui: Control
var modal: Control
var catalog: Array[Dictionary] = []
var cards_by_id := {}
var deck: Array = []
var art_choices := {}
var discovered: Array = []
var full_art := true
var reduced_motion := false
var wins := 0
var matches := 0
var page := 0
var search_text := ""
var filter_color := "All colors"
var filter_rarity := "All rarities"
var filter_kind := "All cards"
var notice := ""
var sides: Array[Dictionary] = []
var current_side := 0
var turn_number := 1
var busy := false
var battle_over := false
var battle_started := false
var opening_active_pending := false
var opening_banner_complete := false
var pending_replacement_side := -1
var pending_begin_turn := -1
var pending_turn_advance := -1
var paused := false
var generation := 0
var selected_hand := -1
var selected_board := -1
var ability_targeting := false
var ability_source := -2
var pending_utility_choice: Dictionary = {}
var battle_log: Array[String] = []
var board_nodes := {}
var rng := RandomNumberGenerator.new()
var battle_layout := LAYOUT.new()
var attack_animations := 0
var attack_gif_animations := 0
var damage_animations := 0
var turn_animations := 0
var coin_flip_overrides: Array = []
var coin_overlay: CanvasLayer
var show_coin_flip_animations := true
var coin_flip_events := 0
var coin_flip_animations := 0
var coin_animation_queue: Array = []
var coin_animation_running := false
var attack_targeting := -1
var retreat_targeting := false
# Tests may force who goes first; -1 means a random coin flip.
var first_side_override := -1
var pending_boost_flash := ""
var boost_animations := 0

func _ready() -> void:
	TranslationServer.set_locale("en")
	rng.randomize()
	coin_overlay = COIN_UI.new()
	coin_overlay.layer = 40
	add_child(coin_overlay)
	catalog = DB.catalog()
	for card in catalog: cards_by_id[card.id] = card
	_load_save()
	_render()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if is_instance_valid(modal):
			if not pending_utility_choice.is_empty(): return
			_close_modal()
		elif screen_name == "battle" and not battle_over:
			_pause_menu()
		else:
			_go("home")

func _load_save() -> void:
	var saved := ATOMIC.load_dictionary(SAVE_PATH)
	var saved_deck: Array = saved.get("deck",DB.starter_deck())
	var cleaned: Array = []
	for id in saved_deck:
		var migrated_id: String = DB.migrate_card_id(str(id))
		if cards_by_id.has(migrated_id) and cleaned.size() < 20 and cleaned.count(migrated_id) < 2:
			cleaned.append(migrated_id)
	deck = cleaned
	if deck.size() < 20:
		for fallback_id in DB.starter_deck():
			if deck.size() >= 20: break
			if deck.count(str(fallback_id)) < 2: deck.append(str(fallback_id))
	if deck.size() != 20: deck = DB.starter_deck()
	art_choices = saved.get("art_choices",{})
	discovered = saved.get("discovered",deck.duplicate())
	full_art = bool(saved.get("full_art",true))
	reduced_motion = bool(saved.get("reduced_motion",false))
	wins = int(saved.get("wins",0))
	matches = int(saved.get("matches",0))

func _save() -> void:
	ATOMIC.save_dictionary(SAVE_PATH,{"deck":deck,"art_choices":art_choices,"discovered":discovered,"full_art":full_art,"reduced_motion":reduced_motion,"wins":wins,"matches":matches})

func _go(screen: String) -> void:
	if screen_name == "battle" and screen != "battle":
		generation += 1
		busy = false
		battle_over = true
		battle_started = false
		opening_active_pending = false
		pending_replacement_side = -1
		pending_begin_turn = -1
		pending_turn_advance = -1
	paused = false
	pending_utility_choice.clear()
	_close_modal()
	screen_name = screen
	page = 0
	notice = ""
	selected_hand = -1
	selected_board = -1
	_render()
	screen_changed.emit(screen)

func _render() -> void:
	if is_instance_valid(root_ui):
		remove_child(root_ui)
		root_ui.queue_free()
	root_ui = Control.new()
	root_ui.size = Vector2(1440,900)
	add_child(root_ui)
	board_nodes.clear()
	var bg := ColorRect.new()
	bg.color = INK
	bg.size = Vector2(1440,900)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ui.add_child(bg)
	if screen_name == "battle":
		_image(root_ui,"res://assets/interface/board.png",Rect2(120,102,1320,798),Color(1,1,1,0.55))
	_nav()
	match screen_name:
		"home": _home()
		"collection", "deck": _collection()
		"battle": _battle()
	if notice != "":
		_text(root_ui,notice,Rect2(148,868,1250,24),14,GOLD)

func _nav() -> void:
	_panel(root_ui,Rect2(0,0,118,900),Color("#0d1624"),Color("#253144"),0)
	_image(root_ui,"res://assets/share/favicon.png",Rect2(31,30,56,56))
	_text(root_ui,"NICHIRIN",Rect2(13,102,100,28),14,CREAM,DISPLAY,HORIZONTAL_ALIGNMENT_CENTER)
	_text(root_ui,"COLOR CLASH",Rect2(8,129,104,20),9,GOLD,MEDIUM,HORIZONTAL_ALIGNMENT_CENTER)
	var labels := [["home","HUB","01"],["collection","COLLECTION","02"],["deck","DECK BUILDER","03"],["battle","BATTLE","04"]]
	for i in range(labels.size()):
		var entry: Array = labels[i]
		var active: bool = screen_name == entry[0]
		_button(root_ui,entry[2]+"\n"+entry[1],Rect2(9,211+i*100,100,76),func():
			if screen_name == "battle" and not battle_over: _pause_menu()
			elif entry[0] == "battle": _start_battle()
			else: _go(entry[0]),active,11)
	_button(root_ui,"HOW TO PLAY",Rect2(9,748,100,42),_rules,false,10)
	_button(root_ui,"SETTINGS",Rect2(9,798,100,42),_settings,false,10)
	_text(root_ui,"FAN-MADE\nDEMON SLAYER",Rect2(8,855,104,34),8,MUTED,MEDIUM,HORIZONTAL_ALIGNMENT_CENTER)

func _header(title: String, subtitle: String) -> void:
	_text(root_ui,title,Rect2(153,29,920,40),28,CREAM,DISPLAY)
	_text(root_ui,subtitle,Rect2(154,73,1040,25),13,MUTED)
	_text(root_ui,"%d WINS    /    %d MATCHES" % [wins,matches],Rect2(1120,44,280,30),12,GOLD,MEDIUM,HORIZONTAL_ALIGNMENT_RIGHT)
	_panel(root_ui,Rect2(148,109,1255,1),Color("#263244"),Color.TRANSPARENT,0)

func _home() -> void:
	_header("THE SLAYER'S TABLE","Your collection. Your breathing style. Your next duel.")
	_panel(root_ui,Rect2(153,137,1247,374),PANEL,Color("#36404c"),12)
	_image(root_ui,"res://assets/share/og.png",Rect2(650,139,746,368))
	_panel(root_ui,Rect2(154,139,505,368),Color("#101b2a"),Color.TRANSPARENT,10)
	_text(root_ui,"DEMON SLAYER • CARD BATTLES",Rect2(185,172,425,24),11,GOLD,MEDIUM)
	_text(root_ui,"Draw your\nblade.",Rect2(185,218,440,139),49,CREAM,DISPLAY)
	_text(root_ui,"Master Color Energy. Build your 20-card deck.\nBoost your fighters into their SURGE forms.",Rect2(188,363,432,52),16,MUTED)
	_button(root_ui,"ENTER BATTLE   →",Rect2(185,433,227,49),_start_battle,true,14)
	_button(root_ui,"BUILD A DECK",Rect2(426,433,197,49),func(): _go("deck"),false,13)
	_text(root_ui,"FEATURED BLADES",Rect2(154,543,640,29),21,CREAM,DISPLAY)
	_text(root_ui,"SURGE EDITIONS • FULL ART",Rect2(155,578,710,22),10,GOLD)
	for i in range(4):
		var id: String = ["tanjiro_hinokami_surge","rengoku_surge","nezuko_surge","kyogai_surge"][i]
		_card(root_ui,cards_by_id[id],Rect2(155+i*215,615,192,230),func(): _card_detail(id))
	var fighters := 0
	var supports := 0
	var items := 0
	for card in catalog:
		match str(card.kind):
			"Fighter": fighters += 1
			"Support": supports += 1
			"Item": items += 1
	_panel(root_ui,Rect2(1048,545,350,301),PANEL,Color("#2c394b"),10)
	_text(root_ui,"YOUR ARMORY",Rect2(1070,567,310,25),20,CREAM,DISPLAY)
	_text(root_ui,str(catalog.size()),Rect2(1072,607,180,61),49,GOLD,DISPLAY)
	_text(root_ui,"PLAYABLE CARDS",Rect2(1073,671,288,20),11,MUTED)
	_text(root_ui,"%d fighters  /  Normal + SURGE\n%d Support  /  %d Item cards" % [fighters,supports,items],Rect2(1073,708,296,45),14,CREAM)
	_button(root_ui,"EXPLORE COLLECTION   →",Rect2(1071,779,301,44),func(): _go("collection"),false,12)

func _filtered() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for card in catalog:
		if search_text != "" and not (str(card.name)+" "+str(card.form)+" "+str(card.text)).to_lower().contains(search_text.to_lower()): continue
		if filter_color != "All colors" and card.color != filter_color: continue
		if filter_rarity != "All rarities" and card.rarity != filter_rarity: continue
		if filter_kind in ["Support","Item"] and card.kind != filter_kind: continue
		if filter_kind == "Fighter" and card.kind != "Fighter": continue
		if filter_kind == "SURGE" and not card.surge: continue
		result.append(card)
	result.sort_custom(func(a: Dictionary,b: Dictionary):
		return int(a.number)<int(b.number))
	return result

func _collection() -> void:
	var building: bool = screen_name == "deck"
	_header("DECK BUILDER" if building else "CARD COLLECTION","A 20-card limit. Countless ways to draw your blade." if building else "Browse all %d cards. Normal fighters Boost into their full-art SURGE forms." % catalog.size())
	var search := LineEdit.new()
	search.position = Vector2(155,140)
	search.size = Vector2(283,43)
	search.placeholder_text = "Search characters, forms, effects…"
	search.text = search_text
	search.add_theme_font_size_override("font_size",13)
	search.text_submitted.connect(func(value): search_text=value; page=0; _render())
	search.text_changed.connect(func(value): search_text=value)
	root_ui.add_child(search)
	_option(root_ui,["All colors"]+DB.COLORS.keys(),filter_color,Rect2(452,140,174,43),func(value): filter_color=value; page=0; _render())
	_option(root_ui,["All versions / rarities","Normal","SURGE","Common","Uncommon","Rare","Epic","Legendary"],filter_rarity,Rect2(638,140,174,43),func(value): filter_rarity="All rarities" if value=="All versions / rarities" else value; page=0; _render())
	_option(root_ui,["All cards","Fighter","Support","Item","SURGE"],filter_kind,Rect2(824,140,174,43),func(value): filter_kind=value; page=0; _render())
	var filtered := _filtered()
	var columns := 5 if building else 6
	var per_page := columns*2
	var max_page := maxi(0,ceili(float(filtered.size())/per_page)-1)
	page = clampi(page,0,max_page)
	_text(root_ui,"%d CARDS    /    %d IN DECK" % [filtered.size(),deck.size()],Rect2(155,196,700,22),11,MUTED)
	var card_width := 165.0 if building else 190.0
	var stride := 181.0 if building else 207.0
	for j in range(per_page):
		var index := page*per_page+j
		if index >= filtered.size(): break
		var card: Dictionary = filtered[index]
		var rect := Rect2(155+(j%columns)*stride,234+floori(float(j)/columns)*302,card_width,268)
		_card(root_ui,card,rect,func(): _card_detail(str(card.id)))
		if building:
			_button(root_ui,"+ ADD  "+str(deck.count(card.id))+"/2",Rect2(rect.position.x,rect.end.y+5,card_width,24),func(): _add_to_deck(str(card.id)),false,10)
	if filtered.is_empty(): _text(root_ui,"No cards match these filters.",Rect2(180,300,800,80),23,MUTED)
	_button(root_ui,"← PREVIOUS",Rect2(155,838,180,36),func(): page=maxi(0,page-1); _render(),false,11)
	_text(root_ui,"PAGE %d / %d" % [page+1,max_page+1],Rect2(345,843,450,27),11,GOLD,MEDIUM,HORIZONTAL_ALIGNMENT_CENTER)
	_button(root_ui,"NEXT →",Rect2(813 if building else 1209,838,180,36),func(): page=mini(max_page,page+1); _render(),false,11)
	if building: _deck_panel()

func _deck_panel() -> void:
	_panel(root_ui,Rect2(1080,136,322,690),PANEL,Color("#334158"),10)
	_text(root_ui,"YOUR DECK",Rect2(1102,156,272,29),21,CREAM,DISPLAY)
	_text(root_ui,"%d / 20 CARDS" % deck.size(),Rect2(1103,199,273,26),17,GOLD)
	_text(root_ui,"Two copies per catalog card.",Rect2(1104,230,260,22),11,MUTED)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(1100,267)
	scroll.size = Vector2(280,419)
	root_ui.add_child(scroll)
	var list := VBoxContainer.new()
	list.custom_minimum_size.x = 265
	list.add_theme_constant_override("separation",4)
	scroll.add_child(list)
	var counts := {}
	for id in deck: counts[id]=counts.get(id,0)+1
	for id in counts:
		var card: Dictionary = cards_by_id[id]
		var row := Button.new()
		row.text = "%d×  %s\n%s     − REMOVE" % [counts[id],card.name,card.form]
		row.custom_minimum_size = Vector2(264,48)
		row.add_theme_font_size_override("font_size",11)
		row.add_theme_color_override("font_color",DB.color_for(str(card.color)))
		row.pressed.connect(func(): deck.erase(id); _save(); _render())
		list.add_child(row)
	_button(root_ui,"RESTORE STARTER",Rect2(1101,705,278,41),func(): deck=DB.starter_deck(); _save(); _render(),false,11)
	_button(root_ui,"BATTLE WITH THIS DECK →",Rect2(1101,759,278,46),_start_battle,true,12)

func _add_to_deck(id: String) -> void:
	if deck.size() >= 20:
		notice = "20-card limit reached. Remove a card before adding another."
	elif deck.count(id) >= 2:
		notice = "You already have two copies of this card."
	else:
		deck.append(id)
		discovered.append(id) if not discovered.has(id) else null
		notice = "Added "+str(cards_by_id[id].name)+" to your deck."
		_save()
	_render()

# Pass an in-play unit to show its live HP, Energy and status instead of collection actions.
func _card_detail(id: String, in_play: Dictionary = {}) -> void:
	var card: Dictionary = cards_by_id[id] if in_play.is_empty() else in_play
	var box := _modal_box(Rect2(390,115,820,667))
	_card(box,card,Rect2(28,36,305,466),Callable())
	_text(box,card.name,Rect2(362,36,430,55),24,CREAM,DISPLAY)
	var form_line: String = str(card.kind).to_upper()+"  /  "+str(card.rarity).to_upper()
	if card.kind == "Fighter":
		if card.surge: form_line = "SURGE  •  FULL ART  •  "+("BOOST FROM NORMAL" if str(card.boost_from)!="" else "STANDALONE")
		else: form_line = "NORMAL  •  BASIC ART"+("  •  BOOSTS TO SURGE" if str(card.boosts_to)!="" else "")
	_text(box,form_line,Rect2(363,92,430,24),12,GOLD,MEDIUM)
	var color_line: String = "COLOR TYPE: "+str(card.color).to_upper()
	if card.kind == "Fighter": color_line += "   •   %d HP   •   RETREAT %d ENERGY" % [int(card.hp),int(card.get("retreat_cost",1))]
	_text(box,color_line,Rect2(364,120,418,24),12,DB.color_for(str(card.color)))
	var y := 154
	if str(card.get("ability_id",""))!="":
		var passive: bool = str(card.get("ability_kind",""))=="passive"
		_text(box,str(card.ability_name).to_upper()+"  •  "+("PASSIVE" if passive else "ONCE PER TURN"),Rect2(364,y,410,22),13,GOLD,MEDIUM)
		_text(box,str(card.ability_text),Rect2(364,y+24,420,58),13,MUTED,BODY,HORIZONTAL_ALIGNMENT_LEFT,true)
		y += 88
	else:
		_text(box,str(card.text),Rect2(364,y,420,60),14,MUTED,BODY,HORIZONTAL_ALIGNMENT_LEFT,true)
		y += 62
	if card.kind == "Fighter":
		for i in range(card.attacks.size()):
			var a: Dictionary = card.attacks[i]
			_text(box,"%s   %d" % [a.name,int(a.damage)],Rect2(364,y,420,26),17,CREAM)
			var attack_info := _cost_text(str(card.color),a)
			if str(a.get("status",""))!="": attack_info += "  •  INFLICTS "+str(a.status).to_upper()
			_text(box,attack_info,Rect2(364,y+26,420,20),12,GOLD)
			if str(a.get("text",""))!="":
				_text(box,str(a.text),Rect2(364,y+46,420,36),12,MUTED,BODY,HORIZONTAL_ALIGNMENT_LEFT,true)
				y += 84
			else:
				y += 56
	if not in_play.is_empty():
		var energy: Array = in_play.get("energy",[])
		var statuses: Array = in_play.get("statuses",[])
		var live := "IN PLAY   •   %d / %d HP" % [int(in_play.get("current_hp",card.hp)),int(card.hp)]
		live += "\nENERGY: "+(", ".join(energy).to_upper() if not energy.is_empty() else "NONE")
		live += "\nSTATUS: "+(", ".join(statuses).to_upper() if not statuses.is_empty() else "NONE")
		_text(box,live,Rect2(364,520,420,66),12,CREAM,MEDIUM,HORIZONTAL_ALIGNMENT_LEFT,true)
		_button(box,"CLOSE",Rect2(600,592,180,43),_close_modal,true,12)
		return
	if str(card.get("boosts_to",""))!="":
		var surge_id: String = str(card.boosts_to)
		_button(box,"VIEW SURGE FORM  →",Rect2(363,532,219,40),func(): _card_detail(surge_id),false,11)
	elif str(card.get("boost_from",""))!="":
		var normal_id: String = str(card.boost_from)
		_button(box,"←  VIEW NORMAL FORM",Rect2(363,532,219,40),func(): _card_detail(normal_id),false,11)
	_button(box,"+ ADD TO DECK",Rect2(363,592,219,43),func(): _close_modal(); _add_to_deck(id),true,12)
	_button(box,"CLOSE",Rect2(600,592,180,43),_close_modal,false,12)

func _new_side(ids: Array) -> Dictionary:
	var pile: Array = []
	for id in ids: pile.append(_make_unit(str(id)))
	pile.shuffle()
	# Guarantee a playable basic fighter (Normal or standalone SURGE) in the opening hand.
	var first_basic := 0
	while first_basic < pile.size() and not DB.is_basic(pile[first_basic]): first_basic += 1
	if first_basic < pile.size():
		var opening: Dictionary = pile[first_basic]
		pile.remove_at(first_basic)
		pile.push_front(opening)
	var hand: Array = []
	for i in range(mini(5,pile.size())): hand.append(pile.pop_front())
	# Keep the starting Normal/standalone fighter in hand until its owner chooses it.
	var active: Dictionary = {}
	var types: Array = []
	for id in ids:
		var c: Dictionary = cards_by_id[str(id)]
		if c.kind == "Fighter" and not types.has(c.color): types.append(c.color)
	return {"deck":pile,"hand":hand,"active":active,"bench":[],"discard":[],"points":0,"energy_ready":false,"energy_color":"Blue","colors":types,"support_used":false,"retreated":false,"turns_taken":0}

func _start_battle() -> void:
	var error := DB.validate_deck(deck)
	if error != "":
		_go("deck")
		notice = error
		_render()
		return
	generation += 1
	sides = [_new_side(deck),_new_side(DB.enemy_deck())]
	screen_name = "battle"
	current_side = _roll_first_side()
	turn_number = 1
	busy = false
	paused = false
	battle_over = false
	battle_started = false
	opening_active_pending = true
	opening_banner_complete = false
	pending_replacement_side = -1
	pending_begin_turn = -1
	pending_turn_advance = -1
	selected_hand = -1
	selected_board = -1
	ability_targeting = false
	ability_source = -2
	attack_targeting = -1
	retreat_targeting = false
	pending_boost_flash = ""
	battle_log = ["Duel begins. First to 3 knockout points wins.", "Coin flip: "+("you go first." if current_side==0 else "your rival goes first.")+" No Energy can be attached on the first turn."]
	for side_index in range(2):
		sides[side_index].active = {}
	_choose_ai_opening_active()
	notice = "Choose a Normal or standalone SURGE fighter from your starting hand for the Active spot."
	_render()
	_opening_sequence(generation)

func _roll_first_side() -> int:
	if first_side_override >= 0: return first_side_override
	return 0 if _flip_coin() else 1

func _opening_fighter_indices(side_index: int) -> Array:
	var result: Array = []
	if side_index < 0 or side_index >= sides.size(): return result
	for i in range(sides[side_index].hand.size()):
		if DB.is_basic(sides[side_index].hand[i]): result.append(i)
	return result

func _choose_opening_active(side_index: int, hand_index: int) -> bool:
	if not opening_active_pending or side_index < 0 or side_index >= sides.size(): return false
	var side: Dictionary = sides[side_index]
	if not side.active.is_empty() or hand_index < 0 or hand_index >= side.hand.size(): return false
	var fighter: Dictionary = side.hand[hand_index]
	if not DB.is_basic(fighter): return false
	side.hand.remove_at(hand_index)
	fighter["played_turn"] = 0
	side.active = fighter
	if side_index == 0:
		opening_active_pending = false
		selected_hand = -1
		notice = "Active fighter selected."
		_log("You choose %s as your Active Fighter." % fighter.name)
		_render()
		if opening_banner_complete: _complete_opening_setup()
	else:
		_log("Your rival chooses %s as their Active Fighter." % fighter.name)
	return true

func _choose_ai_opening_active() -> bool:
	var options := _opening_fighter_indices(1)
	if options.is_empty(): return false
	var best_index: int = int(options[0])
	for option in options:
		var index: int = int(option)
		if int(sides[1].hand[index].hp) > int(sides[1].hand[best_index].hp): best_index = index
	return _choose_opening_active(1,best_index)

func _opening_sequence(token: int) -> void:
	busy = true
	await _turn_banner("COIN FLIP  •  "+("YOU GO FIRST" if current_side==0 else "RIVAL GOES FIRST"),current_side,1.2)
	if generation != token: return
	opening_banner_complete = true
	busy = false
	_render()
	if not opening_active_pending: _complete_opening_setup()

func _complete_opening_setup() -> void:
	if battle_started or opening_active_pending or not opening_banner_complete: return
	if sides.size() < 2 or sides[0].active.is_empty() or sides[1].active.is_empty(): return
	battle_started = true
	busy = true
	_begin_turn(current_side)
	if battle_over:
		busy = false
		_render()
		return
	busy = false
	_render()
	if current_side == 1: _ai_turn(generation)

func _begin_turn(side_index: int) -> void:
	var side: Dictionary = sides[side_index]
	side.turns_taken = int(side.get("turns_taken",0))+1
	side.energy_ready = true
	side.support_used = false
	side.retreated = false
	side["free_retreat"] = false
	side["retreat_discount"] = 0
	if not side.active.is_empty(): side.active["ability_used"] = false
	for unit in side.bench: unit["ability_used"] = false
	var types: Array = side.colors
	side.energy_color = types[rng.randi_range(0,types.size()-1)] if not types.is_empty() else "White"
	_apply_turn_start_statuses(side_index)
	if battle_over: return
	if pending_replacement_side == side_index:
		pending_begin_turn = side_index
		return
	if side.active.is_empty(): _knockout_check(side_index)
	if battle_over: return
	if pending_replacement_side == side_index:
		pending_begin_turn = side_index
		return
	_complete_turn_start(side_index)

func _complete_turn_start(side_index: int) -> void:
	var side: Dictionary = sides[side_index]
	if battle_over or side.active.is_empty(): return
	if str(side.active.get("ability_id",""))=="kagura_dance":
		side.active.energy.append("Red")
		_log(str(side.active.short)+" uses Kagura Dance: +1 Red Energy.")
	_draw_cards(side_index,1)
	_log("You draw a card." if side_index == 0 else "Opponent draws a card.")

func _flip_coin() -> bool:
	coin_flip_events += 1
	var heads: bool = bool(coin_flip_overrides.pop_front()) if not coin_flip_overrides.is_empty() else rng.randi_range(0,1)==1
	if show_coin_flip_animations:
		coin_animation_queue.append(heads)
		if not coin_animation_running: call_deferred("_drain_coin_animation_queue")
	return heads

func _drain_coin_animation_queue() -> void:
	if coin_animation_running or not show_coin_flip_animations or not is_instance_valid(coin_overlay): return
	coin_animation_running = true
	while not coin_animation_queue.is_empty():
		var heads: bool = bool(coin_animation_queue.pop_front())
		coin_flip_animations += 1
		await coin_overlay.play(heads,reduced_motion)
	coin_animation_running = false

func _apply_turn_start_statuses(side_index: int) -> void:
	var side: Dictionary = sides[side_index]
	if side.active.is_empty(): return
	var active_id: String = str(side.active.id)
	var statuses: Array = side.active.get("statuses",[])
	if statuses.has("Sleep"):
		if _flip_coin():
			statuses.erase("Sleep")
			_log(str(side.active.name)+" flips heads and wakes from Sleep.")
		else:
			_log(str(side.active.name)+" flips tails and remains asleep.")
	if statuses.has("Poison"):
		var bonus: int = _poison_bonus(side_index)
		if bonus > 0: _log("Butterfly Support: Poison deals +%d damage." % bonus)
		_apply_status_tick(side_index,"Poison",10+bonus)
		if side.active.is_empty() or str(side.active.id)!=active_id: return
	if statuses.has("Burn"):
		_apply_status_tick(side_index,"Burn",20)
		if side.active.is_empty() or str(side.active.id)!=active_id: return
		if _flip_coin():
			statuses.erase("Burn")
			_log(str(side.active.name)+" flips heads and recovers from Burn.")
		else:
			_log(str(side.active.name)+" flips tails; Burn continues.")

func _apply_status_tick(side_index: int, status: String, damage: int) -> void:
	var active: Dictionary = sides[side_index].active
	active.current_hp=maxi(0,int(active.current_hp)-damage)
	damage_animations+=1
	_log(str(active.name)+" takes "+str(damage)+" "+status+" damage.")
	if int(active.current_hp)<=0: _knockout_check(side_index)

func _draw_cards(side_index: int, count: int) -> void:
	var side: Dictionary = sides[side_index]
	for i in range(count):
		if side.deck.is_empty():
			_log("No cards left to draw.")
			break
		var drawn: Dictionary = side.deck.pop_front()
		if side.hand.size() >= 10:
			side.discard.append(drawn)
		else:
			side.hand.append(drawn)

func _battle() -> void:
	_header("COLOR CLASH","Choose your opening Active, then duel. One active fighter and three bench spots.")
	var me: Dictionary = sides[0]
	var enemy: Dictionary = sides[1]
	_text(root_ui,"OPPONENT",Rect2(433,117,500,24),11,RED,MEDIUM)
	_text(root_ui,"CHOOSE NEW ACTIVE" if pending_replacement_side==0 else ("YOUR ACTIVE" if not opening_active_pending else "CHOOSE YOUR ACTIVE"),Rect2(433,424,380,24),11,GOLD,MEDIUM)
	_text(root_ui,"BENCH  /  %d OF 3" % enemy.bench.size(),Rect2(661,120,395,25),10,MUTED)
	_text(root_ui,"BENCH  /  %d OF 3" % me.bench.size(),Rect2(661,447,395,25),10,MUTED)
	for side_index in range(2):
		var side: Dictionary = sides[side_index]
		var active_rect: Rect2 = battle_layout.zone(&"player_active" if side_index==0 else &"enemy_active")
		if side.active.is_empty():
			_panel(root_ui,active_rect,Color(0.05,0.07,0.12,0.75),Color("#c8ac72") if side_index==0 else Color("#344056"),8)
			var prompt := "CHOOSE FROM\nYOUR BENCH" if pending_replacement_side==side_index else ("CHOOSE FROM\nYOUR HAND" if side_index==0 and opening_active_pending else "ACTIVE SPOT")
			_text(root_ui,prompt,Rect2(active_rect.position+Vector2(10,55),active_rect.size-Vector2(20,70)),15,GOLD,MEDIUM,HORIZONTAL_ALIGNMENT_CENTER,true)
		else:
			_board_card(side_index,-1,side.active,active_rect)
		for i in range(3):
			var rect: Rect2 = battle_layout.bench(side_index,i)
			if i < side.bench.size():
				_board_card(side_index,i,side.bench[i],rect)
			else:
				_panel(root_ui,rect,Color(0.04,0.07,0.12,0.6),Color("#344056"),8)
				_text(root_ui,"+\nBENCH "+str(i+1),Rect2(rect.position+Vector2(8,55),rect.size-Vector2(16,65)),13,Color("#59677d"),MEDIUM,HORIZONTAL_ALIGNMENT_CENTER)
	_panel(root_ui,Rect2(151,150,223,528),Color(0.035,0.06,0.10,0.88),Color("#28364c"),9)
	_text(root_ui,"DUEL RECORD",Rect2(169,171,187,29),16,CREAM,DISPLAY)
	_text(root_ui,"YOU   %d / 3\nRIVAL %d / 3" % [me.points,enemy.points],Rect2(169,216,190,64),19,GOLD,MEDIUM)
	_text(root_ui,"TURN %02d" % turn_number,Rect2(169,290,190,22),12,MUTED)
	for side_index in range(2):
		var side: Dictionary = sides[side_index]
		_text(root_ui,("YOU" if side_index==0 else "RIVAL")+"  DECK %d • HAND %d • DISCARD %d" % [side.deck.size(),side.hand.size(),side.discard.size()],Rect2(169,314+side_index*17,195,16),9,CREAM if side_index==0 else RED,MEDIUM)
	_panel(root_ui,Rect2(169,355,187,1),Color("#28364c"),Color.TRANSPARENT,0)
	_text(root_ui,"\n\n".join(battle_log.slice(maxi(0,battle_log.size()-5))),Rect2(169,366,187,290),12,MUTED,BODY,HORIZONTAL_ALIGNMENT_LEFT,true)
	for i in range(mini(5,enemy.hand.size())):
		_image(root_ui,"res://assets/interface/card_back.png",Rect2(924+i*20,110,27,40))
	var hand_title := "YOUR STARTING HAND  /  choose a fighter for Active" if opening_active_pending else ("STARTING CHOICE COMPLETE" if not battle_started else "YOUR HAND  /  click a card to play")
	_text(root_ui,hand_title,Rect2(154,711,900,24),11,GOLD)
	var hand: Array = me.hand
	var width := minf(110,925.0/maxi(1,hand.size())-7)
	for i in range(hand.size()):
		var rect := Rect2(155+i*(width+7),742,width,128)
		var node := _card(root_ui,hand[i],rect,func(): _hand_clicked(i),true)
		if selected_hand==i: node.modulate=Color(1.15,1.12,0.9)
	_battle_actions()
	if battle_over: _result_modal()

func _hand_clicked(index: int) -> void:
	if opening_active_pending:
		if index < 0 or index >= sides[0].hand.size(): return
		selected_hand = index
		selected_board = -1
		_render()
		return
	if _can_act(0):
		selected_hand = index
		selected_board = -1
		attack_targeting = -1
		ability_targeting = false
		retreat_targeting = false
		_render()

func _board_card(side_index: int, index: int, unit: Dictionary, rect: Rect2) -> void:
	if unit.is_empty(): return
	var node := _card(root_ui,unit,rect,func(): _board_clicked(side_index,index),true)
	var key: String = str(side_index)+"_"+str(index)
	board_nodes[key] = node
	if side_index==0 and selected_hand==-1 and selected_board==index and not _targeting(): node.modulate=Color(1.08,1.06,0.91)
	if _is_target_option(side_index,index): node.modulate=Color(1.28,1.12,0.72)
	elif _targeting() and side_index==1: node.modulate=Color(0.62,0.62,0.68)
	if key == pending_boost_flash:
		pending_boost_flash = ""
		node.modulate = Color(2.0,1.7,0.9)
		var flash := create_tween()
		flash.tween_property(node,"modulate",Color.WHITE,0.18 if reduced_motion else 0.7)
	var status_text := _status_summary(unit)
	if status_text!="":
		var status_color: Color = Color("#f1b36c") if status_text.contains("BURN") else (Color("#a6d7b5") if status_text.contains("POISON") else Color("#c0b2ec"))
		_panel(root_ui,Rect2(rect.position.x+5,rect.position.y+49,rect.size.x-10,19),Color("#172235"),Color("#526177"),4)
		_text(root_ui,status_text,Rect2(rect.position.x+7,rect.position.y+50,rect.size.x-14,17),8,status_color,MEDIUM,HORIZONTAL_ALIGNMENT_CENTER)
	var energy: Array = unit.get("energy",[])
	var hp_text: String = "%d / %d HP" % [int(unit.get("current_hp",unit.hp)),unit.hp]
	_text(root_ui,hp_text,Rect2(rect.position.x,rect.end.y+4,rect.size.x,20),11,RED if unit.current_hp < unit.hp*0.4 else CREAM,MEDIUM,HORIZONTAL_ALIGNMENT_CENTER)
	for j in range(mini(7,energy.size())):
		_panel(root_ui,Rect2(rect.position.x+6+j*16,rect.end.y+27,11,11),DB.color_for(str(energy[j])),Color.TRANSPARENT,5)

func _status_summary(unit: Dictionary) -> String:
	var result := ""
	for status in unit.get("statuses",[]):
		if result!="": result += " • "
		result += str(status).to_upper()
	return result

func _status_color(status: String) -> Color:
	match status:
		"Sleep": return Color("#b9a7e7")
		"Poison": return Color("#93d99c")
		"Burn": return Color("#ff9168")
		"Paralysis": return Color("#f6dc77")
	return CREAM

func _battle_actions() -> void:
	_panel(root_ui,Rect2(1110,139,290,710),PANEL,Color("#35415a"),10)
	var me: Dictionary = sides[0]
	if selected_board >= me.bench.size(): selected_board = -1
	if opening_active_pending:
		_text(root_ui,"SET YOUR ACTIVE",Rect2(1131,157,248,30),19,GOLD,DISPLAY)
		_text(root_ui,"Choose one Normal or standalone SURGE fighter from your starting hand. Your rival has already chosen.",Rect2(1132,212,246,82),13,CREAM,BODY,HORIZONTAL_ALIGNMENT_LEFT,true)
		if selected_hand >= 0 and selected_hand < me.hand.size():
			var candidate: Dictionary = me.hand[selected_hand]
			var eligible: bool = DB.is_basic(candidate)
			_text(root_ui,str(candidate.name),Rect2(1131,320,246,50),17,CREAM,DISPLAY)
			_text(root_ui,"NORMAL / STANDALONE SURGE" if eligible else "BOOST-ONLY SURGE CANNOT START",Rect2(1132,376,246,34),11,GOLD if eligible else RED,MEDIUM,HORIZONTAL_ALIGNMENT_LEFT,true)
			_button(root_ui,"SET AS ACTIVE",Rect2(1132,438,245,48),func(): _choose_opening_active(0,selected_hand),eligible,13)
		else:
			_text(root_ui,"Click a fighter card in your starting hand to choose it.",Rect2(1132,346,246,61),13,MUTED,BODY,HORIZONTAL_ALIGNMENT_LEFT,true)
		return
	if pending_replacement_side == 0:
		_text(root_ui,"CHOOSE NEXT ACTIVE",Rect2(1131,157,248,30),18,GOLD,DISPLAY)
		_text(root_ui,"Your Active Fighter was Knocked Out. Choose a fighter from your Bench to continue the duel.",Rect2(1132,212,246,94),13,CREAM,BODY,HORIZONTAL_ALIGNMENT_LEFT,true)
		_text(root_ui,"Click one of the highlighted cards in your Bench.",Rect2(1132,332,246,58),12,MUTED,BODY,HORIZONTAL_ALIGNMENT_LEFT,true)
		return
	if not battle_started:
		_text(root_ui,"DUEL SETUP",Rect2(1131,157,248,30),19,GOLD,DISPLAY)
		_text(root_ui,"The starting coin is resolving. Your first turn begins after the opening choice.",Rect2(1132,212,246,90),13,CREAM,BODY,HORIZONTAL_ALIGNMENT_LEFT,true)
		return
	_text(root_ui,"YOUR TURN" if current_side==0 else "RIVAL'S TURN",Rect2(1131,157,248,30),20,GOLD if current_side==0 else RED,DISPLAY)
	_text(root_ui,"Resolving…" if busy else "Attacking ends your turn.",Rect2(1132,195,250,24),12,MUTED)
	if retreat_targeting and not me.active.is_empty():
		_text(root_ui,"Retreat",Rect2(1131,245,246,58),20,CREAM,DISPLAY)
		_text(root_ui,"Pay %d Energy from %s, then choose a bench fighter to switch into the active spot." % [_side_retreat_cost(0),me.active.short],Rect2(1132,310,245,80),14,CREAM,BODY,HORIZONTAL_ALIGNMENT_LEFT,true)
		_button(root_ui,"CANCEL",Rect2(1132,404,245,40),func(): retreat_targeting=false; _render(),false,11)
	elif attack_targeting >= 0 and not me.active.is_empty():
		var a: Dictionary = me.active.attacks[attack_targeting]
		_text(root_ui,str(a.name),Rect2(1131,245,246,58),20,CREAM,DISPLAY)
		_text(root_ui,"Choose any one of your opponent's fighters (active or bench) to take %d damage." % int(a.damage),Rect2(1132,310,245,80),14,CREAM,BODY,HORIZONTAL_ALIGNMENT_LEFT,true)
		_button(root_ui,"CANCEL",Rect2(1132,404,245,40),func(): attack_targeting=-1; _render(),false,11)
	elif selected_hand>=0 and selected_hand<me.hand.size():
		var card: Dictionary = me.hand[selected_hand]
		_text(root_ui,card.name,Rect2(1131,245,246,58),20,CREAM,DISPLAY)
		_text(root_ui,card.form if card.kind!="Fighter" else ("SURGE" if card.surge else "NORMAL")+"  •  %d HP" % int(card.hp),Rect2(1132,304,245,25),13,GOLD)
		_text(root_ui,str(card.text),Rect2(1132,336,244,110),13,MUTED,BODY,HORIZONTAL_ALIGNMENT_LEFT,true)
		if card.kind=="Fighter" and not DB.is_basic(card):
			var targets: Array = _boost_targets(0,selected_hand)
			if targets.is_empty():
				_text(root_ui,"No matching Normal card in play to Boost.",Rect2(1132,474,245,40),12,RED,MEDIUM,HORIZONTAL_ALIGNMENT_LEFT,true)
			for j in range(targets.size()):
				var target_index: int = targets[j]
				var ready: bool = _boost_ready(0,target_index)
				var wait_text := "SECOND TURN REQUIRED" if int(me.get("turns_taken",0))<2 else "NEXT TURN"
				var boost_button := _button(root_ui,"BOOST "+("ACTIVE" if target_index<0 else "BENCH "+str(target_index+1))+(("" if ready else "  •  "+wait_text)),Rect2(1132,462+j*48,245,42),func(): _player_boost(target_index),ready,11 if ready else 9)
				boost_button.disabled = not _can_act(0) or not ready
			if not targets.is_empty() and not _boost_ready(0,int(targets[0])) and targets.size()==1:
				_text(root_ui,"Paired SURGE forms unlock on your second turn and cannot Boost on the Normal's play turn.",Rect2(1132,512,245,45),10,MUTED,BODY,HORIZONTAL_ALIGNMENT_LEFT,true)
		else:
			var play_label := "PLACE ON BENCH" if card.kind=="Fighter" else ("USE ITEM" if card.kind=="Item" else "USE SUPPORT")
			var play := _button(root_ui,play_label,Rect2(1132,474,245,49),func(): _player_play(),true,12)
			play.disabled = not _can_act(0) or (card.kind=="Support" and me.support_used) or (card.kind=="Fighter" and me.bench.size()>=3) or not _utility_can_play(0,selected_hand)
		_button(root_ui,"← ACTIVE FIGHTER",Rect2(1132,664,245,38),func(): selected_hand=-1; selected_board=-1; _render(),false,11)
	elif not me.active.is_empty():
		var unit: Dictionary = me.active if selected_board<0 else me.bench[selected_board]
		_text(root_ui,unit.name,Rect2(1131,245,246,58),19,CREAM,DISPLAY)
		_text(root_ui,("ACTIVE" if selected_board<0 else "BENCH "+str(selected_board+1))+"  •  "+("SURGE" if unit.surge else "NORMAL"),Rect2(1132,309,244,24),11,MUTED)
		var status_text := _status_summary(unit)
		_text(root_ui,"STATUS: "+(status_text if status_text!="" else "NONE"),Rect2(1132,333,245,18),9,_status_color(str(unit.statuses[0])) if not unit.get("statuses",[]).is_empty() else MUTED,MEDIUM)
		_text(root_ui,"COLOR ENERGY",Rect2(1131,354,248,24),11,GOLD)
		var attach := _button(root_ui,"ATTACH "+str(me.energy_color).to_upper()+"  +",Rect2(1131,388,246,45),func():
			if _attach_energy(0,selected_board): _render(),false,12)
		attach.add_theme_color_override("font_color",DB.color_for(str(me.energy_color)))
		attach.disabled = not _can_act(0) or not me.energy_ready or ability_targeting or turn_number == 1
		_text(root_ui,"No Energy on the first turn" if turn_number == 1 else "Once per turn • "+("available" if me.energy_ready else "attached"),Rect2(1132,440,245,23),11,MUTED)
		var action_y := 493
		if str(unit.get("ability_id","")) != "":
			action_y = 558
			var passive: bool = str(unit.get("ability_kind",""))=="passive"
			_text(root_ui,str(unit.ability_name).to_upper()+"  •  "+("PASSIVE" if passive else "ONCE PER TURN"),Rect2(1132,470,246,18),10,GOLD,MEDIUM)
			if passive:
				_text(root_ui,str(unit.ability_text),Rect2(1132,490,246,64),10,MUTED,BODY,HORIZONTAL_ALIGNMENT_LEFT,true)
			elif ability_targeting:
				_text(root_ui,"Choose a damaged benched fighter on your opponent's side.",Rect2(1132,490,246,33),11,CREAM,BODY,HORIZONTAL_ALIGNMENT_LEFT,true)
				_button(root_ui,"CANCEL TARGET",Rect2(1132,524,245,30),func(): _cancel_ability_targeting(),false,10)
			else:
				var options: Array = _ability_target_options(0,selected_board)
				var ability_button := _button(root_ui,"ACTIVATE ABILITY",Rect2(1132,491,245,43),func(): _begin_ability_targeting(0,selected_board),true,11)
				ability_button.disabled = not _can_act(0) or not _ability_ready(0,selected_board) or options.is_empty()
				var ability_status := "USED THIS TURN" if bool(unit.get("ability_used",false)) else ("Choose a target" if not options.is_empty() else "No damaged benched target")
				_text(root_ui,ability_status,Rect2(1132,537,245,17),10,MUTED)
		if selected_board<0:
			for i in range(unit.attacks.size()):
				var a: Dictionary = unit.attacks[i]
				var status_tag: String = ("  •  "+str(a.status).to_upper()) if str(a.get("status",""))!="" else ""
				var attack_button := _button(root_ui,"%s   %d\n%s%s" % [a.name,a.damage,_cost_text(str(unit.color),a),status_tag],Rect2(1131,action_y+i*58,246,52),func(): _player_attack(i),_attack_legal(0,i),9)
				attack_button.disabled=not _can_act(0) or not _attack_legal(0,i) or ability_targeting
			var retreat_y: int = action_y+unit.attacks.size()*58+4
			var cost: int = _side_retreat_cost(0)
			var retreat := _button(root_ui,"RETREAT   •   COST %d ENERGY" % cost+("   (USED)" if me.retreated else ""),Rect2(1131,retreat_y,246,40),func(): retreat_targeting=true; _render(),false,10)
			retreat.disabled=not _can_act(0) or not _can_retreat(0) or ability_targeting
		else:
			_text(root_ui,"Benched fighters enter the active spot when your active fighter retreats (Normal: 1 Energy, SURGE: 2 Energy, once per turn).",Rect2(1132,action_y+8,245,70),11,MUTED,BODY,HORIZONTAL_ALIGNMENT_LEFT,true)
	var end := _button(root_ui,"END TURN   →",Rect2(1130,734,247,49),func(): _end_turn_requested(),true,14)
	end.disabled=not _can_act(0)
	_button(root_ui,"PAUSE / LEAVE",Rect2(1130,798,247,33),_pause_menu,false,10)

func _can_act(side: int) -> bool:
	return screen_name=="battle" and battle_started and not opening_active_pending and pending_replacement_side<0 and current_side==side and not busy and not battle_over and not paused

func _ability_ready(side_index: int, unit_index: int) -> bool:
	if side_index<0 or side_index>=sides.size(): return false
	var side: Dictionary = sides[side_index]
	if unit_index < -1 or unit_index >= side.bench.size(): return false
	var unit: Dictionary = side.active if unit_index<0 else side.bench[unit_index]
	if unit.is_empty(): return false
	return str(unit.get("ability_id",""))!="" and str(unit.get("ability_kind",""))=="active" and not bool(unit.get("ability_used",false))

func _begin_ability_targeting(side_index: int, source_index: int) -> void:
	if not _can_act(side_index) or not _ability_ready(side_index,source_index): return
	if _ability_target_options(side_index,source_index).is_empty(): return
	ability_targeting = true
	ability_source = source_index
	_render()

func _cancel_ability_targeting() -> void:
	ability_targeting = false
	ability_source = -2
	_render()

func _choose_ability_target(target_index: int) -> bool:
	if not ability_targeting: return false
	if not _activate_ability(0,ability_source,target_index): return false
	ability_targeting = false
	ability_source = -2
	selected_hand = -1
	_render()
	return true

func _activate_ability(side_index: int, source_index: int, target_index: int) -> bool:
	if not _can_act(side_index) or not _ability_ready(side_index,source_index): return false
	if not _ability_target_options(side_index,source_index).has(target_index): return false
	var side: Dictionary = sides[side_index]
	var source: Dictionary = side.active if source_index<0 else side.bench[source_index]
	match str(source.get("ability_id","")):
		"rapid_drumming":
			var opponent: Dictionary = sides[1-side_index]
			var pulled: Dictionary = opponent.bench[target_index]
			var previous: Dictionary = opponent.active
			if previous.is_empty():
				opponent.bench.remove_at(target_index)
			else:
				_clear_statuses(previous)
				opponent.bench[target_index] = previous
			opponent.active = pulled
			source["ability_used"] = true
			_log("%s uses Rapid Drumming: %s is forced into the active spot." % [source.short,pulled.name])
			return true
	return false

func _attach_energy(side_index: int, target: int) -> bool:
	if not _can_act(side_index): return false
	var side: Dictionary = sides[side_index]
	if not side.energy_ready: return false
	# The player who goes first cannot attach Energy on the duel's first turn.
	if turn_number == 1: return false
	if target>=side.bench.size(): return false
	var unit: Dictionary = side.active if target<0 else side.bench[target]
	unit.energy.append(side.energy_color)
	side.energy_ready=false
	_log("%s receives %s Color Energy." % [unit.name,side.energy_color])
	return true

func _play_card(side_index: int, index: int) -> bool:
	if not _can_act(side_index): return false
	var side: Dictionary = sides[side_index]
	if index<0 or index>=side.hand.size(): return false
	var card: Dictionary = side.hand[index]
	if card.kind=="Fighter":
		# SURGE cards with a Normal counterpart can only enter play by Boosting.
		if not DB.is_basic(card): return false
		if side.bench.size()>=3: return false
		side.hand.remove_at(index)
		card["played_turn"] = turn_number
		side.bench.append(card)
		_log(str(card.name)+" joins the bench.")
	else:
		if card.kind=="Support" and side.support_used: return false
		if card.kind not in ["Support","Item"]: return false
		if not _utility_can_play(side_index,index): return false
		if card.kind=="Support": side.support_used=true
		side.hand.remove_at(index)
		side.discard.append(card)
		_apply_utility_effect(side_index,card)
		_log(str(card.name)+(" used as an Item." if card.kind=="Item" else " supports the team."))
	return true

func _apply_utility_effect(side_index: int, card: Dictionary) -> void:
	var side: Dictionary = sides[side_index]
	var amount: int = int(card.value)
	match str(card.effect):
		"heal": side.active.current_hp=mini(side.active.hp,side.active.current_hp+amount)
		"heal_all":
			side.active.current_hp=mini(side.active.hp,side.active.current_hp+amount)
			for unit in side.bench: unit.current_hp=mini(unit.hp,unit.current_hp+amount)
		"cleanse_heal":
			side.active.current_hp=mini(side.active.hp,side.active.current_hp+amount)
			_clear_statuses(side.active)
		"team_heal_cleanse":
			side.active.current_hp=mini(side.active.hp,side.active.current_hp+amount)
			_clear_statuses(side.active)
			for unit in side.bench:
				unit.current_hp=mini(unit.hp,unit.current_hp+amount)
				_clear_statuses(unit)
		"remove_status": _clear_statuses(side.active)
		"draw": _draw_cards(side_index,amount)
		"coin_energy":
			if _flip_coin():
				var color: String = str(side.get("energy_color","White"))
				side.active.energy.append(color)
				_log("Heads! %s generates and attaches 1 %s Color Energy from the Energy Zone." % [side.active.short,color])
			else:
				_log("Tails! Recovery Breathing generates no Energy.")
		"blue_energy_loop": _resolve_blue_energy_loop_effect(side_index)
		"random_basic": _take_random_basic_fighter(side_index)
		"peek_shuffle": _resolve_peek_shuffle(side_index)
		"hand_swap": _resolve_hand_swap_effect(side_index)
		"shuffle_draw":
			var foe: Dictionary = sides[1-side_index]
			foe.deck.append_array(foe.hand)
			foe.hand.clear()
			_shuffle_array(foe.deck)
			_draw_cards(1-side_index,amount)
			_log("Sunlight Charm: the opponent shuffles their hand into their deck and draws %d cards." % amount)
		"boost": side.active.boost+=amount
		"shield": side.active.shield=maxi(side.active.shield,amount)
		"bench_heal":
			for unit in side.bench: unit.current_hp=mini(unit.hp,unit.current_hp+amount)
		"draw_until": _draw_cards(side_index,maxi(0,amount-side.hand.size()))
		"cleanse_draw":
			_clear_statuses(side.active)
			_draw_cards(side_index,amount)
		"boost_shield":
			side.active.boost+=amount
			side.active.shield=maxi(side.active.shield,amount)
		"foe_switch":
			_resolve_corps_intelligence(side_index)
		"retreat_free": side["free_retreat"] = true
		"retreat_discount": side["retreat_discount"] = int(side.get("retreat_discount",0))+amount

func _utility_can_play(side_index: int, hand_index: int) -> bool:
	if side_index<0 or side_index>=sides.size(): return false
	var side: Dictionary = sides[side_index]
	if hand_index<0 or hand_index>=side.hand.size(): return false
	var effect: String = str(side.hand[hand_index].get("effect",""))
	match effect:
		"blue_energy_loop": return not _blue_fighter_options(side_index).is_empty()
		"foe_switch": return not sides[1-side_index].bench.is_empty()
		"random_basic": return not _basic_fighter_deck_indices(side_index).is_empty()
		"hand_swap": return not _hand_fighter_indices(side_index,hand_index).is_empty() and not _deck_fighter_indices(side_index).is_empty()
	return true

func _hand_fighter_indices(side_index: int, excluded_index: int = -1) -> Array:
	var result: Array = []
	if side_index<0 or side_index>=sides.size(): return result
	var hand: Array = sides[side_index].hand
	for i in range(hand.size()):
		if i!=excluded_index and str(hand[i].get("kind",""))=="Fighter": result.append(i)
	return result

func _deck_fighter_indices(side_index: int) -> Array:
	var result: Array = []
	if side_index<0 or side_index>=sides.size(): return result
	var side: Dictionary = sides[side_index]
	for i in range(side.deck.size()):
		if str(side.deck[i].get("kind",""))=="Fighter": result.append(i)
	return result

func _basic_fighter_deck_indices(side_index: int) -> Array:
	var result: Array = []
	if side_index<0 or side_index>=sides.size(): return result
	var side: Dictionary = sides[side_index]
	for i in range(side.deck.size()):
		if DB.is_basic(side.deck[i]): result.append(i)
	return result

func _blue_fighter_options(side_index: int) -> Array:
	var result: Array = []
	if side_index<0 or side_index>=sides.size(): return result
	var side: Dictionary = sides[side_index]
	if not side.active.is_empty() and str(side.active.get("color",""))=="Blue":
		result.append({"label":"ACTIVE  •  "+str(side.active.name),"target":-1})
	for i in range(side.bench.size()):
		if str(side.bench[i].get("color",""))=="Blue":
			result.append({"label":"BENCH "+str(i+1)+"  •  "+str(side.bench[i].name),"target":i})
	return result

func _open_utility_choice(effect: String, side_index: int, title: String, description: String, options: Array, extra: Dictionary = {}) -> void:
	if options.is_empty(): return
	pending_utility_choice={"effect":effect,"side":side_index}
	for key in extra: pending_utility_choice[key]=extra[key]
	var box_height: float = minf(785.0,235.0+49.0*options.size())
	var box_y: float = (900.0-box_height)*0.5
	var box := _modal_box(Rect2(360,box_y,720,box_height))
	paused=true
	_text(box,title.to_upper(),Rect2(32,26,656,38),23,CREAM,DISPLAY)
	_text(box,description,Rect2(32,72,656,92),14,MUTED,BODY,HORIZONTAL_ALIGNMENT_LEFT,true)
	for i in range(options.size()):
		var option: Dictionary = options[i]
		var callback := Callable(self,"_resolve_utility_choice").bind(option)
		_button(box,str(option.get("label","Choose")),Rect2(32,176+i*47,656,41),callback,i==0,11)

func _resolve_utility_choice(option: Dictionary) -> void:
	if pending_utility_choice.is_empty(): return
	var pending: Dictionary = pending_utility_choice.duplicate(true)
	pending_utility_choice.clear()
	var side_index: int = int(pending.get("side",-1))
	if side_index<0 or side_index>=sides.size():
		_close_modal()
		return
	match str(pending.get("effect","")):
		"blue_energy_loop": _attach_blue_energy_until_tails(side_index,int(option.get("target",-2)))
		"foe_switch": _switch_foe_active(side_index,int(option.get("target",-1)))
		"hand_swap": _swap_hand_fighter_with_deck(side_index,int(option.get("hand_index",-1)))
		"peek_shuffle":
			if bool(option.get("shuffle",false)):
				_shuffle_array(sides[side_index].deck)
				_log("You shuffle your deck after looking at its top card.")
			else:
				_log("You keep the top card in place.")
	_close_modal()
	_render()

func _resolve_blue_energy_loop_effect(side_index: int) -> void:
	var options: Array = _blue_fighter_options(side_index)
	if options.is_empty():
		_log("Urokodaki's Lesson has no Blue fighter to target.")
		return
	if side_index==1:
		var selected: Dictionary = options[0]
		for option in options:
			var index: int = int(option.target)
			var unit: Dictionary = sides[1].active if index<0 else sides[1].bench[index]
			var best_index: int = int(selected.target)
			var best_unit: Dictionary = sides[1].active if best_index<0 else sides[1].bench[best_index]
			if unit.energy.size()<best_unit.energy.size(): selected=option
		_attach_blue_energy_until_tails(side_index,int(selected.target))
	else:
		_open_utility_choice("blue_energy_loop",side_index,"Urokodaki's Lesson","Choose one of your Blue Color Type fighters to receive Blue Energy for each heads.",options)

func _attach_blue_energy_until_tails(side_index: int, target_index: int) -> void:
	if target_index < -1 or target_index >= sides[side_index].bench.size(): return
	var side: Dictionary = sides[side_index]
	var target: Dictionary = side.active if target_index<0 else side.bench[target_index]
	if str(target.get("color",""))!="Blue": return
	var heads := 0
	while _flip_coin():
		target.energy.append("Blue")
		heads+=1
	_log("Urokodaki's Lesson: %s flips %d heads, then tails; attach %d Blue Energy." % [target.name,heads,heads])

func _resolve_corps_intelligence(side_index: int) -> void:
	var opponent: Dictionary = sides[1-side_index]
	if opponent.bench.is_empty():
		_log("Corps Intelligence has no benched fighter to bring forward.")
		return
	if side_index==0:
		var selected := 0
		for i in range(1,opponent.bench.size()):
			if int(opponent.bench[i].current_hp)>int(opponent.bench[selected].current_hp): selected=i
		_log("The rival chooses %s as the new Active Fighter." % opponent.bench[selected].name)
		_switch_foe_active(side_index,selected)
	else:
		var options: Array = []
		for i in range(sides[0].bench.size()):
			options.append({"label":"BENCH "+str(i+1)+"  •  "+str(sides[0].bench[i].name),"target":i})
		_open_utility_choice("foe_switch",side_index,"Corps Intelligence","The rival switches out your Active Fighter. Choose which of your benched fighters becomes Active.",options)

func _switch_foe_active(effect_side: int, bench_index: int) -> void:
	var opponent: Dictionary = sides[1-effect_side]
	if bench_index<0 or bench_index>=opponent.bench.size(): return
	var incoming: Dictionary = opponent.bench[bench_index]
	var outgoing: Dictionary = opponent.active
	if outgoing.is_empty():
		opponent.bench.remove_at(bench_index)
	else:
		_clear_statuses(outgoing)
		opponent.bench[bench_index]=outgoing
	opponent.active=incoming
	_log("%s switches to the Bench; %s becomes Active." % [outgoing.get("short","Active fighter"),incoming.name])

func _take_random_basic_fighter(side_index: int) -> void:
	var indices: Array = _basic_fighter_deck_indices(side_index)
	if indices.is_empty():
		_log("Kasugai Crow's Message finds no Normal or standalone fighter.")
		return
	var side: Dictionary = sides[side_index]
	var deck_index: int = int(indices[rng.randi_range(0,indices.size()-1)])
	var fighter: Dictionary = side.deck.pop_at(deck_index)
	if side.hand.size()<10: side.hand.append(fighter)
	else: side.discard.append(fighter)
	_log("Kasugai Crow's Message brings %s from the deck." % fighter.name)

func _resolve_hand_swap_effect(side_index: int) -> void:
	var side: Dictionary = sides[side_index]
	var options: Array = _hand_fighter_indices(side_index)
	if options.is_empty() or _deck_fighter_indices(side_index).is_empty():
		_log("Kakushi Retrieval needs a fighter in both your hand and deck.")
		return
	if side_index==1:
		_swap_hand_fighter_with_deck(side_index,int(options[0]))
		return
	var choices: Array = []
	for hand_index in options:
		var fighter: Dictionary = side.hand[int(hand_index)]
		choices.append({"label":"EXCHANGE  •  "+str(fighter.name)+" ("+str(fighter.form)+")","hand_index":int(hand_index)})
	_open_utility_choice("hand_swap",side_index,"Kakushi Retrieval","Choose a fighter in your hand to exchange with a random fighter in your deck.",choices)

func _swap_hand_fighter_with_deck(side_index: int, hand_index: int) -> void:
	var side: Dictionary = sides[side_index]
	if hand_index<0 or hand_index>=side.hand.size() or str(side.hand[hand_index].get("kind",""))!="Fighter": return
	var candidates: Array = _deck_fighter_indices(side_index)
	if candidates.is_empty(): return
	var deck_index: int = int(candidates[rng.randi_range(0,candidates.size()-1)])
	var outgoing: Dictionary = side.hand[hand_index]
	var incoming: Dictionary = side.deck[deck_index]
	side.hand[hand_index]=incoming
	side.deck[deck_index]=outgoing
	_shuffle_array(side.deck)
	_log("Kakushi Retrieval exchanges %s for %s." % [outgoing.name,incoming.name])

func _resolve_peek_shuffle(side_index: int) -> void:
	var side: Dictionary = sides[side_index]
	if side.deck.is_empty():
		_log("Swordsmith's Gift: your deck is empty.")
		return
	var top: Dictionary = side.deck[0]
	if side_index==1:
		var shuffle: bool = not DB.is_basic(top) or side.bench.size()>=3
		if shuffle: _shuffle_array(side.deck)
		_log("The rival looks at %s on top and %s the deck." % [top.name,"shuffles" if shuffle else "keeps the order of"])
		return
	var choices: Array = [{"label":"SHUFFLE DECK","shuffle":true},{"label":"KEEP THIS ORDER","shuffle":false}]
	_open_utility_choice("peek_shuffle",side_index,"Swordsmith's Gift","Top card of your deck:\n"+_utility_card_preview(top),choices,{"top_card":top.duplicate(true)})

func _utility_card_preview(card: Dictionary) -> String:
	if str(card.get("kind",""))!="Fighter": return str(card.name)+"  •  "+str(card.kind)+"\n"+str(card.get("text",""))
	var result: String = str(card.name)+"  •  "+str(card.form)+"  •  "+str(card.color)+" Color Type  •  "+str(card.hp)+" HP"
	if str(card.get("ability_name",""))!="": result+="\nAbility: "+str(card.ability_name)+" — "+str(card.ability_text)
	for attack in card.attacks: result+="\n"+str(attack.name)+"  •  "+str(attack.damage)+" damage"
	return result

func _shuffle_array(values: Array) -> void:
	for i in range(values.size()-1,0,-1):
		var other: int = rng.randi_range(0,i)
		var temp: Variant = values[i]
		values[i]=values[other]
		values[other]=temp

func _clear_statuses(unit: Dictionary) -> void:
	unit["statuses"] = []

func _player_play() -> void:
	if _play_card(0,selected_hand):
		selected_hand=-1
		_render()

# Retreat cost: Normal fighters pay 1 Energy, SURGE fighters pay 2. Once per turn.
func _retreat_cost(unit: Dictionary) -> int:
	return int(unit.get("retreat_cost",2 if bool(unit.get("surge",false)) else 1))
# Retreat cost for the side's current active fighter, including "retreat for free" effects.
func _side_retreat_cost(side_index: int) -> int:
	var side: Dictionary = sides[side_index]
	if bool(side.get("free_retreat",false)): return 0
	return maxi(0,_retreat_cost(side.active)-int(side.get("retreat_discount",0)))
func _can_retreat(side_index: int) -> bool:
	var side: Dictionary = sides[side_index]
	if side.retreated or side.active.is_empty() or side.bench.is_empty(): return false
	if side.active.get("statuses",[]).has("Sleep"): return false
	return side.active.energy.size() >= _side_retreat_cost(side_index)
func _retreat(side_index: int, bench_index: int) -> bool:
	if not _can_act(side_index): return false
	var side: Dictionary = sides[side_index]
	if not _can_retreat(side_index) or bench_index<0 or bench_index>=side.bench.size(): return false
	var cost: int = _side_retreat_cost(side_index)
	for i in range(cost): side.active.energy.pop_back()
	var previous: Dictionary = side.active
	for retreat_status in ["Poison","Burn","Paralysis"]: previous.get("statuses",[]).erase(retreat_status)
	side.active=side.bench[bench_index]
	side.bench[bench_index]=previous
	side.retreated=true
	_log("%s retreats (paid %d Energy). %s becomes active." % [previous.short,cost,side.active.name])
	return true
func _attack_legal(side_index: int, attack_index: int) -> bool:
	if sides.is_empty(): return false
	var unit: Dictionary = sides[side_index].active
	if unit.is_empty() or attack_index<0 or attack_index>=unit.attacks.size(): return false
	if unit.get("statuses",[]).has("Sleep"): return false
	var attack: Dictionary = unit.attacks[attack_index]
	var matching: int = unit.energy.count(unit.color)
	return unit.energy.size()>=int(attack.cost) and matching>=int(attack.get("color_cost",1))

func _attack_coin_allows(side_index: int) -> bool:
	var attacker: Dictionary = sides[side_index].active
	if not attacker.get("statuses",[]).has("Paralysis"): return true
	var heads := _flip_coin()
	_log(str(attacker.name)+" flips "+("heads" if heads else "tails")+" against Paralysis.")
	if not heads: _log("The attack misses: 0 damage and no move effect.")
	return heads

func _resolve_attack(side_index: int, attack_index: int, attack_hits: bool = true, target_index: int = -1) -> int:
	if not _attack_legal(side_index,attack_index) or battle_over: return 0
	var attacker: Dictionary = sides[side_index].active
	var opponent: Dictionary = sides[1-side_index]
	if not attack_hits: return 0
	var attack: Dictionary = attacker.attacks[attack_index]
	var effect: String = str(attack.effect)
	var target: Dictionary = opponent.active
	if effect=="snipe" and target_index>=0 and target_index<opponent.bench.size(): target = opponent.bench[target_index]
	var damage: int = int(attack.damage)
	if damage > 0:
		damage += int(attacker.boost)
		if effect != "pierce": damage=maxi(0,damage-int(target.shield))
		attacker.boost=0
		target.shield=0
		target.current_hp=maxi(0,int(target.current_hp)-damage)
	match effect:
		"heal": attacker.current_hp=mini(attacker.hp,attacker.current_hp+10)
		"shield": attacker.shield=10
		"boost": attacker.boost=10
		"draw":
			_draw_cards(side_index,1)
			_log(str(attacker.short)+" cheers: draw 1 card.")
		"bench_splash":
			for unit in opponent.bench: unit.current_hp=maxi(0,int(unit.current_hp)-20)
			if not opponent.bench.is_empty(): _log("The blast hits the bench for 20 damage each.")
		"discard_all_energy":
			attacker.energy.clear()
			_log(str(attacker.short)+" spends all of its Energy.")
	var inflicted_status: String = str(attack.get("status",""))
	if inflicted_status!="" and damage>0 and target == opponent.active: _apply_status(target,inflicted_status,str(attacker.name))
	_log("%s: %s — %d damage to %s." % [attacker.short,attack.name,damage,target.short])
	return damage

func _apply_status(target: Dictionary, status: String, source_name: String) -> void:
	if not target.has("statuses"): target["statuses"] = []
	var statuses: Array = target.get("statuses",[])
	if statuses.has(status):
		_log(str(target.name)+" is already affected by "+status+".")
		return
	statuses.append(status)
	_log(source_name+" inflicts "+status+" on "+str(target.name)+".")

func _knockout_check(defender: int) -> void:
	var side: Dictionary = sides[defender]
	for i in range(side.bench.size()-1,-1,-1):
		if int(side.bench[i].current_hp)<=0:
			_defeat(defender,side.bench[i])
			side.bench.remove_at(i)
	if not side.active.is_empty() and int(side.active.current_hp)<=0:
		_defeat(defender,side.active)
		side.active={}
		if sides[1-defender].points >= 3:
			_finish_battle(1-defender)
			return
		if not side.bench.is_empty():
			if defender == 0:
				pending_replacement_side = defender
				notice = "Choose a fighter from your Bench to replace your Active."
				_log("Choose which benched fighter becomes your Active Fighter.")
			else:
				_choose_ai_replacement(defender)
		else:
			for i in range(side.hand.size()):
				if DB.is_basic(side.hand[i]):
					side.active=side.hand[i]
					side.hand.remove_at(i)
					break
	if sides[1-defender].points>=3 or (side.active.is_empty() and side.bench.is_empty()):
		_finish_battle(1-defender)

func _choose_ai_replacement(side_index: int) -> void:
	var side: Dictionary = sides[side_index]
	if side.bench.is_empty(): return
	var best_index := 0
	var best_score: int = int(side.bench[0].current_hp)+side.bench[0].energy.size()*5
	for i in range(1,side.bench.size()):
		var score: int = int(side.bench[i].current_hp)+side.bench[i].energy.size()*5
		if score > best_score:
			best_score = score
			best_index = i
	side.active = side.bench.pop_at(best_index)
	_log("Your rival chooses %s from the Bench as their new Active Fighter." % side.active.name)

func _choose_replacement(side_index: int, bench_index: int) -> bool:
	if pending_replacement_side != side_index or side_index < 0 or side_index >= sides.size(): return false
	var side: Dictionary = sides[side_index]
	if bench_index < 0 or bench_index >= side.bench.size(): return false
	side.active = side.bench.pop_at(bench_index)
	pending_replacement_side = -1
	notice = "Active Fighter replaced."
	_log("You choose %s from the Bench as your new Active Fighter." % side.active.name)
	if pending_begin_turn == side_index:
		pending_begin_turn = -1
		_complete_turn_start(side_index)
	if pending_turn_advance >= 0:
		pending_turn_advance = -1
		_finish_turn()
	_render()
	return true

func _finish_battle(winner: int) -> void:
	if battle_over: return
	battle_over=true
	pending_replacement_side = -1
	pending_begin_turn = -1
	pending_turn_advance = -1
	matches+=1
	if winner==0: wins+=1
	_save()
	battle_finished.emit(winner==0)
	_log("Victory!" if winner==0 else "Defeat. Draw your blade again.")

func _player_attack(index: int) -> void:
	if not _can_act(0) or not _attack_legal(0,index): return
	if str(sides[0].active.attacks[index].effect)=="snipe":
		attack_targeting = index
		selected_hand = -1
		_render()
		return
	_animated_attack(0,index)

func _animated_attack(side_index: int, index: int, target_index: int = -1) -> void:
	var attack_hits := _attack_coin_allows(side_index)
	var token := generation
	busy=true
	attack_animations+=1
	var opponent_side: int = 1-side_index
	var source: Control = board_nodes.get(str(side_index)+"_-1")
	var target: Control = board_nodes.get(str(opponent_side)+"_"+str(target_index))
	if not is_instance_valid(target): target = board_nodes.get(str(opponent_side)+"_-1")
	var slash := AnimatedSprite2D.new()
	slash.sprite_frames=ATTACK_SLASH_FRAMES
	slash.animation=&"slash"
	slash.centered=true
	var first_frame: Texture2D = ATTACK_SLASH_FRAMES.get_frame_texture(&"slash",0)
	var max_width: float = minf(720.0,root_ui.size.x*0.52)
	slash.scale=Vector2.ONE*(max_width/float(first_frame.get_width()))
	var strike_center := root_ui.size*0.5
	if is_instance_valid(source) and is_instance_valid(target):
		strike_center=((source.position+source.size*0.5)+(target.position+target.size*0.5))*0.5
	slash.position=strike_center
	slash.z_index=24
	root_ui.add_child(slash)
	attack_gif_animations+=1
	if reduced_motion:
		slash.frame=mini(9,ATTACK_SLASH_FRAMES.get_frame_count(&"slash")-1)
		await get_tree().create_timer(0.08).timeout
	else:
		slash.play()
		await slash.animation_finished
	if is_instance_valid(slash): slash.queue_free()
	if generation!=token: return
	# Snapshot opponent HP so every fighter that took damage (target, bench splash) animates.
	var opponent: Dictionary = sides[opponent_side]
	var before := {"-1": int(opponent.active.get("current_hp",0))}
	for i in range(opponent.bench.size()): before[str(i)] = int(opponent.bench[i].current_hp)
	_resolve_attack(side_index,index,attack_hits,target_index)
	var after := {"-1": int(opponent.active.get("current_hp",0))}
	for i in range(opponent.bench.size()): after[str(i)] = int(opponent.bench[i].current_hp)
	for key in before:
		var lost: int = int(before[key])-int(after.get(key,before[key]))
		var node: Control = board_nodes.get(str(opponent_side)+"_"+str(key))
		if lost > 0 and is_instance_valid(node): _damage_feedback(node,lost)
	await get_tree().create_timer(0.6 if not reduced_motion else 0.18).timeout
	if generation!=token: return
	_knockout_check(opponent_side)
	if battle_over:
		busy=false
		_render()
		return
	await _wait_unpaused(token)
	if generation!=token: return
	await _finish_turn()

func _end_turn_requested() -> void:
	if not _can_act(0): return
	busy=true
	_finish_turn()

func _finish_turn() -> void:
	if pending_replacement_side == 0:
		pending_turn_advance = current_side
		busy = false
		_render()
		return
	var token := generation
	_log("Your turn ends." if current_side==0 else "Rival's turn ends.")
	ability_targeting = false
	ability_source = -2
	attack_targeting = -1
	retreat_targeting = false
	current_side=1-current_side
	turn_number+=1
	selected_hand=-1
	selected_board=-1
	_begin_turn(current_side)
	_render()
	if battle_over:
		busy=false
		_render()
		return
	await _turn_banner("YOUR TURN" if current_side==0 else "RIVAL'S TURN",current_side)
	if generation!=token: return
	await _wait_unpaused(token)
	if generation!=token: return
	busy=false
	_render()
	if current_side==1: _ai_turn(token)

func _turn_banner(message: String, side_index: int, hold: float = 0.5) -> void:
	turn_animations+=1
	var banner := _panel(root_ui,Rect2(150,382,940,66),Color("#e5c887") if side_index==0 else Color("#c75147"),Color.TRANSPARENT,4)
	banner.z_index=60
	_text(banner,message,Rect2(0,8,940,50),26,INK,DISPLAY,HORIZONTAL_ALIGNMENT_CENTER)
	banner.modulate.a=0
	var tween := create_tween()
	tween.tween_property(banner,"modulate:a",1.0,0.15)
	tween.tween_interval(hold if not reduced_motion else 0.2)
	tween.tween_property(banner,"modulate:a",0.0,0.2)
	await tween.finished
	if is_instance_valid(banner): banner.queue_free()

func _wait_unpaused(token: int) -> void:
	while paused and generation==token:
		await get_tree().create_timer(0.1).timeout

func _ai_turn(token: int) -> void:
	await get_tree().create_timer(0.65).timeout
	await _wait_unpaused(token)
	if token!=generation or battle_over: return
	var side: Dictionary = sides[1]
	# Bench basics, Boost into SURGE forms, then play Items and at most one Support.
	for i in range(side.hand.size()-1,-1,-1):
		if i < side.hand.size() and DB.is_basic(side.hand[i]) and side.bench.size()<3: _play_card(1,i)
	for i in range(side.hand.size()-1,-1,-1):
		if i >= side.hand.size(): continue
		for target in _boost_targets(1,i):
			if _boost(1,i,int(target)): break
	for i in range(side.hand.size()-1,-1,-1):
		if i >= side.hand.size(): continue
		if side.hand[i].kind=="Item" or (side.hand[i].kind=="Support" and not side.support_used):
			if _play_card(1,i) and not pending_utility_choice.is_empty():
				_render()
				await _wait_unpaused(token)
				if token!=generation or battle_over: return
	_attach_energy(1,-1)
	_ai_use_card_abilities(1)
	_render()
	await get_tree().create_timer(0.45).timeout
	await _wait_unpaused(token)
	if token!=generation or battle_over: return
	var attack_index := -1
	for i in range(side.active.attacks.size()):
		if _attack_legal(1,i): attack_index=i
	if attack_index>=0:
		var target_index := -1
		if str(side.active.attacks[attack_index].effect)=="snipe": target_index = _ai_snipe_target(1)
		_animated_attack(1,attack_index,target_index)
	else:
		busy=true
		await _finish_turn()

func _ai_use_card_abilities(side_index: int) -> void:
	var side: Dictionary = sides[side_index]
	var opponent: Dictionary = sides[1-side_index]
	for source_index in range(-1,side.bench.size()):
		if not _ability_ready(side_index,source_index): continue
		var options: Array = _ability_target_options(side_index,source_index)
		if options.is_empty(): continue
		var target_index: int = int(options[0])
		for candidate in options:
			if int(opponent.bench[candidate].current_hp) < int(opponent.bench[target_index].current_hp): target_index = int(candidate)
		_activate_ability(side_index,source_index,target_index)

func _cost_text(color: String, a: Dictionary) -> String:
	var cost: int = int(a.cost)
	var color_cost: int = int(a.get("color_cost",1))
	if cost <= 0: return "NO ENERGY"
	if color_cost >= cost: return "%d %s ENERGY" % [cost,color.to_upper()]
	return "%d ENERGY (%d %s)" % [cost,color_cost,color.to_upper()]

func _make_unit(id: String) -> Dictionary:
	var unit: Dictionary = cards_by_id[id].duplicate(true)
	unit["current_hp"] = unit.hp
	unit["energy"] = []
	unit["statuses"] = []
	unit["ability_used"] = false
	unit["boost"] = 0
	unit["shield"] = 0
	unit["boosted_from"] = {}
	return unit

# Aoi's Butterfly Support: while she is in play, Poison on her opponent's fighters deals 20 more.
func _poison_bonus(victim_side: int) -> int:
	var other: Dictionary = sides[1-victim_side]
	var units: Array = other.bench.duplicate()
	if not other.active.is_empty(): units.append(other.active)
	for unit in units:
		if str(unit.get("ability_id",""))=="butterfly_support": return 20
	return 0

func _targeting() -> bool:
	return ability_targeting or attack_targeting >= 0 or retreat_targeting or pending_replacement_side >= 0

func _is_target_option(side_index: int, index: int) -> bool:
	if pending_replacement_side >= 0:
		return side_index == pending_replacement_side and side_index == 0 and index >= 0 and index < sides[side_index].bench.size()
	if retreat_targeting: return side_index == 0 and index >= 0 and index < sides[0].bench.size()
	if side_index != 1: return false
	if attack_targeting >= 0: return _attack_target_options(0).has(index)
	if ability_targeting: return _ability_target_options(0,ability_source).has(index)
	return false

func _board_clicked(side_index: int, index: int) -> void:
	if pending_replacement_side >= 0:
		if _is_target_option(side_index,index): _choose_replacement(side_index,index)
		return
	# Opponent fighters in play can be inspected at any time unless you are choosing a target.
	if side_index == 1 and not _targeting() and screen_name == "battle":
		var foe: Dictionary = sides[1]
		var unit: Dictionary = foe.active if index<0 else (foe.bench[index] if index<foe.bench.size() else {})
		if not unit.is_empty():
			_card_detail(str(unit.id),unit)
			paused = true
		return
	if not _can_act(0): return
	if retreat_targeting:
		if _is_target_option(side_index,index) and _retreat(0,index):
			retreat_targeting = false
			selected_board = -1
			_render()
		return
	if attack_targeting >= 0:
		if _is_target_option(side_index,index):
			var attack_index: int = attack_targeting
			attack_targeting = -1
			_animated_attack(0,attack_index,index)
		return
	if ability_targeting:
		if _is_target_option(side_index,index): _choose_ability_target(index)
		return
	if side_index != 0: return
	selected_board=index
	selected_hand=-1
	_render()

func _ability_target_options(side_index: int, source_index: int) -> Array:
	var result: Array = []
	if sides.is_empty(): return result
	var side: Dictionary = sides[side_index]
	if source_index < -1 or source_index >= side.bench.size(): return result
	var source: Dictionary = side.active if source_index<0 else side.bench[source_index]
	match str(source.get("ability_id","")):
		"rapid_drumming":
			var opponent: Dictionary = sides[1-side_index]
			for i in range(opponent.bench.size()):
				if int(opponent.bench[i].current_hp) < int(opponent.bench[i].hp): result.append(i)
	return result

# Board positions holding the Normal card this hand SURGE card Boosts from (active first).
func _boost_targets(side_index: int, hand_index: int) -> Array:
	var result: Array = []
	var side: Dictionary = sides[side_index]
	if hand_index<0 or hand_index>=side.hand.size(): return result
	var from_id: String = str(side.hand[hand_index].get("boost_from",""))
	if from_id == "": return result
	if not side.active.is_empty() and str(side.active.id)==from_id: result.append(-1)
	for i in range(side.bench.size()):
		if str(side.bench[i].id)==from_id: result.append(i)
	return result

# A fighter cannot Boost on the turn it was played, unless a card effect grants "boost_now".
func _boost_ready(side_index: int, target_index: int) -> bool:
	var side: Dictionary = sides[side_index]
	if target_index >= side.bench.size(): return false
	var base: Dictionary = side.active if target_index<0 else side.bench[target_index]
	if base.is_empty(): return false
	if int(side.get("turns_taken",0)) < 2: return false
	if bool(base.get("boost_now",false)): return true
	return int(base.get("played_turn",0)) < turn_number
func _boost(side_index: int, hand_index: int, target_index: int) -> bool:
	if not _can_act(side_index): return false
	if not _boost_targets(side_index,hand_index).has(target_index): return false
	if not _boost_ready(side_index,target_index): return false
	var side: Dictionary = sides[side_index]
	var surge: Dictionary = side.hand[hand_index]
	var base: Dictionary = side.active if target_index<0 else side.bench[target_index]
	var damage_taken: int = int(base.hp)-int(base.current_hp)
	surge["current_hp"] = maxi(1,int(surge.hp)-damage_taken)
	surge["energy"] = base.energy
	surge["boost"] = base.boost
	surge["shield"] = base.shield
	surge["statuses"] = []
	surge["ability_used"] = false
	surge["boosted_from"] = base
	surge["played_turn"] = int(base.get("played_turn",0))
	side.hand.remove_at(hand_index)
	if target_index<0: side.active = surge
	else: side.bench[target_index] = surge
	boost_animations += 1
	pending_boost_flash = str(side_index)+"_"+str(target_index)
	_log("%s Boosts into %s SURGE!" % [base.name,surge.short])
	return true

func _player_boost(target_index: int) -> void:
	if _boost(0,selected_hand,target_index):
		selected_hand = -1
		selected_board = target_index
		_render()

func _attack_target_options(side_index: int) -> Array:
	var result: Array = [-1]
	for i in range(sides[1-side_index].bench.size()): result.append(i)
	return result

func _defeat(defender: int, unit: Dictionary) -> void:
	var points: int = 2 if unit.surge else 1
	sides[1-defender].points+=points
	_log(str(unit.name)+" is defeated. +"+str(points)+" points.")
	_clear_statuses(unit)
	var side: Dictionary = sides[defender]
	side.discard.append(unit)
	var base: Dictionary = unit.get("boosted_from",{})
	if not base.is_empty(): side.discard.append(base)

func _damage_feedback(target: Control, damage: int) -> void:
	damage_animations+=1
	var original := target.position
	var shake := create_tween()
	target.modulate=Color(1.5,0.6,0.55)
	shake.tween_property(target,"position",original+Vector2(9,0),0.05)
	shake.tween_property(target,"position",original-Vector2(9,0),0.05)
	shake.tween_property(target,"position",original,0.08)
	shake.parallel().tween_property(target,"modulate",Color.WHITE,0.18)
	var hit := _text(root_ui,"−"+str(damage),Rect2(target.position.x+target.size.x*0.5-100,target.position.y+55,200,65),47 if target.size.x>120 else 34,RED,DISPLAY,HORIZONTAL_ALIGNMENT_CENTER)
	hit.z_index=30
	var flight := create_tween().set_parallel()
	flight.tween_property(hit,"position:y",hit.position.y-55,0.65)
	flight.tween_property(hit,"modulate:a",0.0,0.75)

func _ai_snipe_target(side_index: int) -> int:
	var opponent: Dictionary = sides[1-side_index]
	var best := -1
	var best_hp: int = int(opponent.active.get("current_hp",9999))
	for i in range(opponent.bench.size()):
		if int(opponent.bench[i].current_hp) < best_hp:
			best_hp = int(opponent.bench[i].current_hp)
			best = i
	return best

func _log(value: String) -> void:
	battle_log.append(value)
	if battle_log.size()>30: battle_log.pop_front()

func _result_modal() -> void:
	if is_instance_valid(modal): return
	var victory: bool = sides[0].points>=3 or sides[1].active.is_empty()
	var box := _modal_box(Rect2(441,267,701,345))
	_text(box,"VICTORY" if victory else "DEFEAT",Rect2(32,40,639,72),49,GOLD if victory else RED,DISPLAY,HORIZONTAL_ALIGNMENT_CENTER)
	_text(box,"A decisive strike. An unbreakable spirit." if victory else "Even a Hashira learns from the next duel.",Rect2(30,137,641,45),18,CREAM,BODY,HORIZONTAL_ALIGNMENT_CENTER)
	_text(box,"YOU %d  /  RIVAL %d KNOCKOUT POINTS" % [sides[0].points,sides[1].points],Rect2(30,194,641,29),12,MUTED,MEDIUM,HORIZONTAL_ALIGNMENT_CENTER)
	_button(box,"DUEL AGAIN",Rect2(51,264,281,46),func(): _close_modal(); _start_battle(),true,14)
	_button(box,"BACK TO HUB",Rect2(365,264,281,46),func(): _go("home"),false,14)

func _rules() -> void:
	var box := _modal_box(Rect2(379,94,835,726))
	_text(box,"THE WAY OF THE BLADE",Rect2(35,30,765,47),29,CREAM,DISPLAY)
	var rules := "Build exactly 20 cards, at most two copies of each. Each player has one Active Fighter and exactly three bench spots. A Nichirin coin flip decides who goes first. Before the first turn begins, you choose a Normal or standalone SURGE fighter from your starting hand for your Active spot; your rival chooses their own. No Energy can be attached on the duel's first turn. Draw one card and gain one Color Energy each turn; attach it once. Attack costs show how much Energy must match the fighter's Color Type.\n\nBOOST: Normal fighters use basic art and have one attack. Their full-art SURGE forms cannot be played on their own: select the SURGE card in your hand and Boost it onto its matching Normal card in play. It keeps the attached Energy and damage taken, and its status conditions clear. You can Boost a paired SURGE only from your second turn onward, and not on the turn its Normal was played unless a card effect explicitly permits it. Standalone SURGE cards (with no Normal version) may be played normally, even on the first turn.\n\nUse any number of Items each turn, but only one Support. Active abilities work once per turn; passive abilities are always on. Only your active fighter attacks, and attacking ends your turn. Use End Turn to pass. Retreat once per turn: discard Energy from your active fighter (Normal 1, SURGE 2) and switch it with a benched fighter. When an Active Fighter is Knocked Out, its owner chooses a fighter from their Bench to replace it; the rival AI makes its own choice.\n\nSTATUS EFFECTS: Sleep — flip at turn start; heads wakes it. A sleeping fighter can't attack or retreat. Poison — 10 damage at its owner's turn start. Burn — 20 damage at turn start, then flip; heads removes it. Paralysis — flip before attacking; tails means 0 damage and no effect. Retreating clears Poison, Burn and Paralysis, as do status-curing Items and Supports.\n\nA knockout scores 1 point, or 2 for a SURGE fighter. First to 3 points wins."
	_text(box,rules,Rect2(37,92,760,560),14,MUTED,BODY,HORIZONTAL_ALIGNMENT_LEFT,true)
	_button(box,"DRAW YOUR BLADE",Rect2(35,660,765,43),_close_modal,true,13)

func _settings() -> void:
	var box := _modal_box(Rect2(471,280,640,345))
	_text(box,"TABLE SETTINGS",Rect2(31,32,576,43),27,CREAM,DISPLAY)
	_button(box,"REDUCED MOTION: "+("ON" if reduced_motion else "OFF"),Rect2(34,112,570,45),func(): reduced_motion=not reduced_motion; _save(); _close_modal(); _settings(),reduced_motion,12)
	_button(box,"OPEN SOURCE LICENSES",Rect2(34,171,570,43),func():
		LICENSES.open(self),false,12)
	_text(box,"Local saves • Offline AI battles • English",Rect2(34,226,570,29),12,MUTED,BODY,HORIZONTAL_ALIGNMENT_CENTER)
	_button(box,"CLOSE",Rect2(34,272,570,43),_close_modal,true,12)

func _pause_menu() -> void:
	if screen_name != "battle": return
	var box := _modal_box(Rect2(477,291,625,337))
	paused=true
	_text(box,"SHEATHE YOUR BLADE",Rect2(30,30,565,50),26,CREAM,DISPLAY,HORIZONTAL_ALIGNMENT_CENTER)
	_text(box,"The duel is paused. Leaving ends this local match.",Rect2(32,106,561,47),16,MUTED,BODY,HORIZONTAL_ALIGNMENT_CENTER,true)
	_button(box,"RESUME DUEL",Rect2(33,183,560,46),_close_modal,true,13)
	_button(box,"LEAVE FOR HUB",Rect2(33,249,560,43),func(): _go("home"),false,12)

func _modal_box(rect: Rect2) -> Control:
	_close_modal()
	modal=Control.new()
	modal.size=Vector2(1440,900)
	modal.z_index=100
	add_child(modal)
	var dim := ColorRect.new()
	dim.color=Color(0.015,0.025,0.04,0.87)
	dim.size=Vector2(1440,900)
	modal.add_child(dim)
	return _panel(modal,rect,PANEL,Color("#5e5268"),14)

func _close_modal() -> void:
	if is_instance_valid(modal):
		remove_child(modal)
		modal.queue_free()
	modal=null
	paused=false

func _art_for(id: String) -> bool:
	return bool(cards_by_id.get(id,{}).get("surge",false))

func _card(parent: Control, card: Dictionary, rect: Rect2, action: Callable, small: bool = false) -> Control:
	var face := FACE.new()
	face.position=rect.position
	face.setup(card,_art_for(str(card.id)),rect.size,small)
	if action.is_valid(): face.pressed.connect(action)
	else: face.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(face)
	return face

func _panel(parent: Control, rect: Rect2, fill: Color, border: Color = Color("#303c50"), radius: int = 8) -> Panel:
	var panel := Panel.new()
	panel.position=rect.position
	panel.size=rect.size
	var style := StyleBoxFlat.new()
	style.bg_color=fill
	style.border_color=border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	panel.add_theme_stylebox_override("panel",style)
	panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	return panel

func _text(parent: Control, value: String, rect: Rect2, font_size: int, tint: Color = CREAM, font: Font = BODY, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, wrap: bool = false) -> Label:
	var label := Label.new()
	label.text=value
	label.position=rect.position
	label.horizontal_alignment=alignment
	label.add_theme_font_override("font",font)
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",tint)
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	if wrap: label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	else: label.clip_text=true
	# A fixed minimum width makes wrapped text measure against its box, not its full line.
	if wrap: label.custom_minimum_size=Vector2(rect.size.x,0)
	parent.add_child(label)
	label.size=rect.size
	return label

func _button(parent: Control, value: String, rect: Rect2, action: Callable, primary: bool = false, font_size: int = 14) -> Button:
	var button := Button.new()
	button.text=value
	button.position=rect.position
	button.size=rect.size
	button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font",MEDIUM)
	button.add_theme_font_size_override("font_size",font_size)
	button.add_theme_color_override("font_color",CREAM if primary else Color("#b9c4d4"))
	button.add_theme_color_override("font_disabled_color",Color("#556177"))
	for state in ["normal","hover","pressed","disabled","focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color=(RED if primary else Color("#192637")).lightened(0.12 if state=="hover" else 0)
		if state=="disabled": style.bg_color=Color("#101a29")
		style.border_color=GOLD if state=="focus" else (Color("#eb8a72") if primary else Color("#344157"))
		style.set_border_width_all(1)
		style.set_corner_radius_all(6)
		button.add_theme_stylebox_override(state,style)
	if action.is_valid(): button.pressed.connect(action)
	parent.add_child(button)
	return button

func _image(parent: Control, path: String, rect: Rect2, tint: Color = Color.WHITE) -> TextureRect:
	var image := TextureRect.new()
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.texture=FACE.texture(path)
	image.position=rect.position
	image.size=rect.size
	image.modulate=tint
	image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(image)
	return image

func _option(parent: Control, values: Array, selected: String, rect: Rect2, action: Callable) -> void:
	var option := OptionButton.new()
	option.position=rect.position
	option.size=rect.size
	option.add_theme_font_size_override("font_size",13)
	for i in range(values.size()):
		option.add_item(str(values[i]))
		if values[i]==selected: option.select(i)
	option.item_selected.connect(func(index): action.call(str(values[index])))
	parent.add_child(option)
