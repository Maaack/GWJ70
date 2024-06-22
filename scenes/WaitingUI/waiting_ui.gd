extends Control

@export var folklore_stats_scene : PackedScene
@export var folklore_data : Array :
	set(value):
		folklore_data = value
		if is_inside_tree():
			_refresh_list()
@onready var container_node : Container = %StatusContainer

func _clear_list():
	for child in container_node.get_children():
		child.queue_free()

func _build_list():
	for folklore_item in folklore_data:
		var stats_instance = folklore_stats_scene.instantiate()
		stats_instance.folklore_item = folklore_item
		container_node.add_child.call_deferred(stats_instance)

func _refresh_list():
	_clear_list()
	_build_list()

func _ready():
	folklore_data = folklore_data
