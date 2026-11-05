extends Control
## Sleepy Cat: a tiny game that is unclear on purpose. It exists to show what a blind playtest finds.
##
## Keep the cat fed for GOAL_SEC seconds. By default the game hides almost everything a new player needs
## (the plain version). Launch with `-- --clear` for the version that applies what the playtest report said.

const HUNGER_PER_SEC := 0.05
const FEED_AMOUNT := 0.4
const GOAL_SEC := 30.0

const BG_TOP := Color(0.17, 0.16, 0.23)
const BG_BOTTOM := Color(0.07, 0.065, 0.1)
const FUR := Color(0.87, 0.77, 0.65)
const FUR_SHADE := Color(0.74, 0.63, 0.52)
const FUR_LIGHT := Color(0.96, 0.91, 0.83)
const INK := Color(0.12, 0.1, 0.13)
const PINK := Color(0.93, 0.6, 0.63)
const ORANGE := Color(0.95, 0.55, 0.2)
const BREATH_SEC := 3.2

var clear: bool = false
var hunger: float = 0.1
var elapsed: float = 0.0
var state: String = "play"  # card | play | lost | won
var _lost_for: float = 0.0
var _t: float = 0.0  # always runs; drives the idle breathing only

var _bg: Control
var _cat: Control
var _bar_bg: Panel
var _bar_fill: Panel
var _fill_box: StyleBoxFlat
var _time_label: Label
var _msg: Label
var _feed_label: Label
var _feed_button: Button
var _card: Panel
var _dim: ColorRect
var _pulse: Tween
var _vignette: GradientTexture2D
var _glow: GradientTexture2D


func _ready() -> void:
	clear = "--clear" in OS.get_cmdline_user_args()
	get_viewport().msaa_2d = Viewport.MSAA_4X
	_build()
	get_viewport().size_changed.connect(_layout)
	_layout()
	if clear:
		state = "card"
		_card.visible = true
		_dim.visible = true


func _build() -> void:
	_vignette = _radial([Color(0, 0, 0, 0), Color(0, 0, 0, 0.1), Color(0, 0, 0, 0.55)], [0.0, 0.55, 1.0])
	_glow = _radial([Color(1.0, 0.72, 0.45, 0.13), Color(1.0, 0.72, 0.45, 0.0)], [0.0, 1.0])
	_bg = Control.new()
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg.draw.connect(_draw_bg)
	add_child(_bg)

	_cat = Control.new()
	_cat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cat.draw.connect(_draw_cat)
	add_child(_cat)

	_msg = Label.new()
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg.add_theme_font_size_override("font_size", 40)
	_msg.add_theme_color_override("font_color", Color(0.98, 0.94, 0.88))
	_msg.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	_msg.add_theme_constant_override("shadow_offset_y", 3)
	_msg.add_theme_constant_override("shadow_offset_x", 0)
	_msg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_msg)

	if clear:
		_bar_bg = Panel.new()
		_bar_bg.add_theme_stylebox_override("panel", _box(Color(1, 1, 1, 0.07), 20, Color(1, 1, 1, 0.1), 2))
		_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_bar_bg)
		_bar_fill = Panel.new()
		_fill_box = _box(Color(0.3, 0.8, 0.4), 16)
		_bar_fill.add_theme_stylebox_override("panel", _fill_box)
		_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bar_bg.add_child(_bar_fill)
		_time_label = Label.new()
		_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_time_label.add_theme_font_size_override("font_size", 32)
		_time_label.add_theme_color_override("font_color", Color(0.85, 0.83, 0.9))
		_time_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_time_label)
		_feed_button = Button.new()
		_feed_button.text = "FEED FISH"
		_feed_button.add_theme_font_size_override("font_size", 44)
		_style_button(_feed_button, 36)
		_feed_button.pressed.connect(_feed)
		add_child(_feed_button)
		_dim = ColorRect.new()
		_dim.color = Color(0.03, 0.03, 0.05, 0.45)
		_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_dim.visible = false
		add_child(_dim)
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
	var box := _box(Color(0.2, 0.19, 0.27), 32, Color(1, 1, 1, 0.09), 2)
	box.shadow_color = Color(0, 0, 0, 0.45)
	box.shadow_size = 40
	box.shadow_offset = Vector2(0, 16)
	_card.add_theme_stylebox_override("panel", box)
	var title := Label.new()
	title.name = "Title"
	title.text = "How to play"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(1.0, 0.68, 0.36))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(title)
	var text := Label.new()
	text.name = "Text"
	text.text = "Keep the cat fed for 30 seconds.\nThe bar at the top shows how hungry it is.\nWhen the bar turns red, tap FEED FISH."
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 29)
	text.add_theme_color_override("font_color", Color(0.9, 0.88, 0.94))
	text.add_theme_constant_override("line_spacing", 6)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(text)
	var ok := Button.new()
	ok.name = "Ok"
	ok.text = "OK"
	ok.add_theme_font_size_override("font_size", 40)
	_style_button(ok, 28)
	ok.pressed.connect(_close_card)
	_card.add_child(ok)
	_card.visible = false
	add_child(_card)


