@tool
class_name AudioPlayer
extends Control

signal playback_started
signal playback_stopped
signal playback_paused
signal playback_completed

enum UIStates{
	DISABLED,
	PLAYING,
	STOPPED,
	PAUSED,
}

@export var current_state : UIStates :
	set(value):
		current_state = value
		_refresh_object_visiblity()

@export var audio_stream : AudioStream :
	set(value):
		audio_stream = value
		if audio_stream:
			if current_state == UIStates.DISABLED:
				current_state = UIStates.STOPPED
		if is_inside_tree():
			$AudioStreamPlayer.stream = audio_stream

@onready var audio_stream_player = $AudioStreamPlayer

func _refresh_object_visiblity():
	if not is_inside_tree(): return
	match(current_state):
		UIStates.DISABLED:
			%PlayButton.hide()
			%PauseButton.hide()
			%StopButton.hide()
			%StopButton.disabled = false
		UIStates.PLAYING:
			%PlayButton.hide()
			%PauseButton.show()
			%StopButton.show()
			%StopButton.disabled = false
		UIStates.STOPPED:
			%PlayButton.show()
			%PauseButton.hide()
			%StopButton.show()
			%StopButton.disabled = true
		UIStates.PAUSED:
			%PlayButton.show()
			%PauseButton.hide()
			%StopButton.show()
			%StopButton.disabled = false

func pause():
	if current_state == UIStates.PLAYING:
		current_state = UIStates.PAUSED
		audio_stream_player.stream_paused = true
		playback_paused.emit()

func stop():
	if current_state in [UIStates.PLAYING, UIStates.PAUSED]:
		current_state = UIStates.STOPPED
		audio_stream_player.stop()
		playback_stopped.emit()

func play():
	if current_state in [UIStates.STOPPED, UIStates.PAUSED]:
		current_state = UIStates.PLAYING
		if audio_stream_player.stream_paused:
			audio_stream_player.stream_paused = false
		else:
			audio_stream_player.play()
		playback_started.emit()

func _completed():
	current_state = UIStates.STOPPED
	playback_completed.emit()

func _on_pause_button_pressed():
	pause()

func _on_stop_button_pressed():
	stop()

func _on_play_button_pressed():
	play()

func _on_audio_stream_player_finished():
	_completed()

func ready():
	current_state = current_state
