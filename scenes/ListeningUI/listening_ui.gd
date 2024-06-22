extends Control

signal folklore_submitted

@onready var past_folklore_player : AudioPlayerControl = %AudioPlayer
@onready var folklore_transcript_label : RichTextLabel = %FolkloreTranscriptLabel
@onready var story_title_label : Label = %StoryTitleLabel
@onready var author_name_label : Label = %AuthorNameLabel


func _on_past_folklore_controller_folklore_queued(file_key : String, audio_stream : AudioStreamWAV, story_title : String, author_name : String, transcript : String):
	past_folklore_player.stop()
	past_folklore_player.audio_stream = audio_stream
	story_title_label.text = story_title
	author_name_label.text = author_name
	%RecordingContainer.story_title = story_title
	%RecordingContainer.author_name = author_name
	%RecordingContainer.parent_file_key = file_key
	past_folklore_player.play()
	folklore_transcript_label.text = "[right]%s[/right]" % transcript

func _on_pass_on_button_pressed():
	%ListeningContainer.hide()
	%RecordingContainer.show()

func _on_recording_container_return_confirmed():
	%ListeningContainer.show()
	%RecordingContainer.hide()

func _on_recording_container_folklore_submitted():
	folklore_submitted.emit()
