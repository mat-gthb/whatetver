extends CanvasLayer

# Called when the node enters the scene tree for the first time.
func _ready():
	transition()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func transition():
	$Fade.play("fadeout-dissolve")

