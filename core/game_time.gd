extends Node
## One full game day takes 300 real seconds, matching the original campus cycle.
signal time_changed(hour: float)

var day_duration_seconds := 300.0
var time_running := true
var current_hour := 0.0

func _process(delta: float) -> void:
	if time_running and day_duration_seconds > 0.0:
		set_time(current_hour + delta * 24.0 / day_duration_seconds)

func set_time(hour: float) -> void:
	current_hour = fposmod(hour, 24.0)
	time_changed.emit(current_hour)
