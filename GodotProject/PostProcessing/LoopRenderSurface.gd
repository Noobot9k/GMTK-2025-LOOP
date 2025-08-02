@tool
extends MeshInstance3D
class_name LoopRenderSurface

@export var SourceViewport : Viewport

func _process(_delta: float) -> void:
	material_override.set("shader_parameter/LOOP_TEXTURE", SourceViewport.get_texture())
