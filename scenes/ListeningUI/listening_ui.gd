extends Control

@export var past_folklore_scene : PackedScene
@export var past_folklore_data : Array :
	set(value):
		past_folklore_data = value
		if is_inside_tree():
			_refresh_list()
@onready var container_node : Container = %PastFolkloreContainer
@onready var past_folklore_player : AudioPlayer = %AudioPlayer
@onready var folklore_transcript_label : RichTextLabel = %FolkloreTranscriptLabel

func _clear_list():
	for child in container_node.get_children():
		child.queue_free()

func _build_list():
	for folklore_item in past_folklore_data:
		var past_instance = past_folklore_scene.instantiate()
		if folklore_item and folklore_item.has("file_name"):
			past_instance.folklore_item = folklore_item
		if past_instance.has_signal(&"past_folklore_queued"):
			past_instance.connect(&"past_folklore_queued", _on_past_folklore_queued)
		container_node.add_child.call_deferred(past_instance)

func _refresh_list():
	_clear_list()
	_build_list()

func _on_past_folklore_queued(audio_stream : AudioStreamWAV, transcript : String):
	past_folklore_player.stop()
	past_folklore_player.audio_stream = audio_stream
	past_folklore_player.play()
	folklore_transcript_label.text = "[right]%s[/right]" % transcript

func _ready():
	past_folklore_data = past_folklore_data
