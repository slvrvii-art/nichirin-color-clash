class_name CardDatabase
extends RefCounted

const ART := {
    "title_kitchen": preload("res://assets/template/cardgame/title_kitchen.webp"),
    "battle_board": preload("res://assets/template/cardgame/battle_board.webp"),
    "kitchen_break": preload("res://assets/template/cardgame/kitchen_break.webp"),
    "chef_sama": preload("res://assets/template/cardgame/chef_sama.webp"),
    "icon_sword": preload("res://assets/template/cardgame/icon_sword.webp"),
    "icon_shield": preload("res://assets/template/cardgame/icon_shield.webp"),
    "leaderboard_crest": preload("res://assets/template/cardgame/leaderboard_crest.png"),
    "ingredient_fungus": preload("res://assets/template/cardgame/ingredient_fungus.png"),
    "ingredient_herb": preload("res://assets/template/cardgame/ingredient_herb.png"),
    "ingredient_meat": preload("res://assets/template/cardgame/ingredient_meat.png"),
    "ingredient_ember": preload("res://assets/template/cardgame/ingredient_ember.png"),
    "juice_card_back": preload("res://assets/template/cardgame/juice/card_back.png"),
    "juice_mana_burner": preload("res://assets/template/cardgame/juice/mana_burner.png"),
    "juice_armor_pan": preload("res://assets/template/cardgame/juice/armor_pan.png"),
    "juice_pantry_jar": preload("res://assets/template/cardgame/juice/pantry_jar.png"),
    "juice_encounter_seal": preload("res://assets/template/cardgame/juice/encounter_seal.png"),
    "juice_selection_knife": preload("res://assets/template/cardgame/juice/selection_knife.png"),
    "juice_cooking_cauldron": preload("res://assets/template/cardgame/juice/cooking_cauldron.png"),
    "tutorial_mise": preload("res://assets/template/cardgame/tutorial/mise_guide.png"),
    "tutorial_pointer": preload("res://assets/template/cardgame/tutorial/spoon_pointer.png"),
    "hud_hero_station_frame": preload("res://assets/template/cardgame/layout/hero_station_frame.png"),
    "hud_unit_plate_frame": preload("res://assets/template/cardgame/layout/unit_plate_frame.png"),
    "hud_passive_medallion_frame": preload("res://assets/template/cardgame/layout/passive_medallion_frame.png"),
    "hud_turn_marker": preload("res://assets/template/cardgame/layout/turn_marker.png"),
    "hud_end_turn_frame": preload("res://assets/template/cardgame/layout/end_turn_frame.png"),
    "hud_history_ticket_frame": preload("res://assets/template/cardgame/layout/history_ticket_frame.png"),
    "hud_pantry_tray_frame": preload("res://assets/template/cardgame/layout/pantry_tray_frame.png"),
    "hud_mana_rack_frame": preload("res://assets/template/cardgame/layout/mana_rack_frame.png"),
    "hud_deck_cradle": preload("res://assets/template/cardgame/layout/deck_cradle.png"),
    "picklemancer": preload("res://assets/template/cardgame/picklemancer.webp"),
    "mold_monarch": preload("res://assets/template/cardgame/mold_monarch.webp"),
    "ember_butcher": preload("res://assets/template/cardgame/ember_butcher.webp"),
    "banquet_tyrant": preload("res://assets/template/cardgame/banquet_tyrant.webp"),
    "card_back": preload("res://assets/template/cardgame/card_back.webp"),
    "coal_squire": preload("res://assets/template/cardgame/coal_squire.webp"),
    "pan_paladin": preload("res://assets/template/cardgame/pan_paladin.webp"),
    "pepper_mage": preload("res://assets/template/cardgame/pepper_mage.webp"),
    "broth_elemental": preload("res://assets/template/cardgame/broth_elemental.webp"),
    "truffle_knight": preload("res://assets/template/cardgame/truffle_knight.webp"),
    "precise_chop": preload("res://assets/template/cardgame/precise_chop.webp"),
    "searing_arc": preload("res://assets/template/cardgame/searing_arc.webp"),
    "mise_en_place": preload("res://assets/template/cardgame/mise_en_place.webp"),
    "kitchen_guard": preload("res://assets/template/cardgame/kitchen_guard.webp"),
    "seasoned_strike": preload("res://assets/template/cardgame/seasoned_strike.webp"),
    "mise_the_thousand_handed": preload("res://assets/template/cardgame/mise_the_thousand_handed.png"),
    "the_sovereign_cleaver": preload("res://assets/template/cardgame/the_sovereign_cleaver.png"),
    "bell_of_the_last_service": preload("res://assets/template/cardgame/bell_of_the_last_service.png"),
    "mooncap_broth": preload("res://assets/template/cardgame/mooncap_broth.webp"),
    "braised_bulwark": preload("res://assets/template/cardgame/braised_bulwark.webp"),
    "dragonpepper_roast": preload("res://assets/template/cardgame/dragonpepper_roast.webp"),
    "leftover_stew": preload("res://assets/template/cardgame/leftover_stew.webp"),
    "pickle_imp": preload("res://assets/template/cardgame/pickle_imp.webp"),
    "moldling": preload("res://assets/template/cardgame/moldling.webp"),
    "cursed_onion": preload("res://assets/template/cardgame/cursed_onion.webp"),
    "dough_golem": preload("res://assets/template/cardgame/dough_golem.webp"),
    "meat_mimic": preload("res://assets/template/cardgame/meat_mimic.webp"),
    "cellar_rat": preload("res://assets/template/cardgame/cellar_rat.webp"),
    "gravy_specter": preload("res://assets/template/cardgame/gravy_specter.webp"),
}

