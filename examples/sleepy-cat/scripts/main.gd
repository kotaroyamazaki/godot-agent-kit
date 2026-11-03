extends Control
## Sleepy Cat: a tiny game that is unclear on purpose. It exists to show what a blind playtest finds.
##
## Keep the cat fed for GOAL_SEC seconds. By default the game hides almost everything a new player needs
## (the plain version). Launch with `-- --clear` for the version that applies what the playtest report said.

const HUNGER_PER_SEC := 0.05
const FEED_AMOUNT := 0.4
const GOAL_SEC := 30.0

var clear: bool = false
var hunger: float = 0.1
var elapsed: float = 0.0
var state: String = "play"  # card | play | lost | won
var _lost_for: float = 0.0

var _bg: ColorRect
var _cat: Control
var _bar_bg: ColorRect
var _bar_fill: ColorRect
var _time_label: Label
var _msg: Label
var _feed_label: Label
var _feed_button: Button
var _card: Panel
var _pulse: Tween


func _ready() -> void:
	clear = "--clear" in OS.get_cmdline_user_args()
	_build()
	get_viewport().size_changed.connect(_layout)
	_layout()
	if clear:
		state = "card"
		_card.visible = true


func _build() -> void:
	_bg = ColorRect.new()
	_bg.color = Color(0.13, 0.12, 0.17)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	_cat = Control.new()
	_cat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cat.draw.connect(_draw_cat)
	add_child(_cat)

	_msg = Label.new()
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg.add_theme_font_size_override("font_size", 40)
	_msg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_msg)

	if clear:
		_bar_bg = ColorRect.new()
		_bar_bg.color = Color(0.25, 0.24, 0.3)
		_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_bar_bg)
		_bar_fill = ColorRect.new()
		_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bar_bg.add_child(_bar_fill)
		_time_label = Label.new()
		_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_time_label.add_theme_font_size_override("font_size", 32)
		_time_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_time_label)
		_feed_button = Button.new()
		_feed_button.text = "FEED FISH"
		_feed_button.add_theme_font_size_override("font_size", 44)
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.95, 0.55, 0.2)
		box.set_corner_radius_all(28)
		box.border_color = Color(1.0, 0.85, 0.5)
		box.set_border_width_all(6)
		for style_name in ["normal", "hover", "pressed", "focus"]:
			_feed_button.add_theme_stylebox_override(style_name, box)
		_feed_button.pressed.connect(_feed)
		add_child(_feed_button)
		_build_card()
	else:
		_feed_label = Label.new()
		_feed_label.text = "fish"
		_feed_label.add_theme_font_size_override("font_size", 30)
		_feed_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
		_feed_label.mouse_filter = Control.MOUSE_FILTER_STOP
		_feed_label.gui_input.connect(_on_label_input)
		add_child(_feed_label)


func _build_card() -> void:
	_card = Panel.new()
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.2, 0.19, 0.27)
	box.set_corner_radius_all(24)
	_card.add_theme_stylebox_override("panel", box)
	var title := Label.new()
	title.name = "Text"
	title.text = "How to play\n\nKeep the cat fed for 30 seconds.\nThe bar at the top shows how hungry it is.\nWhen the bar turns red, tap FEED FISH."
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 34)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(title)
	var ok := Button.new()
	ok.name = "Ok"
	ok.text = "OK"
	ok.add_theme_font_size_override("font_size", 40)
	ok.pressed.connect(_close_card)
	_card.add_child(ok)
	_card.visible = false
	add_child(_card)


func _layout() -> void:
	var s := get_viewport_rect().size
	_bg.size = s
	_cat.size = s
	_cat.pivot_offset = Vector2(s.x * 0.5, s.y * 0.42)
	_msg.position = Vector2(0, s.y * 0.68)
	_msg.size = Vector2(s.x, 120)
	if clear:
		_bar_bg.position = Vector2(s.x * 0.1, s.y * 0.07)
		_bar_bg.size = Vector2(s.x * 0.8, 40)
		_time_label.position = Vector2(0, s.y * 0.07 + 54)
		_time_label.size = Vector2(s.x, 50)
		_feed_button.size = Vector2(s.x * 0.7, 130)
		_feed_button.position = Vector2(s.x * 0.15, s.y * 0.82)
		_feed_button.pivot_offset = _feed_button.size * 0.5
		_card.size = Vector2(s.x * 0.84, 560)
		_card.position = Vector2(s.x * 0.08, s.y * 0.25)
		var text: Label = _card.get_node("Text")
		text.position = Vector2(30, 40)
		text.size = Vector2(_card.size.x - 60, 360)
		var ok: Button = _card.get_node("Ok")
		ok.size = Vector2(240, 90)
		ok.position = Vector2((_card.size.x - 240) * 0.5, 440)
	else:
		_feed_label.position = Vector2(s.x * 0.08, s.y * 0.93)
		_feed_label.size = Vector2(90, 44)
	_cat.queue_redraw()


