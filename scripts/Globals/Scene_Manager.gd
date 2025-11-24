extends Node

signal load_start(loading_screen)                       ## Triggered when an asset begins loading
signal scene_added(loaded_scene:Node,loading_screen)    ## Triggered right after asset is added to SceneTree but before transition animation finishes
signal load_complete(loaded_scene:Node)                 ## Triggered when loading has completed

signal _content_finished_loading(content)               ## internal - triggered when content is loaded and final data handoff and transition out begins
signal _content_invalid(content_path:String)            ## internal - triggered when attempting to load invalid content (e.g. an asset does not exist or path is incorrect)
signal _content_failed_to_load(content_path:String)     ## internal - triggered when loading has started but failed to complete

var _loading_screen : LoadingScreen
var _loading_screen_scene : PackedScene = preload("res://scenes/menus/loading_screen.tscn")
var _transition : String
var _content_path : String
var _load_progress_timer : Timer
var _load_scene_into : Node 
var _scene_to_unload : Node
var _loading_in_progress : bool = false

var current_level_node : Node
var inCredits : bool = false

## Connects signals and runs start up commands, like making sure levels.json exists
func _ready() -> void:
	_content_invalid.connect(_on_content_invalid)
	_content_failed_to_load.connect(_on_content_failed_to_load)
	_content_finished_loading.connect(_on_content_finished_loading)
	
	ensure_level_data_exists()


func _add_loading_screen(transition_type:String="no_transition"):
	# using "no_in_transition" as the transition name when skipping a transition felt... weird
	# dunno if this solution is better, but it's only one line so I can live with this one-off
	# An alternative would be to store starting animations in a dictionary and swap them for the animation name
	# it removes this one-off, but adds a step elsewhere - all about preference.
	_transition = "no_to_transition" if transition_type == "no_transition" else transition_type
	_loading_screen = _loading_screen_scene.instantiate() as LoadingScreen
	get_tree().root.add_child(_loading_screen)
	_loading_screen.start_transition(_transition)

func swap_scenes(scene_to_load:String, load_into:Node=null, scene_to_unload:Node=null, transition_type:String="fade_to_black") -> void:
	# Unhide mouse hen called  - Just in case
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if _loading_in_progress:
		push_warning("SceneManager is already loading something")
		return
	
	_loading_in_progress = true
	if load_into == null: load_into = get_tree().root
	_load_scene_into = load_into
	_scene_to_unload = scene_to_unload
	
	_add_loading_screen(transition_type)
	_load_content(scene_to_load)

func _load_content(content_path:String) -> void:
	#print("Loading Start...")
	load_start.emit(_loading_screen)
	
	_content_path = content_path
	var loader = ResourceLoader.load_threaded_request(content_path)
	if not ResourceLoader.exists(content_path) or loader == null:
		_content_invalid.emit(content_path)
		return 		
	
	_load_progress_timer = Timer.new()
	_load_progress_timer.wait_time = 0.1
	_load_progress_timer.timeout.connect(_monitor_load_status)
	
	get_tree().root.add_child(_load_progress_timer)   # NEW > insert loading bar into?
	_load_progress_timer.start()
	#print("Loading Finish...")

func _monitor_load_status() -> void:
	var load_progress = []
	var load_status = ResourceLoader.load_threaded_get_status(_content_path, load_progress)
	
	match load_status:
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_content_invalid.emit(_content_path)
			_load_progress_timer.stop()
			return
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if _loading_screen != null:
				_loading_screen.update_bar(load_progress[0] * 100) # 0.1
		ResourceLoader.THREAD_LOAD_FAILED:
			_content_failed_to_load.emit(_content_path)
			_load_progress_timer.stop()
			return
		ResourceLoader.THREAD_LOAD_LOADED:
			_load_progress_timer.stop()
			_load_progress_timer.queue_free()
			_content_finished_loading.emit(ResourceLoader.load_threaded_get(_content_path).instantiate())
			return # this last return isn't necessary but I like how the 3 dead ends stand out as similarinished_loading.emit(ResourceLoader.load_threaded_get(_content_path).instantiate())


func _on_content_failed_to_load(path:String):
	printerr("Error: Failed to load resource: '%s'" % [path])
func _on_content_invalid(path:String) -> void:
	printerr("Error: Cannot load resource: '%s'" % [path])