const COLORS := {"Red":"#ed6555", "Blue":"#58b9e5", "Yellow":"#f4cc68", "Green":"#83cfa2", "Purple":"#b491df", "Pink":"#eb98bd", "White":"#d9dfed"}
const RARITIES := ["Normal", "SURGE", "Common", "Uncommon", "Rare", "Epic", "Legendary"]
const VERSIONS := ["Normal", "SURGE"]
# Characters with a Normal card that Boosts into its SURGE card.
const FIGHTERS := [
	["tanjiro","Tanjiro Kamado","Blue","Water Wheel","Constant Flux"],
	["nezuko","Nezuko Kamado","Pink","Exploding Blood","Crimson Kick"],
	["zenitsu","Zenitsu Agatsuma","Yellow","Thunderclap & Flash","Sixfold Lightning"],
	["inosuke","Inosuke Hashibira","Green","Pierce","Crazy Cutting"],
	["giyu","Giyu Tomioka","Blue","Flowing Dance","Dead Calm"],
	["rengoku","Kyojuro Rengoku","Red","Unknowing Fire","Flame Tiger"],
	["shinobu","Shinobu Kocho","Purple","Butterfly Dance","Insect Dance"],
	["tengen","Tengen Uzui","Yellow","Roar","String Performance"],
	["mitsuri","Mitsuri Kanroji","Pink","Shivers of First Love","Catlove Shower"],
	["muichiro","Muichiro Tokito","White","Sea of Clouds","Obscuring Clouds"],
	["genya","Genya Shinazugawa","Purple","Nichirin Shot","Demon-Eater Strike"],
	["akaza","Akaza","Blue","Destructive Death","Compass Needle"],
	["rui","Rui","White","Thread Cage","Cutting Thread Rotation"],
	["daki","Daki","Pink","Obi Slash","Eight-Layered Obi"],
	["gyutaro","Gyutaro","Green","Flying Blood Sickles","Rotating Circular Slashes"],
	["enmu","Enmu","Purple","Dream Whisper","Endless Dream"]
]
const FULL_ART_FILES := ["tanjiro","nezuko","zenitsu","rengoku","giyu","susamaru"]
const MOVE_STATUSES := {
	"nezuko":["","Burn"], "zenitsu":["Paralysis","Paralysis"],
	"rengoku":["","Burn"], "shinobu":["Poison","Poison"],
	"akaza":["","Paralysis"], "rui":["","Paralysis"],
	"gyutaro":["","Poison"], "enmu":["Sleep","Sleep"]
}
const EFFECT_TEXT := {
	"heal":"Restore 10 HP to this fighter.",
	"shield":"This fighter takes 10 less damage from the next attack.",
	"pierce":"Ignores the defender's guard.",
	"boost":"This fighter's next attack deals +10 damage.",
	"draw":"Draw 1 card from your deck.",
	"snipe":"Choose any one of your opponent's fighters to take this damage.",
	"bench_splash":"Also deals 20 damage to every fighter on your opponent's bench.",
	"discard_all_energy":"Remove all Energy from this fighter."
}

