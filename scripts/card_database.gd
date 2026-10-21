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
const FIGHTERS := [
	["tanjiro","Tanjiro Kamado","Blue","Water Wheel","Hinokami Kagura"],
	["nezuko","Nezuko Kamado","Pink","Exploding Blood","Crimson Kick"],
	["zenitsu","Zenitsu Agatsuma","Yellow","Thunderclap & Flash","Sixfold Lightning"],
	["inosuke","Inosuke Hashibira","Green","Pierce","Crazy Cutting"],
	["giyu","Giyu Tomioka","Blue","Flowing Dance","Dead Calm"],
	["rengoku","Kyojuro Rengoku","Red","Unknowing Fire","Flame Tiger"],
	["shinobu","Shinobu Kocho","Purple","Butterfly Dance","Insect Dance"],
	["tengen","Tengen Uzui","Yellow","Roar","String Performance"],
	["mitsuri","Mitsuri Kanroji","Pink","Shivers of First Love","Catlove Shower"],
	["muichiro","Muichiro Tokito","White","Sea of Clouds","Obscuring Clouds"],
	["obanai","Obanai Iguro","Purple","Winding Serpent","Slithering Serpent"],
	["sanemi","Sanemi Shinazugawa","Green","Dust Whirlwind Cutter","Gale Slash"],
	["gyomei","Gyomei Himejima","White","Serpentinite Bipolar","Stone Skin"],
	["kanao","Kanao Tsuyuri","Pink","Honorable Shadow Plum","Equinoctial Eye"],
	["genya","Genya Shinazugawa","Purple","Nichirin Shot","Demon-Eater Strike"],
	["akaza","Akaza","Blue","Destructive Death","Compass Needle"],
	["doma","Doma","White","Frozen Lotus","Crystal Ice Child"],
	["muzan","Muzan Kibutsuji","Red","Blood Whip","Black Blood Thorns"],
	["kokushibo","Kokushibo","Purple","Dark Moon","Moonlit Catastrophe"],
	["rui","Rui","White","Thread Cage","Cutting Thread Rotation"],
	["daki","Daki","Pink","Obi Slash","Eight-Layered Obi"],
	["gyutaro","Gyutaro","Green","Flying Blood Sickles","Rotating Circular Slashes"],
	["enmu","Enmu","Purple","Dream Whisper","Endless Dream"],
	["yoriichi","Yoriichi Tsugikuni","Red","Sun Halo Dance","Thirteenth Form"]
]
const ALT_ART := ["tanjiro","nezuko","zenitsu","rengoku","giyu"]
const MOVE_STATUSES := {
	"nezuko":["","Burn"], "zenitsu":["Paralysis","Paralysis"],
	"rengoku":["","Burn"], "shinobu":["Poison","Poison"],
	"akaza":["","Paralysis"], "doma":["Sleep","Sleep"],
	"muzan":["","Poison"], "rui":["","Paralysis"],
	"gyutaro":["","Poison"], "enmu":["Sleep","Sleep"]
}

# The first 18 utility cards retain their saved card IDs; several medicines are now Items.
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
const SUPPORT_EXTRA_SUFFIXES := ["Plan","Briefing","Formation"]
const ITEM_EXTRA_SUBJECTS := ["Wisteria Salve","Nichirin Oil","Butterfly Poultice","Crow's Ration","Swordsmith Kit","Breathing Draught","Ubuyashiki Seal","Sunlight Charm","Mountain Bandage","Demon-Slaying Tonic","Calming Incense","Wisteria Powder","Hashira Field Kit","Haganezuka Stone"]
const ITEM_EXTRA_SUFFIXES := ["Kit","Supply","Cache"]
const SUPPORT_EXTRA_EFFECTS := ["draw","boost","shield","heal","team_heal_cleanse","remove_status"]
const ITEM_EXTRA_EFFECTS := ["heal","cleanse_heal","draw","boost","shield","remove_status","heal_all"]
const EXTRA_VALUES := [10,20,30,40,50]

