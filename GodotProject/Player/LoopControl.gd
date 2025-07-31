extends Node
class_name LoopControl

@export var LoopSize : float = 24
@export var RemotePositions : Array[Node3D]
@export var PlayerChar : PlayerCharacter

func _process(_delta: float) -> void:
	PlayerChar.voidout_hight = -LoopSize/2
	for remotePos in RemotePositions:
		remotePos.position.y = LoopSize
