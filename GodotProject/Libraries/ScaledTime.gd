@tool
extends Node

var CurrentTime : float = 0
var CurrentTime_Unscaled : float = 0

# use await
func WaitOneFrame():
	return get_tree().process_frame

# use await
func WaitForSeconds(seconds : float):
	return get_tree().create_timer(seconds).timeout

func _process(delta):
	CurrentTime += delta
	CurrentTime_Unscaled += delta / Engine.time_scale
