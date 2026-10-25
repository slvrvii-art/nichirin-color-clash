extends Control
## Lightweight game-specific boot with honest preparation and recovery.
const FONTS := preload("res://scripts/manus/game_fonts.gd")
@export_file("*.tscn") var target_scene := "res://scenes/card_game.tscn"
const LOAD_POLL_INTERVAL := 0.05
const LOAD_TIMEOUT_MSEC := 30000
var progress_bar: ProgressBar
var status_label: Label
var retry_button: Button
var load_poll_timer: Timer
var loading := false
var transitioning := false

func _ready() -> void:
	TranslationServer.set_locale("en")
	var bg := ColorRect.new()
	bg.color=Color("#0a111d")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var icon := TextureRect.new()
	icon.texture=load("res://assets/share/favicon.png") as Texture2D
	icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position=Vector2(656,270)
	icon.size=Vector2(128,128)
	add_child(icon)
	var title := Label.new()
	title.text="NICHIRIN: COLOR CLASH"
	title.position=Vector2(320,425)
	title.size=Vector2(800,60)
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",32)
	title.add_theme_color_override("font_color",Color("#e5c887"))
	add_child(title)
	status_label=Label.new()
	status_label.text="Preparing your armory…"
	status_label.position=Vector2(420,507)
	status_label.size=Vector2(600,40)
	status_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	add_child(status_label)
	progress_bar=ProgressBar.new()
	progress_bar.position=Vector2(470,570)
	progress_bar.size=Vector2(500,9)
	progress_bar.show_percentage=false
	progress_bar.indeterminate=true
	add_child(progress_bar)
	retry_button=Button.new()
	retry_button.text="Retry loading"
	retry_button.position=Vector2(570,610)
	retry_button.size=Vector2(300,44)
	retry_button.hide()
	retry_button.pressed.connect(_begin_loading)
	add_child(retry_button)
	load_poll_timer=Timer.new()
	load_poll_timer.one_shot=true
	load_poll_timer.wait_time=LOAD_POLL_INTERVAL
	add_child(load_poll_timer)
	_begin_loading()

func _begin_loading() -> void:
	if loading or transitioning: return
	loading=true
	retry_button.hide()
	progress_bar.show()
	progress_bar.indeterminate=true
	progress_bar.value=0.0
	status_label.text="Preparing your armory…"
	await get_tree().process_frame
	await get_tree().process_frame
	_enter_game.call_deferred()

func _enter_game() -> void:
	if not ResourceLoader.exists(target_scene):
		_fail()
		return
	transitioning=true
	progress_bar.indeterminate=false
	progress_bar.value=0.0
	status_label.text="Loading the game…"
	var load_started_msec := Time.get_ticks_msec()
	var status := ResourceLoader.load_threaded_get_status(target_scene)
	if status != ResourceLoader.THREAD_LOAD_LOADED and status != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		var request_error := ResourceLoader.load_threaded_request(target_scene,"PackedScene")
		if request_error != OK:
			status = ResourceLoader.load_threaded_get_status(target_scene)
			if status != ResourceLoader.THREAD_LOAD_IN_PROGRESS and status != ResourceLoader.THREAD_LOAD_LOADED:
				_fail()
				return
	var progress: Array = []
	while is_inside_tree():
		if Time.get_ticks_msec() - load_started_msec > LOAD_TIMEOUT_MSEC:
			_fail()
			return
		progress.clear()
		status = ResourceLoader.load_threaded_get_status(target_scene,progress)
		if not progress.is_empty():
			progress_bar.value=clampf(float(progress[0])*100.0,0.0,100.0)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var scene := ResourceLoader.load_threaded_get(target_scene) as PackedScene
			if scene == null or get_tree().change_scene_to_packed(scene) != OK:
				_fail()
			return
		if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_fail()
			return
		load_poll_timer.start()
		await load_poll_timer.timeout
	if is_inside_tree(): _fail()

func _fail() -> void:
	loading=false
	transitioning=false
	progress_bar.hide()
	progress_bar.indeterminate=true
	status_label.text="Unable to prepare the game. Please retry."
	retry_button.show()