func _box(color: Color, radius: int, border: Color = Color(0, 0, 0, 0), border_w: int = 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.border_color = border
	box.set_border_width_all(border_w)
	box.anti_aliasing = true
	return box


func _style_button(b: Button, radius: int) -> void:
	var states := {
		"normal": ORANGE, "hover": ORANGE.lightened(0.08), "focus": ORANGE, "pressed": ORANGE.darkened(0.12)}
	for style_name in states:
		var box := _box(states[style_name], radius, Color(1.0, 0.82, 0.55), 4)
		box.shadow_color = Color(0.0, 0.0, 0.0, 0.4)
		box.shadow_size = 14
		box.shadow_offset = Vector2(0, 8 if style_name != "pressed" else 3)
		b.add_theme_stylebox_override(style_name, box)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(color_name, Color(0.24, 0.11, 0.03))


func _radial(colors: Array, offsets: Array) -> GradientTexture2D:
	var g := Gradient.new()
	g.colors = PackedColorArray(colors)
	g.offsets = PackedFloat32Array(offsets)
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 256
	tex.height = 256
	return tex


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
		_dim.size = s
		_card.size = Vector2(s.x * 0.9, 470)
		_card.position = Vector2(s.x * 0.05, s.y * 0.32)
		var title: Label = _card.get_node("Title")
		title.position = Vector2(30, 44)
		title.size = Vector2(_card.size.x - 60, 60)
		var text: Label = _card.get_node("Text")
		text.position = Vector2(20, 130)
		text.size = Vector2(_card.size.x - 40, 200)
		var ok: Button = _card.get_node("Ok")
		ok.size = Vector2(240, 90)
		ok.position = Vector2((_card.size.x - 240) * 0.5, 350)
	else:
		_feed_label.position = Vector2(s.x * 0.08, s.y * 0.93)
		_feed_label.size = Vector2(90, 44)
	_bg.queue_redraw()
	_cat.queue_redraw()


func _draw_bg() -> void:
	var s := get_viewport_rect().size
	_bg.draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(s.x, 0), s, Vector2(0, s.y)]),
		PackedColorArray([BG_TOP, BG_TOP, BG_BOTTOM, BG_BOTTOM]))
	var c := Vector2(s.x * 0.5, s.y * 0.45)
	var gr := s.x * 0.75
	_bg.draw_texture_rect(_glow, Rect2(c - Vector2(gr, gr), Vector2(gr, gr) * 2.0), false)
	var v := s * 0.78
	_bg.draw_texture_rect(_vignette, Rect2(s * 0.5 - v, v * 2.0), false)