# Hand-authored fighters. Standalone SURGE cards have no Normal counterpart and are played directly.
const SPECIAL_FIGHTERS := [
	{"id":"murata_normal","name":"Murata","short":"Murata","color":"Blue","hp":50,"surge":false,"art":"murata",
		"attacks":[{"name":"Cheer","damage":0,"cost":0,"color_cost":0,"effect":"draw"}]},
	{"id":"kyogai_surge","name":"Kyogai","short":"Kyogai","color":"Yellow","hp":125,"surge":true,"art":"kyogai",
		"ability_id":"rapid_drumming","ability_kind":"active","ability_name":"Rapid Drumming",
		"ability_text":"Once per turn, choose one of your opponent's benched fighters that has damage on it. Move it to their active spot.",
		"attacks":[{"name":"Drum Spell: Slash","damage":70,"cost":2,"color_cost":2,"effect":"none"}]},
	{"id":"aoi_normal","name":"Aoi Kanzaki","short":"Aoi","color":"Purple","hp":70,"surge":false,"art":"aoi",
		"ability_id":"butterfly_support","ability_kind":"passive","ability_name":"Butterfly Support",
		"ability_text":"While Aoi is in play, Poison on your opponent's fighters deals an additional 20 damage.",
		"attacks":[{"name":"Medicine Toss","damage":20,"cost":1,"color_cost":1,"effect":"none"}]},
	{"id":"susamaru_normal","name":"Susamaru","short":"Susamaru","color":"Red","hp":90,"surge":false,"art":"susamaru",
		"attacks":[{"name":"Piercing Kick","damage":40,"cost":1,"color_cost":1,"effect":"snipe"}]},
	{"id":"susamaru_surge","name":"Susamaru","short":"Susamaru","color":"Red","hp":130,"surge":true,"art":"susamaru","boost_from":"susamaru_normal",
		"attacks":[{"name":"Spiraling Shot","damage":70,"cost":2,"color_cost":2,"effect":"none"},
			{"name":"Sixfold Temari Unbound","damage":100,"cost":3,"color_cost":3,"effect":"bench_splash"}]},
	{"id":"yahaba_normal","name":"Yahaba","short":"Yahaba","color":"White","hp":80,"surge":false,"art":"yahaba",
		"attacks":[{"name":"Smack Down","damage":40,"cost":1,"color_cost":1,"effect":"none"}]},
	{"id":"tanjiro_hinokami_surge","name":"Tanjiro Kamado (Hinokami Kagura)","short":"Hinokami Tanjiro","color":"Red","hp":140,"surge":true,"art":"tanjiro_hinokami",
		"ability_id":"kagura_dance","ability_kind":"passive","ability_name":"Kagura Dance",
		"ability_text":"At the start of your turn, if this fighter is in the active spot, generate 1 Red Energy onto it.",
		"attacks":[{"name":"Raging Sun","damage":60,"cost":2,"color_cost":2,"effect":"none"},
			{"name":"Clear Blue Sky","damage":125,"cost":4,"color_cost":4,"effect":"discard_all_energy"}]}
]

