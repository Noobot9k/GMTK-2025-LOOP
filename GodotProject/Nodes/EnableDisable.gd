@tool
extends Node3D
class_name EnableDisable

@export var EnableObjects : Array[Node3D]
@export_tool_button("Enable") var SetEnabledToolButton = func(): SetEnabled(true)
@export_tool_button("Disable") var SetDisabledToolButton = func(): SetEnabled(false)

func SetEnabled(enabled : bool):
	for obj in EnableObjects:
		if obj is GPUParticles3D:
			obj.emitting = enabled
		elif obj is CollisionShape3D:
			obj.set_deferred("disabled", not enabled)
			#var parent = obj.get_parent()
			#if parent and parent is RigidBody3D:
				#parent.sleeping = false
		elif obj is Ignitable:
			obj.OnFire = enabled
		else:
			obj.visible = enabled
