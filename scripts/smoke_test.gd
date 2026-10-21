extends SceneTree
const DB := preload("res://scripts/card_database.gd")
const ATTACK_SLASH_FRAMES := preload("res://assets/interface/attack_slash_frames.tres")
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("[SMOKE_FAIL] "+message)

func _unit(id: String) -> Dictionary:
	var u: Dictionary = DB.find_card(id)
	u["current_hp"] = u.hp
	u["energy"] = []
	u["statuses"] = []
	u["ability_used"] = false
	u["boost"] = 0
	u["shield"] = 0
	u["boosted_from"] = {}
	return u

func _run() -> void:
	var catalog := DB.catalog()
	expect(catalog.size()>=150,"at least 150 cards")
	var ids := {}
	var fighters := 0
	var supports := 0
	var items := 0
	var status_moves := {}
	for card in catalog:
		ids[card.id]=true
		expect(card.kind in ["Fighter","Support","Item"],"card categories are Fighter, Support or Item")
		expect(DB.COLORS.has(card.color),"valid Color Type")
		if card.kind=="Fighter":
			fighters+=1
			expect(card.form in ["Normal","SURGE"],"fighters are only Normal or SURGE")
			expect(bool(card.surge)==(card.form=="SURGE"),"SURGE flag matches edition")
			if not card.surge: expect(card.attacks.size()==1,"Normal fighters have one attack: "+str(card.id))
			for a in card.attacks:
				if str(a.get("status",""))!="": status_moves[str(a.status)]=true
		elif card.kind=="Support": supports+=1
		else: items+=1
		for removed in ["Muzan","Yoriichi","Kokushibo","Kanao","Gyomei","Doma","Sanemi","Obanai"]:
			expect(not str(card.name).contains(removed),"removed character absent: "+removed)
	expect(fighters==39,"16 Normal/SURGE pairs + 7 new fighters = 39")
	expect(DB.find_card("tanjiro_normal").boosts_to=="tanjiro_surge" and DB.find_card("tanjiro_surge").boost_from=="tanjiro_normal","Boost links")
	expect(DB.is_basic(DB.find_card("kyogai_surge")) and DB.is_basic(DB.find_card("tanjiro_hinokami_surge")),"standalone SURGE cards are basic")
	expect(not DB.is_basic(DB.find_card("susamaru_surge")),"Susamaru SURGE requires Boost")
	expect(DB.find_card("murata_normal").hp==50 and DB.find_card("kyogai_surge").hp==125 and DB.find_card("aoi_normal").hp==70 and DB.find_card("susamaru_normal").hp==90 and DB.find_card("yahaba_normal").hp==80 and DB.find_card("tanjiro_hinokami_surge").hp==140,"new fighter HP")
	expect(supports>0 and items>0,"both Support and Item cards exist")
	expect(ids.size()==catalog.size(),"all catalog IDs distinct")
	for s in ["Sleep","Poison","Burn","Paralysis"]: expect(status_moves.has(s),s+" appears on at least one move")
	expect(DB.migrate_card_id("tanjiro_4")=="tanjiro_surge" and DB.migrate_card_id("giyu_2")=="giyu_normal","old fighter IDs migrate")
	expect(DB.validate_deck(DB.starter_deck())=="","valid 20-card starter")
	expect(DB.validate_deck(DB.enemy_deck())=="","valid 20-card rival deck")
	var oversized := DB.starter_deck()
	oversized.append("support_3")
	expect(DB.validate_deck(oversized)!="","21 cards rejected")
	expect(ATTACK_SLASH_FRAMES.get_frame_count(&"slash")==18,"supplied attack GIF imported as 18 frames")

	var game = load("res://scenes/card_game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	expect(game.screen_name=="home","boots to game hub")
	game.deck=DB.starter_deck()
	game._start_battle()
	game.reduced_motion=false
	await create_timer(0.9).timeout
	var me: Dictionary = game.sides[0]
	var foe: Dictionary = game.sides[1]
	expect(not me.active.is_empty(),"opening active placed")
	expect(game._attach_energy(0,-1),"attach Color Energy")
	expect(not game._attach_energy(0,-1),"second attachment disallowed")

	# Boost: SURGE needs its Normal in play; keeps energy and damage
	me.active = _unit("tanjiro_normal")
	me.active.energy = ["Blue","Blue"]
	me.active.current_hp = me.active.hp-30
	me.bench = []
	me.hand = [_unit("tanjiro_surge"),_unit("giyu_surge"),_unit("kyogai_surge")]
	expect(not game._play_card(0,0),"SURGE with a Normal version cannot be benched directly")
	expect(game._boost_targets(0,1).is_empty(),"no Boost target without matching Normal")
	expect(game._boost(0,0,-1),"Boost Tanjiro into SURGE")
	expect(me.active.id=="tanjiro_surge" and me.active.energy.size()==2 and me.active.current_hp==me.active.hp-30,"Boost keeps Energy and damage")
	expect(game._play_card(0,1),"standalone SURGE Kyogai plays to bench")
	# Kyogai Rapid Drumming pulls a damaged benched opponent fighter
	foe.active = _unit("rengoku_normal")
	foe.bench = [_unit("yahaba_normal"),_unit("susamaru_normal")]
	foe.bench[1].current_hp = 50
	expect(game._ability_target_options(0,0)==[1],"only damaged bench fighters are targets")
	game._begin_ability_targeting(0,0)
	expect(game._choose_ability_target(1),"Rapid Drumming resolves")
	expect(foe.active.id=="susamaru_normal" and foe.bench[1].id=="rengoku_normal","damaged fighter moved to active")
	expect(not game._activate_ability(0,0,1),"ability once per turn")
	# Aoi Butterfly Support adds 20 to Poison on the opponent
	foe.active.current_hp = 90
	foe.active["statuses"] = ["Poison"]
	me.bench.append(_unit("aoi_normal"))
	game._apply_turn_start_statuses(1)
	expect(foe.active.current_hp==60,"Poison + Butterfly Support deals 30")
	foe.active["statuses"] = []
	# Kagura Dance generates Red Energy at turn start while active
	var original_active: Dictionary = _unit("tanjiro_normal")
	me.active = _unit("tanjiro_hinokami_surge")
	game._begin_turn(0)
	expect(me.active.energy==["Red"],"Kagura Dance adds Red Energy")
	me.active.energy = ["Red","Red","Red","Red"]
	expect(game._attack_legal(0,1),"Clear Blue Sky legal with 4 Red")
	foe.active.current_hp = 200
	expect(game._resolve_attack(0,1)==125 and me.active.energy.is_empty(),"Clear Blue Sky deals 125 and removes all Energy")
	# Murata Cheer draws 1 for free
	me.active = _unit("murata_normal")
	var hand_before: int = me.hand.size()
	expect(game._attack_legal(0,0),"Cheer costs 0")
	game._resolve_attack(0,0)
	expect(me.hand.size()==hand_before+1,"Cheer draws a card")
	# Susamaru snipe and bench splash
	me.active = _unit("susamaru_normal")
	me.active.energy = ["Red"]
	foe.bench = [_unit("yahaba_normal")]
	expect(game._resolve_attack(0,0,true,0)==40 and foe.bench[0].current_hp==40,"Piercing Kick hits chosen bench fighter")
	me.active = _unit("susamaru_surge")
	me.active.energy = ["Red","Red"]
	expect(not game._attack_legal(0,1),"Sixfold Temari needs 3 Red")
	me.active.energy = ["Red","Red","Red"]
	foe.active = _unit("rengoku_surge")
	game._resolve_attack(0,1)
	expect(foe.bench[0].current_hp==20,"Sixfold Temari splashes 20 to bench")
	foe.bench[0].current_hp = 0
	var pts: int = me.points
	game._knockout_check(1)
	expect(foe.bench.is_empty() and me.points==pts+1,"bench knockout scores")
	foe.bench = []
	foe.points = 0
	me.points = 0

	# Items many, Support once
	me.active = _unit("tanjiro_normal")
	me.bench = [_unit("giyu_normal")]
	me.support_used = false
	me.hand = [DB.find_card("support_0"),DB.find_card("support_9"),DB.find_card("support_2"),DB.find_card("support_6"),DB.find_card("support_7")]
	expect(game._play_card(0,0),"first Item")
	expect(game._play_card(0,0),"second Item")
	expect(game._play_card(0,0),"third Item")
	expect(not me.support_used,"Items do not use the Support limit")
	expect(game._play_card(0,0),"first Support")
	expect(not game._play_card(0,0),"second Support rejected")

	# Sleep blocks attack and retreat; heads at turn start wakes
	me.active = _unit("tanjiro_normal")
	me.active.energy = ["Blue","Blue"]
	me.bench = [_unit("giyu_normal")]
	me.retreated = false
	game._apply_status(me.active,"Sleep","Test")
	expect(not game._attack_legal(0,0),"Sleep blocks attacks")
	expect(not game._retreat(0,0),"Sleep blocks retreat")
	game.coin_flip_overrides = [false]
	game._apply_turn_start_statuses(0)
	expect(me.active.statuses.has("Sleep"),"tails keeps Sleep")
	game.coin_flip_overrides = [true]
	game._apply_turn_start_statuses(0)
	expect(not me.active.statuses.has("Sleep"),"heads wakes from Sleep")
	expect(game._attack_legal(0,0),"woken fighter may attack")

	# Poison: 10 per turn start, persists, cleared by retreat
	me.active.current_hp = 100
	game._apply_status(me.active,"Poison","Test")
	game._apply_turn_start_statuses(0)
	game._apply_turn_start_statuses(0)
	expect(me.active.current_hp==80,"Poison deals 10 each turn start")
	expect(me.active.statuses.has("Poison"),"Poison persists")
	var poisoned: Dictionary = me.active
	me.retreated = false
	expect(game._retreat(0,0),"poisoned fighter can retreat")
	expect(not poisoned.statuses.has("Poison"),"retreat clears Poison")

	# Burn: 20 then coin; tails stays, heads clears
	me.active.current_hp = 100
	game._apply_status(me.active,"Burn","Test")
	game.coin_flip_overrides = [false]
	game._apply_turn_start_statuses(0)
	expect(me.active.current_hp==80 and me.active.statuses.has("Burn"),"Burn deals 20 and tails keeps it")
	game.coin_flip_overrides = [true]
	game._apply_turn_start_statuses(0)
	expect(me.active.current_hp==60 and not me.active.statuses.has("Burn"),"Burn deals 20 and heads clears it")

	# Cure card clears statuses
	game._apply_status(me.active,"Poison","Test")
	game._apply_status(me.active,"Paralysis","Test")
	me.hand = [DB.find_card("support_0")]
	expect(game._play_card(0,0),"curing Item resolves")
	expect(me.active.statuses.is_empty(),"curing Item clears statuses")

	# Paralysis: tails -> 0 damage, no effect
	me.active = _unit("shinobu_normal")
	me.active.energy = ["Purple"]
	foe.active = _unit("rengoku_normal")
	game._apply_status(me.active,"Paralysis","Test")
	game.coin_flip_overrides = [false]
	var hits: bool = game._attack_coin_allows(0)
	var hp0: int = foe.active.current_hp
	expect(not hits and game._resolve_attack(0,0,hits)==0 and foe.active.current_hp==hp0 and foe.active.statuses.is_empty(),"Paralysis tails: 0 damage and no status")
	game.coin_flip_overrides = [true]
	hits = game._attack_coin_allows(0)
	expect(hits and game._resolve_attack(0,0,hits)>0 and foe.active.statuses.has("Poison"),"Paralysis heads: attack hits and applies its effect")

	# Real animated attack with GIF and auto end turn
	me.active = original_active
	me.active["statuses"] = []
	me.active.energy = [me.active.color]
	foe.active = _unit("rengoku_normal")
	game.current_side = 0
	game.busy = false
	game._render()
	var hp_before: int = foe.active.current_hp
	game._player_attack(0)
	await create_timer(2.2).timeout
	expect(game.attack_gif_animations>=1,"attack plays supplied GIF")
	expect(foe.active.current_hp<hp_before or foe.points>=0,"attack resolves")
	expect(game.current_side==1,"attack automatically ends turn")
	game._go("home")
	await create_timer(0.9).timeout
	game._start_battle()
	await create_timer(0.9).timeout
	game._end_turn_requested()
	await create_timer(0.1).timeout
	expect(game.current_side==1,"explicit End Turn changes side")
	game._go("home")
	game.free()
	await create_timer(0.9).timeout
	if failures.is_empty():
		print("[SMOKE_PASS] 150 cards, Boost, new fighters and abilities, Normal/SURGE fighters, Items vs Support, Sleep/Poison/Burn/Paralysis, cures, GIF attack, auto/manual end turn")
		quit(0)
	else: quit(1)