func _draw_cat() -> void:
	var s := get_viewport_rect().size
	var c := Vector2(s.x * 0.5, s.y * 0.42)
	var r := minf(s.x * 0.26, 190.0)
	var fur := Color(0.78, 0.7, 0.62)
	var dark := Color(0.1, 0.1, 0.12)
	for sx in [-1.0, 1.0]:
		_cat.draw_colored_polygon(PackedVector2Array([
			c + Vector2(sx * r * 0.95, -r * 0.2),
			c + Vector2(sx * r * 0.8, -r * 1.25),
			c + Vector2(sx * r * 0.2, -r * 0.85)]), fur)
	_cat.draw_circle(c, r, fur)
	var eye_y := c.y - r * 0.1
	for sx in [-1.0, 1.0]:
		var ex: float = c.x + sx * r * 0.42
		if hunger < 0.7:
			_cat.draw_circle(Vector2(ex, eye_y), r * 0.1, dark)
		else:
			_cat.draw_line(Vector2(ex - r * 0.14, eye_y - r * 0.03 * sx), Vector2(ex + r * 0.14, eye_y + r * 0.03 * sx), dark, 7.0)
	_cat.draw_colored_polygon(PackedVector2Array([
		c + Vector2(-r * 0.08, r * 0.18), c + Vector2(r * 0.08, r * 0.18), c + Vector2(0, r * 0.3)]), Color(0.9, 0.55, 0.6))
	_cat.draw_line(c + Vector2(0, r * 0.3), c + Vector2(-r * 0.15, r * 0.42), dark, 4.0)
	_cat.draw_line(c + Vector2(0, r * 0.3), c + Vector2(r * 0.15, r * 0.42), dark, 4.0)


func _process(delta: float) -> void:
	if state == "play":
		elapsed += delta
		hunger = minf(1.0, hunger + HUNGER_PER_SEC * delta)
		if hunger >= 1.0:
			_end("lost")
		elif elapsed >= GOAL_SEC:
			_end("won")
	elif state == "lost":
		_lost_for += delta
		if not clear and _lost_for > 3.0:
			_restart()
	if clear:
		var w: float = _bar_bg.size.x
		_bar_fill.size = Vector2(w * hunger, _bar_bg.size.y)
		_bar_fill.color = Color(0.3, 0.8, 0.4).lerp(Color(0.9, 0.2, 0.2), clampf((hunger - 0.4) / 0.5, 0.0, 1.0))
		_time_label.text = "%d / %d s" % [int(elapsed), int(GOAL_SEC)]
		_set_pulse(state == "play" and hunger > 0.6)
	_cat.queue_redraw()


func _set_pulse(on: bool) -> void:
	if on and _pulse == null:
		_pulse = create_tween().set_loops()
		_pulse.tween_property(_feed_button, "scale", Vector2(1.07, 1.07), 0.35)
		_pulse.tween_property(_feed_button, "scale", Vector2.ONE, 0.35)
	elif not on and _pulse != null:
		_pulse.kill()
		_pulse = null
		_feed_button.scale = Vector2.ONE


func _on_label_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_feed()


func _feed() -> void:
	if state != "play":
		return
	hunger = maxf(0.0, hunger - FEED_AMOUNT)
	if clear:
		var t := create_tween()
		t.tween_property(_cat, "scale", Vector2(1.1, 1.1), 0.08)
		t.tween_property(_cat, "scale", Vector2.ONE, 0.18)


func _close_card() -> void:
	_card.visible = false
	state = "play"


func _end(result: String) -> void:
	state = result
	_lost_for = 0.0
	if result == "lost":
		_msg.text = "The cat left.\nTap to try again." if clear else "The cat left."
	else:
		_msg.text = "The cat stays!\nYou fed it for %d seconds." % int(GOAL_SEC) if clear else "zzz..."


func _restart() -> void:
	hunger = 0.1
	elapsed = 0.0
	_msg.text = ""
	state = "play"


func _gui_input(ev: InputEvent) -> void:
	if clear and (state == "lost" or state == "won") and ev is InputEventMouseButton and ev.pressed:
		_restart()
