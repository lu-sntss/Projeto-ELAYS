extends Resource

class_name SkyPreset

@export_color_no_alpha var horizon_color: Color = Color(0.48, 0.52, 0.6)
@export_color_no_alpha var zenith_color: Color = Color(0.18, 0.18, 0.35)
@export_color_no_alpha var cloud_color: Color = Color(0.5, 0.5, 0.58)
@export_range(0.0, 1.0) var cloud_coverage: float = 0.7

@export_color_no_alpha var sun_light_color: Color = Color(0.85, 0.85, 0.9)
@export_range(0.0, 8.0) var sun_light_energy: float = 0.65

@export_color_no_alpha var fog_color: Color = Color(0.14, 0.15, 0.2)
@export_color_no_alpha var ambient_color: Color = Color(0.1, 0.1, 0.18)
@export_range(0.0, 2.0) var ambient_energy: float = 0.3
