extends Node

signal url_received(upload_url : String, audio_key : String)

func request_destination(parent : String = ""):
	var form : Dictionary = {}
	if not parent.is_empty():
		form['parent'] = parent
	var body = JSON.stringify(form)
	$APIClient.request(body)

func _on_api_client_request_failed(error):
	print(error)

func _on_api_client_response_received(response_body):
	if response_body.has("upload_url"):
		url_received.emit(response_body["upload_url"], response_body["audio_key"])
