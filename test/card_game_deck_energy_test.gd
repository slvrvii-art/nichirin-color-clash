extends SceneTree

const CARD_GAME := preload("res://scripts/card_game.gd")
const DB := preload("res://scripts/card_database.gd")
const ATOMIC_JSON := preload("res://scripts/atomic_json_file.gd")
const TEST_SAVE := "user://card_game_deck_energy_test.json"

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("[DECK_ENERGY_FAIL] " + message)

func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _cleanup() -> void:
	for path in [TEST_SAVE, TEST_SAVE + ATOMIC_JSON.BACKUP_SUFFIX, TEST_SAVE + ATOMIC_JSON.TEMPORARY_SUFFIX]:
		_remove(path)

func _run() -> void:
	_cleanup()
	var game = load("res://scenes/card_game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._save_path = TEST_SAVE
	game.reduced_motion = true
	game.show_coin_flip_animations = false
	game.show_energy_animations = false
	game.deck = DB.starter_deck()
	game.deck_profiles.clear()
	game.deck_profiles.append({"name":"Deck 1","cards":game.deck.duplicate(),"energy_types":["Blue"]})
	game.current_deck_index = 0
	game.deck_energy_types = ["Blue"]

	_expect(game._create_deck_profile(), "a second deck profile can be created")
	_expect(game.deck_profiles.size() == 2, "deck creation adds an independent profile")
	_expect(game._toggle_deck_energy_type("Red"), "a second Color Energy type can be selected")
	_expect(game._toggle_deck_energy_type("Yellow"), "a third Color Energy type can be selected")
	_expect(not game._toggle_deck_energy_type("Green"), "a fourth Energy type is rejected")
	_expect(game.deck_energy_types.size() == 3, "each deck's Energy pool is capped at three")
	_expect(game._select_deck_profile(0, false), "the first deck profile can be selected")
	_expect(game.deck_energy_types == ["Blue"], "Energy selection remains independent on Deck 1")
	_expect(game._select_deck_profile(1, false), "the second deck profile can be selected")
	_expect(game.deck_energy_types.size() == 3 and game.deck_energy_types.has("Red") and game.deck_energy_types.has("Yellow"), "Deck 2 retains its own selected Energy colors")
	for i in range(8):
		_expect(game._create_deck_profile(), "deck profile %d of 10 can be created" % (i + 3))
	_expect(game.deck_profiles.size() == 10, "the profile collection supports ten decks")
	_expect(not game._create_deck_profile(), "an eleventh deck profile is rejected")
	game._persist_save()
	game._load_save()
	_expect(game.deck_profiles.size() == 10, "all ten deck profiles survive a local save reload")
	_expect(game.deck_energy_types.size() == 3, "the selected deck Energy pool survives save reload")
	game.screen_name = "deck"
	game._render()
	var selector_node: Node = game.root_ui.find_child("DeckProfileSelector", true, false)
	var profile_selector: OptionButton = selector_node as OptionButton
	_expect(profile_selector != null and profile_selector.item_count == 10, "deck builder presents all ten profiles in its selector")
	var energy_controls_present := true
	for color in DB.COLORS.keys():
		var color_name: String = str(color).replace(" ", "_")
		if not game.root_ui.find_child("DeckEnergy_" + color_name, true, false) is Button:
			energy_controls_present = false
	_expect(energy_controls_present, "deck builder exposes a selectable control for every Color Energy type")
	var new_button: Button = game.root_ui.find_child("NewDeckButton", true, false) as Button
	_expect(new_button != null and new_button.disabled, "New Deck is disabled at the ten-deck limit")

	var white_card: Dictionary = {}
	for card in DB.catalog():
		if str(card.get("kind", "")) != "Fighter" or str(card.get("color", "")) != "White":
			continue
		for attack in card.get("attacks", []):
			if int(attack.get("cost", 0)) > 0:
				white_card = DB.find_card(str(card.id))
				break
		if not white_card.is_empty():
			break
	_expect(not white_card.is_empty(), "catalog contains a White fighter with a nonzero attack cost")
	if not white_card.is_empty():
		var white_unit: Dictionary = game._make_unit(str(white_card.id))
		var white_attack: Dictionary = white_unit.attacks[0]
		white_unit.energy.clear()
		for i in range(int(white_attack.cost)):
			white_unit.energy.append("Red" if i % 2 == 0 else "Blue")
		game.sides.clear()
		var player_side: Dictionary = game._new_side(DB.starter_deck(), ["Red", "Yellow"])
		var rival_side: Dictionary = game._new_side(DB.enemy_deck(), ["Blue"])
		player_side.active = white_unit
		rival_side.active = game._make_unit("giyu_normal")
		game.sides.append(player_side)
		game.sides.append(rival_side)
		game.current_side = 0
		game.screen_name = "battle"
		game.battle_started = true
		game.battle_over = false
		game.busy = false
		game.turn_number = 2
		_expect(game._attack_legal(0, 0), "White attack accepts enough Energy of any colors")
		_expect(game._cost_text("White", white_attack).contains("COLORLESS"), "White attack cost is presented as colorless")
		var retreat_cost: int = game._retreat_cost(white_unit)
		white_unit.energy.clear()
		for i in range(retreat_cost):
			white_unit.energy.append("Red" if i % 2 == 0 else "Yellow")
		player_side.bench.append(game._make_unit("tanjiro_normal"))
		game.sides[0] = player_side
		_expect(game._can_retreat(0), "White fighter retreat accepts any attached Energy colors")
		var replacement_id: String = str(game.sides[0].bench[0].id)
		_expect(game._retreat(0, 0), "White fighter can retreat after paying its any-color cost")
		_expect(str(game.sides[0].active.id) == replacement_id and game.sides[0].bench[0].energy.is_empty(), "retreat spends the White fighter's required Energy and switches Active")

	var pool_side: Dictionary = game._new_side(DB.starter_deck(), ["Red", "Yellow"])
	pool_side.active = game._make_unit("tanjiro_normal")
	game.sides[0] = pool_side
	game.sides[1] = game._new_side(DB.enemy_deck(), ["Blue"])
	game.sides[1].active = game._make_unit("giyu_normal")
	game.show_energy_animations = true
	game.show_coin_flip_animations = false
	game.screen_name = "battle"
	game.battle_started = true
	game.battle_over = false
	game.current_side = 0
	game.turn_number = 2
	game.busy = false
	game._begin_turn(0)
	_expect(game.sides[0].energy_color in ["Red", "Yellow"], "turn Energy is selected only from the deck's configured pool")
	game._render()
	var completed_before: int = game.energy_animations_completed
	var enqueued_before: int = game.energy_animations_enqueued
	_expect(game._grant_energy_to_unit(0, -1, "Red"), "an Energy grant can target an Active fighter")
	_expect(game.sides[0].active.energy.has("Red"), "the granted Energy is attached to the fighter")
	_expect(game.energy_animations_enqueued == enqueued_before + 1, "an attached Energy queues a flight animation")
	var flight_wait := 0.0
	while flight_wait < 2.0 and (game.energy_animation_running or not game.energy_animation_queue.is_empty() or game.energy_animations_completed == completed_before):
		await create_timer(0.025).timeout
		flight_wait += 0.025
	_expect(game.energy_animations_completed == completed_before + 1, "the Energy flight completes and cleans up")

	var attacker: Dictionary = game._make_unit("giyu_normal")
	var attack: Dictionary = attacker.attacks[0]
	for i in range(int(attack.cost)):
		attacker.energy.append(str(attacker.color))
	attacker.statuses = ["Paralysis"]
	game.sides[0].active = game._make_unit("tanjiro_normal")
	game.sides[1].active = attacker
	game.current_side = 1
	game.turn_number = 3
	game.show_coin_flip_animations = true
	game.show_energy_animations = false
	game.show_card_play_animations = false
	game.coin_animation_queue.clear()
	game.coin_animation_running = false
	game.coin_flip_overrides = [true]
	game.attack_coin_wait_count = 0
	game.attack_gif_animations = 0
	game.coin_flip_animations = 0
	game._render()
	_expect(game._attack_legal(1, 0), "the test attacker has enough matching Energy before Paralysis")
	game._animated_attack(1, 0)
	await process_frame
	_expect(game.attack_gif_animations == 0 and game.attack_coin_wait_count == 1, "the slash remains queued while the coin flip is playing")
	var attack_wait := 0.0
	while attack_wait < 6.0 and game.busy:
		await create_timer(0.025).timeout
		attack_wait += 0.025
	_expect(game.coin_flip_animations == 1, "the paralysis coin animation completes once")
	_expect(game.attack_gif_animations == 1, "the attack slash plays after the coin overlay finishes")

	game._go("home")
	game.free()
	await create_timer(0.25).timeout
	_cleanup()
	if failures.is_empty():
		print("[DECK_ENERGY_PASS] deck profiles, Energy pools, White colorless payment, Energy-flight, and coin/attack ordering")
		quit(0)
	else:
		print("[DECK_ENERGY_FAIL] %d assertion(s) failed" % failures.size())
		quit(1)
