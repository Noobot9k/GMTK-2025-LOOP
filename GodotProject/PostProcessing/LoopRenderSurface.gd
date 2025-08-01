@tool
extends MeshInstance3D

@export var SourceViewport : Viewport

func _process(_delta: float) -> void:
	material_override.set("shader_parameter/LOOP_TEXTURE", SourceViewport.get_texture())
