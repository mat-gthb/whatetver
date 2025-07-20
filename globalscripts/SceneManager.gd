extends CanvasLayer

# SceneTransitioner.gd - Autoload singleton for animated scene transitions

enum TransitionType {
	FADE,
	SLIDE_LEFT,
	SLIDE_RIGHT,
	CIRCLE_CLOSE,
	PIXELATE,
	SWIPE_UP
}

# UI Elements for transitions
var transition_rect: ColorRect
var transition_shader_rect: ColorRect
var circle_shader: Shader
var pixelate_shader: Shader

# Transition settings
var transition_duration: float = 1.0
var is_transitioning: bool = false

# Shaders for advanced effects
var circle_shader_code = """
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec2 center = vec2(0.5, 0.5);

void fragment() {
	vec2 uv = SCREEN_UV;
	float distance = length(uv - center);
	float radius = progress * 1.5;
	
	if (distance > radius) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		COLOR = texture(TEXTURE, UV);
		COLOR.a = 0.0;
	}
}
"""

var pixelate_shader_code = """
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float pixel_size : hint_range(1.0, 100.0) = 10.0;

void fragment() {
	vec2 uv = UV;
	float pixels = pixel_size * progress;
	
	if (pixels > 1.0) {
		uv = floor(uv * pixels) / pixels;
	}
	
	COLOR = texture(TEXTURE, uv);
	COLOR.a = progress;
}
"""

func _ready():
	# Set layer to be on top
	layer = 100
	
	# Create transition elements
	setup_transition_elements()
	
	# Initially hide transition overlay
	hide_transition()

func setup_transition_elements():
	# Main transition rectangle for simple effects
	transition_rect = ColorRect.new()
	transition_rect.color = Color.BLACK
	transition_rect.size = get_viewport().size
	transition_rect.position = Vector2.ZERO
	add_child(transition_rect)
	
	# Shader-based transition rectangle
	transition_shader_rect = ColorRect.new()
	transition_shader_rect.size = get_viewport().size
	transition_shader_rect.position = Vector2.ZERO
	add_child(transition_shader_rect)
	
	# Create shaders
	setup_shaders()
	
	# Connect to viewport size changes
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func setup_shaders():
	# Circle shader
	circle_shader = Shader.new()
	circle_shader.code = circle_shader_code
	
	# Pixelate shader
	pixelate_shader = Shader.new()
	pixelate_shader.code = pixelate_shader_code

func _on_viewport_size_changed():
	var viewport_size = get_viewport().size
	transition_rect.size = viewport_size
	transition_shader_rect.size = viewport_size

# Main transition function
func transition_to_scene(scene_path: String, transition_type: TransitionType = TransitionType.FADE):
	if is_transitioning:
		return
	
	is_transitioning = true
	
	match transition_type:
		TransitionType.FADE:
			await _fade_transition(scene_path)
		TransitionType.SLIDE_LEFT:
			await _slide_transition(scene_path, Vector2(-1, 0))
		TransitionType.SLIDE_RIGHT:
			await _slide_transition(scene_path, Vector2(1, 0))
		TransitionType.CIRCLE_CLOSE:
			await _circle_transition(scene_path)
		TransitionType.PIXELATE:
			await _pixelate_transition(scene_path)
		TransitionType.SWIPE_UP:
			await _swipe_transition(scene_path)
	
	is_transitioning = false

# Fade transition (classic)
func _fade_transition(scene_path: String):
	show_transition()
	transition_rect.color = Color.BLACK
	transition_rect.modulate.a = 0.0
	
	# Fade out
	var fade_out = create_tween()
	fade_out.tween_property(transition_rect, "modulate:a", 1.0, transition_duration / 2)
	await fade_out.finished
	
	# Change scene
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	
	# Fade in
	var fade_in = create_tween()
	fade_in.tween_property(transition_rect, "modulate:a", 0.0, transition_duration / 2)
	await fade_in.finished
	
	hide_transition()

# Slide transition
func _slide_transition(scene_path: String, direction: Vector2):
	show_transition()
	var viewport_size = get_viewport().size
	
	# Set initial position off-screen
	transition_rect.color = Color.BLACK
	transition_rect.position = Vector2(-direction.x * viewport_size.x, -direction.y * viewport_size.y)
	transition_rect.modulate.a = 1.0
	
	# Slide in
	var slide_in = create_tween()
	slide_in.tween_property(transition_rect, "position", Vector2.ZERO, transition_duration / 2)
	await slide_in.finished
	
	# Change scene
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	
	# Slide out
	var slide_out = create_tween()
	slide_out.tween_property(transition_rect, "position", Vector2(direction.x * viewport_size.x, direction.y * viewport_size.y), transition_duration / 2)
	await slide_out.finished
	
	# Reset position
	transition_rect.position = Vector2.ZERO
	hide_transition()

