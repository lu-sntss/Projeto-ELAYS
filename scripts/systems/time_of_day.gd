extends Node
# Sem class_name — autoload registrado como "TimeOfDay"

signal on_phase_changed(phase: String)
signal on_time_changed(time: float)

## Minutos reais equivalentes a 1 dia in-game
@export var minutos_por_dia: float = 2.0

var hora_atual: float = 8.0
var pausado: bool = false

# Intervalo mínimo (segundos reais) entre emissões de on_time_changed
const THROTTLE_SINAL: float = 2.0

var _fase_atual: String = ""
var _timer_throttle: float = 0.0

func _ready() -> void:
	_fase_atual = _calcular_fase()

func _process(delta: float) -> void:
	if pausado:
		return

	var velocidade := 24.0 / (minutos_por_dia * 60.0)
	hora_atual = fmod(hora_atual + velocidade * delta, 24.0)

	_timer_throttle += delta
	if _timer_throttle >= THROTTLE_SINAL:
		_timer_throttle = 0.0
		on_time_changed.emit(hora_atual)

	var nova_fase := _calcular_fase()
	if nova_fase != _fase_atual:
		_fase_atual = nova_fase
		on_phase_changed.emit(_fase_atual)

func _calcular_fase() -> String:
	if hora_atual < 6.0:
		return "madrugada"
	elif hora_atual < 12.0:
		return "amanhecer"
	elif hora_atual < 18.0:
		return "dia"
	return "anoitecer"

func pausar() -> void:
	pausado = true

func retomar() -> void:
	pausado = false

func setar_hora(hora: float) -> void:
	hora_atual = clamp(hora, 0.0, 24.0)
	on_time_changed.emit(hora_atual)
	var nova_fase := _calcular_fase()
	if nova_fase != _fase_atual:
		_fase_atual = nova_fase
		on_phase_changed.emit(_fase_atual)
