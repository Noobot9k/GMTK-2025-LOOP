extends GPUParticles3D
class_name AutoPlayGPUParticles3D

@export var AutoPlay : bool = true

func _ready() -> void:
	if AutoPlay: emitting = true
