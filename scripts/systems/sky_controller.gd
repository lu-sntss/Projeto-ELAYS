extends Node
# Sem class_name — script de nó de cena, não autoload

@export var luz_solar: NodePath
@export var world_env: NodePath

@onready var luz_solar_node: DirectionalLight3D = get_node_or_null(luz_solar) as DirectionalLight3D
@onready var world_environment_node: WorldEnvironment = get_node_or_null(world_env) as WorldEnvironment

const _HORAS_PRESET: Array[float] = [0.0, 6.0, 12.0, 18.0, 24.0]

const _PRESET_MADRUGADA := preload("res://data/sky_presets/night.tres")
const _PRESET_AMANHECER := preload("res://data/sky_presets/dawn.tres")
const _PRESET_DIA       := preload("res://data/sky_presets/midday.tres")
const _PRESET_ANOITECER := preload("res://data/sky_presets/dusk.tres")

var _presets: Dictionary
var _material_ceu: ShaderMaterial

func _ready() -> void:
	_presets = {
		0.0:  _PRESET_MADRUGADA,
		6.0:  _PRESET_AMANHECER,
		12.0: _PRESET_DIA,
		18.0: _PRESET_ANOITECER,
	}

	if world_environment_node and world_environment_node.environment and world_environment_node.environment.sky:
		_material_ceu = world_environment_node.environment.sky.sky_material as ShaderMaterial

	var timer := Timer.new()
	timer.wait_time = 0.1
	timer.autostart = true
	timer.timeout.connect(_atualizar_ceu)
	add_child(timer)

	await get_tree().process_frame  # Esperar um frame para garantir que tudo esteja pronto
	_atualizar_ceu()

func _atualizar_ceu() -> void:
	if not _material_ceu:
		if not world_environment_node:
			world_environment_node = get_node_or_null(world_env) as WorldEnvironment
		if world_environment_node and world_environment_node.environment and world_environment_node.environment.sky:
			_material_ceu = world_environment_node.environment.sky.sky_material as ShaderMaterial
			print("SkyController Debug - Tentando setar material: ", _material_ceu != null)
			print("WorldEnv node: ", world_environment_node, " env: ", world_environment_node.environment, " sky: ", world_environment_node.environment.sky)
	if not _material_ceu:
		push_warning("SkyController: Material do céu não encontrado!")
		return

	var hora := TimeOfDay.hora_atual
	var preset_a: SkyPreset = null
	var preset_b: SkyPreset = null
	var t: float = 0.0

	for i in range(_HORAS_PRESET.size() - 1):
		if hora >= _HORAS_PRESET[i] and hora < _HORAS_PRESET[i + 1]:
			preset_a = _presets.get(fmod(_HORAS_PRESET[i], 24.0))
			preset_b = _presets.get(fmod(_HORAS_PRESET[i + 1], 24.0))
			t = (hora - _HORAS_PRESET[i]) / (_HORAS_PRESET[i + 1] - _HORAS_PRESET[i])
			break

	if not preset_a or not preset_b:
		push_warning("SkyController: Presets não encontrados para hora ", hora)
		return

	# Debug prints
	print("SkyController Debug - Hora: ", hora, " Preset A: ", preset_a.resource_name if preset_a else "null", " Preset B: ", preset_b.resource_name if preset_b else "null", " t: ", t)
	print("Horizon Color: ", preset_a.horizon_color.lerp(preset_b.horizon_color, t))
	print("Sun Energy: ", lerpf(preset_a.sun_light_energy, preset_b.sun_light_energy, t))

	# Uniforms do shader do céu
	_material_ceu.set_shader_parameter("horizon_color", preset_a.horizon_color.lerp(preset_b.horizon_color, t))
	_material_ceu.set_shader_parameter("zenith_color",  preset_a.zenith_color.lerp(preset_b.zenith_color, t))
	_material_ceu.set_shader_parameter("cloud_color",   preset_a.cloud_color.lerp(preset_b.cloud_color, t))
	_material_ceu.set_shader_parameter("cloud_coverage", lerpf(preset_a.cloud_coverage, preset_b.cloud_coverage, t))
	_material_ceu.set_shader_parameter("time_of_day", hora / 24.0)

	# Posição solar: elevation_rad = -(hora/24 - 0.25) * TAU
	var elevacao := -(hora / 24.0 - 0.25) * TAU
	if luz_solar_node:
		luz_solar_node.rotation = Vector3(elevacao, PI / 4.0, 0.0)
		luz_solar_node.light_color  = preset_a.sun_light_color.lerp(preset_b.sun_light_color, t)
		luz_solar_node.light_energy = lerpf(preset_a.sun_light_energy, preset_b.sun_light_energy, t)
	else:
		push_warning("SkyController: luz_solar_node não encontrado!")

	# Fog e ambient no Environment
	var env := world_environment_node.environment if world_environment_node else null
	if env:
		env.fog_light_color      = preset_a.fog_color.lerp(preset_b.fog_color, t)
		env.ambient_light_color  = preset_a.ambient_color.lerp(preset_b.ambient_color, t)
		env.ambient_light_energy = lerpf(preset_a.ambient_energy, preset_b.ambient_energy, t)
	else:
		push_warning("SkyController: environment resource não encontrado ao aplicar fog/ambient.")
