extends Node

signal url_received(upload_url : String, audio_key : String)

func request_destination():
	var body = $APIClient.mock_empty_body()
	$APIClient.request(body)

func _on_api_client_request_failed(error):
	print(error)

func _on_api_client_response_received(response_body):
	if response_body.has("upload_url"):
		url_received.emit(response_body["upload_url"], response_body["audio_key"])
