extends ProgressBar

signal timed_out

enum States{
	STOPPED,
	RUNNING,
	PAUSED
}

@export var time : float

var _state : States = States.STOPPED

func start(timer_time : float = 0.0):
	_state = States.RUNNING
	if timer_time > 0:
		time = timer_time
	$Timer.start(time)

func stop():
	_state = States.STOPPED
	value = 0
	if not $Timer.is_stopped():
		$Timer.stop()

func _on_timer_timeout():
	timed_out.emit()

func _process(delta):
	if _state == States.RUNNING:
		var ratio = 1.0 - ($Timer.time_left / time)
		value = ratio