static func catalog() -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	for i in range(FIGHTERS.size()):
		var f: Array = FIGHTERS[i]
		for surge in [false,true]:
			var version: String = "SURGE" if surge else "Normal"
			var hp: int = 90 + (i % 3) * 10 + (35 if surge else 0)
			var base_damage: int = 25 + (i % 2) * 10 + (10 if surge else 0)
			var ability_id: String = "blood_dominion" if str(f[0]) == "muzan" else ""
			var ability_name: String = "Blood Dominion" if ability_id != "" else ""
			var ability_text: String = "Once per turn, choose a benched fighter. Generate one Color Energy of your current Energy color on it." if ability_id != "" else ""
			var move_statuses: Array = MOVE_STATUSES.get(str(f[0]),["",""])
			var secondary_effect: String = ["heal","shield","pierce","boost","none"][i % 5]
			var first_attack := {"name":str(f[3]),"damage":base_damage,"cost":1,"effect":"none","status":str(move_statuses[0])}
			var second_attack := {"name":str(f[4]),"damage":base_damage+40+(20 if surge else 0),"cost":3 if surge else 2,"effect":secondary_effect,"status":str(move_statuses[1])}
			cards.append({"id":str(f[0])+ ("_surge" if surge else "_normal"), "number":cards.size()+1,
				"name":str(f[1]),"form":version,"kind":"Fighter","color":str(f[2]),"hp":hp,"surge":surge,
				"rarity":version,"art":str(f[0]),"alternate":str(f[0]) in ALT_ART,
				"ability_id":ability_id,"ability_name":ability_name,"ability_text":ability_text,
				"attacks":[first_attack,second_attack],
				"text":"SURGE: awards 2 points when defeated." if surge else "Normal fighter edition."})
	for i in range(SUPPORTS.size()):
		var s: Array = SUPPORTS[i]
		_append_utility(cards,"support_"+str(i),str(s[0]),str(s[1]),int(s[2]),str(s[3]),str(s[4]),i)
	for i in range(42):
		var suffix_index: int = int(i / SUPPORT_EXTRA_SUBJECTS.size())
		var name: String = str(SUPPORT_EXTRA_SUBJECTS[i % SUPPORT_EXTRA_SUBJECTS.size()])+" "+str(SUPPORT_EXTRA_SUFFIXES[suffix_index])
		var effect: String = str(SUPPORT_EXTRA_EFFECTS[i % SUPPORT_EXTRA_EFFECTS.size()])
		var value: int = int(EXTRA_VALUES[i % EXTRA_VALUES.size()])
		_append_utility(cards,"support_extra_%02d" % i,name,effect,value,"healing" if effect in ["heal","shield","team_heal_cleanse","remove_status"] else "training","Support",i+18)
	for i in range(42):
		var suffix_index: int = int(i / ITEM_EXTRA_SUBJECTS.size())
		var name: String = str(ITEM_EXTRA_SUBJECTS[i % ITEM_EXTRA_SUBJECTS.size()])+" "+str(ITEM_EXTRA_SUFFIXES[suffix_index])
		var effect: String = str(ITEM_EXTRA_EFFECTS[i % ITEM_EXTRA_EFFECTS.size()])
		var value: int = int(EXTRA_VALUES[(i+2) % EXTRA_VALUES.size()])
		_append_utility(cards,"item_%02d" % i,name,effect,value,"healing" if effect in ["heal","cleanse_heal","heal_all","remove_status"] else "training","Item",i+36)
	return cards

static func _append_utility(cards: Array[Dictionary], id: String, name: String, effect: String, value: int, art: String, kind: String, ordinal: int) -> void:
	var descriptions := {
		"heal":"Restore %d HP to your active fighter.",
		"heal_all":"Restore %d HP to all your fighters.",
		"cleanse_heal":"Restore %d HP to your active fighter and clear its status conditions.",
		"team_heal_cleanse":"Restore %d HP to each fighter and clear their status conditions.",
		"remove_status":"Clear all status conditions from your active fighter.",
		"draw":"Draw %d cards.",
		"boost":"Your active fighter's next attack deals +%d damage.",
		"shield":"Guard your active fighter against %d damage."
	}
	var text: String = descriptions.get(effect,"Restore %d HP to your active fighter.")
	if effect == "remove_status": text = "Clear all status conditions from your active fighter."
	else: text = text % value
	cards.append({"id":id,"number":cards.size()+1,"name":name,"form":kind,"kind":kind,"color":"White","hp":0,
		"surge":false,"rarity":"Rare" if ordinal % 5 == 0 else ("Uncommon" if ordinal % 3 == 0 else "Common"),
		"art":art,"alternate":false,"attacks":[],"effect":effect,"value":value,"text":text})

static func starter_deck() -> Array:
	return ["tanjiro_normal","tanjiro_normal","tanjiro_surge","tanjiro_surge","giyu_normal","giyu_normal","giyu_surge","giyu_surge","akaza_normal","akaza_normal","akaza_surge","akaza_surge","support_0","support_0","support_9","support_9","support_1","support_6","support_10","support_12"]

static func enemy_deck() -> Array:
	return ["rengoku_normal","rengoku_normal","rengoku_surge","rengoku_surge","muzan_normal","muzan_normal","muzan_surge","muzan_surge","yoriichi_normal","yoriichi_normal","yoriichi_surge","yoriichi_surge","support_0","support_0","support_2","support_2","support_6","support_7","support_12","support_17"]

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
	var fighters := 0
	for id in ids:
		var card := find_card(str(id))
		if card.is_empty():
			return "This deck contains an unknown card."
		counts[id] = counts.get(id,0)+1
		if counts[id] > 2:
			return "At most two copies of each catalog card."
		if card.kind == "Fighter":
			fighters += 1
	return "Include at least one Fighter." if fighters == 0 else ""

static func color_for(name: String) -> Color:
	return Color(COLORS.get(name,"#d9dfed"))

# Compatibility for the retained, unexposed starter multiplayer scene.
static func art(art_id: String) -> Texture2D:
	return ART.get(art_id)
