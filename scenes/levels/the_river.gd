extends Level

var current_checkpoint: Node2D

var camera_right_limit = 6300
var camera_top_limit = null

# Hidden Area Tilemap Layers
@onready var hiddenarea01 = $TileMap_Container/HiddenArea_01
@onready var hiddenarea02 = $TileMap_Container/HiddenArea_02

func _ready() -> void:
	# Set spawn node as checkpoint
	current_checkpoint = $Checkpoint_Container/Spawn
	# Set up level coins
	call_deferred("setup_level", $Coin_Container)
	AudioManager.play_music(preload("res://assets/music/RiverMusic.ogg"))

func _on_end_area_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		SceneManager.load_next_level(level_name, true)

# Once the checkpoint area is entered, move checkpoint reference to checkpoint 01 node
func _on_checkpoint_01_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		current_checkpoint = $Checkpoint_Container/Checkpoint_01


## Hidden area reveal functions

# Area 01
func _on_hidden_area_01_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		hiddenarea01.visible = false
func _on_hidden_area_01_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		hiddenarea01.visible = true

# Area 02
func _on_hidden_area_02_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		hiddenarea02.visible = false
func _on_hidden_area_02_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		hiddenarea02.visible = true
