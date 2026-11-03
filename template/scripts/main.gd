extends Control
## The first screen. Start building here; everything in this file is meant to be replaced.

var _count: int = 0
@onready var _label: Label = $Label
@onready var _button: Button = $Button

func _ready() -> void:
	_button.pressed.connect(_bump)

func _bump() -> void:
	_count += 1
	_label.text = "%d" % _count
