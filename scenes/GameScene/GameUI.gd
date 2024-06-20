extends Control

var _user_status : String
var _user_folklore : Array

func _ready():
	InGameMenuController.scene_tree = get_tree()
	$GetFolkloreUser.request()

func _on_get_folklore_user_user_received(user_status, folklore):
	_user_status = user_status
	_user_folklore = folklore
	%UserStatusLabel.text = "You are currently %s" % _user_status
	%WaitingUI.folklore_data = _user_folklore