func _on_content_finished_loading(incoming_scene) -> void:
	var outgoing_scene = _scene_to_unload
	
	# Set new scene as current level node
	current_level_node = incoming_scene
	
	# Set the level name from the scene file name
	if incoming_scene.scene_file_path != "":
		var scene_basename = incoming_scene.scene_file_path.get_file().get_basename()
		incoming_scene.set("level_name", scene_basename)
		
	# Transfer data if applicable
	if outgoing_scene != null:
		if outgoing_scene.has_method("get_data") and incoming_scene.has_method("receive_data"):
			incoming_scene.receive_data(outgoing_scene.get_data())
			
	# Add the scene to the tree
	_load_scene_into.add_child(incoming_scene)
	scene_added.emit(incoming_scene, _loading_screen)
	
	# Remove the old scene
	if _scene_to_unload != null:
		if _scene_to_unload != get_tree().root:
			_scene_to_unload.queue_free()
			
	# Call optional hooks
	if incoming_scene.has_method("init_scene"):
		incoming_scene.init_scene()
		
	if _loading_screen != null:
		_loading_screen.finish_transition()
		
	if incoming_scene.has_method("start_scene"):
		incoming_scene.start_scene()
		
	# Mark loading complete
	_loading_in_progress = false
	load_complete.emit(incoming_scene)




## Logic for reading and writing level data to the level.json
## Adds persistance to levels like which coins have been collected
func ensure_level_data_exists():
	var save_path = "user://levels.json"
	var default_path = "res://scenes/levels/levels.json"
	
	if not FileAccess.file_exists(save_path):
		if FileAccess.file_exists(default_path):
			var default_file = FileAccess.open(default_path, FileAccess.READ)
			var save_file = FileAccess.open(save_path, FileAccess.WRITE)
			
			if default_file and save_file:
				save_file.store_string(default_file.get_as_text())
				print("Copied default levels.json to user://")
			else:
				push_error("Failed to open default or user save file.")
		else:
			push_error("Default levels.json is missing from res://")

func load_level_data() -> Dictionary:
	if not FileAccess.file_exists("user://levels.json"):
		printerr("levels.json does not exist in user://")
		return {}
		
	var file = FileAccess.open("user://levels.json", FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		var result = JSON.parse_string(json_text)
		if result is Dictionary:
			return result
		else:
			printerr("Failed to parse levels.json.")
	else:
		printerr("Could not open levels.json.")
	return {}

func leave_level(level_name: String, complete: bool):
	if SceneManager.inCredits:
		return
	
	var data = load_level_data()
	var levels = data.get("levels", [])
	var collected_this_run = current_level_node.get_collected_coins(current_level_node.get_node("Coin_Container"))
	
	for level in levels:
		if level.get("level_name") == level_name:
			# Mark the level as complete if called from end of level
			if complete:
				level["is_completed"] = true
			
			# Ensure arrays exist
			if !level.has("uncollected_coins"):
				level["uncollected_coins"] = []
			if !level.has("collected_coins"):
				level["collected_coins"] = []
				
			var uncollected = level["uncollected_coins"]
			var collected = level["collected_coins"]
			
			for coin in collected_this_run:
				if coin in uncollected:
					uncollected.erase(coin)
					if coin not in collected:
						collected.append(coin)
						
			# Update the level entry
			level["uncollected_coins"] = uncollected
			level["collected_coins"] = collected
			break
			
	save_level_data(data)

func save_level_data(data: Dictionary):
	var file = FileAccess.open("user://levels.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))  # Pretty print with tabs

func get_next_level(current_level_name: String) -> Dictionary:
	var data = load_level_data()
	var levels = data.get("levels", [])
	
	for i in levels.size():
		if levels[i].get("level_name", "") == current_level_name:
			if i + 1 < levels.size():
				return levels[i + 1]
			else:
				print("This was the last level.")
				return {}
	
	print("Current level not found in levels.json")
	return {}

func get_next_level_path(current_level_name: String):
	var next_level = get_next_level(current_level_name)
	if next_level:
		var scene_path = next_level.get("scene_path", "")
		if scene_path != "":
			return scene_path


func load_next_level(current_level_name: String, complete: bool):
	# Save level changes
	leave_level(current_level_name, complete)
	# Call next uncompleted level and free current level
	# If no uncompleted levels remain, load main menu
	if get_next_level_path(current_level_name):
		swap_scenes(get_next_level_path(current_level_name), null, current_level_node, "no_transition")
	else:
		swap_scenes("res://scenes/menus/Credits.tscn", null, current_level_node, "no_transition")


## Debug command to reset saved level data
func reset_all_levels() -> void:
	var data = load_level_data()
	var levels = data.get("levels", [])
	
	for level in levels:
		level["is_completed"] = false
		level["collected_coins"] = []
	
	save_level_data(data)
	print("All levels have been reset.")
