extends Control

signal folklore_submitted
signal playback_started
signal playback_ended
signal recording_started
signal recording_stopped

@onready var past_folklore_player : AudioPlayerControl = %AudioPlayer
@onready var folklore_transcript_label : RichTextLabel = %FolkloreTranscriptLabel
@onready var story_title_label : Label = %StoryTitleLabel
@onready var author_name_label : Label = %AuthorNameLabel

@export var music_volume_db : float = 0.0

func _on_past_folklore_controller_folklore_queued(file_key : String, audio_stream : AudioStreamWAV, story_title : String, author_name : String, transcript : String):
	past_folklore_player.stop()
	past_folklore_player.audio_stream = audio_stream
	story_title_label.text = story_title
	author_name_label.text = author_name
	%RecordingContainer.story_title = story_title
	%RecordingContainer.author_name = author_name
	%RecordingContainer.parent_file_key = file_key
	past_folklore_player.force_play()
	folklore_transcript_label.text = "[right]%s[/right]" % transcript

func _on_pass_on_button_pressed():
	%ListeningContainer.hide()
	%RecordingContainer.show()
	playback_started.emit()

func _on_recording_container_return_confirmed():
	%ListeningContainer.show()
	%RecordingContainer.hide()
	playback_ended.emit()

func _on_recording_container_folklore_submitted():
	$PastFolkloreController.mark_folklore_submitted(%RecordingContainer.parent_file_key)
	folklore_submitted.emit()

func _on_audio_player_playback_started():
	%PassOnButton.text = "Finish Listening"
	%PassOnButton.disabled = true
	playback_started.emit()
	if not $MusicStreamPlayer.playing:
		$MusicStreamPlayer.volume_db = -60
		$MusicStreamPlayer.play()
	var tween = create_tween()
	tween.tween_property($MusicStreamPlayer, "volume_db", music_volume_db, 3)

func _enable_pass_on_button():
	%PassOnButton.text = "Pass On"
	%PassOnButton.disabled = false

func _stop_music():
	var tween = create_tween()
	tween.tween_property($MusicStreamPlayer, "volume_db", -60, 3)
	await(tween.finished)
	$MusicStreamPlayer.stop()

func _on_playback_stopped():
	_enable_pass_on_button()
	playback_ended.emit()
	_stop_music()

func _on_audio_player_playback_completed():
	_on_playback_stopped()

func _on_audio_player_playback_stopped():
	_on_playback_stopped()

func _on_recording_container_recording_started():
	recording_started.emit()

func _on_recording_container_recording_stopped():
	recording_stopped.emit()
