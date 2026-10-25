extends SceneTree

const DB := preload("res://scripts/card_database.gd")
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("[ADD_TO_DECK_FAIL] " + message)


func _visible_add_button(game: Variant, visible_index: int) -> Button:
	var button_index := 0
	for node in game.root_ui.find_children("*", "Button", true, false):
		var button := node as Button
		if button.text.begins_with("+ ADD  "):
			if button_index == visible_index:
				return button
			button_index += 1
	return null


func _run() -> void:
	var game = load("res://scenes/card_game.tscn").instantiate()
	root.add_child(game)
	await process_frame

	game.deck = DB.starter_deck()
	game.deck.pop_back()
	game.page = 0
	game.screen_name = "deck"
	game._render()

	var filtered: Array[Dictionary] = game._filtered()
	var target_index := -1
	var target_id := ""
	for i in range(mini(10, filtered.size())):
		var candidate_id := str(filtered[i].id)
		if game.deck.count(candidate_id) < 2:
			target_index = i
			target_id = candidate_id
			break

	var collection_button: Button = null
	if target_index >= 0:
		collection_button = _visible_add_button(game, target_index)
	_expect(target_index >= 0 and is_instance_valid(collection_button), "deck builder renders an available Add to Deck button")
	var collection_count_before: int = int(game.deck.count(target_id))
	if is_instance_valid(collection_button):
		collection_button.pressed.emit()
	await process_frame
	_expect(game.deck.size() == 20 and game.deck.count(target_id) == collection_count_before + 1, "collection Add to Deck callback adds exactly one card and keeps the deck limit")

	game.deck = DB.starter_deck()
	game.deck.pop_back()
	var detail_id := ""
	for card: Dictionary in DB.catalog():
		var candidate_id := str(card.id)
		if game.deck.count(candidate_id) < 2:
			detail_id = candidate_id
			break
	game._card_detail(detail_id)
	var detail_button: Button = null
	for node in game.find_children("*", "Button", true, false):
		var button := node as Button
		if button.text == "+ ADD TO DECK":
			detail_button = button
			break
	_expect(not detail_id.is_empty() and is_instance_valid(detail_button), "card detail opens with its Add to Deck action")
	var detail_count_before: int = int(game.deck.count(detail_id))
	if is_instance_valid(detail_button):
		detail_button.pressed.emit()
	await process_frame
	_expect(game.deck.size() == 20 and game.deck.count(detail_id) == detail_count_before + 1, "detail-view Add to Deck callback closes the modal and adds exactly one card")

	game.free()
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("[ADD_TO_DECK_PASS] collection and detail actions invoke void handlers and preserve deck limits")
		quit(0)
	else:
		quit(1)
