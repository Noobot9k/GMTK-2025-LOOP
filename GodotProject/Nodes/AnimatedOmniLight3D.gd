@tool
extends OmniLight3D
class_name AnimatedOmniLight3D

@export var Playing : bool = false:
	set(newValue):
		Playing = newValue
		if not Playing: return
		if Loop: return
		if CurrentPlayTime < AnimationLength: return
		CurrentPlayTime = 0
@export var AutoPlay : bool = false
@export var Loop : bool = true
@export var AnimationLength : float = 1
@export var CurrentPlayTime : float = 0
@export var EnergyMultiplier : float = 1
@export var EnergyOverTime : Curve
@export var ColorOverTime : Gradient


func _ready() -> void:
	if Engine.is_editor_hint(): return
	if AutoPlay: Playing = true

func _process(delta: float) -> void:
	if not Playing: return
	
	CurrentPlayTime += delta
	if CurrentPlayTime > AnimationLength:
		if Loop:
			CurrentPlayTime -= AnimationLength
		else:
			CurrentPlayTime = AnimationLength
			Playing = false
	var currentAlpha = CurrentPlayTime / AnimationLength
	
	if EnergyOverTime: light_energy = EnergyOverTime.sample(currentAlpha) \
		* EnergyMultiplier
	if ColorOverTime: light_color = ColorOverTime.sample(currentAlpha)
