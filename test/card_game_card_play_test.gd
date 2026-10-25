extends SceneTree

var game
var failures: Array[String] = []
var shown: Array[String] = []
var active_reveals := 0
var max_active_reveals := 0

func _initialize() -> void:
	call_deferred("_run")

func _expect(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error("[CARD_PLAY_FAIL] " + message)

func _wait_until(condition: Callable, timeout: float = 4.0) -> bool:
	var deadline := Time.get_ticks_usec() + int(timeout * 1000000.0)
	while not condition.call() and Time.get_ticks_usec() < deadline:
		await process_frame
	return bool(condition.call())

func _duel(side: int = 0) -> void:
	game._go("home")
	game.screen_name = "battle"
	game.battle_over = false
	game.battle_started = true
	game.opening_active_pending = false
	game.current_side = side
	game.turn_number = 3
	game.busy = false
	game.paused = false
	game.show_coin_flip_animations = false
	game.show_energy_animations = false
	var side_states: Array[Dictionary] = [game._new_side(game.deck,["Blue"]),game._new_side(game.deck,["Red"])]
	game.sides = side_states
	for i in range(2):
		game.sides[i].hand = []
		game.sides[i].deck = []
		game.sides[i].bench = []
		game.sides[i].turns_taken = 2
		game.sides[i].energy_ready = false
	game.sides[0].active = game._make_unit("giyu_normal")
	game.sides[1].active = game._make_unit("rengoku_normal")
	game._render()

func _press(text: String) -> bool:
	for node in game.root_ui.find_children("*","Button",true,false):
		var button := node as Button
		if button.text == text and not button.disabled:
			button.pressed.emit()
			return true
	return false

func _hover_count(expected: int) -> void:
	var hover: Control = game.root_ui.find_child("OpponentHandHover",true,false)
	_expect(hover != null,"opponent hand hover target exists even when empty")
	if hover == null: return
	hover.mouse_entered.emit()
	_expect(game.opponent_hand_count_label.visible and game.opponent_hand_count_label.text.begins_with(str(expected)+" CARD"),"hover shows actual hand count %d" % expected)
	_expect(hover.get_signal_connection_list("mouse_entered").size() == 1,"pooled hand has one current hover handler")
	hover.mouse_exited.emit()
	_expect(not game.opponent_hand_count_label.visible,"hand count hides on hover exit")

func _run() -> void:
	game = load("res://scenes/card_game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.card_play_overlay.presentation_started.connect(func(id: String):
		shown.append(id)
		active_reveals += 1
		max_active_reveals = maxi(max_active_reveals,active_reveals))
	game.card_play_overlay.presentation_finished.connect(func(_id: String): active_reveals -= 1)
	_duel()
	game.sides[0].hand = [CardDatabase.find_card("support_11")]
	game.sides[0].deck = [CardDatabase.find_card("murata_normal"),CardDatabase.find_card("zenitsu_normal")]
	game.sides[1].hand = [CardDatabase.find_card("support_3")]
	game.selected_hand = 0
	game._render()
	_hover_count(1)
	var hand_target: Control = game.root_ui.find_child("OpponentHandHover",true,false)
	var motion := InputEventMouseMotion.new()
	motion.position = hand_target.get_global_transform_with_canvas() * Vector2(18,18)
	motion.global_position = motion.position
	motion.relative = Vector2.ONE
	game.get_viewport().push_input(motion,true)
	await process_frame
	await process_frame
	_expect(game.opponent_hand_count_label.visible,"actual pointer movement over the card backs shows the hand count")
	_expect(_press("USE SUPPORT"),"actual Support button starts the reveal")
	await process_frame
	_expect(game.card_reveal_running and game.card_play_overlay.playing,"card appears enlarged before Support effects")
	_expect(game.sides[0].hand.size() == 1 and game.sides[0].deck.size() == 2 and not game.sides[0].support_used,"draw and Support-use state do not resolve during popup")
	var attacks_before: int = game.attack_animations
	game._player_attack(0)
	_expect(game.attack_animations == attacks_before,"an attack cannot overlap a card-use popup")
	if OS.get_cmdline_user_args().has("--capture-reveal"):
		await create_timer(0.20).timeout
		await RenderingServer.frame_post_draw
		var image: Image = game.get_viewport().get_texture().get_image()
		_expect(image.save_png("/tmp/nichirin-card-popup.png") == OK,"real renderer writes the reveal frame")
	_expect(await _wait_until(func(): return not game.card_action_running),"Support reveal/effect action completes")
	_expect(game.sides[0].hand.size() == 2 and game.sides[0].deck.is_empty() and game.sides[0].support_used,"Support draws two cards only after reveal")
	game.reduced_motion = true

	# Reused hover target: count is actual size, not the five visible card backs.
	for count in [8,0,1]:
		game.sides[1].hand.clear()
		for i in range(count): game.sides[1].hand.append(CardDatabase.find_card("murata_normal"))
		game._render()
		_hover_count(count)

	# Boost is also reserved until the real enlarged SURGE card has cleared.
	_duel()
	game.sides[0].active.played_turn = 0
	game.sides[0].hand = [game._make_unit("giyu_surge")]
	game.selected_hand = 0
	game._render()
	_expect(_press("BOOST ACTIVE"),"actual Boost button starts a SURGE reveal")
	await process_frame
	_expect(game.card_reveal_running and game.sides[0].active.id == "giyu_normal" and game.pending_boost_flash == "","Boost/flash waits for the SURGE popup")
	_expect(await _wait_until(func(): return not game.card_action_running),"Boost completes")
	_expect(game.sides[0].active.id == "giyu_surge","SURGE enters play after its reveal")

	# A targeting ability does not move the opponent's card during its reveal.
	_duel()
	game.sides[0].active = game._make_unit("kyogai_surge")
	game.sides[1].bench = [game._make_unit("murata_normal")]
	game.sides[1].bench[0].current_hp = 40
	game._render()
	game._begin_ability_targeting(0,-1)
	game._board_clicked(1,0)
	await process_frame
	_expect(game.card_reveal_running and game.sides[1].active.id == "rengoku_normal" and not game.sides[0].active.ability_used,"Rapid Drumming waits for its card reveal")
	_expect(await _wait_until(func(): return not game.card_action_running),"ability reveal completes")
	_expect(game.sides[1].active.id == "murata_normal" and game.sides[0].active.ability_used,"ability moves the target after reveal")

	# Attack order is reveal, Paralysis coin, slash, then damage.
	_duel()
	game.sides[0].active.energy = ["Blue","Blue","Blue"]
	game.sides[0].active.statuses = ["Paralysis"]
	game.show_coin_flip_animations = true
	game.coin_flip_overrides = [true]
	game._render()
	var coin_before: int = game.coin_flip_events
	var slash_before: int = game.attack_gif_animations
	var hp_before: int = game.sides[1].active.current_hp
	game._player_attack(0)
	await process_frame
	_expect(game.card_reveal_running and game.coin_flip_events == coin_before and game.attack_gif_animations == slash_before and game.sides[1].active.current_hp == hp_before,"attack coin, slash and damage wait for the popup")
	_expect(await _wait_until(func(): return game.coin_animation_running),"Paralysis coin begins after reveal")
	_expect(not game.card_reveal_running and game.attack_gif_animations == slash_before,"coin clears before slash")
	_expect(await _wait_until(func(): return game.sides[1].active.current_hp < hp_before),"attack damage resolves after slash")
	game._go("home")
	await create_timer(0.25).timeout

	# Energy-generating Items reveal before flipping and showing the Energy flight.
	_duel()
	game.sides[0].hand = [CardDatabase.find_card("support_2")]
	game.show_coin_flip_animations = true
	game.show_energy_animations = true
	game.coin_flip_overrides = [true]
	game.selected_hand = 0
	game._render()
	var generated_before: int = game.energy_animations_enqueued
	var flights_before: int = game.energy_animations_completed
	coin_before = game.coin_flip_events
	_expect(_press("USE ITEM"),"Recovery Breathing starts its reveal")
	await process_frame
	_expect(game.card_reveal_running and game.sides[0].active.energy.is_empty() and game.coin_flip_events == coin_before and game.energy_animations_enqueued == generated_before,"coin and Energy generation wait for the Item popup")
	_expect(await _wait_until(func(): return game.coin_animation_running),"Energy Item flips after reveal")
	_expect(not game.card_reveal_running and game.energy_animations_completed == flights_before,"Energy flight waits behind the coin")
	_expect(await _wait_until(func(): return not game.card_action_running),"Energy Item completes without deadlock")
	_expect(game.sides[0].active.energy.size() == 1 and game.energy_animations_completed == flights_before + 1,"Energy flight and grant complete after the reveal and coin")

	# The actual rival turn awaits every reveal instead of dumping all plays at once.
	_duel(1)
	game.sides[1].hand = [game._make_unit("murata_normal"),CardDatabase.find_card("item_02"),CardDatabase.find_card("support_11")]
	game.sides[1].deck = [CardDatabase.find_card("zenitsu_normal"),CardDatabase.find_card("giyu_normal")]
	game._render()
	var reveals_before: int = game.card_reveals_completed
	game._ai_turn(game.generation)
	_expect(await _wait_until(func(): return game.current_side == 0 and not game.busy,6.0),"rival turn completes without reveal deadlock")
	_expect(game.card_reveals_completed == reveals_before + 3 and max_active_reveals == 1,"rival fighter, Support and Item reveal sequentially")
	_expect(game.sides[1].bench.size() == 1 and game.sides[1].hand.size() == 2,"rival plays and draws finish correctly")
	_hover_count(2)

	# Leaving during a popup must not apply the reserved card to the departed duel.
	_duel()
	game.sides[0].hand = [CardDatabase.find_card("item_02")]
	var departed_side: Dictionary = game.sides[0]
	game.selected_hand = 0
	game._render()
	_expect(_press("USE ITEM"),"Item starts a cancellable reveal")
	await process_frame
	game._go("home")
	await create_timer(0.5).timeout
	_expect(not game.card_play_overlay.playing and not game.card_action_running and departed_side.hand.size() == 1 and int(departed_side.get("retreat_discount",0)) == 0,"cancelled reveal neither hangs nor applies stale effects")
	game.free()
	await create_timer(0.25).timeout
	print("[CARD_PLAY_RESULT] %d reveals; %d failures" % [shown.size(),failures.size()])
	quit(0 if failures.is_empty() else 1)
