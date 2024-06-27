extends Node

var characters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890'

func generate_word(length):
	var word: String
	var char_length = len(characters)
	for i in range(length):
		word += characters[randi()% char_length]
	return word

func _set_user_id() -> String:
	randomize() # Should be call on run, but doing again for the sake of it.
	var key = "UserID"
	var default = generate_word(32)
	var user_id = Config.get_config(AppSettings.GAME_SECTION, key, default)
	if user_id == default:
		Config.set_config(AppSettings.GAME_SECTION, key, user_id)
	return user_id

func register_user():
	var form : Dictionary = {
		"user_id" : _set_user_id()
	}
	var body = JSON.stringify(form)
	$APIClient.request(body)


func _on_api_client_request_failed(error):
	push_error(error)
