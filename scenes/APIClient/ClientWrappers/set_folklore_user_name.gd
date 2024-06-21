extends Node

signal name_updated
signal request_failed

func request(user_name : String):
	var form : Dictionary = {
		"user_id" : Config.get_config(AppSettings.GAME_SECTION, "UserID"),
		"user_name" : user_name
	}
	var body = JSON.stringify(form)
	$APIClient.request(body)

func _on_api_client_response_received(response_body):
	name_updated.emit()

func _on_api_client_request_failed(error):
	request_failed.emit()
