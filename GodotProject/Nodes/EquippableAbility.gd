extends Node3D
class_name EquippableAbility

signal Fired
signal FireHeldChanged
signal AttackChargeAlphaChanged

@export var Enabled : bool = true
@export var Active : bool = false
var FireHeld : bool = false
var IsInUse : bool = false
var AttackChargeAlpha : float = 0

var _lastAttackChargeAlpha : float = 0
var _lastFireHeld : bool = false

func TrySetActive(newActive : bool) -> bool:
	if (Active and IsInUse): return false
	
	Unequip()
	Active = newActive
	if (!newActive):
		visible = newActive
	# visibility is also set by the EquippableAbility itself.
	# it's just set here too so it hides if the player interupts its stow anim.
	
	return true

func Unequip():
	pass

func _ready():
	pass # Replace with function body.

func _process(_delta):
	if FireHeld != _lastFireHeld:
		_lastFireHeld = FireHeld
		FireHeldChanged.emit(FireHeld)
	
	if AttackChargeAlpha != _lastAttackChargeAlpha:
		_lastAttackChargeAlpha = AttackChargeAlpha
		AttackChargeAlphaChanged.emit(AttackChargeAlpha)
