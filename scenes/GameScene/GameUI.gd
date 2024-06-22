extends Control

const WAITING_STATUS = "Waiting"
const LISTENING_STATUS = "Listening"
const UPLOADING_STATUS = "Uploading"
const INTRODUCED_STATUS = "Introduced"

var _user_status : String
var _user_folklore : Array

func _ready():
	InGameMenuController.scene_tree = get_tree()
	$GetFolkloreUser.request()

func _on_get_folklore_user_user_received(user_status, user_name, folklore_accepted, folklore):
	_user_status = user_status
	_user_folklore = folklore
	%WaitingUI.folklore_data = _user_folklore
	
	%NamingUI.hide()
	%ListeningUI.hide()
	%WaitingUI.hide()
	
	if not user_name or user_name.is_empty():
		%NamingUI.show()
		return
	
	%UserStatusLabel.text = "You are currently %s" % _user_status
	if _user_status in [INTRODUCED_STATUS, UPLOADING_STATUS, LISTENING_STATUS]:
		%ListeningUI.show()
	else:
		%WaitingUI.show()

func _on_naming_ui_name_updated():
	%NamingUI.hide()
	$GetFolkloreUser.request()

func _unhandled_key_input(event):
	if event.is_action_pressed(&"hard_reset"):
		Config.erase_section(AppSettings.GAME_SECTION)

func _on_listening_ui_folklore_submitted():
	%WaitingUI.show()
