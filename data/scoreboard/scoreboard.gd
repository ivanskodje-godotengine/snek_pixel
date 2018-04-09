extends Node

var score = 0
var high_score = 0

func add_points(value):
	add_points_to_score(value)
	if(has_high_score()):
		update_high_score()

func reset_score():
	score = 0
	$score_value.text = str(score)

func add_points_to_score(value):
	score += value
	$score_value.text = str(score)

func update_high_score():
	high_score = score
	$high_score_value.text = str(high_score)

func has_high_score():
	return score > high_score