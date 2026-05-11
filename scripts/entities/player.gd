extends CharacterBody3D

const VELOCIDADE_CAMINHADA := 4.0
const VELOCIDADE_CORRIDA := 7.0
const ACELERACAO := 10.0
const DESACELERACAO := 8.0
const GRAVIDADE := 9.8
const FORCA_PULO := 4.5

@export var sensibilidade_mouse: float = 0.002
# ~85 graus em radianos
const LIMITE_VERTICAL := 1.4835

@onready var cabeca: Node3D = $Cabeca
@onready var camera: Camera3D = $Cabeca/Camera3D

var rotacao_camera_x: float = 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(evento: InputEvent) -> void:
	if evento is InputEventMouseMotion:
		_processar_mouse_look(evento)
	elif evento.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	_aplicar_gravidade(delta)
	_processar_movimento(delta)
	move_and_slide()

func _processar_mouse_look(evento: InputEventMouseMotion) -> void:
	rotate_y(-evento.relative.x * sensibilidade_mouse)
	rotacao_camera_x -= evento.relative.y * sensibilidade_mouse
	rotacao_camera_x = clamp(rotacao_camera_x, -LIMITE_VERTICAL, LIMITE_VERTICAL)
	cabeca.rotation.x = rotacao_camera_x

func _aplicar_gravidade(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVIDADE * delta

func _processar_movimento(delta: float) -> void:
	var direcao := Vector3.ZERO

	if Input.is_action_pressed("move_forward"):
		direcao -= transform.basis.z
	if Input.is_action_pressed("move_back"):
		direcao += transform.basis.z
	if Input.is_action_pressed("move_left"):
		direcao -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		direcao += transform.basis.x

	if direcao != Vector3.ZERO:
		direcao = direcao.normalized()

	var velocidade_alvo := VELOCIDADE_CORRIDA if Input.is_action_pressed("sprint") else VELOCIDADE_CAMINHADA

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = FORCA_PULO

	var fator := ACELERACAO if direcao != Vector3.ZERO else DESACELERACAO
	velocity.x = move_toward(velocity.x, direcao.x * velocidade_alvo, fator * delta)
	velocity.z = move_toward(velocity.z, direcao.z * velocidade_alvo, fator * delta)
