extends Node

signal folklore_queued(file_key : String, audio_stream : AudioStreamWAV, story_title : String, author_name : String, transcript : String)

@export var buttons_container : Container
@export var slots_available : int
@export var custom_slot_available : bool = false

var data : Array = []

var _requested_folklore_iter : int = 0
var _requesting_folklore : bool = false

func _clear_list():
	for child in buttons_container.get_children():
		child.queue_free()

func _build_list():
	var empty_to_listen : bool = true
	var data_iter = 0
	for data_row in data:
		var button_instance := Button.new()
		button_instance.text = "Wait"
		if data_row.has(&"story_title") and data_row.has(&"author_name"):
			button_instance.text = "%s by %s" % [data_row[&"story_title"], data_row[&"author_name"]]
			if data_row.has(&"retelling_submitted") and data_row[&"retelling_submitted"]:
				button_instance.disabled = true
		elif empty_to_listen:
			empty_to_listen = false
			button_instance.text = "Listen..."
		else:
			button_instance.disabled = true
		if button_instance.has_signal(&"pressed"):
			button_instance.connect(&"pressed", _on_past_folklore_button_pressed.bind(button_instance, data_iter))
		buttons_container.add_child.call_deferred(button_instance)
		data_iter += 1
	if custom_slot_available:
		var button_instance := Button.new()
		button_instance.text = "Share Your Own..."
		if button_instance.has_signal(&"pressed"):
			button_instance.connect(&"pressed", _on_share_custom_button_pressed)
		buttons_container.add_child.call_deferred(button_instance)

func _refresh_list():
	_clear_list()
	_build_list()

func _reset_download_button_state():
	var button_child : Button = buttons_container.get_child(_requested_folklore_iter)
	if button_child:
		button_child.disabled = false
	if buttons_container.get_child_count() > _requested_folklore_iter + 1:
		var next_child = buttons_container.get_child(_requested_folklore_iter + 1)
		next_child.disabled = false
		next_child.text = "Listen..."

func _get_past_folklore_audio_stream(audio_stream_path) -> AudioStreamWAV:
	if not FileAccess.file_exists(audio_stream_path): return
	var audio_loader = AudioLoader.new()
	var audio_stream : AudioStreamWAV = audio_loader.loadfile(audio_stream_path)
	return audio_stream

func _play_folklore(data_index : int):
	var data_row : Dictionary = data[data_index]
	var audio_stream := _get_past_folklore_audio_stream(data_row[&"audio_file_path"])
	if not audio_stream:
		audio_stream = AudioStreamWAV.new()
	folklore_queued.emit(data_row[&"file_name"], audio_stream, data_row[&"story_title"], data_row[&"author_name"], data_row[&"transcript"])

func _create_folklore():
	var audio_stream = AudioStreamWAV.new()
	folklore_queued.emit("", audio_stream, "", "", "Share your own story with the community of listeners.")

func _on_share_custom_button_pressed():
	_create_folklore()


func _on_past_folklore_button_pressed(button_instance, data_iter):
	var past_folklore : Dictionary = data[data_iter]
	if past_folklore.is_empty():
		if _requesting_folklore : return
		_requesting_folklore = true
		button_instance.disabled = true
		_requested_folklore_iter = data_iter
		$GetPastFolklore.request(_get_existing_file_names())
	else:
		_play_folklore(data_iter)

func _get_existing_file_names() -> Array[String]:
	var existing_file_names : Array[String] = []
	for data_row in data:
		if not data_row.is_empty() and data_row.has(&"file_name"):
			existing_file_names.append(data_row[&"file_name"])
	return existing_file_names

func _on_get_past_folklore_url_received(download_url : String, file_key : String, story_title : String, author_name : String, transcript : String):
	var data_row = data[_requested_folklore_iter]
	data_row[&"download_url"] = download_url
	data_row[&"transcript"] = transcript
	data_row[&"file_name"] = file_key
	data_row[&"audio_file_path"] = "user://%s" % file_key.get_file()
	data_row[&"story_title"] = story_title
	data_row[&"author_name"] = author_name
	_update_persistent_setting()
	var button_child : Button = buttons_container.get_child(_requested_folklore_iter)
	if button_child:
		button_child.text = "%s by %s" % [data_row[&"story_title"], data_row[&"author_name"]]
	if FileAccess.file_exists(data_row[&"audio_file_path"]):
		_reset_download_button_state()
		_play_folklore(_requested_folklore_iter)
		return
	var error = $S3GetRequest.request_raw(download_url, Array(), HTTPClient.METHOD_GET, PackedByteArray())
	if error != OK:
		push_error("Failed to initiate S3 download. Error code: %d" % error)
	data[_requested_folklore_iter] = data_row

func _on_s_3_get_request_request_completed(result, response_code, headers, body):
	_requesting_folklore = false
	_reset_download_button_state()
	if response_code == 200:
		var data_row = data[_requested_folklore_iter]
		var file = FileAccess.open(data_row[&"audio_file_path"], FileAccess.WRITE)
		var error = FileAccess.get_open_error()
		if error != OK:
			push_error("Failed to save the downloaded file %d" % error)
			return
		file.store_buffer(body)
		file.close()
		await(get_tree().create_timer(0.1).timeout)
		_play_folklore(_requested_folklore_iter)
	else:
		push_error("Failed to download file, %d %s" % [response_code, body.get_string_from_utf8()])

func _get_retold_count() -> int:
	var retold_count : int = 0
	for data_row in data:
		if data_row.has(&"retelling_submitted") and data_row[&"retelling_submitted"]:
			retold_count += 1
	return retold_count

func _ready():
	var default_data := Array()
	for slot_iter in slots_available:
		default_data.append({})
	data = Config.get_config(AppSettings.GAME_SECTION, "PastFolklore", default_data)
	var retold_count = _get_retold_count()
	while len(data) - retold_count < slots_available:
		data.append({})
	_refresh_list()

func _update_persistent_setting():
	Config.set_config(AppSettings.GAME_SECTION, "PastFolklore", data)

func _on_get_past_folklore_request_failed():
	var button_child : Button = buttons_container.get_child(_requested_folklore_iter)
	if button_child:
		button_child.text = "Try again later..."
		button_child.disabled = true
	_requesting_folklore = false

func mark_folklore_submitted(file_key):
	var data_iter = 0
	for data_row in data:
		if not data_row.is_empty() and data_row.has(&"file_name"):
			if file_key == data_row[&"file_name"]:
				data_row[&"retelling_submitted"] = true
				break
		data_iter += 1
	var button_child : Button = buttons_container.get_child(data_iter)
	if button_child:
		button_child.disabled = true
	_update_persistent_setting()
