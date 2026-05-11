shader_type sky;

uniform vec3 horizon_color : source_color = vec3(0.48, 0.52, 0.6);
uniform vec3 zenith_color : source_color = vec3(0.18, 0.18, 0.35);
uniform vec3 cloud_color : source_color = vec3(0.5, 0.5, 0.58);
uniform float cloud_coverage : hint_range(0.0, 1.0) = 0.7;
uniform float cloud_speed : hint_range(0.0, 0.2) = 0.02;
// Reservado para o sistema do Farol — direção do sol para halo futuro
uniform vec3 sun_direction = vec3(0.0, -1.0, 0.0);
uniform float time_of_day : hint_range(0.0, 1.0) = 0.5;

float hash2(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 19.19);
	return fract(p.x * p.y);
}

float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash2(i),              hash2(i + vec2(1.0, 0.0)), f.x),
		mix(hash2(i + vec2(0.0, 1.0)), hash2(i + vec2(1.0, 1.0)), f.x),
		f.y
	);
}

float fbm(vec2 p) {
	float val = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		val += noise2(p) * amp;
		p = p * 2.1 + vec2(1.7, 9.2);
		amp *= 0.5;
	}
	return val;
}

void sky() {
	// Gradiente vertical com curva quadrática — banda de horizonte mais larga
	float elevacao = clamp(EYEDIR.y * 1.5 + 0.5, 0.0, 1.0);
	vec3 cor_base = mix(horizon_color, zenith_color, elevacao * elevacao);

	// Nuvens procedurais — hemisfério superior e banda do horizonte
	float margem = EYEDIR.y + 0.15;
	if (margem > 0.0) {
		float altura_inv = 1.0 / max(margem, 0.05);
		vec2 uv_nuvem = EYEDIR.xz * altura_inv * 0.4;
		uv_nuvem += vec2(TIME * cloud_speed, TIME * cloud_speed * 0.35);

		float n = fbm(uv_nuvem);
		float mascara = smoothstep(1.0 - cloud_coverage, 1.0 - cloud_coverage + 0.4, n);
		float fade = smoothstep(0.0, 0.25, EYEDIR.y);
		cor_base = mix(cor_base, cloud_color, mascara * fade * 0.75);
	}

	// sun_direction: halo mínimo para manter uniform ativo (Farol usará futuramente)
	float halo = pow(max(0.0, dot(normalize(EYEDIR), normalize(-sun_direction))), 24.0);
	cor_base += vec3(halo * 0.04);

	// Modulação de brilho pelo ciclo — reforça noite além das cores dos presets
	float fator_dia = sin(time_of_day * PI) * 0.2 + 0.8;

	COLOR = cor_base * fator_dia;
}
