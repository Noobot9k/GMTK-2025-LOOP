extends Node3D

@export var pitch_randomness : float = 0.1

@export var SFX_falling : AudioStreamPlayer3D
@export var SFX_landing : AudioStreamPlayer3D
@export var SFX_jump_precharge : AudioStreamPlayer3D
@export var SFX_steps_parent : Node3D

@export var SFX_shot_charging : AudioStreamPlayer3D
@export var SFX_shot_uncharged : AudioStreamPlayer3D
@export var SFX_shot_charged : AudioStreamPlayer3D

@onready var char_control : CharacterController = NodeLib.FindParentScriptOfClass(self, CharacterController)
#@export var attack_control : AttackController ##= $".."

#func fired():#charge_alpha : float):
	#if attack_control.AttackChargeAlpha <= 0:
		#SFX_shot_uncharged.play()
	#else:
		#SFX_shot_charged.play()

func landed():
	SFX_landing.pitch_scale = 1 + (randf() - pitch_randomness/2.0) * pitch_randomness
	SFX_landing.play()

func jump_precharging():
	SFX_jump_precharge.play()

func step():
	var sound_count = SFX_steps_parent.get_child_count(true) - 1
	var sound : AudioStreamPlayer3D = SFX_steps_parent.get_child(roundi(randf() * sound_count))
	sound.play()

func set_sound_playing(sound : AudioStreamPlayer3D, playing : bool):
	if sound.playing != playing:
		sound.playing = playing

func _ready() -> void:
	char_control.Landed.connect(Callable(self, "landed"))
	char_control.Jumped.connect(Callable(self, "step"))
	#char_control.Jump_precharging.connect(Callable(self, "jump_precharging"))
	#attack_control.Fired.connect(Callable(self, "fired"))

func _process(_delta: float) -> void:
	set_sound_playing(SFX_falling, not char_control.is_on_floor())
	
	#var move_alpha = clampf(char_control.velocity.length() / char_control.move_speed, 0, 1)
	#SFX_falling.volume_db = lerpf(-80, -30, pow(move_alpha, 1))
	SFX_falling.volume_db = -70.0 + char_control.velocity.length() * 2
	
	#set_sound_playing(SFX_shot_charging, attack_control.charge_alpha > 0)
	#SFX_shot_charging.pitch_scale = 1 + attack_control.charge_alpha
