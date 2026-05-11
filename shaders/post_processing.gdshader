shader_type canvas_item;

// Intensidade da curvatura barrel vertical (horizonte convexo)
uniform float curve_strength : hint_range(0.0, 1.0) = 0.15;
// Posição vertical do equador da distorção (0.5 = centro da tela)
uniform float vertical_offset : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec2 uv = UV;

	// Distorção barrel centrada no equador configurável
	vec2 centrado = uv - vec2(0.5, vertical_offset);
	float dist_sq = dot(centrado, centrado);
	vec2 uv_dist = uv + centrado * dist_sq * curve_strength;

	if (uv_dist.x < 0.0 || uv_dist.x > 1.0 ||
		uv_dist.y < 0.0 || uv_dist.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		COLOR = texture(TEXTURE, uv_dist);
		vec2 uv_vig = uv - vec2(0.5);
		float vignette = 1.0 - dot(uv_vig, uv_vig) * 2.2;
		COLOR.rgb *= clamp(vignette, 0.0, 1.0);
	}
}
