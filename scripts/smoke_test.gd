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
	expect(catalog.size()==DB.TOTAL_CARDS and DB.TOTAL_CARDS==51,"51-card catalog")
	var detached_view := DB.catalog()
	detached_view.clear()
	expect(DB.catalog().size()==DB.TOTAL_CARDS,"catalog views cannot mutate the shared catalog")
	var cached_attacks: Array = catalog[0].get("attacks",[])
	expect(catalog[0].is_read_only() and cached_attacks.is_read_only(),"shared card definitions and nested attacks are frozen")
	var mutable_copy := DB.find_card("tanjiro_normal")
	mutable_copy["test_copy_marker"] = true
	expect(mutable_copy.has("test_copy_marker") and not DB.find_card("tanjiro_normal").has("test_copy_marker"),"find_card returns isolated mutable copies")
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
	expect(DB.find_card("murata_normal").hp==50 and DB.find_card("kyogai_surge").hp==130 and DB.find_card("aoi_normal").hp==70 and DB.find_card("susamaru_normal").hp==90 and DB.find_card("yahaba_normal").hp==80 and DB.find_card("tanjiro_hinokami_surge").hp==140,"new fighter HP")
	expect(supports==4 and items==8,"exactly 4 Support and 8 Item cards")
	for removed_id in ["support_0","support_1","support_4","support_8","support_12","support_13","support_14","support_16","support_17","item_00"]:
		expect(DB.find_card(removed_id).is_empty(),"removed utility ID absent: "+removed_id)
	for card in catalog:
		if card.kind == "Fighter":
			expect(int(card.hp) % 10 == 0,str(card.id)+" HP is a multiple of 10")
			for a in card.attacks: expect(int(a.damage) % 10 == 0,str(card.id)+" damage is a multiple of 10")
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
	game.screen_name="collection"
	game._render()
	var ordered_results: Array[Dictionary] = game._filtered()
	var ordered := true
	for i in range(1,ordered_results.size()):
		if int(ordered_results[i-1].number)>int(ordered_results[i].number): ordered=false
	expect(ordered and ordered_results.size()==DB.TOTAL_CARDS,"collection filters retain catalog-number order")
	game.search_text="TANJIRO"
	var searched_results: Array[Dictionary] = game._filtered()
	var search_is_case_insensitive := not searched_results.is_empty()
	for card in searched_results:
		var searchable := (str(card.name)+" "+str(card.form)+" "+str(card.text)).to_lower()
		if not searchable.contains("tanjiro"): search_is_case_insensitive=false
	expect(search_is_case_insensitive,"collection search remains case-insensitive")
	game.search_text=""
	var first_filters: Array[Node] = game.root_ui.find_children("*","OptionButton",true,false)
	var initial_filter_ids := {}
	var initial_item_counts: Array[int] = []
	for filter_node in first_filters:
		var instance_id: int = filter_node.get_instance_id()
		initial_filter_ids[instance_id]=true
		initial_item_counts.append((filter_node as OptionButton).get_popup().item_count)
	initial_item_counts.sort()
	game._render()
	var second_filters: Array[Node] = game.root_ui.find_children("*","OptionButton",true,false)
	var filters_reused_cleanly := second_filters.size()==3 and second_filters.size()==initial_filter_ids.size()
	var second_item_counts: Array[int] = []
	for filter_node in second_filters:
		var instance_id: int = filter_node.get_instance_id()
		if not initial_filter_ids.has(instance_id):
			filters_reused_cleanly=false
		second_item_counts.append((filter_node as OptionButton).get_popup().item_count)
	second_item_counts.sort()
	filters_reused_cleanly = filters_reused_cleanly and second_item_counts==initial_item_counts
	expect(filters_reused_cleanly,"reused collection filters clear old options without allocating replacement nodes")
	game.deck=DB.starter_deck()
	game.show_coin_flip_animations = false
	game.reduced_motion = true
	var coin_events_before: int = game.coin_flip_events
	game.coin_flip_overrides = [true]
	game.show_coin_flip_animations = true
	var observed_heads: bool = game._flip_coin()
	expect(observed_heads and game.coin_flip_events==coin_events_before+1 and game.coin_animation_queue.size()==1,"each coin flip queues its animated result")
	game.show_coin_flip_animations = false
	game.coin_animation_queue.clear()
	game.coin_flip_overrides.clear()
	# The real first-player helper uses the same animated coin-resolution path.
	var firsts := {}
	for n in range(24):
		firsts[game._roll_first_side()] = true
	expect(firsts.has(0) and firsts.has(1),"first player is random")
	game.first_side_override = 0
	game._start_battle()
	expect(game.opening_active_pending and game.sides[0].active.is_empty(),"player must choose the opening Active")
	expect(DB.is_basic(game.sides[1].active) and game.sides[1].hand.size()==4,"AI chooses an eligible fighter from its opening hand")
	var starters: Array = game._opening_fighter_indices(0)
	expect(not starters.is_empty(),"opening hand contains a Normal or standalone SURGE starter")
	var ineligible_index := -1
	for i in range(game.sides[0].hand.size()):
		if game.sides[0].hand[i].kind=="Fighter" and not DB.is_basic(game.sides[0].hand[i]): ineligible_index=i
	if ineligible_index >= 0:
		expect(not game._choose_opening_active(0,ineligible_index),"paired SURGE cannot be selected as an opening Active")
	expect(game._choose_opening_active(0,int(starters[0])),"player sets an opening Active from hand")
	expect(game.sides[0].active.kind=="Fighter" and game.sides[0].hand.size()==4,"chosen starter leaves the opening hand")
	await create_timer(1.0).timeout
	expect(game.battle_started and game.sides[0].turns_taken==1,"first turn starts after Active choice and coin banner")
	var me: Dictionary = game.sides[0]
	var foe: Dictionary = game.sides[1]
	expect(not me.active.is_empty(),"opening Active fighter placed")
	expect(not game._attach_energy(0,-1),"no Energy on the first turn")
	game.turn_number = 2
	me.energy_ready = true
	expect(game._attach_energy(0,-1),"attach Color Energy")
	expect(not game._attach_energy(0,-1),"second attachment disallowed")

	# Retreat cost: Normal 1, SURGE 2, once per turn, chosen from the active fighter
	me.active = _unit("tanjiro_normal")
	me.bench = [_unit("giyu_surge"), _unit("murata_normal")]
	me.retreated = false
	expect(DB.find_card("tanjiro_normal").retreat_cost==1 and DB.find_card("tanjiro_surge").retreat_cost==2,"retreat costs Normal 1 / SURGE 2")
	expect(not game._retreat(0,0),"retreat needs enough Energy")
	me.active.energy = ["Blue","Blue"]
	expect(game._retreat(0,0) and me.active.id=="giyu_surge" and me.bench[0].energy.size()==1,"Normal retreat pays 1 Energy")
	me.active.energy = ["Blue","Blue","Blue"]
	expect(not game._retreat(0,1),"only one retreat per turn")
	me.retreated = false
	expect(game._retreat(0,1) and me.bench[1].energy.size()==1,"SURGE retreat pays 2 Energy")
	game.retreat_targeting = true
	expect(game._is_target_option(0,0) and not game._is_target_option(1,0),"retreat targets your bench")
	game.retreat_targeting = false

	# Standalone SURGE is playable immediately, even on its owner's first turn.
	game.turn_number = 1
	me.turns_taken = 1
	me.active = _unit("murata_normal")
	me.bench = []
	me.hand = [DB.find_card("kyogai_surge")]
	expect(game._play_card(0,0),"standalone SURGE plays normally on the first turn")
	me.bench = []
	game.turn_number = 2

	# Paired SURGE requires the owner's second turn and a different turn from the Normal play.
	me.active = _unit("murata_normal")
	me.bench = []
	me.retreated = false
	me.hand = [_unit("giyu_normal"), _unit("giyu_surge")]
	me.turns_taken = 1
	expect(game._play_card(0,0),"bench Giyu")
	expect(not game._boost(0,0,0),"cannot Boost on the turn played")
	expect(not game._boost_ready(0,0),"paired SURGE is locked on the owner's first turn")
	me.turns_taken = 2
	game.turn_number += 1
	expect(game._boost(0,0,0) and me.bench[0].id=="giyu_surge","Boost after the Normal is established and the owner starts their second turn")
	me.bench[0]["played_turn"] = game.turn_number
	me.bench[0]["boost_now"] = true
	me.turns_taken = 1
	expect(not game._boost_ready(0,0),"same-turn Boost effect cannot bypass the second-turn requirement")
	me.turns_taken = 2
	expect(game._boost_ready(0,0),"card effect may allow Boosting immediately")

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
	expect(game._resolve_attack(0,1)==130 and me.active.energy.is_empty(),"Clear Blue Sky deals 130 and removes all Energy")
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
	# A human must choose a benched replacement after its Active is Knocked Out.
	me.active = _unit("tanjiro_normal")
	me.active.current_hp = 0
	me.bench = [_unit("giyu_normal"),_unit("murata_normal")]
	foe.active = _unit("rengoku_normal")
	game.pending_replacement_side = -1
	game.pending_turn_advance = -1
	game._knockout_check(0)
	expect(game.pending_replacement_side==0 and me.active.is_empty(),"player replacement pauses after an Active knockout")
	expect(game._is_target_option(0,1) and not game._can_act(0),"only own bench cards are replacement options")
	expect(game._choose_replacement(0,1) and me.active.id=="murata_normal" and me.bench[0].id=="giyu_normal","player chooses which bench fighter becomes Active")
	# The AI chooses its highest-survivability bench card automatically.
	foe.active = _unit("rengoku_normal")
	foe.active.current_hp = 0
	foe.bench = [_unit("yahaba_normal"),_unit("susamaru_normal")]
	game._knockout_check(1)
	expect(foe.active.id=="susamaru_normal" and foe.bench.size()==1,"AI chooses its own bench replacement")
	foe.bench = []
	foe.points = 0
	me.points = 0

	# Multiple Items are legal, but only one Support resolves per turn.
	me.active = _unit("tanjiro_normal")
	me.bench = [_unit("giyu_normal")]
	me.support_used = false
	me.hand = [DB.find_card("support_3"),DB.find_card("support_2"),DB.find_card("support_15"),DB.find_card("support_5"),DB.find_card("support_11")]
	expect(game._play_card(0,0),"first Item")
	expect(game._play_card(0,0),"second Item")
	expect(game._play_card(0,0),"third Item")
	expect(not me.support_used,"Items do not use the Support limit")
	expect(game._play_card(0,0),"first Support")
	expect(not game._play_card(0,0),"second Support rejected")
	# Recovery Breathing adds the active Color Energy on heads without consuming the ordinary attachment.
	me.active = _unit("giyu_normal")
	me.active.energy = []
	me.energy_color = "Purple"
	me.energy_ready = true
	game.coin_flip_overrides = [false]
	me.hand = [DB.find_card("support_2")]
	expect(game._play_card(0,0) and me.active.energy.is_empty() and me.energy_ready,"Recovery Breathing tails grants no Energy")
	game.coin_flip_overrides = [true]
	me.hand = [DB.find_card("support_2")]
	expect(game._play_card(0,0) and me.active.energy==["Purple"] and me.energy_ready,"Recovery Breathing heads attaches Energy Zone color without spending normal attachment")
	# Sunlight Charm recycles the opponent's full hand and draws three.
	foe.hand = [DB.find_card("support_6"),DB.find_card("support_7")]
	foe.deck = [DB.find_card("support_5"),DB.find_card("support_9"),DB.find_card("support_11"),DB.find_card("support_2")]
	var foe_cards_before: int = foe.hand.size()+foe.deck.size()
	me.hand = [DB.find_card("item_01")]
	expect(game._play_card(0,0) and foe.hand.size()==3 and foe.hand.size()+foe.deck.size()==foe_cards_before,"Sunlight Charm shuffles opponent hand and draws 3")
	# Kasugai Crow's Message searches a random Normal/standalone fighter, not a Boost-only SURGE.
	me.support_used = false
	me.deck = [DB.find_card("tanjiro_surge"),DB.find_card("giyu_normal"),DB.find_card("kyogai_surge"),DB.find_card("support_5")]
	me.hand = [DB.find_card("support_7")]
	expect(me.hand[0].kind=="Item" and me.hand[0].name=="Kasugai Crow's Message","Kasugai Crow renamed and converted to Item")
	expect(game._play_card(0,0) and me.hand.size()==1 and DB.is_basic(me.hand[0]) and me.deck.size()==3,"Kasugai message adds one random Normal or standalone fighter")
	# Corps Intelligence leaves the replacement choice to the affected player/AI.
	me.support_used = false
	foe.active = _unit("rengoku_normal")
	foe.active["statuses"] = ["Poison"]
	foe.bench = [_unit("yahaba_normal"),_unit("susamaru_normal")]
	me.hand = [DB.find_card("support_10")]
	expect(me.hand[0].text=="Switch out your opponent’s Active Fighter to the Bench. (Your opponent chooses the new Active Fighter.)","Corps Intelligence displays the choice rule")
	expect(game._play_card(0,0) and foe.active.id=="susamaru_normal" and foe.bench[1].id=="rengoku_normal" and foe.bench[1].statuses.is_empty(),"Corps Intelligence AI chooses a replacement")
	game.current_side = 1
	me.active = _unit("tanjiro_normal")
	me.bench = [_unit("giyu_normal"),_unit("murata_normal")]
	foe.active = _unit("rengoku_normal")
	foe.bench = [_unit("yahaba_normal")]
	foe.support_used = false
	foe.hand = [DB.find_card("support_10")]
	expect(game._play_card(1,0) and game.paused and game.pending_utility_choice.effect=="foe_switch","AI Corps Intelligence asks the player to choose")
	game._resolve_utility_choice({"target":1})
	expect(me.active.id=="murata_normal" and me.bench[1].id=="tanjiro_normal","player chooses new Active Fighter")
	game.current_side = 0
	# Urokodaki chooses a Blue fighter, then attaches one Blue Energy per heads until tails.
	me.active = _unit("tanjiro_normal")
	me.bench = [_unit("giyu_normal")]
	me.support_used = false
	me.hand = [DB.find_card("support_6")]
	game.coin_flip_overrides = [true,true,false]
	expect(game._play_card(0,0) and game.paused and game.pending_utility_choice.effect=="blue_energy_loop","Urokodaki opens the Blue-fighter choice")
	game._resolve_utility_choice({"target":0})
	expect(me.bench[0].energy==["Blue","Blue"] and game.coin_flip_overrides.is_empty(),"Urokodaki attaches Blue Energy for each heads until tails")
	# Ubuyashiki draws exactly two cards.
	me.support_used = false
	me.hand = [DB.find_card("support_11")]
	me.deck = [DB.find_card("tanjiro_normal"),DB.find_card("giyu_normal"),DB.find_card("support_5")]
	expect(me.hand[0].text=="Draw 2 cards." and game._play_card(0,0) and me.hand.size()==2 and me.deck.size()==1,"Ubuyashiki's Guidance draws 2")
	# Hisa's Care removes all statuses from the active fighter.
	me.support_used = false
	me.active.statuses = ["Poison","Burn"]
	me.hand = [DB.find_card("support_5")]
	expect(me.hand[0].name=="Hisa's Care" and me.hand[0].text=="Remove all status conditions from your active fighter.","Hisa's Care name and text")
	expect(game._play_card(0,0) and me.active.statuses.is_empty(),"Hisa's Care clears all active statuses")
	# Kakushi Retrieval swaps a chosen hand Fighter for a random deck Fighter.
	me.hand = [DB.find_card("tanjiro_normal"),DB.find_card("support_18")]
	me.deck = [DB.find_card("giyu_surge"),DB.find_card("rengoku_normal"),DB.find_card("support_5")]
	game.rng.seed = 721
	expect(me.hand[1].kind=="Item" and game._play_card(0,1) and game.paused,"Kakushi Retrieval is an Item and opens a hand choice")
	game._resolve_utility_choice({"hand_index":0})
	var returned_hand_fighter := false
	for card in me.deck:
		if card.id=="tanjiro_normal": returned_hand_fighter=true
	expect(me.hand.size()==1 and me.hand[0].kind=="Fighter" and me.hand[0].id!="tanjiro_normal" and returned_hand_fighter,"Kakushi Retrieval exchanges the chosen card")
	# Swordsmith's Gift reveals the actual top card and may shuffle or retain its order.
	var peek_deck: Array = [DB.find_card("tanjiro_normal"),DB.find_card("giyu_normal"),DB.find_card("rengoku_normal"),DB.find_card("nezuko_normal"),DB.find_card("zenitsu_normal"),DB.find_card("support_5")]
	me.deck = peek_deck.duplicate()
	me.hand = [DB.find_card("support_9")]
	var known_top: String = str(me.deck[0].id)
	expect(game._play_card(0,0) and game.pending_utility_choice.top_card.id==known_top,"Swordsmith lets the player inspect the top card")
	game._resolve_utility_choice({"shuffle":false})
	expect(me.deck[0].id==known_top,"Swordsmith can keep the current deck order")
	game.rng.seed = 1907
	me.hand = [DB.find_card("support_9")]
	expect(game._play_card(0,0) and game.paused,"Swordsmith offers an optional shuffle")
	game._resolve_utility_choice({"shuffle":true})
	var shuffled_ids: Array = []
	for card in me.deck: shuffled_ids.append(str(card.id))
	expect(shuffled_ids!=["tanjiro_normal","giyu_normal","rengoku_normal","nezuko_normal","zenitsu_normal","support_5"],"Swordsmith can shuffle the deck")
	# Kakushi Stretcher and Tamayo's Remedy retain their requested effects.
	me.free_retreat = false
	me.active = _unit("giyu_surge")
	me.active.energy = ["Blue"]
	me.retreat_discount = 0
	expect(game._side_retreat_cost(0)==2 and not game._can_retreat(0),"SURGE retreat costs 2")
	me.hand = [DB.find_card("item_02")]
	expect(game._play_card(0,0) and game._side_retreat_cost(0)==1 and game._can_retreat(0),"Kakushi Stretcher lowers retreat cost by 1")
	me.retreat_discount = 0
	me.active.current_hp = 90
	me.active.statuses = ["Poison"]
	me.hand = [DB.find_card("support_3")]
	expect(me.hand[0].text=="Restore 20 HP to your active fighter.","Tamayo's Remedy displays the requested effect")
	expect(game._play_card(0,0) and me.active.current_hp==110 and me.active.statuses.has("Poison"),"Tamayo's Remedy heals 20 without clearing status")
	me.active = _unit("giyu_surge")
	me.active.energy = ["Blue"]
	me.retreat_discount = 0
	expect(game._side_retreat_cost(0)==2 and not game._can_retreat(0),"SURGE retreat costs 2")
	me.hand = [DB.find_card("item_02")]
	expect(game._play_card(0,0) and game._side_retreat_cost(0)==1 and game._can_retreat(0),"Kakushi Stretcher lowers retreat cost by 1")
	me.retreat_discount = 0
	me.active = _unit("giyu_surge")
	me.active.current_hp = 90
	me.active.statuses = ["Poison"]
	me.hand = [DB.find_card("support_3")]
	expect(me.hand[0].text=="Restore 20 HP to your active fighter.","Tamayo's Remedy displays the requested effect")
	expect(game._play_card(0,0) and me.active.current_hp==110 and me.active.statuses.has("Poison"),"Tamayo's Remedy heals 20 without clearing status")

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
	me.support_used = false
	me.hand = [DB.find_card("support_5")]
	expect(game._play_card(0,0),"curing Support resolves")
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
	game.first_side_override = 0
	game._start_battle()
	var end_turn_starters: Array = game._opening_fighter_indices(0)
	if not end_turn_starters.is_empty(): game._choose_opening_active(0,int(end_turn_starters[0]))
	await create_timer(1.0).timeout
	expect(game.battle_started,"second duel waits for opening choice before starting")
	game._end_turn_requested()
	await create_timer(0.1).timeout
	expect(game.current_side==1,"explicit End Turn changes side")
	game._go("home")
	game.free()
	await create_timer(0.9).timeout
	if failures.is_empty():
		print("[SMOKE_PASS] 51 cards (4 Support, 8 Item), revised utility effects, randomized first player, coin animation queue, opening Active choice, knockout bench replacement, first-turn Energy lock, second-own-turn Boost, standalone SURGE, retreat costs, status effects, GIF attack, auto/manual end turn")
		quit(0)
	else: quit(1)
