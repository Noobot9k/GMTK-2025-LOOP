extends SubViewport
class_name SubViewportAutoResolution

@export var UseScreenResolution : bool = true
@export var ScreenResolutionDivider : int = 1

func _process(_delta: float) -> void:
	size = DisplayServer.screen_get_usable_rect().size / ScreenResolutionDivider