# The first 18 utility cards retain their saved card IDs; several medicines are Items.
const SUPPORTS := [
	["Wisteria Medicine","cleanse_heal",30,"healing","Item"],
	["Butterfly Mansion","team_heal_cleanse",20,"healing","Support"],
	["Recovery Breathing","heal",20,"healing","Item"],
	["Tamayo's Remedy","cleanse_heal",50,"healing","Item"],
	["Aoi's Care","cleanse_heal",30,"healing","Item"],
	["Wisteria Sanctuary","team_heal_cleanse",20,"healing","Support"],
	["Urokodaki's Lesson","draw",2,"training","Support"],
	["Kasugai Crow","draw",2,"training","Support"],
	["Final Selection","draw",3,"training","Support"],
	["Swordsmith's Gift","draw",1,"training","Item"],
	["Corps Intelligence","draw",2,"training","Support"],
	["Ubuyashiki's Guidance","draw",3,"training","Support"],
	["Total Concentration","boost",20,"training","Support"],
	["Hashira Training","boost",30,"training","Support"],
	["Nichirin Polish","boost",10,"training","Item"],
	["Unwavering Spirit","shield",20,"healing","Item"],
	["Haganezuka's Resolve","boost",20,"training","Support"],
	["Protect the Innocent","shield",30,"healing","Support"]
]

const SUPPORT_EXTRA_SUBJECTS := ["Hashira Council","Corps Dispatch","Ubuyashiki's Order","Wisteria Escort","Swordsmith Meeting","Final Selection Brief","Kakushi Team","Butterfly Mansion Clinic","Crow Messenger","Demon Slayer Corps","Mountain Training","Night Watch","Rengoku's Resolve","Water Hashira's Counsel"]
const SUPPORT_EXTRA_SUFFIXES := ["Plan","Briefing","Formation","Mandate"]
const ITEM_EXTRA_SUBJECTS := ["Wisteria Salve","Nichirin Oil","Butterfly Poultice","Crow's Ration","Swordsmith Kit","Breathing Draught","Ubuyashiki Seal","Sunlight Charm","Mountain Bandage","Demon-Slaying Tonic","Calming Incense","Wisteria Powder","Hashira Field Kit","Haganezuka Stone"]
const ITEM_EXTRA_SUFFIXES := ["Kit","Supply","Cache","Reserve"]
const SUPPORT_EXTRA_EFFECTS := ["draw","boost","shield","heal","team_heal_cleanse","remove_status"]
const ITEM_EXTRA_EFFECTS := ["heal","cleanse_heal","draw","boost","shield","remove_status","heal_all"]
const EXTRA_VALUES := [10,20,30,40,50]
const TOTAL_CARDS := 150
const SUPPORT_EXTRA_COUNT := 46

