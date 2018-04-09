extends Control

# SETTINGS
export (int) var pixel_size = 32
export (int) var screen_pixels_x = 30
export (int) var screen_pixels_y = 30
export (int, 0, 10) var spawn_padding = 5

# GAMEPLAY CONFIG
export (int, 2, 100) var default_snek_length = 3
export (float,0,1) var default_tick_delay = 0.35

# GAME SPEED
var tick_delay = default_tick_delay # s
var time = 0 # s

# NODES
onready var scoreboard = $scoreboard
onready var sfx_crash = $sfx/crash
onready var sfx_target = $sfx/target
onready var sfx_move = $sfx/move

# GAME OBJECTS
onready var target = Target.new()
onready var snek = Snek.new()


func _ready():
	setup_screen()
	init_game()

func setup_screen():
	OS.window_size = Vector2(screen_pixels_x * pixel_size, screen_pixels_y * pixel_size)
	OS.center_window()

func init_game():
	reset_scoreboard()
	reset_tick_delay()
	spawn_snek()
	spawn_target()

func reset_scoreboard():
	scoreboard.reset_score()

func reset_tick_delay():
	tick_delay = default_tick_delay

func spawn_snek():
	var random_start_pos = get_random_start_pos()
	snek.reset_snek(random_start_pos, default_snek_length)

func get_random_start_pos():
	while(true):
		var start_pos = rand_pos()
		if(start_pos.x > spawn_padding && start_pos.x < screen_pixels_x - spawn_padding
			&& start_pos.y > spawn_padding && start_pos.y < screen_pixels_y - spawn_padding):
			return start_pos

func rand_pos():
	randomize()
	var rand_x = int(rand_range(0, screen_pixels_x))
	var rand_y = int(rand_range(0, screen_pixels_y))
	return Vector2(rand_x, rand_y)

func spawn_target():
	var cannot_spawn = true
	while (cannot_spawn):
		target.position = rand_pos()
		cannot_spawn = snek.has_collision_with(target.position)

func _process(delta):
	time += delta
	if(time > tick_delay):
		reset_time()
		handle_snek()
		update_drawing()
	handle_user_input()

func reset_time():
	time = 0

func handle_snek():
	snek.move()
	snek.update_previous_direction()
	
	if(snek.collided_with_self()):
		print(">> Head collided with body!")
		sfx_crash.play()
		init_game()
	
	# Check if snek has left the screen
	if(snek.is_outside_screen(0, screen_pixels_x, 0, screen_pixels_y)):
		print(">> Head collided with walls!")
		sfx_crash.play()
		init_game()
		return

	# Check if snek has collided with target
	if(snek.collided_with(target.position)):
		print(">> Target acquired!")
		add_points()
		add_body_part()
		spawn_target()
		sfx_target.play()
	else:
		sfx_move.play()

func update_drawing():
	update() # update() is not a descriptive function name, since it updates the drawing in nodes that extends CanvasItem

func handle_user_input():
	if(move_up_pressed() && can_move_up()):
		snek.current_direction = Direction.UP
	elif(move_down_pressed() && can_move_down()):
		snek.current_direction = Direction.DOWN
	elif(move_left_pressed() && can_move_left()):
		snek.current_direction = Direction.LEFT
	elif(move_right_pressed() && can_move_right()):
		snek.current_direction = Direction.RIGHT

func move_up_pressed():
	return Input.is_action_just_pressed("ui_up")

func move_down_pressed():
	return Input.is_action_just_pressed("ui_down")

func move_left_pressed():
	return Input.is_action_just_pressed("ui_left")

func move_right_pressed():
	return Input.is_action_just_pressed("ui_right")

func can_move_up():
	return snek.previous_direction != Direction.DOWN

func can_move_right():
	return snek.previous_direction != Direction.LEFT

func can_move_down():
	return snek.previous_direction != Direction.UP

func can_move_left():
	return snek.previous_direction != Direction.RIGHT


func add_body_part():
	snek.add_body()
	tick_delay = tick_delay - (tick_delay*0.05)



func add_points():
	var points = target.reward * (snek.position_list.size() / default_snek_length)
	scoreboard.add_points(points)


func _draw():
	# Draw snake head
	draw_pixel(snek.position_list[0], snek.COLOR_SNAKE_HEAD)
	
	# Draw snake body
	for i in range(1, snek.position_list.size()):
		if(i % 2 == 0):
			draw_pixel(snek.position_list[i], snek.COLOR_SNAKE_BODY_1)
		else:
			draw_pixel(snek.position_list[i], snek.COLOR_SNAKE_BODY_2)
			
	# Draw Target
	draw_pixel(target.position, target.color)


func draw_pixel(pos, color):
	var rect = Rect2(pos * pixel_size, Vector2(pixel_size, pixel_size))
	draw_rect(rect, color, true)


class Snek:
	# APPERANCE
	const COLOR_SNAKE_HEAD = Color(0.5, 1, 0.5)
	const COLOR_SNAKE_BODY_1 = Color(0, 0.75, 0)
	const COLOR_SNAKE_BODY_2 = Color(0, 0.85, 0)
	
	# MOVEMENT VARS
	var position_list = []
	var current_direction = Direction.RIGHT
	var previous_direction = current_direction
	
	
	func move():
		for i in range(position_list.size()-1, 0, -1):
			position_list[i] = position_list[i-1]
		position_list[0] += current_direction
	
	func collided_with_self():
		for i in range(1, position_list.size()):
			if(position_list[i] == position_list[0]):
				return true
		return false
	
	func collided_with(other_pos):
		return position_list[0] == other_pos
	
	func is_outside_screen(min_x, max_x, min_y, max_y):
		return position_list[0].x < min_x || position_list[0].x >= max_x || position_list[0].y < min_y || position_list[0].y >= max_y
	
	func add_body():
		var last_index = position_list.size()-1
		var new_body_pos = position_list[last_index]
		position_list.append(new_body_pos)
	
	func reset_snek(start_position, snek_length):
		position_list = []
		for i in range(0, snek_length):
			position_list.append(start_position)
	
	func has_collision_with(other_position):
		for position in position_list:
			if(position == other_position):
				return true
		return false
	
	func update_previous_direction():
		previous_direction = current_direction


class Target:
	var position = Vector2()
	var color = Color(0, 1, 1)
	var reward = 250