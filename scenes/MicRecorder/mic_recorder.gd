extends Node

signal recording_started
signal recording_stopped(audio_stream : AudioStreamWAV)

const SAMPLE_RATE = 22050

@export var audio_bus : StringName = &"Microphone"
@export var effect_index : int = 0
@export var stereo : bool = true
var effect: AudioEffect
var audio_stream: AudioStreamWAV


func _ready() -> void:
	$AudioStreamRecorder.bus = audio_bus
	var idx := AudioServer.get_bus_index(audio_bus)
	effect = AudioServer.get_bus_effect(idx, effect_index)
	if not effect is AudioEffectRecord:
		push_error("missing Record bus effect at index %d" % effect_index)

func toggle_recording():
	if effect.is_recording_active():
		audio_stream = effect.get_recording()
		effect.set_recording_active(false)
		audio_stream.set_mix_rate(SAMPLE_RATE)
		audio_stream.set_format(AudioStreamWAV.FORMAT_16_BITS)
		audio_stream.set_stereo(stereo)
		recording_stopped.emit(audio_stream)
	else:
		effect.set_recording_active(true)
		recording_started.emit()

func _input(event):
	if event.is_action_pressed(&"record"):
		toggle_recording()
