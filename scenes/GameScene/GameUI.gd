extends Control

const WAITING_STATUS = "Waiting"
const LISTENING_STATUS = "Listening"
const UPLOADING_STATUS = "Uploading"
const INTRODUCED_STATUS = "Introduced"

var _user_status : String
var _user_folklore : Array

var _connect_attempts : int = 0

func _refresh_user():
	$GetFolkloreUser.request()
	%RequestProgressBar.start()

func _ready():
	InGameMenuController.scene_tree = get_tree()
	_refresh_user()

func _on_get_folklore_user_user_received(user_status, user_name, folklore_accepted, folklore):
	%RequestProgressBar.stop()
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
	elif _user_status in [WAITING_STATUS]:
		%WaitingUI.show()

func _on_naming_ui_name_updated():
	%NamingUI.hide()
	_refresh_user()

func _unhandled_key_input(event):
	if event.is_action_pressed(&"hard_reset"):
		Config.erase_section(AppSettings.GAME_SECTION)

func _on_listening_ui_folklore_submitted():
	%ListeningUI.hide()
	_refresh_user()

func _on_time_progress_bar_timed_out():
	_refresh_user()
	var label_text : String = "Trying again"
	_connect_attempts += 1
	if _connect_attempts > 1:
		label_text += " (%d)" % _connect_attempts
	%UserStatusLabel.text = label_text

