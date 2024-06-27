extends "res://addons/maaacks_game_template/extras/scenes/Opening/Opening.gd"

func _ready():
	super._ready()
	$RegisterUser.register_user()
