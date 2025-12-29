extends Level

@export var player: CharacterBody2D

var current_checkpoint: Node2D
var camera_right_limit = 1400
var camera_top_limit = -1000


func _ready() -> void:
	# Set spawn node as checkpoint
	current_checkpoint = $Checkpoint_Container/Spawn
	AudioManager.play_music(preload("res://assets/music/CreditMusic.mp3"))
	
	SceneManager.inCredits = true

func _exit_tree() -> void:
	SceneManager.inCredits = false
