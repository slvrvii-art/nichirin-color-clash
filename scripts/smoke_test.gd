extends SceneTree
const DB := preload("res://scripts/card_database.gd")
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("[SMOKE_FAIL] "+message)
func _run() -> void:
	var catalog := DB.catalog()
	expect(catalog.size()==162,"162-card catalog")
	var ids := {}
	for card in catalog:
		ids[card.id]=true
		expect(card.kind in ["Fighter","Support"],"renamed card categories")
		expect(DB.COLORS.has(card.color),"valid Color Type")
	expect(ids.size()==162,"all catalog IDs distinct")
	expect(DB.validate_deck(DB.starter_deck())=="","valid 20-card starter")
	var oversized := DB.starter_deck()
	oversized.append("support_3")
	expect(DB.validate_deck(oversized)!="","21 cards rejected")
	var game = load("res://scenes/card_game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	expect(game.screen_name=="home","boots to game hub")
	game.deck=DB.starter_deck()
	game._start_battle()
	await create_timer(0.9).timeout
	expect(game.sides.size()==2 and not game.sides[0].active.is_empty(),"one opening active per player")
	expect(not game._attack_legal(0,0),"attack requires matching Color Energy")
	expect(game._attach_energy(0,-1),"attach generated Color Energy")
	expect(not game._attach_energy(0,-1),"second attachment disallowed")
	expect(game._attack_legal(0,0),"matching Color Energy enables attack")
	game._draw_cards(0,10)
	var me: Dictionary = game.sides[0]
	for i in range(me.hand.size()-1,-1,-1):
		if me.hand[i].kind=="Fighter": game._play_card(0,i)
	expect(me.bench.size()==3,"exactly three bench capacity")
	var extra_index := -1
	for i in range(me.hand.size()):
		if me.hand[i].kind=="Fighter": extra_index=i; break
	if extra_index>=0: expect(not game._play_card(0,extra_index),"fourth bench rejected")
	var support_index := -1
	for i in range(me.hand.size()):
		if me.hand[i].kind=="Support": support_index=i; break
	if support_index>=0:
		expect(game._play_card(0,support_index),"Support resolves")
		expect(me.support_used,"Support limited to once per turn")
	game._render()
	var hp_before: int = game.sides[1].active.current_hp
	game._player_attack(0)
	await create_timer(1.15).timeout
	expect(game.sides[1].active.current_hp<hp_before,"actual active attack damages opponent")
	expect(game.current_side==1,"attack automatically ends player turn")
	expect(game.attack_animations>=1 and game.damage_animations>=1 and game.turn_animations>=2,"attack damage and turn animations triggered")
	game._go("home")
	await create_timer(0.9).timeout
	expect(game.screen_name=="home","leaving cancels queued opponent actions")
	game._start_battle()
	await create_timer(0.9).timeout
	game._end_turn_requested()
	await create_timer(0.1).timeout
	expect(game.current_side==1,"explicit End Turn changes side")
	game._pause_menu()
	expect(game.paused,"pause state active")
	game._close_modal()
	expect(not game.paused,"resume releases pause")
	game._go("home")
	game.free()
	await create_timer(0.9).timeout
	if failures.is_empty():
		print("[SMOKE_PASS] catalog, decks, active/bench, Color Energy, Support, damage, attack auto-end, manual end, pause and replay")
		quit(0)
	else: quit(1)
