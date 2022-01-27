extends Node2D


# Declare member variables here. Examples:
var radius = 40
var particles = []
var links = []
var n = 8
var REST_STIFFNESS = 120
var JUMP_STIFFNESS = 1200
var JUMP_EXTEND = 1.5
	
class ExtendableLink:
	var link: DampedSpringJoint2D
	var rest_length: float
	var rest_stiffness: float
	var extension_length: float
	var extension_stiffness: float
	
	func angleBetween(v1: Vector2, v2: Vector2):
		var v = v2 - v1
		return atan2(-v.x, v.y)
		
	func makeLink(a: PhysicsBody2D, b: PhysicsBody2D, stiffness):
		var link = DampedSpringJoint2D.new()
		link.node_a = a.get_path()
		link.node_b = b.get_path()
		link.rest_length = (a.position - b.position).length()
		link.length = link.rest_length
		link.stiffness = stiffness
		link.position = a.position
		link.rotation = angleBetween(a.position, b.position)
		return link
	
	func _init(
		a: PhysicsBody2D,
		b: PhysicsBody2D, 
		extend_ratio: float,
		rest_stiffness: float,
		extension_stiffness: float):
		self.link = self.makeLink(a,b,rest_stiffness)
		self.rest_length = self.link.length
		self.rest_stiffness = rest_stiffness
		self.extension_length = self.link.length * extend_ratio
		self.extension_stiffness = extension_stiffness
	
	func extend():
		self.link.rest_length = self.extension_length
		self.link.stiffness = self.extension_stiffness
	
	func retract():
		self.link.rest_length = self.rest_length
		self.link.stiffness = self.rest_stiffness

func makeParticle(pos: Vector2):
	var GooParticle = preload("res://src/Actors/GooParticle.tscn")
	var p = GooParticle.instance()
	p.position = pos
	return p

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(0,n):
		var theta = i * 2 * PI / n
		particles.append(makeParticle(Vector2(radius * cos(theta), radius * sin(theta))))
	for p in particles:
		add_child(p)
	for i in range(0, n / 2):
		links.append(
			ExtendableLink.new(
				particles[i], particles[i + n/2],
				JUMP_EXTEND, REST_STIFFNESS, JUMP_STIFFNESS
			))
	for i in range(0, n):
		links.append(
			ExtendableLink.new(
				particles[i], particles[(i+1) % n],
				JUMP_EXTEND, REST_STIFFNESS, JUMP_STIFFNESS
			))
	for l in links:
		add_child(l.link)

func get_direction() -> Vector2:
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		0
	)
		
func _physics_process(delta):
	particles[0].apply_central_impulse(20 * get_direction())
	if Input.is_key_pressed(KEY_SPACE):
		for l in links:
			l.extend()
	else:
		for l in links:
			l.retract()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
