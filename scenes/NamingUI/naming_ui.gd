extends Control

signal name_updated

const SECRET_PRINT = "Prince Cats'A'Lot"

const BAD_WORDS : Array = ["fuck", "shit", "cunt", "cock", "pussy", "tits", "piss"]

@onready var user_name_edit : LineEdit = %UserNameEdit

var _request_in_progress : bool = false

func _validate_string(validate_string : String):
	if validate_string.is_empty() : return false
	if validate_string.length() < 4 : return false
	if validate_string.length() > 25 : return false
	for word in BAD_WORDS:
		if validate_string.findn(word) > -1: return false
	return true

func _on_set_folklore_user_name_name_updated():
	_request_in_progress = false
	name_updated.emit()

func _on_set_folklore_user_name_request_failed():
	_request_in_progress = false
	%ConfirmButton.disabled = false
	%ErrorMessage.show()

func _on_user_name_edit_text_changed(new_text):
	if new_text == SECRET_PRINT:
		%Instructions.hide()
		%CatsMessage.show()
		%ConfirmButton.hide()
	else:
		%Instructions.show()
		%CatsMessage.hide()
		%ConfirmButton.show()
	%ConfirmButton.disabled = !(_validate_string(new_text)) or _request_in_progress

func _on_confirm_button_pressed():
	_request_in_progress = true
	%ConfirmButton.disabled = _request_in_progress
	var user_name : String = user_name_edit.text.strip_edges()
	_validate_string(user_name)
	$SetFolkloreUserName.request(user_name)
