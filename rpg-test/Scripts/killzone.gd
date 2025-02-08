extends Area2D

func _on_body_entered(body) -> void:
	print("You died!")
	body.die() # Character dies
