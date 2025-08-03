extends Area3D
class_name LoopExtensionActivator

signal TargetLoopSizeSet

static var Singleton : LoopExtensionActivator

@export var LoopController : LoopControl
@export var TargetLoopSize : float = -1

func _ready() -> void:
	Singleton = self
	#TargetLoopSize = LoopController.LoopSize
	body_entered.connect(BodyEntered)

func SetTargetLoopSize(newLoopSize : float):
	TargetLoopSize = newLoopSize
	TargetLoopSizeSet.emit()

func TweenTimeScale(targetTimeScale : float, tweenLength : float = 1) -> Tween:
	var newTween : Tween = get_tree().create_tween()
	newTween.set_ignore_time_scale(true)
	newTween.set_ease(Tween.EASE_IN_OUT)
	newTween.set_trans(Tween.TRANS_CUBIC)
	newTween.tween_property(Engine, "time_scale", targetTimeScale, tweenLength)
	return newTween

func BodyEntered(other : Node3D):
	if not other.is_in_group("Player"): return
	if TargetLoopSize <= 0: return
	print("Target loop size has been set! TargetLoopSize: ", TargetLoopSize)
	var tempLoopSize = TargetLoopSize
	TargetLoopSize = -1
	
	print("Tweening time to a stop...")
	await TweenTimeScale(0, 0.25).finished
	print("Tweening loop size...")
	await LoopController.TweenLoopSize(tempLoopSize, 2).finished
	print("Tweening time back up to speed...")
	await TweenTimeScale(1).finished
	
