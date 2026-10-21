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
	game._start_battle()
	await create_timer(0.95).timeout
	for i in range(game.sides[0].hand.size()-1,-1,-1):
		if game.sides[0].hand[i].kind=="Fighter": game._play_card(0,i)
	game._attach_energy(0,-1)
	game._render()
	await capture("battle")
	game._go("home")
	game.free()
	await create_timer(0.1).timeout
	quit()
