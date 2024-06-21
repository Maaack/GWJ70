extends Node

var _recorded_audio_stream : AudioStreamWAV
var _recorded_audio_key : String
var _folklore_audio_key : String
var _folklore_audio_file_path : String

func _on_mic_recorder_recording_stopped(audio_stream):
	if audio_stream is AudioStreamWAV:
		_recorded_audio_stream = audio_stream
		$RecordedStreamPlayer.stream = audio_stream

func _save_temporary_wav_file(file_path : String):
	if _recorded_audio_stream == null: return
	var error = _recorded_audio_stream.save_to_wav(file_path)
	if error != OK:
		push_error("Failed to save WAV file. Error code: %d" % error)
		return error

func _get_audio_file_data():
	var file_path = "user://temp_audio.wav"
	_save_temporary_wav_file(file_path)

	if FileAccess.file_exists(file_path):
		return FileAccess.get_file_as_bytes(file_path)

func _on_retell_folklore():
	$GetSubmitURL.request_destination(_folklore_audio_key)

func _on_get_past_folklore():
	$GetPastFolklore.request()

func _input(event):
	if event.is_action_pressed(&"playback"):
		if $RecordedStreamPlayer.playing:
			$RecordedStreamPlayer.stop()
		else: 
			$RecordedStreamPlayer.play()
	elif event.is_action_pressed(&"save"):
		_on_retell_folklore()
	elif event.is_action_pressed(&"get"):
		_on_get_past_folklore()

func _on_get_submit_url_url_received(upload_url, audio_key):
	# Use the pre-signed URL to upload the audio data
	var request = $S3PutRequest
	_recorded_audio_key = audio_key

	var headers = ["Content-Type: audio/wav"]
	var error = request.request_raw(upload_url, headers, HTTPClient.METHOD_PUT, _get_audio_file_data())
	if error != OK:
		push_error("Failed to initiate S3 upload. Error code: %d" % error)

func _on_s_3_put_request_request_completed(result, response_code, headers, body):
	if response_code != 200:
		push_error("Failed to upload audio to S3. HTTP status code: %d ; body: %s" % [response_code, body.get_string_from_utf8()])
		return
	$SubmitFolklore.transcribe_folklore(_recorded_audio_key)

func _on_get_past_folklore_url_received(download_url : String, transcription : String):
		# Use the pre-signed URL to upload the audio data
	var request = $S3GetRequest
	_folklore_audio_key = download_url.split("?", true, 1)[0].rsplit("/", true, 1)[1]
	_folklore_audio_file_path = "user://%s" % _folklore_audio_key
	if FileAccess.file_exists(_folklore_audio_file_path): 
		_play_downloaded_folklore()
		return
	var error = request.request_raw(download_url, Array(), HTTPClient.METHOD_GET, PackedByteArray())
	if error != OK:
		push_error("Failed to initiate S3 download. Error code: %d" % error)

func _play_downloaded_folklore():
	if not FileAccess.file_exists(_folklore_audio_file_path): return
	var audio_loader = AudioLoader.new()
	var audio_stream : AudioStreamWAV = audio_loader.loadfile(_folklore_audio_file_path)
	audio_stream.resource_path = _folklore_audio_file_path
	$FolkloreStreamPlayer.stream = audio_stream
	$FolkloreStreamPlayer.play()
	
func _on_s_3_get_request_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var file = FileAccess.open(_folklore_audio_file_path, FileAccess.WRITE)
		var error = FileAccess.get_open_error()
		if error != OK:
			print("Failed to save the downloaded file %d" % error)
			return
		file.store_buffer(body)
		file.close()
		await(get_tree().create_timer(0.1).timeout)
		_play_downloaded_folklore()
	else:
		push_error("Failed to download file, %d %s" % [response_code, body.get_string_from_utf8()])