# Circle close/open transition
func _circle_transition(scene_path: String):
	show_transition()
	transition_shader_rect.visible = true
	
	# Create shader material
	var material = ShaderMaterial.new()
	material.shader = circle_shader
	material.set_shader_parameter("center", Vector2(0.5, 0.5))
	transition_shader_rect.material = material
	
	# Close circle
	var close_tween = create_tween()
	close_tween.tween_method(_set_circle_progress, 0.0, 1.0, transition_duration / 2)
	await close_tween.finished
	
	# Change scene
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	
	# Open circle
	var open_tween = create_tween()
	open_tween.tween_method(_set_circle_progress, 1.0, 0.0, transition_duration / 2)
	await open_tween.finished
	
	transition_shader_rect.visible = false
	hide_transition()

# Pixelate transition
func _pixelate_transition(scene_path: String):
	show_transition()
	transition_shader_rect.visible = true
	transition_rect.visible = false
	
	# Create shader material
	var material = ShaderMaterial.new()
	material.shader = pixelate_shader
	material.set_shader_parameter("pixel_size", 50.0)
	transition_shader_rect.material = material
	
	# Pixelate in
	var pixelate_in = create_tween()
	pixelate_in.tween_method(_set_pixelate_progress, 0.0, 1.0, transition_duration / 2)
	await pixelate_in.finished
	
	# Change scene
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	
	# Pixelate out
	var pixelate_out = create_tween()
	pixelate_out.tween_method(_set_pixelate_progress, 1.0, 0.0, transition_duration / 2)
	await pixelate_out.finished
	
	transition_shader_rect.visible = false
	transition_rect.visible = true
	hide_transition()

# Swipe up transition
func _swipe_transition(scene_path: String):
	show_transition()
	var viewport_size = get_viewport().size
	
	transition_rect.color = Color.BLACK
	transition_rect.size = Vector2(viewport_size.x, 0)
	transition_rect.position = Vector2(0, viewport_size.y)
	transition_rect.modulate.a = 1.0
	
	# Swipe up
	var swipe_up = create_tween()
	swipe_up.parallel().tween_property(transition_rect, "size:y", viewport_size.y, transition_duration / 2)
	swipe_up.parallel().tween_property(transition_rect, "position:y", 0, transition_duration / 2)
	await swipe_up.finished
	
	# Change scene
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	
	# Swipe down
	var swipe_down = create_tween()
	swipe_down.parallel().tween_property(transition_rect, "size:y", 0, transition_duration / 2)
	swipe_down.parallel().tween_property(transition_rect, "position:y", -viewport_size.y, transition_duration / 2)
	await swipe_down.finished
	
	# Reset
	transition_rect.size = viewport_size
	transition_rect.position = Vector2.ZERO
	hide_transition()

# Helper functions for shader parameters
func _set_circle_progress(progress: float):
	if transition_shader_rect.material:
		transition_shader_rect.material.set_shader_parameter("progress", progress)

func _set_pixelate_progress(progress: float):
	if transition_shader_rect.material:
		transition_shader_rect.material.set_shader_parameter("progress", progress)

# Show/hide transition overlay
func show_transition():
	visible = true

func hide_transition():
	visible = false
	transition_rect.visible = true
	transition_shader_rect.visible = false

# Set transition duration
func set_transition_duration(duration: float):
	transition_duration = duration

# Check if currently transitioning
func is_in_transition() -> bool:
	return is_transitioning

# Quick access functions for each transition type
func fade_to_scene(scene_path: String):
	transition_to_scene(scene_path, TransitionType.FADE)

func slide_left_to_scene(scene_path: String):
	transition_to_scene(scene_path, TransitionType.SLIDE_LEFT)

func slide_right_to_scene(scene_path: String):
	transition_to_scene(scene_path, TransitionType.SLIDE_RIGHT)

func circle_to_scene(scene_path: String):
	transition_to_scene(scene_path, TransitionType.CIRCLE_CLOSE)

func pixelate_to_scene(scene_path: String):
	transition_to_scene(scene_path, TransitionType.PIXELATE)

func swipe_to_scene(scene_path: String):
	transition_to_scene(scene_path, TransitionType.SWIPE_UP)
