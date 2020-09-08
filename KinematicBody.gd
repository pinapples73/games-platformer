extends KinematicBody2D

#-------------------VARIABLES----------------------
#NODES
export(NodePath) var level_path
onready var level_node = get_node(level_path)
onready var ledge_detection_top = $Rays/LedgeDetection/Ledge_d_top
onready var ledge_detection_bot = $Rays/LedgeDetection/Ledge_d_bot
onready var ledge_detection_up = $Rays/LedgeDetection/Ledge_d_up
onready var climb_detection_middle = $Rays/ClimbDetection/Climb_d_middle
onready var climb_detection_up = $Rays/ClimbDetection/Climb_d_up
onready var climb_detection_down = $Rays/ClimbDetection/Climb_d_down
onready var player_sprite = $Sprite
onready var player_collider = $CollisionShape


#PLAYER BASICS
export (int) var speed = 300
export (int) var jump_speed = -300
export (int) var gravity = 1000
export (float, 0, 1.0) var friction = 0.2
export (float, 0, 1.0) var acceleration = 0.25
onready var collider_size = player_collider.get_shape().get_extents()

var velocity = Vector2.ZERO

#LEDGE CLIMBING RELATED
var aligned_with_ledge = false;

#PLAYER ABILITIES
# - double jump
export (bool) var ability_double_jump = false
var jump_count = 0
# - wall jump
export (bool) var ability_wall_jump = false
var wall_jump_timer = 0
# - dashing
export (bool) var ability_dash = false
export (float) var dash_speed = 2000
export (float) var dash_distance = 8
export (float) var dash_cooldown = 10
var temp_gravity = gravity
var temp_dash_cooldown = 0
var can_dash = true
var is_dashing_start = true
var dash_distance_left = dash_distance
# - climbing
export (bool) var ability_climb = false
var aligned_with_wall = false

#INPUT VARIBLES
var input_horizontal
var input_vertical
var input_jump
var input_dash
var input_action

#PLAYER STATES
enum {
	DEFAULT,
	AIRBOURNE,
	HANGING,
	DASHING,
	WALLJUMPING,
	CLIMBING
}


#PLAYER FACING VALUES
enum {
	RIGHT = 1,
	LEFT = -1
}


#DEFAULT VARIABLES
var state = DEFAULT
var player_facing_direction = RIGHT
var wall_jump_direction = LEFT



#-------------------SHARED FUNCTIONS----------------------

#get inputs and update input variables to be used by calling function
func get_input():
	input_horizontal = 0
	input_vertical = 0
	input_jump = false
	input_dash = false
	input_action = false
	
	if Input.is_action_pressed("player_right"):
		input_horizontal += 1
	if Input.is_action_pressed("player_left"):
		input_horizontal -= 1
	if Input.is_action_pressed("player_up"):
		input_vertical += 1
	if Input.is_action_pressed("player_down"):
		input_vertical -= 1
	if Input.is_action_just_pressed("player_jump"):
		input_jump = true
	if Input.is_action_just_pressed("player_dash"):
		input_dash = true
	if Input.is_action_just_pressed("player_action"):
		input_action = true
	
	
#move player
func move_player(delta):
	velocity.y += gravity * delta
	velocity = move_and_slide(velocity, Vector2.UP)
	
	
#player facing	
func player_facing(direction):
	if direction < 0:
		player_sprite.flip_h = true
		ledge_detection_top.cast_to = Vector2(-16, 0)
		ledge_detection_bot.cast_to = Vector2(-16, 0)
		ledge_detection_up.position.x = -26
		climb_detection_middle.cast_to = Vector2(-18,0)
		climb_detection_up.position.x = -18
		climb_detection_down.position.x = -18
		player_facing_direction = LEFT
	elif direction > 0:
		player_sprite.flip_h = false
		ledge_detection_top.cast_to = Vector2(16, 0)
		ledge_detection_bot.cast_to = Vector2(16, 0)
		ledge_detection_up.position.x = 26
		climb_detection_middle.cast_to = Vector2(18,0)
		climb_detection_up.position.x = 18
		climb_detection_down.position.x = 18
		player_facing_direction = RIGHT
		
		
#check for ledges
func check_for_ledge():
	aligned_with_ledge = false;
	#check raycasts for the correct collisions
	if not ledge_detection_top.is_colliding() and ledge_detection_bot.is_colliding():
		state = HANGING
	

#check for walls to wall jump
func check_for_wall():
	#check raycasts for the correct collisions
	if ledge_detection_top.is_colliding() and ledge_detection_bot.is_colliding():
		return true
	else:
		return false


