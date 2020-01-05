#The stagger state end with the stagger animation from the AnimationPlayer
#The animation only affects the Body Sprite"s modulate property so 
#it could stack with other animations if we had two AnimationPlayer nodes

# warning-ignore:unused_class_variable
extends "res://utils/state/State.gd"

var knockback_direction = Vector2()

func enter():
	owner.get_node("AnimationPlayer").play("stagger")

func _on_animation_finished(_anim_name):
	owner.get_body().modulate = Color('#ffffff')
	emit_signal("finished", "previous")