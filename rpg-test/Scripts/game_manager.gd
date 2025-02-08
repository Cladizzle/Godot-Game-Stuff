extends Node

var score = 0

@onready var score_label: Label = $UI/PanelContainer/scorelabel

func _ready():
	score_label.text = "Coins: 0"

func add_point():
		score += 1
		score_label.text = "Coins:" + str(score)
