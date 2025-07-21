extends ColorRect
@onready var Welcometext = $Welcometext

# Called when the node enters the scene tree for the first time.
func _ready():
	return_text_animation_typing() # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func return_text_animation_typing():
	var full_text = "...Or have I seen you before?"
	for i in range(full_text.length()):
		Welcometext.text = full_text.substr(0, i + 1)
		await get_tree().create_timer(0.05).timeout 
	
