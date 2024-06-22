extends Node

signal url_received(url : String, file_key : String, story_name : String, author_name : String, transcript : String)
signal request_failed

func request(exclude_files : Array = []):
	var form : Dictionary = {
		"user_id" : Config.get_config(AppSettings.GAME_SECTION, "UserID"),
		"exclude_files" : exclude_files
	}
	var body = JSON.stringify(form)
	print(body)
	$APIClient.request(body)

func _on_api_client_response_received(response_body):
	if response_body is Dictionary:
		if response_body.has("url"):
			url_received.emit(response_body["url"], response_body["file_key"], response_body["story_title"], response_body["author_user_name"], response_body["transcript"])
	print(response_body)


func _on_api_client_request_failed(error):
	request_failed.emit()
