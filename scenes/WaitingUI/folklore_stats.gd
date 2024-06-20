extends Control

@export var folklore_item : Dictionary :
	set(value):
		folklore_item = value
		if is_inside_tree():
			%FolkloreStatus.text = folklore_item["file_status"]

func _ready():
	folklore_item = folklore_item
