extends AudioPlayerControl

func _start_recording():
	%AudioProgressBar.hide()
	%TimeProgressBar.show()
	%TimeProgressBar.start()
	super._start_recording()

func _stop_recording():
	%AudioProgressBar.show()
	%TimeProgressBar.stop()
	%TimeProgressBar.hide()
	super._stop_recording()

func _on_time_progress_bar_timed_out():
	_stop_recording()
