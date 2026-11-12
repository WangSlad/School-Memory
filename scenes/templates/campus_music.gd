extends AudioStreamPlayer

# Explicit references ensure the playlist is included in exported builds.
const DAILY_TRACKS: Array[AudioStream] = [
	preload("res://assets/musics/日常1.mp3"),
	preload("res://assets/musics/日常2.mp3"),
	preload("res://assets/musics/日常3.mp3"),
	preload("res://assets/musics/日常4.mp3"),
	preload("res://assets/musics/日常5.mp3"),
	preload("res://assets/musics/日常6.mp3"),
	preload("res://assets/musics/日常7.mp3"),
]

var _remaining: Array[AudioStream] = []
var _last_track: AudioStream


func _ready() -> void:
	finished.connect(_play_next)
	_play_next()


func _play_next() -> void:
	if _remaining.is_empty():
		_remaining = DAILY_TRACKS.duplicate()
		_remaining.shuffle()
		if _remaining.size() > 1 and _remaining.back() == _last_track:
			_remaining.reverse()
	stream = _remaining.pop_back()
	_last_track = stream
	play()
