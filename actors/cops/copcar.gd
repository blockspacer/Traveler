#warning-ignore-all:unused_class_variable
extends "res://enemies/CopBase.gd"

signal spawned

const PoliceMan = preload("res://enemies/polceman/PoliceMan.tscn")

export(float) var SPEED := 200
export(float) var VISION := 5
export(int) var WAIT_TIME := 30
#export(int)	var MASS := 1.0
#export(int)	var ARRIVE_DISTANCE := 10.0

enum STATES { IDLE, PATROL, ONCALL, TRAFFIC, FOLLOW }
var _state = null

var path = []
var target_point_world = Vector2()
var target_position = Vector2()
#
#var velocity = Vector2()

var ROADS :Node
var TARGET : Node
onready var DISPATCH := get_parent()
onready var POLICELIGHTS := $PoliceLights

func on_error(new_error:int)->void:
	new_error = error
	if error != OK:
		print("Error in CopCar :", error)

func initialize(_target : Node, _roads :Node  = ROADS) -> void:
	TARGET = _target
	if not _roads:
		ROADS = get_tree().get_nodes_in_group("Roads")[0]
	else:
		ROADS = _roads
	self.error = $IdleTimer.connect("timeout",self,"_on_IdleTimer_timeout")
	_change_state(STATES.IDLE)

func _change_state(new_state) -> void:
	if (new_state == _state):
		return
	if _state == STATES.FOLLOW:
		POLICELIGHTS.set_emitting(false)
	if new_state == STATES.IDLE:
		$IdleTimer.start(randi() % WAIT_TIME)
	elif new_state == STATES.PATROL:
		get_new_target()
		path = DISPATCH.get_new_path(position, target_position)
		if not path or len(path) == 1:
			_change_state(STATES.IDLE)
			return
		target_point_world = path[1] #set target as next point in line as we are at path[0] now
	elif new_state == STATES.FOLLOW:
		if POLICELIGHTS:
			POLICELIGHTS.set_emitting(true)
			spawn_cop()
	_state = new_state

func spawn_cop()->void:
	var new_cop = PoliceMan.instance()
	DISPATCH.call_deferred("add_child", new_cop)
	new_cop.global_position = $CopSpawn.global_position
	emit_signal("spawned",new_cop)
	new_cop.initialize(TARGET)

#func cop_is_done(cop : Node):
#	cop.queue_free()
#	_change_state(STATES.IDLE)

func _physics_process(delta) -> void:
	if _state != STATES.PATROL:
		return
	move_to(target_point_world, delta)
	update_angle()
	if is_arrived(target_point_world):
		path.remove(0)
		if len(path) == 0:
			_change_state(STATES.IDLE)
			return
		target_point_world = path[0]

func get_new_target() -> void:
	path.clear()
	target_point_world = null
	#if not on a valid tile move back to dispatch
	if not is_pos_valid(position):
		position = DISPATCH.get_dispatch_location()
	#get new desination
	target_position = DISPATCH.get_next_pos()
	visible = true

func move_to(world_position: Vector2, delta: float) -> void:
	var desired_velocity = (world_position - position).normalized() * SPEED * delta
	var steering = desired_velocity - velocity
	velocity += steering / MASS
	if move_and_collide(velocity, false):
		_change_state(STATES.IDLE)

func update_angle() ->void:
	var angle = velocity.angle()
	$VisionPivot.rotation = angle
	#warning-ignore:narrowing_conversion
	$AnimatedSprite.frame = get_next_frame(rad2deg(angle))
	
func get_next_frame(check_angle:int) -> int:
	var frame : int = 4
	if check_angle < 180 and check_angle > 90:
		frame = 0
	elif check_angle < 90 and check_angle > 0:
		frame = 3
	elif check_angle < 0 and check_angle > -90:
		frame = 2
	elif check_angle < -90 and check_angle > -180:
		frame = 1
	return frame
	
func is_arrived(world_position:Vector2) -> bool:
	return position.distance_to(world_position) < ARRIVE_DISTANCE

func is_pos_valid(pos) ->bool:
	return ROADS.world_to_map(pos) in DISPATCH.walkable_cells_list

func _on_IdleTimer_timeout() ->void:
		_change_state(STATES.PATROL)

func pull_over(_target:Node) -> void:
	if TARGET == _target:
		InfoHUB.display(PULLOVER_MESSAGE,MESSAGECOLOR)
		_change_state(STATES.FOLLOW)
		
func warning(_target:Node)->void:
	if TARGET == _target:
		speak(WARNING_MESSAGE)