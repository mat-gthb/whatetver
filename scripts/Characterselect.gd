extends ColorRect
@onready var greeting_label = $GreetingLabel
@onready var dog_button = $dogbutton
@onready var cat_button = $catbutton
func _ready():
	# Get the player name from GameManager and display it
	var player_name = GameManager.get_player_name()
	greeting_label.text = "Okay " + player_name + ", what species are you?"
	
	# Optional: Add some animation to make it appear smoothly
	animate_greeting()

func animate_greeting():
	# Start invisible
	greeting_label.modulate.a = 0.0
	dog_button.modulate.a = 0.0
	cat_button.modulate.a = 0.0
	# Animate fade in
	var tween = create_tween()
	tween.tween_property(greeting_label, "modulate:a", 1.0, 2.0)
	tween.tween_property(dog_button, "modulate:a", 1.0, 3.0)
	tween.set_parallel(true)  
	tween.tween_property(cat_button, "modulate:a", 1.0, 3.0)
# Alternative: If you want to add typing effect
func animate_greeting_with_typing():
	var player_name = GameManager.get_player_name()
	var full_text = "Okay " + player_name + ", what species are you?"
	
	greeting_label.text = ""
	
	# Type out each character
	for i in range(full_text.length()):
		greeting_label.text = full_text.substr(0, i + 1)
		await get_tree().create_timer(0.05).timeout  # Adjust speed here
