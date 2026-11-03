extends Node
## Verification autoload from godot-kit. Register it as "Shot" in project.godot. It does nothing unless
## the game is started with one of the arguments below (after `--`), so it is safe to ship.
##
## Screenshots:  --shot=/abs/out.png --shot-after=6
##               add --shot-every=2 to save out_1.png, out_2.png ... (--shot-count frames, default 4), then quit
## Input replay (real input events; coordinates are in the project's viewport size, seconds since start):
##               --tap=x,y,sec             touch once. Repeat the argument for more taps
##               --hold=x,y,sec[,length]   touch and hold (default 0.6 s)
##               --swipe=x1,y1,x2,y2,sec   drag from one point to another
##               --click=x,y,sec           left mouse click
##               --move=x,y,sec            move the mouse there (to test hover)
##               --key=Name,sec[,length]   press a key, e.g. Enter, Space, Left, A (default 0.05 s)
## --demo:       sets Shot.demo = true. Implement self-play in the game when it is true, so that
##               screenshots and recordings can reach the interesting moments.

var demo: bool = false
var _path: String = ""
var _after: float = 6.0
var _every: float = 0.0
var _count: int = 4
var _taken: int = 0
var _t: float = 0.0
var _queue: Array = []  # [[sec, kind, args...]]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		var v: PackedStringArray = a.get_slice("=", 1).split(",")
		if a == "--demo":
			demo = true
		elif a.begins_with("--shot="):
			_path = a.substr(7)
		elif a.begins_with("--shot-after="):
			_after = float(a.substr(13))
		elif a.begins_with("--shot-every="):
			_every = float(a.substr(13))
		elif a.begins_with("--shot-count="):
			_count = int(a.substr(13))
		elif a.begins_with("--tap="):
			_queue.append([float(v[2]), "touch", Vector2(float(v[0]), float(v[1])), 0.05])
		elif a.begins_with("--hold="):
			_queue.append([float(v[2]), "touch", Vector2(float(v[0]), float(v[1])), float(v[3]) if v.size() > 3 else 0.6])
		elif a.begins_with("--swipe="):
			_queue.append([float(v[4]), "swipe", Vector2(float(v[0]), float(v[1])), Vector2(float(v[2]), float(v[3]))])
		elif a.begins_with("--click="):
			_queue.append([float(v[2]), "click", Vector2(float(v[0]), float(v[1]))])
		elif a.begins_with("--move="):
			_queue.append([float(v[2]), "move", Vector2(float(v[0]), float(v[1]))])
		elif a.begins_with("--key="):
			_queue.append([float(v[1]), "key", v[0], float(v[2]) if v.size() > 2 else 0.05])
	set_process(_path != "" or not _queue.is_empty())

func _process(delta: float) -> void:
	_t += delta
	for i in range(_queue.size() - 1, -1, -1):
		if _t >= _queue[i][0]:
			var it: Array = _queue[i]
			_queue.remove_at(i)
			_fire(it)
	if _path == "":
		return
	if _every > 0.0:
		if _t >= _after + _every * _taken:
			_taken += 1
			_save(_path.get_basename() + "_" + str(_taken) + ".png")
			if _taken >= _count:
				get_tree().quit()
	elif _t >= _after:
		_save(_path)
		get_tree().quit()

func _save(p: String) -> void:
	RenderingServer.force_draw(false)  # macOS stops drawing a hidden window, so force a frame first
	var img: Image = get_viewport().get_texture().get_image()
	if get_viewport().use_hdr_2d:  # an HDR 2D viewport is linear; convert back to sRGB before saving
		img.convert(Image.FORMAT_RGBA8)
		img.linear_to_srgb()
	img.save_png(p)
	print("[Shot] saved ", p)

func _later(sec: float, f: Callable) -> void:
	get_tree().create_timer(sec).timeout.connect(f)

func _win(pos: Vector2) -> Vector2:  # viewport coordinates -> window coordinates
	return get_viewport().get_final_transform() * pos

func _touch(pos: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.position = _win(pos)
	e.pressed = pressed
	Input.parse_input_event(e)

func _drag(pos: Vector2, rel: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = 0
	e.position = _win(pos)
	e.relative = get_viewport().get_final_transform().basis_xform(rel)
	Input.parse_input_event(e)

func _mouse_move(pos: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = _win(pos)
	e.global_position = e.position
	Input.parse_input_event(e)

func _mouse_button(pos: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.position = _win(pos)
	e.global_position = e.position
	e.pressed = pressed
	Input.parse_input_event(e)

func _key(key_name: String, pressed: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = OS.find_keycode_from_string(key_name)
	e.physical_keycode = e.keycode
	e.pressed = pressed
	Input.parse_input_event(e)

func _fire(it: Array) -> void:
	match it[1]:
		"touch":
			var pos: Vector2 = it[2]
			_touch(pos, true)
			_later(float(it[3]), func() -> void: _touch(pos, false))
		"swipe":
			var a: Vector2 = it[2]
			var b: Vector2 = it[3]
			_touch(a, true)
			for k in range(1, 7):
				var p := a.lerp(b, float(k) / 6.0)
				_later(0.025 * k, func() -> void: _drag(p, (b - a) / 6.0))
			_later(0.025 * 7, func() -> void: _touch(b, false))
		"click":
			var pos: Vector2 = it[2]
			_mouse_move(pos)
			_later(0.03, func() -> void: _mouse_button(pos, true))
			_later(0.08, func() -> void: _mouse_button(pos, false))
		"move":
			_mouse_move(it[2])
		"key":
			var key_name: String = it[2]
			if OS.find_keycode_from_string(key_name) == KEY_NONE:
				push_warning("[Shot] unknown key name: " + key_name)
				return
			_key(key_name, true)
			_later(float(it[3]), func() -> void: _key(key_name, false))