func _ellipse(center: Vector2, rx: float, ry: float, from: float = 0.0, to: float = TAU, n: int = 40) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var a: float = lerpf(from, to, float(i) / n)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func _draw_cat() -> void:
	var s := get_viewport_rect().size
	var c := Vector2(s.x * 0.5, s.y * 0.42)
	var r := minf(s.x * 0.26, 190.0)
	var ground := c.y + r * 1.5
	var k := sin(_t * TAU / BREATH_SEC)

	# Ground shadow, soft: a few stacked ellipses. It stays put while the cat breathes.
	for i in 4:
		var f := 1.0 + i * 0.12
		_cat.draw_colored_polygon(_ellipse(Vector2(c.x, ground), r * 0.95 * f, r * 0.13 * f), Color(0, 0, 0, 0.13))

	# Breathing: scale the whole cat a little from the ground point.
	var sc := Vector2(1.0 + 0.006 * k, 1.0 + 0.014 * k)
	var base := Vector2(c.x, ground)
	_cat.draw_set_transform(base - base * sc, 0.0, sc)

	# Tail behind the body.
	var tail := PackedVector2Array()
	for i in 13:
		var u := float(i) / 12.0
		tail.append(c + Vector2(r * (0.55 + 0.5 * sin(u * 2.2)), r * (1.38 - 0.95 * u * u)))
	_cat.draw_polyline(tail, FUR_SHADE, r * 0.17, true)
	_cat.draw_circle(tail[tail.size() - 1], r * 0.085, FUR_SHADE, true, -1.0, true)

	# Body and paws.
	_cat.draw_colored_polygon(_ellipse(c + Vector2(0, r * 0.98), r * 0.8, r * 0.56), FUR_SHADE)
	_cat.draw_colored_polygon(_ellipse(c + Vector2(0, r * 0.92), r * 0.66, r * 0.5), FUR)
	_cat.draw_colored_polygon(_ellipse(c + Vector2(0, r * 1.0), r * 0.34, r * 0.36), FUR_LIGHT)
	for sx in [-1.0, 1.0]:
		var p: Vector2 = c + Vector2(sx * r * 0.27, r * 1.43)
		_cat.draw_colored_polygon(_ellipse(p, r * 0.17, r * 0.1), FUR_LIGHT)
		for tx in [-1.0, 1.0]:
			_cat.draw_line(p + Vector2(tx * r * 0.05, -r * 0.02), p + Vector2(tx * r * 0.05, r * 0.06), FUR_SHADE, 2.5, true)

	# Ears: outer fur, inner pink.
	for sx in [-1.0, 1.0]:
		_cat.draw_colored_polygon(PackedVector2Array([
			c + Vector2(sx * r * 0.95, -r * 0.2),
			c + Vector2(sx * r * 0.8, -r * 1.25),
			c + Vector2(sx * r * 0.2, -r * 0.85)]), FUR)
		_cat.draw_colored_polygon(PackedVector2Array([
			c + Vector2(sx * r * 0.82, -r * 0.42),
			c + Vector2(sx * r * 0.76, -r * 1.06),
			c + Vector2(sx * r * 0.36, -r * 0.8)]), PINK.lerp(FUR, 0.25))

	# Head: a darker rim underneath gives it weight, then the face and a lighter muzzle.
	_cat.draw_circle(c + Vector2(0, r * 0.05), r, FUR_SHADE, true, -1.0, true)
	_cat.draw_circle(c, r * 0.98, FUR, true, -1.0, true)
	_cat.draw_colored_polygon(_ellipse(c + Vector2(0, r * 0.3), r * 0.42, r * 0.3), FUR_LIGHT)
	for i in 3:
		var x := (i - 1) * r * 0.16
		var ln := r * (0.26 if i == 1 else 0.19)
		_cat.draw_colored_polygon(PackedVector2Array([
			c + Vector2(x - r * 0.035, -r * 0.96), c + Vector2(x + r * 0.035, -r * 0.96),
			c + Vector2(x, -r * 0.96 + ln)]), FUR_SHADE)

	# Cheeks.
	for sx in [-1.0, 1.0]:
		var cheek: Vector2 = c + Vector2(sx * r * 0.6, r * 0.2)
		_cat.draw_circle(cheek, r * 0.15, Color(PINK, 0.18), true, -1.0, true)
		_cat.draw_circle(cheek, r * 0.1, Color(PINK, 0.25), true, -1.0, true)

	# Eyes: open with highlights, or closed into lines when hungry.
	var eye_y := c.y - r * 0.1
	for sx in [-1.0, 1.0]:
		var ex: float = c.x + sx * r * 0.42
		if hunger < 0.7:
			_cat.draw_circle(Vector2(ex, eye_y), r * 0.11, INK, true, -1.0, true)
			_cat.draw_circle(Vector2(ex + r * 0.035, eye_y - r * 0.04), r * 0.035, Color(1, 1, 1, 0.92), true, -1.0, true)
			_cat.draw_circle(Vector2(ex - r * 0.03, eye_y + r * 0.04), r * 0.015, Color(1, 1, 1, 0.6), true, -1.0, true)
		else:
			var a := Vector2(ex - r * 0.14, eye_y - r * 0.03 * sx)
			var b := Vector2(ex + r * 0.14, eye_y + r * 0.03 * sx)
			_cat.draw_line(a, b, INK, 7.0, true)
			_cat.draw_circle(a, 3.5, INK, true, -1.0, true)
			_cat.draw_circle(b, 3.5, INK, true, -1.0, true)

	# Whiskers.
	for sx in [-1.0, 1.0]:
		for i in 3:
			var from: Vector2 = c + Vector2(sx * r * 0.32, r * (0.24 + i * 0.07))
			var to: Vector2 = c + Vector2(sx * r * 1.02, r * (0.12 + i * 0.13))
			_cat.draw_line(from, to, Color(1, 1, 1, 0.5), 2.5, true)

	# Nose and the small "^" mouth.
	_cat.draw_colored_polygon(PackedVector2Array([
		c + Vector2(-r * 0.08, r * 0.18), c + Vector2(r * 0.08, r * 0.18), c + Vector2(0, r * 0.3)]), PINK)
	_cat.draw_circle(c + Vector2(-r * 0.045, r * 0.195), r * 0.035, PINK, true, -1.0, true)
	_cat.draw_circle(c + Vector2(r * 0.045, r * 0.195), r * 0.035, PINK, true, -1.0, true)
	_cat.draw_line(c + Vector2(0, r * 0.3), c + Vector2(-r * 0.15, r * 0.42), INK, 4.0, true)
	_cat.draw_line(c + Vector2(0, r * 0.3), c + Vector2(r * 0.15, r * 0.42), INK, 4.0, true)
	_cat.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _process(delta: float) -> void:
	_t += delta
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
		var inner := _bar_bg.size - Vector2(8, 8)
		var w: float = maxf(inner.x * hunger, 2.0)
		_bar_fill.position = Vector2(4, 4)
		_bar_fill.size = Vector2(w, inner.y)
		_fill_box.set_corner_radius_all(int(minf(inner.y * 0.5, w * 0.5)))
		_fill_box.bg_color = Color(0.3, 0.8, 0.4).lerp(Color(0.9, 0.2, 0.2), clampf((hunger - 0.4) / 0.5, 0.0, 1.0))
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
	_dim.visible = false
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
