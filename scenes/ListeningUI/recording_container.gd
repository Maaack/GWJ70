extends VBoxContainer

const RECORDING_STREAM_DESTINATION = "user://recording_audio.wav"

signal return_confirmed
signal folklore_submitted

var story_title : String :
	set(value):
		story_title = value
		if is_inside_tree():
			%StoryTitleLabel.text = story_title
			%StoryTitleEdit.text = story_title

var author_name : String :
	set(value):
		author_name = value
		if is_inside_tree():
			%AuthorNameLabel.text = author_name

var parent_file_key : String
var _recorded_audio_stream : AudioStreamWAV
var _recorded_audio_key : String

func _get_title():
	var title : String = %StoryTitleEdit.text
	if title.is_empty():
		title = %StoryTitleLabel.text
	return title

func _save_temporary_wav_file(file_path : String):
	if _recorded_audio_stream == null: return
	var error = _recorded_audio_stream.save_to_wav(file_path)
	if error != OK:
		push_error("Failed to save WAV file. Error code: %d" % error)
		return error
		
func _get_audio_file_data():
	_save_temporary_wav_file(RECORDING_STREAM_DESTINATION)
	if FileAccess.file_exists(RECORDING_STREAM_DESTINATION):
		return FileAccess.get_file_as_bytes(RECORDING_STREAM_DESTINATION)

func _submit_folklore():
	$GetSubmitURL.request(_get_title(), parent_file_key)

func _on_audio_player_recording_stopped(audio_stream):
	if audio_stream is AudioStreamWAV:
		_recorded_audio_stream = audio_stream

func _on_go_back_button_pressed():
	$ConfirmationDialog.popup_centered()

func _on_confirmation_dialog_canceled():
	pass # Replace with function body.

func _on_confirmation_dialog_confirmed():
	return_confirmed.emit()

func _on_get_submit_url_url_received(upload_url, audio_key):
	_recorded_audio_key = audio_key
	var audio_data = _get_audio_file_data()

	var headers = ["Content-Type: audio/wav"]
	var error = $S3PutRequest.request_raw(upload_url, headers, HTTPClient.METHOD_PUT, audio_data)
	if error != OK:
		push_error("Failed to initiate S3 upload. Error code: %d" % error)

func _on_s_3_put_request_request_completed(result, response_code, headers, body):
	if response_code != 200:
		push_error("Failed to upload audio to S3. HTTP status code: %d ; body: %s" % [response_code, body.get_string_from_utf8()])
		return
	$SubmitFolklore.request(_recorded_audio_key)

func _on_submit_button_pressed():
	%SubmitButton.disabled = true
	_submit_folklore()

func _on_submit_folklore_folklore_submitted():
	%SubmitButton.disabled = false
	folklore_submitted.emit()
