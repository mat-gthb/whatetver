extends Node

# GameManager.gd - Autoload singleton
# This script manages player data and save files throughout the game

var player_name: String = ""
var save_file_path: String = "user://saves/"

func _ready():
	# Ensure save directory exists
	if not DirAccess.dir_exists_absolute(save_file_path):
		DirAccess.open("user://").make_dir_recursive("saves")

# Check if a save file exists for the given name
func save_exists(name: String) -> bool:
	var file_path = save_file_path + name + ".save"
	return FileAccess.file_exists(file_path)

# Save player data to file
func save_game_data(additional_data: Dictionary = {}):
	if player_name.is_empty():
		print("Error: No player name set")
		return false
	
	var save_data = {
		"player_name": player_name,
		"save_date": Time.get_datetime_string_from_system(),
	}
	
	# Merge any additional data
	for key in additional_data:
		save_data[key] = additional_data[key]
	
	var file_path = save_file_path + player_name + ".save"
	var save_file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if save_file:
		save_file.store_string(JSON.stringify(save_data))
		save_file.close()
		print("Game saved for: ", player_name)
		return true
	else:
		print("Error: Could not create save file")
		return false

# Load player data from file
func load_game_data() -> Dictionary:
	if player_name.is_empty():
		print("Error: No player name set")
		return {}
	
	var file_path = save_file_path + player_name + ".save"
	
	if not FileAccess.file_exists(file_path):
		print("Error: Save file doesn't exist")
		return {}
	
	var save_file = FileAccess.open(file_path, FileAccess.READ)
	if save_file:
		var json_string = save_file.get_as_text()
		save_file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var save_data = json.get_data()
			print("Game loaded for: ", player_name)
			return save_data
		else:
			print("Error parsing save file")
			return {}
	else:
		print("Error: Could not open save file")
		return {}

# Get list of all save files (for save selection screen)
func get_all_saves() -> Array:
	var saves = []
	var dir = DirAccess.open(save_file_path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".save"):
				var player_name_from_file = file_name.replace(".save", "")
				saves.append(player_name_from_file)
			file_name = dir.get_next()
	
	return saves

# Delete a save file
func delete_save(name: String) -> bool:
	var file_path = save_file_path + name + ".save"
	
	if FileAccess.file_exists(file_path):
		var dir = DirAccess.open("user://")
		dir.remove(file_path)
		print("Deleted save for: ", name)
		return true
	else:
		print("Save file doesn't exist: ", name)
		return false
		
# FUNCTIONS FOR GAME DATA SAVES
func set_player_name(name: String):
	player_name = name
	print("Player name set to: ", player_name)

# Get the current player name
func get_player_name() -> String:
	return player_name
	
# ============= DEBUGGING TESTS =============

func debug_create_test_save(name: String):
	"""Create a test save file for debugging"""
	var old_name = player_name
	set_player_name(name)
	save_game_data({"test_data": "This is test data", "level": 1})
	player_name = old_name
	print("DEBUG: Created test save for: ", name)

func debug_list_all_saves():
	"""Print all existing saves"""
	var saves = get_all_saves()
	print("DEBUG: All saves found: ", saves)
	return saves

func debug_save_file_path(name: String) -> String:
	"""Get the full path to a save file for debugging"""
	var path = save_file_path + name + ".save"
	print("DEBUG: Save file path for '", name, "': ", path)
	print("DEBUG: File exists: ", FileAccess.file_exists(path))
	return path
