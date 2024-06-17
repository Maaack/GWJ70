extends Node

var _audio_stream : AudioStreamWAV
var _audio_key : String

func _on_mic_recorder_recording_stopped(audio_stream):
	if audio_stream is AudioStreamWAV:
		_audio_stream = audio_stream
		$AudioStreamPlayer.stream = audio_stream

func _save_temporary_wav_file(file_path : String):
	if _audio_stream == null: return
	var error = _audio_stream.save_to_wav(file_path)
	if error != OK:
		push_error("Failed to save WAV file. Error code: %d" % error)
		return error

func _send_file_data(file_data : PackedByteArray):
	$GetSubmitURL.request_destination()
	#$SubmitFolklore.send_audio(audio_data)

func _get_audio_file_data():
	var file_path = "user://temp_audio.wav"
	# _save_temporary_wav_file(file_path)

	if FileAccess.file_exists(file_path):
		return FileAccess.get_file_as_bytes(file_path)

func _on_send_folklore():
	var file_path = "user://temp_audio.wav"
	# _save_temporary_wav_file(file_path)

	if FileAccess.file_exists(file_path):
		var audio_data = FileAccess.get_file_as_bytes(file_path)
		_send_file_data(audio_data)
	else:
		push_error("Failed to locate the saved WAV file.")

func _input(event):
	if event.is_action_pressed(&"playback"):
		if $AudioStreamPlayer.playing:
			$AudioStreamPlayer.stop()
		else: 
			$AudioStreamPlayer.play()
	elif event.is_action_pressed(&"save"):
		_on_send_folklore()

func _on_get_submit_url_url_received(upload_url, audio_key):
	# Use the pre-signed URL to upload the audio data
	var request = $HTTPRequest
	_audio_key = audio_key

	var headers = ["Content-Type: audio/wav"]
	print(upload_url)
	var error = request.request_raw(upload_url, headers, HTTPClient.METHOD_PUT, _get_audio_file_data())
	if error != OK:
		push_error("Failed to initiate S3 upload. Error code: %d" % error)

func _on_http_request_request_completed(result, response_code, headers, body : PackedByteArray):
	if response_code != 200:
		push_error("Failed to upload audio to S3. HTTP status code: %d ; body: %s" % [response_code, body.get_string_from_utf8()])
		return

	$SubmitFolklore.transcribe_folklore(_audio_key)
