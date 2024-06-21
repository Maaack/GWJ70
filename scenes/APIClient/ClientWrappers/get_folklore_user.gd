extends Node

signal user_received(user_status : String, user_name : String, folklore_accepted: int, folklore : Dictionary)

func request():
	var form : Dictionary = {
		"user_id" : Config.get_config(AppSettings.GAME_SECTION, "UserID")
	}
	var body = JSON.stringify(form)
	$APIClient.request(body)

func _on_api_client_response_received(response_body):
	if response_body.has("user_status"):
		user_received.emit(response_body["user_status"], 
		response_body["user_name"], 
		response_body["folklore_accepted"], 
		response_body["files"])
