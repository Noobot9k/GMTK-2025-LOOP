@tool
extends Node3D
class_name Ignitable

@export var OnFire : bool = true:
	set(newValue):
		OnFire = newValue
		for obj in VisibilityToggles:
			obj.visible = newValue
@export var IsStatic : bool = false:
	set(newValue):
		IsStatic = newValue
		for obj : Light3D in VisibilityToggles:
			if obj is not Light3D: continue
			obj.light_bake_mode = Light3D.BAKE_STATIC if IsStatic else Light3D.BAKE_DYNAMIC

@export var VisibilityToggles : Array[Node3D]
