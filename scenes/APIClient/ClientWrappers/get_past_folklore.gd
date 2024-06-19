extends Node

signal url_received(url : String, transcription : String)

func get_past_folklore():
	var body = $APIClient.mock_empty_body()
	$APIClient.request(body)

func _on_api_client_response_received(response_body):
	if response_body is Dictionary:
		if response_body.has("url"):
			url_received.emit(response_body["url"], response_body["transcript"])
	print(response_body)
