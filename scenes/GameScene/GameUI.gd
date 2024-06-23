extends Control

const WAITING_STATUS = "Waiting"
const LISTENING_STATUS = "Listening"
const UPLOADING_STATUS = "Uploading"
const INTRODUCED_STATUS = "Introduced"
const USER_STATUS_STRING = "You are in the %s generation. You are currently %s.\n"

const LOWEST_BG_MUSIC_VOLUME = -60.0
const MID_AMBIENCE_MUSIC_VOLUME = -15.0
const LOWEST_AMBIENCE_MUSIC_VOLUME = -30.0

var _user_status : String
var _user_folklore : Array

var _connect_attempts : int = 0

func _refresh_user():
	$GetFolkloreUser.request()
	%RequestProgressBar.show()
	%RequestProgressBar.start()

func _ready():
	InGameMenuController.scene_tree = get_tree()
	_refresh_user()

func _get_number_suffix(number : int) -> String:
	if number == 1:
		return "st"
	elif number == 2:
		return"nd"
	elif number == 3:
		return "rd"
	else:
		return "th"

func _on_get_folklore_user_user_received(user_status, user_name, generation, folklore_accepted, folklore):
	%RequestProgressBar.stop()
	%RequestProgressBar.hide()
	_user_status = user_status
	_user_folklore = folklore
	%WaitingUI.folklore_data = _user_folklore
	
	%NamingUI.hide()
	%ListeningUI.hide()
	%WaitingUI.hide()
	
	if not user_name or user_name.is_empty():
		%NamingUI.show()
		return
	var generation_string = "%d%s" % [generation, _get_number_suffix(generation)]

	%UserStatusLabel.text = USER_STATUS_STRING % [generation_string, _user_status]
	if _user_status in [INTRODUCED_STATUS, UPLOADING_STATUS, LISTENING_STATUS]:
		%ListeningUI.show()
		%ListeningUI.can_create_custom = folklore_accepted > 0 or generation < 2
	elif _user_status in [WAITING_STATUS]:
		%WaitingUI.show()

func _on_naming_ui_name_updated():
	%NamingUI.hide()
	_refresh_user()

func _unhandled_key_input(event):
	if event.is_action_pressed(&"hard_reset"):
		Config.erase_section(AppSettings.GAME_SECTION)

func _on_listening_ui_folklore_submitted():
	var tween = create_tween()
	tween.tween_property($BackgroundMusicPlayer, "volume_db", 0, 3)
	tween.parallel().tween_property($AmbienceStreamPlayer, "volume_db", 0, 3)
	%ListeningUI.hide()
	_refresh_user()

func _on_time_progress_bar_timed_out():
	_refresh_user()
	var label_text : String = "Trying again"
	_connect_attempts += 1
	if _connect_attempts > 1:
		label_text += " (%d)" % _connect_attempts
	%UserStatusLabel.text = label_text

func _on_listening_ui_playback_started():
	var tween = create_tween()
	tween.tween_property($BackgroundMusicPlayer, "volume_db", -60, 3)
	tween.parallel().tween_property($AmbienceStreamPlayer, "volume_db", MID_AMBIENCE_MUSIC_VOLUME, 3)

func _on_listening_ui_playback_ended():
	var tween = create_tween()
	tween.tween_property($BackgroundMusicPlayer, "volume_db", 0, 3)
	tween.parallel().tween_property($AmbienceStreamPlayer, "volume_db", 0, 3)

func _on_listening_ui_recording_started():
	var tween = create_tween()
	tween.tween_property($AmbienceStreamPlayer, "volume_db", LOWEST_AMBIENCE_MUSIC_VOLUME, 0.5)

func _on_listening_ui_recording_stopped():
	var tween = create_tween()
	tween.tween_property($AmbienceStreamPlayer, "volume_db", MID_AMBIENCE_MUSIC_VOLUME, 0.5)
