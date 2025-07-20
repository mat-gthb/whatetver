extends Node

# MusicManager.gd - Autoload singleton for persistent music across scenes

@onready var audio_player = AudioStreamPlayer.new()

var current_track: AudioStream = null
var is_playing: bool = false
var music_volume: float = 0.5
var fade_duration: float = 1.0

# Dictionary to store different music tracks
var music_tracks = {
	"menu": "res://audio/menu_music.wav"
}

func _ready():
	# Add the audio player to the scene tree
	add_child(audio_player)
	
	# Set initial properties
	audio_player.volume_db = linear_to_db(music_volume)
	audio_player.autoplay = false
	
	# Connect to scene change signal to handle music transitions
	get_tree().tree_changed.connect(_on_scene_changed)

# Play a specific track
func play_music(track_name: String, fade_in: bool = true):
	if not music_tracks.has(track_name):
		print("Music track not found: ", track_name)
		return
	
	var new_track = load(music_tracks[track_name])
	
	# Don't restart if same track is already playing
	if current_track == new_track and is_playing:
		return
	
	current_track = new_track
	
	if fade_in and is_playing:
		# Fade out current, then fade in new
		fade_to_track(new_track)
	else:
		# Direct play
		audio_player.stream = new_track
		audio_player.play()
		is_playing = true
		
		if fade_in:
			fade_in_track()

# Fade between tracks
func fade_to_track(new_track: AudioStream):
	# Fade out current track
	var fade_out_tween = create_tween()
	fade_out_tween.tween_method(_set_volume, music_volume, 0.0, fade_duration / 2)
	
	await fade_out_tween.finished
	
	# Change track and fade in
	audio_player.stream = new_track
	audio_player.play()
	current_track = new_track
	is_playing = true
	
	var fade_in_tween = create_tween()
	fade_in_tween.tween_method(_set_volume, 0.0, music_volume, fade_duration / 2)

# Fade in currently loaded track
func fade_in_track():
	var tween = create_tween()
	_set_volume(0.0)
	tween.tween_method(_set_volume, 0.0, music_volume, fade_duration)

# Fade out current track
func fade_out_track():
	var tween = create_tween()
	tween.tween_method(_set_volume, music_volume, 0.0, fade_duration)
	
	await tween.finished
	stop_music()

# Stop music completely
func stop_music():
	audio_player.stop()
	is_playing = false
	current_track = null

# Pause music
func pause_music():
	if is_playing:
		audio_player.stream_paused = true

# Resume music
func resume_music():
	if is_playing:
		audio_player.stream_paused = false

# Set volume (0.0 to 1.0)
func set_music_volume(volume: float):
	music_volume = clamp(volume, 0.0, 1.0)
	_set_volume(music_volume)

# Internal volume setter for tweening
func _set_volume(volume: float):
	audio_player.volume_db = linear_to_db(volume)

# Check if music is currently playing
func is_music_playing() -> bool:
	return is_playing and audio_player.playing

# Get current track name
func get_current_track_name() -> String:
	for track_name in music_tracks:
		if music_tracks[track_name] == str(current_track.resource_path):
			return track_name
	return ""

# Add new music track to the dictionary
func add_music_track(track_name: String, file_path: String):
	music_tracks[track_name] = file_path

# Scene change handler (optional - for automatic music switching)
func _on_scene_changed():
	# You can add logic here to automatically change music based on scene
	pass

# Play music based on scene name (helper function)
func play_music_for_scene(scene_name: String):
	match scene_name.to_lower():
		"menu", "mainmenu", "startmenu":
			play_music("menu")
		"game", "level", "gameplay":
			play_music("gameplay")
		"victory", "win":
			play_music("victory")
		"defeat", "gameover", "lose":
			play_music("defeat")
		_:
			# Default to gameplay music
			play_music("gameplay")
