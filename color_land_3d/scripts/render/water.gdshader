shader_type spatial;
render_mode unshaded;

// Color Land 3D — Tropical Cartoon Ocean Shader
// Chiroyli tropik moviy okean, dunyo koordinatalarida jonli to'lqinlar va oq ko'pik

uniform vec4 deep_color : source_color = vec4(0.02, 0.42, 0.76, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.08, 0.78, 0.90, 1.0);
uniform vec4 foam_color : source_color = vec4(0.96, 0.99, 1.0, 0.95);
uniform float wave_speed : hint_range(0.0, 2.0) = 0.65;
uniform int quality_level : hint_range(0, 2) = 1; // 0 = LOW, 1 = MEDIUM, 2 = HIGH

void fragment() {
	// Dunyo koordinatalari bo'yicha to'lqin chastotasi — har qanday xarita o'lchamida mukammal ko'rinadi
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 uv = world_pos.xz * 0.24;
	float t = TIME * wave_speed;

	float wave = 0.0;
	if (quality_level == 0) {
		// LOW: bitta sodda sinus to'lqini
		wave = sin(uv.x * 2.0 + t * 1.2) * 0.5;
	} else if (quality_level == 1) {
		// MEDIUM: 2 qatlamli multfilm to'lqin harakati
		float w1 = sin(uv.x * 2.2 + t * 1.4) * cos(uv.y * 1.8 + t * 1.1);
		float w2 = sin((uv.x * 1.3 - uv.y * 1.9) + t * 0.9);
		wave = (w1 * 0.6 + w2 * 0.4);
	} else {
		// HIGH: to'liq 3 qatlamli multfilm to'lqin harakati
		float w1 = sin(uv.x * 2.2 + t * 1.4) * cos(uv.y * 1.8 + t * 1.1);
		float w2 = sin((uv.x * 1.3 - uv.y * 1.9) + t * 0.9);
		float w3 = cos(uv.x * 3.1 + uv.y * 2.4 - t * 1.6);
		wave = (w1 * 0.5 + w2 * 0.3 + w3 * 0.2);
	}

	// Chuqur va sayoz tropik ranglar uyg'unligi
	vec3 water = mix(deep_color.rgb, shallow_color.rgb, 0.52 + 0.48 * wave);

	// To'lqin cho'qqilarida oq multfilm ko'pigi (MEDIUM va HIGH)
	if (quality_level > 0) {
		float crest = smoothstep(0.42, 0.80, wave);
		water = mix(water, foam_color.rgb, crest * 0.45);
	}

	// Nozik quyosh yaltirashi (faqat HIGH)
	if (quality_level == 2) {
		float glint = pow(max(0.0, wave), 4.0) * 0.25;
		water += vec3(glint);
	}

	ALBEDO = water;
}
