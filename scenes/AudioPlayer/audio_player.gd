@tool
class_name AudioPlayerControl
extends Control

signal playback_started
signal playback_stopped
signal playback_paused
signal playback_completed
signal recording_started
signal recording_stopped(audio_stream : AudioStreamWAV)

const SAMPLE_RATE = 22050

enum UIStates{
	DISABLED,
	PLAYING,
	STOPPED,
	PAUSED,
	RECORDING,
	MUTED
}

@export var current_state : UIStates :
	set(value):
		current_state = value
		_refresh_object_visiblity()

@export var audio_stream : AudioStream :
	set(value):
		audio_stream = value
		if not audio_stream : 
			_stream_length = 0.0
			return
		_stream_length = audio_stream.get_length()
		if _stream_length == 0: return
		if current_state == UIStates.DISABLED:
			current_state = UIStates.STOPPED
		if is_inside_tree():
			$AudioStreamPlayer.stream = audio_stream
@export var start_delay : float = 0.0

@export_group("Recording")
@export var recording_enabled : bool = false
@export var recording_audio_bus : StringName = &"Microphone"
@export var recording_effect_index : int = 0
@export var stereo : bool = true

@onready var audio_stream_player = $AudioStreamPlayer
@onready var audio_progress_bar = %AudioProgressBar

var _stream_length : float

var record_effect: AudioEffect

var _hide_stop_button : bool = false

func has_stream() -> bool:
	return audio_stream != null

func _refresh_object_visiblity():
	if not is_inside_tree(): return
	match(current_state):
		UIStates.DISABLED:
			%PlayButton.hide()
			%PauseButton.hide()
			%StopButton.hide()
			%StopButton.disabled = false
			%RecordButton.hide()
		UIStates.PLAYING:
			%PlayButton.hide()
			%PauseButton.show()
			%StopButton.visible = not _hide_stop_button
			%StopButton.disabled = false
			%RecordButton.hide()
		UIStates.STOPPED:
			%PlayButton.visible = has_stream()
			%PauseButton.hide()
			%StopButton.visible = not _hide_stop_button
			%StopButton.disabled = true
			%RecordButton.visible = recording_enabled
		UIStates.PAUSED:
			%PlayButton.visible = has_stream()
			%PauseButton.hide()
			%StopButton.visible = not _hide_stop_button
			%StopButton.disabled = false
			%RecordButton.visible = recording_enabled
		UIStates.RECORDING:
			%PlayButton.hide()
			%PauseButton.hide()
			%StopButton.visible = not _hide_stop_button
			%StopButton.disabled = false
			%RecordButton.hide()
func pause():
	if current_state == UIStates.PLAYING:
		current_state = UIStates.PAUSED
		audio_stream_player.stream_paused = true
		playback_paused.emit()

func stop():
	if current_state in [UIStates.PLAYING, UIStates.PAUSED, UIStates.RECORDING]:
		audio_stream_player.stop()
		audio_progress_bar.value = 0.0
		if record_effect.is_recording_active():
			_stop_recording()
		else:
			current_state = UIStates.STOPPED
			playback_stopped.emit()

func force_play():
	_hide_stop_button = true
	play()

func play():
	if _stream_length == 0:
		playback_completed.emit()
		return
	if current_state in [UIStates.STOPPED, UIStates.PAUSED]:
		current_state = UIStates.PLAYING
		if audio_stream_player.stream_paused:
			audio_stream_player.stream_paused = false
		else:
			playback_started.emit()
			if start_delay > 0.0:
				await(get_tree().create_timer(start_delay).timeout)
				if current_state != UIStates.PLAYING: return
			audio_stream_player.play()

func _completed():
	_hide_stop_button = false
	current_state = UIStates.STOPPED
	audio_progress_bar.value = 0.0
	playback_completed.emit()

func _start_recording():
	if record_effect.is_recording_active(): return
	record_effect.set_recording_active(true)
	current_state = UIStates.RECORDING
	recording_started.emit()

func _stop_recording():
	if not record_effect.is_recording_active(): return
	var recorded_audio_stream : AudioStreamWAV = record_effect.get_recording()
	record_effect.set_recording_active(false)
	recorded_audio_stream.set_mix_rate(SAMPLE_RATE)
	recorded_audio_stream.set_format(AudioStreamWAV.FORMAT_16_BITS)
	recorded_audio_stream.set_stereo(stereo)
	audio_stream = recorded_audio_stream
	current_state = UIStates.STOPPED
	recording_stopped.emit(recorded_audio_stream)

func toggle_recording():
	if record_effect.is_recording_active():
		_stop_recording()
	else:
		_start_recording()

func record():
	if current_state in [UIStates.STOPPED, UIStates.PAUSED]:
		_start_recording()

func _on_record_button_pressed():
	record()

func _on_pause_button_pressed():
	pause()

func _on_stop_button_pressed():
	stop()

func _on_play_button_pressed():
	play()

func _on_audio_stream_player_finished():
	_completed()

func _process(_delta):
	if current_state == UIStates.PLAYING:
		var ratio = audio_stream_player.get_playback_position() / _stream_length
		audio_progress_bar.value = ratio

func _ready() -> void:
	current_state = current_state
	$AudioStreamRecorder.bus = recording_audio_bus
	var idx := AudioServer.get_bus_index(recording_audio_bus)
	record_effect = AudioServer.get_bus_effect(idx, recording_effect_index)
	if not record_effect is AudioEffectRecord:
		push_error("missing Record bus effect at index %d" % recording_effect_index)
