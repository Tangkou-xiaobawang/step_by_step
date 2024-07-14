extends HBoxContainer

var player_labels = {}


func _process(_delta):
	pass


func increase_score(for_who):
	assert(for_who in player_labels)
	var pl = player_labels[for_who]
	pl.score += 1
	pl.label.set_text(pl.name + "\n" + str(pl.score))


func add_player(id, new_player_name):
	var l = Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.set_text(new_player_name + "\n" + "0")
	l.set_h_size_flags(SIZE_EXPAND_FILL)
	var font = preload("res://ui/montserrat.otf")
	l.set("custom_fonts/font", font)
	l.set("custom_font_size/font_size", 18)
	add_child(l)
	player_labels[id] = { name = new_player_name, label = l, score = 0 }


func _ready():
	$"../Winner".hide()
	set_process(true)


func _input(event):
	if event is InputEventKey:
		if event.is_pressed():
			if event.keycode==KEY_ESCAPE:
				if $"../Winner".visible==false:
					$"../Winner".show()
				else:
					$"../Winner".hide()


func _on_exit_game_pressed():
	#应先清除对等体，否则会出现异常报错
	multiplayer.clear()
	gamestate.end_game()
	

