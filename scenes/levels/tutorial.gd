extends Level

@onready var narrator_dialogue_box = $Dialogue_Manager/Dialogue_Container/Narrator_Dialogue_Box
@onready var dialogue_data := {}

@export var player: CharacterBody2D

var current_checkpoint: Node2D
var camera_right_limit = 5500
var camera_top_limit = -4095


func _ready() -> void:
	# Set spawn node as checkpoint
	current_checkpoint = $Checkpoint_Container/Spawn
	# Remove any coins that were previously collected
	setup_level($Coin_Container)
	Dialogic.signal_event.connect(DialogicSignal)
	AudioManager.play_music(preload("res://assets/music/TutorialMusic.ogg"))



func _on_end_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		SceneManager.load_next_level(level_name, true)



# Once the checkpoint area is entered, move checkpoint reference to checkpoint 01 node
func _on_checkpoint_01_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		current_checkpoint = $Checkpoint_Container/Checkpoint_01


func _on_checkpoint_02_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		current_checkpoint = $Checkpoint_Container/Checkpoint_02


func start_dialogue(timeline_name: String):
	player.is_paused = true
	Dialogic.start(timeline_name)

func DialogicSignal(arg: String):
	if arg == "end":
		player.is_paused = false


func _on_narrator_01_trigger_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		start_dialogue("tutorial_01")
		# Disable trigger so it can't fire again
		$Dialogue_Manager/Trigger_Container/Narrator_01_Trigger.disconnect("body_entered", Callable(self, "_on_narrator_01_trigger_body_entered"))
