@tool
extends Area3D
class_name Ignitable

signal Ignited
signal Extinguished

@export var ExtinguishVelocity : float = 15

var _lastPos : Vector3

@export var OnFire : bool = true:
	set(newValue):
		if OnFire == newValue: return
		
		OnFire = newValue
		for obj in VisibilityToggles:
			obj.visible = newValue
		
		if Engine.is_editor_hint(): return
		
		if OnFire: Ignited.emit()
		else: Extinguished.emit()
@export var IsStatic : bool = false:
	set(newValue):
		IsStatic = newValue
		for obj : Light3D in VisibilityToggles:
			if obj is not Light3D: continue
			obj.light_bake_mode = Light3D.BAKE_STATIC if IsStatic else Light3D.BAKE_DYNAMIC
@export var CanBeProximityIgnited : bool = true

@export var VisibilityToggles : Array[Node3D]

func _ready() -> void:
	if Engine.is_editor_hint(): return
	
	_lastPos = global_position
	area_entered.connect(AreaEntered)

func AreaEntered(other : Area3D):
	if Engine.is_editor_hint(): return
	
	if not CanBeProximityIgnited: return
	if other is not Ignitable: return
	var otherIgnitable : Ignitable = other
	if not otherIgnitable.OnFire: return
	OnFire = true

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	
	var deltaPos = global_position - _lastPos
	
	if OnFire and abs(deltaPos.y) / _delta > ExtinguishVelocity:
		OnFire = false
	
	_lastPos = global_position
