extends Node

signal url_received(upload_url : String, audio_key : String)

func request_destination():
	var form : Dictionary = {}
	var body = JSON.stringify(form)
	$APIClient.request(body)

func _on_api_client_request_failed(error):
	print(error)

func _on_api_client_response_received(response_body):
	var data : Dictionary = JSON.parse_string(response_body)
	if data.has("upload_url"):
		url_received.emit(data["upload_url"], data["audio_key"])
