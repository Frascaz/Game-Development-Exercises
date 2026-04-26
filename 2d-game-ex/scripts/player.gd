extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -350.0

# Double Jump
var has_double_jumped = false

# Dying System
var dying: bool = false

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump: AudioStreamPlayer2D = $Jump
@onready var double_jump: AudioStreamPlayer2D = $DoubleJump
@onready var hit: AudioStreamPlayer2D = $Hit


func die():
	# Esegue questo codice solo se non è GIÀ morto
	if not dying:
		dying = true
		hit.play()
		animated_sprite.play("death_anim") # Chiamato UNA SOLA VOLTA!

func update_animation(direction: float):
	# (Rimosso il controllo "dying" da qui, perché se è morto questa funzione non viene nemmeno chiamata)
	
	# 1. Gira lo sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
		
	# 2. Gestisci le animazioni a terra
	if is_on_floor():
		if direction != 0:
			animated_sprite.play("run")
		else:
			animated_sprite.play("idle")  
	
	# 3. Gestisci le animazioni in aria (Salto vs Caduta)
	else:
		if animated_sprite.animation == "doublejump":
			if velocity.y > 0:
				animated_sprite.play("falling")
			return 
			
		if velocity.y < 0:
			animated_sprite.play("jumping") 
		elif velocity.y > 0:
			animated_sprite.play("falling")


func _physics_process(delta: float) -> void:
	# 1. GRAVITÀ: Applicata sempre, sia ai vivi che ai morti (così i cadaveri cadono a terra)
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 2. SE IL PERSONAGGIO È MORTO:
	if dying:
		velocity.x = move_toward(velocity.x, 0, SPEED) # Frena gradualmente (o metti = 0)
		move_and_slide()    # Applica solo la gravità e la frenata
		return              # BLOCCA tutto. Niente update_animation() che lo fa looppare!
	
	# --- DA QUI IN POI IL CODICE GIRA SOLO SE IL PERSONAGGIO È VIVO ---

	# Handle jump.
	if is_on_floor():
		has_double_jumped = false
		
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		jump.play()
		
	# Handle Double Jump    
	elif Input.is_action_just_pressed("Jump") and not has_double_jumped:
		velocity.y = JUMP_VELOCITY
		animated_sprite.play("doublejump")
		double_jump.play()
		has_double_jumped = true

	# Get the direction: -1, 0, 1
	var direction := Input.get_axis("Move_Left", "Move_Right")

	# Apply Movement
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	# Handle Animation (viene chiamata SOLO se il pg è vivo)
	update_animation(direction)

	move_and_slide()