static func catalog() -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	for i in range(FIGHTERS.size()):
		var f: Array = FIGHTERS[i]
		var key: String = str(f[0])
		var move_statuses: Array = MOVE_STATUSES.get(key,["",""])
		for surge in [false,true]:
			var hp: int = 90 + (i % 3) * 10 + (35 if surge else 0)
			var base_damage: int = 25 + (i % 2) * 10 + (10 if surge else 0)
			var first_attack := {"name":str(f[3]),"damage":base_damage,"cost":1,"color_cost":1,"effect":"none","status":str(move_statuses[0])}
			var attacks: Array = [first_attack]
			if surge:
				var secondary_effect: String = ["heal","shield","pierce","boost","none"][i % 5]
				attacks.append({"name":str(f[4]),"damage":base_damage+60,"cost":3,"color_cost":1,"effect":secondary_effect,"status":str(move_statuses[1])})
			var short_name: String = "Rengoku" if key == "rengoku" else str(f[1]).split(" ")[0]
			var spec := {"id":key+("_surge" if surge else "_normal"),"name":str(f[1]),"short":short_name,"color":str(f[2]),
				"hp":hp,"surge":surge,"art":key,"attacks":attacks}
			if surge: spec["boost_from"] = key+"_normal"
			_append_fighter(cards,spec)
	for spec in SPECIAL_FIGHTERS:
		_append_fighter(cards,spec)
	for i in range(SUPPORTS.size()):
		var s: Array = SUPPORTS[i]
		_append_utility(cards,"support_"+str(i),str(s[0]),str(s[1]),int(s[2]),str(s[3]),str(s[4]),i)
	for i in range(SUPPORT_EXTRA_COUNT):
		var name: String = str(SUPPORT_EXTRA_SUBJECTS[i % SUPPORT_EXTRA_SUBJECTS.size()])+" "+str(SUPPORT_EXTRA_SUFFIXES[int(i / SUPPORT_EXTRA_SUBJECTS.size())])
		var effect: String = str(SUPPORT_EXTRA_EFFECTS[i % SUPPORT_EXTRA_EFFECTS.size()])
		var value: int = int(EXTRA_VALUES[i % EXTRA_VALUES.size()])
		_append_utility(cards,"support_extra_%02d" % i,name,effect,value,"healing" if effect in ["heal","shield","team_heal_cleanse","remove_status"] else "training","Support",i+18)
	var item_count: int = TOTAL_CARDS - cards.size()
	for i in range(item_count):
		var name: String = str(ITEM_EXTRA_SUBJECTS[i % ITEM_EXTRA_SUBJECTS.size()])+" "+str(ITEM_EXTRA_SUFFIXES[int(i / ITEM_EXTRA_SUBJECTS.size())])
		var effect: String = str(ITEM_EXTRA_EFFECTS[i % ITEM_EXTRA_EFFECTS.size()])
		var value: int = int(EXTRA_VALUES[(i+2) % EXTRA_VALUES.size()])
		_append_utility(cards,"item_%02d" % i,name,effect,value,"healing" if effect in ["heal","cleanse_heal","heal_all","remove_status"] else "training","Item",i+64)
	# Link Normal cards to the SURGE card they Boost into.
	var by_id := {}
	for card in cards: by_id[card.id] = card
	for card in cards:
		var from_id: String = str(card.get("boost_from",""))
		if from_id != "" and by_id.has(from_id):
			by_id[from_id]["boosts_to"] = card.id
			by_id[from_id]["text"] = "Normal fighter. Boost it into "+str(card.short)+" SURGE."
	return cards

static func _append_fighter(cards: Array[Dictionary], spec: Dictionary) -> void:
	var surge: bool = bool(spec.surge)
	var art: String = str(spec.art)
	var attacks: Array = []
	for a in spec.attacks:
		var attack: Dictionary = (a as Dictionary).duplicate(true)
		if not attack.has("status"): attack["status"] = ""
		if not attack.has("color_cost"): attack["color_cost"] = 1
		attack["text"] = str(EFFECT_TEXT.get(str(attack.effect),""))
		attacks.append(attack)
	var boost_from: String = str(spec.get("boost_from",""))
	var text: String
	if surge and boost_from != "": text = "SURGE: Boost from its Normal card in play. Awards 2 points when defeated."
	elif surge: text = "Standalone SURGE: play it directly. Awards 2 points when defeated."
	else: text = "Normal fighter."
	cards.append({"id":str(spec.id),"number":cards.size()+1,"name":str(spec.name),"short":str(spec.get("short",spec.name)),
		"form":"SURGE" if surge else "Normal","kind":"Fighter","retreat_cost":2 if surge else 1,"color":str(spec.color),"hp":int(spec.hp),"surge":surge,
		"rarity":"SURGE" if surge else "Normal","art":art,
		"art_file":art+("_full" if surge and art in FULL_ART_FILES else ""),
		"alternate":surge,"boost_from":boost_from,"boosts_to":"",
		"ability_id":str(spec.get("ability_id","")),"ability_kind":str(spec.get("ability_kind","")),
		"ability_name":str(spec.get("ability_name","")),"ability_text":str(spec.get("ability_text","")),
		"attacks":attacks,"text":text})

