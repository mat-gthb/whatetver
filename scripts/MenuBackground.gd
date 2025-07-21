extends Control

# References to UI elements
@onready var title_label = $Starttext
@onready var text_box = $NameInput
@onready var tween = $Tween
@onready var error_label = $ErrorLabel

# Game manager singleton reference
var game_manager: GameManager

func _ready():
	# Get reference to GameManager singleton
	game_manager = GameManager
	MusicManager.play_music("menu")
	
	# Hide elements initially
	title_label.modulate.a = 0.0
	text_box.modulate.a = 0.0
	error_label.visible = false
	
	# Connect signals
	#submit_button.pressed.connect(_on_submit_pressed)
	text_box.text_submitted.connect(_on_text_submitted)
	
	# Start the animation sequence
	await get_tree().create_timer(5.00).timeout
	start_menu_animation()

func start_menu_animation():
	# Create tween for smooth animations
	var tween = create_tween()
	tween.set_parallel(true)  # Allow multiple animations at once
	
	# Animate title text appearing
	tween.tween_property(title_label, "modulate:a", 1.0, 2.0)
	
	# Wait a bit, then animate the text box
	await tween.finished
	
	# Animate text box appearing
	var box_tween = create_tween()
	box_tween.set_parallel(true)
	
	# Fade in
	box_tween.tween_property(text_box, "modulate:a", 1.0, 3.0)

func reverse_menu_animation():
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(title_label, "modulate:a", 0.0, 2.0)
	
	var box_tween = create_tween()
	box_tween.set_parallel(true)
	box_tween.tween_property(text_box, "modulate:a", 0.0, 2.0)

# Called when submit button is pressed or Enter is hit in text box
func _on_submit_pressed():
	_validate_and_process_name()

func _on_text_submitted(text: String):
	_validate_and_process_name()

func _validate_and_process_name():
	if SceneManager.is_in_transition():
		return
		
	var player_name = text_box.text.strip_edges()
	
	# Validate the name
	var validation_result = _validate_name(player_name)
	
	if validation_result.is_valid:
		# Hide error message
		error_label.visible = false
		
		# Save the player name and game as a new save
		game_manager.set_player_name(player_name)
		
		# Check if this name matches an existing save
		if game_manager.save_exists(player_name):
			reverse_menu_animation()
			# Switch to welcome back scene
			await get_tree().create_timer(3.0).timeout
			get_tree().change_scene_to_file("res://scenes/Returning.tscn")
			
		else:
			# Switch to character creation
			game_manager.save_game_data()
			
			SceneManager.fade_to_scene("res://scenes/CharacterSpeciSelect.tscn")
	else:
		# Show error message
		_show_error(validation_result.error_message)

func _validate_name(name: String) -> Dictionary:
	var result = {"is_valid": false, "error_message": ""}
	
	# Check length (2 to 20 characters)
	if name.length() < 2:
		result.error_message = "Name must be at least 2 characters long"
		return result
	
	if name.length() > 20:
		result.error_message = "Name must be no more than 20 characters long"
		return result
	
	# Check for only letters (no numbers or special characters)
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z]+$")  # Only letters, no spaces
	
	if not regex.search(name):
		result.error_message = "Name can only contain letters (A-Z, a-z)"
		return result
	
	result.is_valid = true
	return result

func _show_error(message: String):
	error_label.text = message
	error_label.visible = true
	
	# Optional: Add a tween to make error appear smoothly
	var error_tween = create_tween()
	error_label.modulate.a = 0.0
	error_tween.tween_property(error_label, "modulate:a", 1.0, 0.3)

