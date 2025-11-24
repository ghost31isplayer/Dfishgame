extends Node2D
class_name MusicManager

@export var fade_time: float = 1.0

# Try to grab existing children named "_player_a" and "_player_b" if they exist.
@onready var _player_a: AudioStreamPlayer = get_node_or_null("_player_a")
@onready var _player_b: AudioStreamPlayer = get_node_or_null("_player_b")

var _active_player: AudioStreamPlayer
var _inactive_player: AudioStreamPlayer

func _ready() -> void:
	# If the child nodes don't exist (e.g. script autoloaded without the scene),
	# create them so we never hit null.
	if _player_a == null:
		_player_a = AudioStreamPlayer.new()
		_player_a.name = "_player_a"
		add_child(_player_a)
	
	if _player_b == null:
		_player_b = AudioStreamPlayer.new()
		_player_b.name = "_player_b"
		add_child(_player_b)
	
	_active_player = _player_a
	_inactive_player = _player_b
	
	_active_player.volume_db = -16.0
	_inactive_player.volume_db = -80.0



func play_music(stream: AudioStream) -> void:
	if _active_player.stream == stream:
		return # already playing this track
	
	_inactive_player.stream = stream
	_inactive_player.volume_db = -80.0
	_inactive_player.play()
	
	_crossfade()


func stop_music() -> void:
	if _active_player:
		_active_player.stop()
	if _inactive_player:
		_inactive_player.stop()


func _crossfade() -> void:
	var from_p := _active_player
	var to_p := _inactive_player
	
	if from_p == null or to_p == null:
		return
	
	var t := create_tween()
	t.tween_property(from_p, "volume_db", -80.0, fade_time)
	t.parallel().tween_property(to_p, "volume_db", -16.0, fade_time)
	
	t.tween_callback(func():
		from_p.stop()
		var tmp = _active_player
		_active_player = _inactive_player
		_inactive_player = tmp
	)
