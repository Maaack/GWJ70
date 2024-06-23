extends VBoxContainer

const TEMP_STREAM_DESTINATION = "user://temp_audio.wav"

var _submitted_audio_key : String
var _loaded_file_path : String

func _get_title():
	return %StoryTitleEdit.text

func _get_audio_file_data(audio_file_path):
	var bytes
	if FileAccess.file_exists(audio_file_path):
		bytes = FileAccess.get_file_as_bytes(audio_file_path)
		if bytes == null or bytes.is_empty():
			push_error(FileAccess.get_open_error())
	return bytes

func _submit_folklore():
	$GetSubmitURL.request(_get_title())
	
func _get_audio_stream(audio_stream_path) -> AudioStreamWAV:
	if not FileAccess.file_exists(audio_stream_path): return
	var audio_loader = AudioLoader.new()
	var audio_stream : AudioStreamWAV = audio_loader.loadfile(audio_stream_path)
	return audio_stream

func _on_get_submit_url_url_received(upload_url, audio_key):
	_submitted_audio_key = audio_key
	if not FileAccess.file_exists(TEMP_STREAM_DESTINATION):
		return
	var file_data = FileAccess.get_file_as_bytes(TEMP_STREAM_DESTINATION)
	var headers = ["Content-Type: audio/wav"]
	var error = $S3PutRequest.request_raw(upload_url, headers, HTTPClient.METHOD_PUT, file_data)
	if error != OK:
		push_error("Failed to initiate S3 upload. Error code: %d" % error)

func _on_s_3_put_request_request_completed(result, response_code, headers, body):
	if response_code != 200:
		push_error("Failed to upload audio to S3. HTTP status code: %d ; body: %s" % [response_code, body.get_string_from_utf8()])
		return
	$SubmitFolklore.request(_submitted_audio_key)

func _on_submit_button_pressed():
	%SubmitButton.disabled = true
	_submit_folklore()

func _on_submit_folklore_folklore_submitted():
	%SubmitButton.disabled = false

func _on_submit_folklore_request_failed():
	%SubmitButton.disabled = false
	%SubmitButton.text = "Try Again"

func _on_button_pressed():
	$FileDialog.popup_centered()

func _save_temporary_wav_file(audio_stream: AudioStreamWAV, file_path : String):
	var error = audio_stream.save_to_wav(file_path)
	if error != OK:
		push_error("Failed to save WAV file. Error code: %d" % error)
		return error


func _on_file_dialog_file_selected(path):
	_loaded_file_path = path
	if not _loaded_file_path.is_empty():
		var _audio_stream = _get_audio_stream(_loaded_file_path)
		_save_temporary_wav_file(_audio_stream, TEMP_STREAM_DESTINATION)
		$AudioPlayer.audio_stream = _audio_stream
	%SubmitButton.disabled = $AudioPlayer.audio_stream == null

