extends Node

signal folklore_submitted

func request(s3_key : String):
	var form : Dictionary = {
		"user_id" : Config.get_config(AppSettings.GAME_SECTION, "UserID"),
		"s3_key": s3_key
	}
	var body = JSON.stringify(form)
	$APIClient.request(body)

func _on_api_client_response_received(response_body):
	folklore_submitted.emit()
	print(response_body)

func _on_api_client_request_failed(error):
	print(error)
