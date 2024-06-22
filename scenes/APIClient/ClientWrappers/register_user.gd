extends Node

func register_user():
	var form : Dictionary = {
		"user_id" : Config.get_config(AppSettings.GAME_SECTION, "UserID")
	}
	var body = JSON.stringify(form)
	$APIClient.request(body)


func _on_api_client_request_failed(error):
	push_error(error)
