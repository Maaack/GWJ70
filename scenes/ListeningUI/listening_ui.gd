extends Control


@onready var past_folklore_player : AudioPlayer = %AudioPlayer
@onready var folklore_transcript_label : RichTextLabel = %FolkloreTranscriptLabel


func _on_past_folklore_controller_folklore_queued(audio_stream, story_name, author_name, transcript):
	past_folklore_player.stop()
	past_folklore_player.audio_stream = audio_stream
	past_folklore_player.play()
	folklore_transcript_label.text = "[right]%s[/right]" % transcript
