extends Node

func transcribe_folklore(s3_key):
	var form : Dictionary = {
		"s3_key": s3_key
	}
	var body = JSON.stringify(form)
	$APIClient.request(body)

func _on_api_client_response_received(response_body):
	print(response_body)

func _on_api_client_request_failed(error):
	print(error)
