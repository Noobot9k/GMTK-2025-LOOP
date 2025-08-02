extends Node
class_name EquippableAbilityManager

signal CurrentlyEquippedChanged

@export var RootAbility : EquippableAbility
@export var EquippableAbilities : Array[EquippableAbility]

@export var ViewModelNode : ViewModel
@export var ViewModelAnimTree : AnimationTree
@export var AnimTreeFireHeldPath : String

var CurrentlyEquipped : EquippableAbility

func _ready():
	for ability : EquippableAbility in EquippableAbilities:
		_subscribeToEquippableAbilityEvents(ability)
	
	_subscribeToEquippableAbilityEvents(RootAbility)
	if RootAbility: Equip(RootAbility)

func _subscribeToEquippableAbilityEvents(ability : EquippableAbility):
	if not ability: return
	#ability.Fired.connect(Callable(ViewModelNode, "AnimShootLight"))
	ability.FireHeldChanged.connect(Callable(ViewModelNode, "SetAnimFireHeld"))
	ability.AttackChargeAlphaChanged.connect(Callable(ViewModelNode, "SetAnimChargeAlpha"))

func _process(_delta):
	#if CurrentlyEquipped:
		#ViewModelNode.AnimChargeAlpha = CurrentlyEquipped.AttackChargeAlpha
	
	#if ViewModelAnimTree:
		#ViewModelAnimTree.set(AnimTreeFireHeldPath, Input.is_action_pressed("Fire"))
	
	if Input.is_action_just_pressed("equippables_clear"):
		#UnequipCurrent()
		Equip(RootAbility)
	elif Input.is_action_just_pressed("equippables_1"):
		Equip(EquippableAbilities[0])
	#elif Input.is_action_just_pressed("equippables_2"):
		#Equip(EquippableAbilities[1])
	#elif Input.is_action_just_pressed("equippables_3"):
		#pass #Equip(EquippableAbilities[2])
	elif Input.is_action_just_pressed("equippables_cycle"):
		if CurrentlyEquipped:
			var index = EquippableAbilities.find(CurrentlyEquipped)
			if index != null:
				EquipAbilityAtIndex(index+1, false)
		else:
			Equip(EquippableAbilities[0])

func EquipAbilityAtIndex(index : int, wrapAround : bool = false):
	if index >= EquippableAbilities.size():
		if wrapAround:
			index -= EquippableAbilities.size()
		else:
			#UnequipCurrent()
			Equip(RootAbility)
			return
	
	Equip(EquippableAbilities[index])
	#return EquippableAbilities[index]

func Equip(equippable : EquippableAbility):
	if not equippable: return
	if not equippable.Enabled: return
	if not UnequipCurrent(): return
	CurrentlyEquipped = equippable
	equippable.TrySetActive(true)
	CurrentlyEquippedChanged.emit(CurrentlyEquipped)

func UnequipCurrent():
	if CurrentlyEquipped:
		var success = CurrentlyEquipped.TrySetActive(false)
		if success: CurrentlyEquipped = null;
		return success
	return true
