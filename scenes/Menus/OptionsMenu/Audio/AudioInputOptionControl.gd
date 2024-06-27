@tool
extends ListOptionControl

func _set_input_device():
	AudioServer.input_device = _get_setting()

func _add_microphone_audio_stream() -> void:
	var instance = AudioStreamPlayer.new()
	instance.stream = AudioStreamMicrophone.new()
	instance.autoplay = true
	add_child.call_deferred(instance)
	instance.ready.connect(_set_input_device)

func _check_status():
	print("1 ", AudioServer.input_device)
	await(get_tree().create_timer(0.2).timeout)
	print("2 ", AudioServer.input_device)

func _ready():
	if ProjectSettings.get_setting("audio/driver/enable_input", false):
		if AudioServer.input_device.is_empty():
			_add_microphone_audio_stream()
		else:
			_set_input_device()
		option_values = AudioServer.get_input_device_list()
	else:
		hide()
	super._ready()

func _on_setting_changed(value):
	if value >= option_values.size(): return
	AudioServer.input_device = option_values[value]
	super._on_setting_changed(value)
