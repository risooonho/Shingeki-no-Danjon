extends Node

func _ready():
	VisualServer.set_default_clear_color(Color(0.05, 0.05, 0.07))
	randomize()
#	seed(101)
	$"Generator".generate(10, 10)

func _process(delta):
	update()

#ta funkcja to hack i ma być usunięta razem z update, gdy set_default_clear_color() będzie naprawiony
func _draw():
	var camera = $"Player/Camera"
	draw_rect(Rect2(camera.get_camera_position() - OS.get_window_size()/2, OS.get_window_size()), Color(0.05, 0.05, 0.07))