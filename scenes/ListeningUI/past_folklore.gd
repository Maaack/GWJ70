@tool
extends Control

signal past_folklore_queued(audio_stream : AudioStreamWAV, transcription : String)

enum UIStates{
	DISABLED,
	WAITING,
	DOWNLOADING,
	QUEUED
}

@export var current_state : UIStates :
	set(value):
		current_state = value
		_refresh_object_visiblity()

@export var past_folklore_key : String :
	set(value):
		past_folklore_key = value
		_past_folklore_audio_file_path = "user://%s" % past_folklore_key

var _past_folklore_audio_file_path : String : 
	set(value):
		_past_folklore_audio_file_path = value
		_get_past_folklore_audio_stream(_past_folklore_audio_file_path)

var _past_folklore_audio_stream : AudioStreamWAV
var _past_folklore_transcript : String

func _get_past_folklore_audio_stream(audio_file_path):
	if not FileAccess.file_exists(audio_file_path): return
	if _past_folklore_audio_stream: return
	var audio_loader = AudioLoader.new()
	_past_folklore_audio_stream = audio_loader.loadfile(audio_file_path)
	return _past_folklore_audio_stream

func _refresh_object_visiblity():
	if not is_inside_tree(): return
	match(current_state):
		UIStates.DISABLED:
			%TitleLabel.hide()
			%DownloadButton.hide()
		UIStates.WAITING:
			%TitleLabel.show()
			%DownloadButton.show()
		UIStates.DOWNLOADING:
			%TitleLabel.show()
			%DownloadButton.hide()
		UIStates.QUEUED:
			%TitleLabel.show()
			%DownloadButton.hide()

func _on_download_button_pressed():
	current_state = UIStates.DOWNLOADING
	$GetPastFolklore.request()

func _play_folklore():
	_past_folklore_audio_file_path = _past_folklore_audio_file_path
	past_folklore_queued.emit(_past_folklore_audio_stream, _past_folklore_transcript)
	current_state = UIStates.QUEUED

func _on_get_past_folklore_url_received(download_url, transcription):
	_past_folklore_transcript = transcription
	past_folklore_key = download_url.split("?", true, 1)[0].rsplit("/", true, 1)[1]
	if FileAccess.file_exists(_past_folklore_audio_file_path):
		_play_folklore()
		return
	var error = $S3GetRequest.request_raw(download_url, Array(), HTTPClient.METHOD_GET, PackedByteArray())
	if error != OK:
		push_error("Failed to initiate S3 download. Error code: %d" % error)

func _on_s_3_get_request_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var file = FileAccess.open(_past_folklore_audio_file_path, FileAccess.WRITE)
		var error = FileAccess.get_open_error()
		if error != OK:
			push_error("Failed to save the downloaded file %d" % error)
			return
		file.store_buffer(body)
		file.close()
		await(get_tree().create_timer(0.1).timeout)
		_play_folklore()
	else:
		push_error("Failed to download file, %d %s" % [response_code, body.get_string_from_utf8()])

func _on_get_past_folklore_request_failed():
	if current_state == UIStates.DOWNLOADING:
		current_state = UIStates.WAITING
