extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://scenes/card_game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.deck=CardDatabase.starter_deck()
	game.reduced_motion=true
	game.show_coin_flip_animations=false
	game._start_battle()
	var elapsed := 0.0
	var attacks := 0
	var completed := false
	while elapsed<75.0:
		await create_timer(0.05).timeout
		elapsed+=0.05
		if game.battle_over:
			completed=true
			break
		if game.opening_active_pending:
			var starters: Array = game._opening_fighter_indices(0)
			if not starters.is_empty(): game._choose_opening_active(0,int(starters[0]))
			continue
		if game.pending_replacement_side == 0:
			game._choose_replacement(0,0)
			continue
		if not game.pending_utility_choice.is_empty():
			var pending: Dictionary = game.pending_utility_choice.duplicate(true)
			var option: Dictionary = {}
			match str(pending.get("effect","")):
				"blue_energy_loop":
					var choices: Array = game._blue_fighter_options(int(pending.get("side",0)))
					if not choices.is_empty(): option=choices[0]
				"foe_switch": option={"target":0}
				"hand_swap":
					var fighter_indices: Array = game._hand_fighter_indices(int(pending.get("side",0)))
					if not fighter_indices.is_empty(): option={"hand_index":int(fighter_indices[0])}
				"peek_shuffle": option={"shuffle":false}
			game._resolve_utility_choice(option)
			continue
		if not game._can_act(0): continue
		var me: Dictionary = game.sides[0]
		for i in range(me.hand.size()-1,-1,-1):
			if me.hand[i].kind=="Fighter" and me.bench.size()<3: game._play_card(0,i)
		for i in range(me.hand.size()):
			if me.hand[i].kind=="Support" and not me.support_used:
				game._play_card(0,i)
				break
		game._attach_energy(0,-1)
		game._render()
		var index := -1
		for i in range(me.active.attacks.size()):
			if game._attack_legal(0,i): index=i
		if index>=0:
			attacks+=1
			game._player_attack(index)
		else: game._end_turn_requested()
	print("[MATCH_RESULT] complete=%s turns=%d player_attacks=%d score=%d:%d animations=%d:%d:%d" % [completed,game.turn_number,attacks,game.sides[0].points,game.sides[1].points,game.attack_animations,game.damage_animations,game.turn_animations])
	var ok: bool = completed and attacks>0 and (game.sides[0].points>=3 or game.sides[1].points>=3 or game.sides[0].active.is_empty() or game.sides[1].active.is_empty())
	game._go("home")
	game._start_battle()
	ok=ok and not game.battle_over and game.turn_number==1
	game._go("home")
	game.free()
	await create_timer(0.2).timeout
	quit(0 if ok else 1)
