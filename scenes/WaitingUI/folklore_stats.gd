extends Control

@export var folklore_item : Dictionary :
	set(value):
		folklore_item = value
		if is_inside_tree():
			%TitleLabel.text = folklore_item["story_title"]
			%StatusLabel.text = folklore_item["file_status"]
			%SharedLabel.text = "Shared: %d " % folklore_item["share_count"]
			%PassedOnLabel.text = "Passed On: %d " % folklore_item["child_count"]

func _ready():
	folklore_item = folklore_item
