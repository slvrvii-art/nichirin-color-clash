extends SceneTree
var game: Node
func _initialize() -> void:
	call_deferred("run")
func capture(name: String) -> void:
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	await process_frame
	root.get_texture().get_image().save_png("/tmp/nichirin-"+name+".png")
	print("[NATIVE_CAPTURE] "+name)
func run() -> void:
	game=load("res://scenes/card_game.tscn").instantiate()
	root.add_child(game)
	await create_timer(0.15).timeout
	await capture("home")
	game._go("collection")
	await capture("collection")
	game._go("deck")
	await capture("deck")
	game.deck=CardDatabase.starter_deck()
	game.first_side_override=0
	game.show_coin_flip_animations=true
	game.reduced_motion=true
	game._start_battle()
	await create_timer(0.2).timeout
	await capture("battle-opening-choice")
	var starters: Array = game._opening_fighter_indices(0)
	if not starters.is_empty(): game._choose_opening_active(0,int(starters[0]))
	await create_timer(0.75).timeout
	for i in range(game.sides[0].hand.size()-1,-1,-1):
		if game.sides[0].hand[i].kind=="Fighter": game._play_card(0,i)
	game._render()
	await capture("battle")
	game._flip_coin()
	await create_timer(0.22).timeout
	await capture("coin")
	await create_timer(0.55).timeout
	game._go("home")
	game.free()
	await create_timer(0.1).timeout
	quit()