#check for climbable walls
func check_for_climbable_walls():
	if climb_detection_middle.is_colliding():
		return true
	else:
		return false
	

#check for cooldowns
func check_for_cooldowns(delta):
	
	#dash cooldown checker
	if temp_dash_cooldown > 0:
		temp_dash_cooldown -= 10 * delta
	else:
		can_dash = true
		is_dashing_start = true

		
#-------------------STATE FUNCTIONS----------------------
		
#player_default
func player_default(delta):
	
	jump_count = 0
	
	#all cooldowns will be handled in one method
	check_for_cooldowns(delta)
	
	#if player is not on floor
	if not is_on_floor():
		state = AIRBOURNE
	
	get_input()
	
	if input_dash and can_dash:
		state = DASHING
	
	#jumping whilst on ground
	if input_jump:
		velocity.y = jump_speed
	
	#calculate horizontal movement
	if input_horizontal != 0:
		velocity.x = lerp(velocity.x, input_horizontal * speed, acceleration)
	else:
		velocity.x = lerp(velocity.x, 0, friction)
	
	player_facing(velocity.x)
		
	move_player(delta)
	
	
#player_airbourne
func player_airbourne(delta):
	
	check_for_cooldowns(delta)
	
	get_input()
	
	#when landing on floor move back to default state
	if is_on_floor():
		state = DEFAULT
		
	#check if player is dashing	
	if ability_dash and input_dash and can_dash:
		state = DASHING
	
	#when falling back down from jump or off platform check for ledges and double jump
	if velocity.y >= 0:
		check_for_ledge()
		if ability_double_jump and input_jump and jump_count == 0:
			velocity.y = jump_speed
			jump_count = 1	
	
	#check for walls		
	if check_for_wall():
		if ability_wall_jump and input_jump:
			wall_jump_direction = -player_facing_direction
			wall_jump_timer = 8
			state = WALLJUMPING
			
	if check_for_climbable_walls():
		if ability_climb and input_action:
			state = CLIMBING
			
	
	if input_horizontal != 0:
		velocity.x = lerp(velocity.x, input_horizontal * speed, acceleration)
	else:
		velocity.x = lerp(velocity.x, 0, friction)
	
	player_facing(velocity.x)
	
	move_player(delta)
	
	
#player_hanging
func player_hanging():
		
	#align player to ledge
	if aligned_with_ledge:
		get_input()
		
		if input_jump:
			velocity.y = jump_speed
			state = AIRBOURNE			
		
		if input_vertical == -1:
			state = AIRBOURNE		
	else:
		var ledge_position = Vector2()
		ledge_position.x = ledge_detection_bot.get_collision_point().x
		ledge_position.y = ledge_detection_up.get_collision_point().y
		
		position.x = ledge_position.x - (collider_size.x * player_facing_direction)
		position.y = ledge_position.y + collider_size.y
				
		aligned_with_ledge = true
				

#player dashing
func player_dashing(delta):	
	if not is_dashing_start:
		#calculate horizontal movement
		if dash_distance_left > 5:
			velocity.x = lerp(velocity.x, player_facing_direction * dash_speed, acceleration  * 2)
		else:
			if dash_distance_left == 0:
				temp_dash_cooldown = dash_cooldown
				gravity = temp_gravity
				state = DEFAULT
			velocity.x = lerp(velocity.x, 0, friction)
				
		dash_distance_left -= 1		
	else:
		dash_distance_left = dash_distance
		temp_gravity = gravity
		gravity = 0
		is_dashing_start = false
		can_dash = false
		
	move_player(delta)	
	
	
#player double jumping
func player_wall_jumping(delta):
	if wall_jump_timer > 0:
		wall_jump_timer -= 1
	else:
		wall_jump_timer = 0
		state = AIRBOURNE
		
	velocity.x = lerp(velocity.x, wall_jump_direction * speed, acceleration)
	velocity.y = jump_speed
	jump_count = 0
	
	player_facing(velocity.x)
	
	move_player(delta)


#player climbing
func player_climbing(delta):
	var wall_position
	wall_position = climb_detection_middle.get_collision_point().x
#
	position.x = wall_position - (collider_size.x * player_facing_direction)
				
	aligned_with_wall = true
		
	
#-------------------RUNNER FUNCTIONS----------------------
func _physics_process(delta):
	
	match state:
		DEFAULT:
			player_default(delta)
		AIRBOURNE:
			player_airbourne(delta)
		HANGING:
			player_hanging()
		DASHING:
			player_dashing(delta)
		WALLJUMPING: 
			player_wall_jumping(delta)
		CLIMBING:
			player_climbing(delta)
		
		
	
	