static func _append_utility(cards: Array[Dictionary], id: String, name: String, effect: String, value: int, art: String, kind: String, ordinal: int) -> void:
	var descriptions := {
		"heal":"Restore %d HP to your active fighter.",
		"heal_all":"Restore %d HP to all your fighters.",
		"cleanse_heal":"Restore %d HP to your active fighter and clear its status conditions.",
		"team_heal_cleanse":"Restore %d HP to each fighter and clear their status conditions.",
		"draw":"Draw %d cards.",
		"boost":"Your active fighter's next attack deals +%d damage.",
		"shield":"Guard your active fighter against %d damage."
	}
	var text: String = "Clear all status conditions from your active fighter." if effect == "remove_status" else str(descriptions.get(effect,"Restore %d HP to your active fighter.")) % value
	cards.append({"id":id,"number":cards.size()+1,"name":name,"short":name,"form":kind,"kind":kind,"color":"White","hp":0,
		"surge":false,"rarity":"Rare" if ordinal % 5 == 0 else ("Uncommon" if ordinal % 3 == 0 else "Common"),
		"art":art,"art_file":art,"alternate":false,"boost_from":"","boosts_to":"","attacks":[],"effect":effect,"value":value,"text":text})

static func is_basic(card: Dictionary) -> bool:
	return str(card.get("kind","")) == "Fighter" and str(card.get("boost_from","")) == ""

static func starter_deck() -> Array:
	return ["tanjiro_normal","tanjiro_normal","tanjiro_surge","tanjiro_surge","giyu_normal","giyu_normal","giyu_surge","giyu_surge","murata_normal","murata_normal","tanjiro_hinokami_surge","support_0","support_0","support_9","support_9","support_1","support_6","support_10","support_12","support_14"]

static func enemy_deck() -> Array:
	return ["rengoku_normal","rengoku_normal","rengoku_surge","rengoku_surge","susamaru_normal","susamaru_normal","susamaru_surge","susamaru_surge","yahaba_normal","yahaba_normal","support_0","support_0","support_2","support_2","support_6","support_7","support_12","support_17","support_9","support_9"]

static func find_card(id: String) -> Dictionary:
	for card in catalog():
		if card.id == id:
			return card.duplicate(true)
	return {}

static func migrate_card_id(old_id: String) -> String:
	if not find_card(old_id).is_empty(): return old_id
	var split: PackedStringArray = old_id.rsplit("_",true,1)
	if split.size() == 2 and split[1].is_valid_int():
		for fighter in FIGHTERS:
			if str(fighter[0]) == split[0]:
				return str(fighter[0])+("_surge" if int(split[1]) == 4 else "_normal")
	return old_id

static func validate_deck(ids: Array) -> String:
	if ids.size() != 20:
		return "Your deck needs exactly 20 cards (%d/20)." % ids.size()
	var counts := {}
	var basics := 0
	for id in ids:
		var card := find_card(str(id))
		if card.is_empty():
			return "This deck contains an unknown card."
		counts[id] = counts.get(id,0)+1
		if counts[id] > 2:
			return "At most two copies of each catalog card."
		if is_basic(card):
			basics += 1
	return "Include at least one Normal or standalone SURGE fighter." if basics == 0 else ""

static func color_for(name: String) -> Color:
	return Color(COLORS.get(name,"#d9dfed"))

# Compatibility for the retained, unexposed starter multiplayer scene.
static func art(art_id: String) -> Texture2D:
	return ART.get(art_id)
