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
const RARITIES := ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Legendary"]
const FORMS := ["First Resolve", "Final Selection", "Breathing Form", "Awakened", "SURGE", "Eternal Resolve"]
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
const SUPPORTS := [
	["Wisteria Medicine","heal",30,"healing"], ["Butterfly Mansion","heal",40,"healing"],
	["Recovery Breathing","heal",20,"healing"], ["Tamayo's Remedy","heal",50,"healing"],
	["Aoi's Care","heal",30,"healing"], ["Wisteria Sanctuary","heal_all",20,"healing"],
	["Urokodaki's Lesson","draw",2,"training"], ["Kasugai Crow","draw",2,"training"],
	["Final Selection","draw",3,"training"], ["Swordsmith's Gift","draw",1,"training"],
	["Corps Intelligence","draw",2,"training"], ["Ubuyashiki's Guidance","draw",3,"training"],
	["Total Concentration","boost",20,"training"], ["Hashira Training","boost",30,"training"],
	["Nichirin Polish","boost",10,"training"], ["Unwavering Spirit","shield",20,"healing"],
	["Haganezuka's Resolve","boost",20,"training"], ["Protect the Innocent","shield",30,"healing"]
]

static func catalog() -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	for i in range(FIGHTERS.size()):
		var f: Array = FIGHTERS[i]
		for form in range(6):
			var surge: bool = form == 4
			var hp: int = 80 + form * 10 + (i % 3) * 10 + (30 if surge else 0)
			var base_damage: int = 20 + form * 5 + (i % 2) * 10
			var color: String = "Red" if i == 0 and form >= 3 else str(f[2])
			var effect: String = ["none","heal","shield","pierce","boost","none"][form]
			var ability_id: String = "blood_dominion" if str(f[0])=="muzan" else ""
			var ability_name: String = "Blood Dominion" if ability_id!="" else ""
			var ability_text: String = "Once per turn, choose a benched fighter. Generate one Color Energy of your current Energy color on it." if ability_id!="" else ""
			cards.append({"id":str(f[0])+"_"+str(form), "number":cards.size()+1, "name":str(f[1]),
				"form":FORMS[form], "kind":"Fighter", "color":color, "hp":hp, "surge":surge,
				"rarity":RARITIES[form], "art":str(f[0]), "alternate":str(f[0]) in ALT_ART,
				"ability_id":ability_id, "ability_name":ability_name, "ability_text":ability_text,
				"attacks":[{"name":str(f[3]),"damage":base_damage,"cost":1,"effect":"none"},
				{"name":str(f[4]),"damage":base_damage+30+(20 if surge else 0),"cost":3 if surge else 2,"effect":effect}],
				"text":"SURGE: awards 2 points when defeated." if surge else ["A blade drawn with courage.","Power attack restores 10 HP.","Power attack grants a 10-damage guard.","Power attack ignores guarding.","", "An unbreakable will."][form]})
	for i in range(SUPPORTS.size()):
		var s: Array = SUPPORTS[i]
		var descriptions := {"heal":"Restore %d HP to your active fighter.", "heal_all":"Restore %d HP to all your fighters.", "draw":"Draw %d cards.", "boost":"Your active fighter's next attack deals +%d damage.", "shield":"Guard your active fighter against %d damage."}
		cards.append({"id":"support_"+str(i),"number":cards.size()+1,"name":s[0],"form":"Support", "kind":"Support", "color":"White", "hp":0,"surge":false,"rarity":"Rare" if i%3==0 else "Common", "art":s[3],"alternate":false,"attacks":[],"effect":s[1],"value":s[2],"text":descriptions[s[1]] % int(s[2])})
	return cards

static func starter_deck() -> Array:
	return ["tanjiro_0","tanjiro_0","tanjiro_1","tanjiro_1","giyu_0","giyu_0","giyu_2","giyu_2","akaza_0","akaza_0","tanjiro_2","giyu_4","support_0","support_1","support_6","support_7","support_8","support_12","support_15","support_16"]

static func enemy_deck() -> Array:
	return ["rengoku_0","rengoku_0","rengoku_1","rengoku_1","muzan_0","muzan_0","muzan_2","muzan_2","yoriichi_0","yoriichi_0","rengoku_2","muzan_4","support_0","support_2","support_6","support_7","support_8","support_12","support_15","support_16"]

static func find_card(id: String) -> Dictionary:
	for card in catalog():
		if card.id == id:
			return card.duplicate(true)
	return {}

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
