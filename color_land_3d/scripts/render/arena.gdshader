shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

// Arena ustki yuzasi: hudud va iz chegaralarini silliq chizadi.
//
// Egalik ma'lumoti har katak uchun bitta piksel bo'lib keladi, arena
// esa ekranda o'nlab marta kattalashadi — oddiy "nearest" filtr bilan
// chegara zinapoyaga aylanadi, "linear" bilan esa butun rang loyqa
// bo'lib ketadi.
//
// Shuning uchun bu yerda **ovoz berish** ishlatiladi: har piksel eng
// yaqin 4 katakning egasini oladi va ularga bilinear og'irlik beradi.
// Qaysi egaga tushgan og'irliklar yig'indisi katta bo'lsa, o'sha
// g'olib. Natijada burchaklar yumaloqlanadi, 45 gradusli zinapoya esa
// to'g'ri diagonalga aylanadi — katak ichidagi ranglar esa toza
// qoladi. Chegaraning o'zi ekran o'lchamiga qarab yumshatiladi
// (antialiasing).

// R — hudud egasi (0..255), G — iz egasi (0..255).
uniform sampler2D index_tex : filter_nearest, repeat_disable;
// 512x1: 0 — egasiz quruqlik, 1..255 — hudud, 256..511 — iz.
uniform sampler2D palette_tex : source_color, filter_nearest, repeat_disable;
uniform vec2 grid_size;
uniform float surface_roughness : hint_range(0.0, 1.0) = 0.9;

int index_at(vec2 cell) {
	vec2 uv = (cell + vec2(0.5)) / grid_size;
	vec4 texel = texture(index_tex, uv);
	int owner = int(texel.r * 255.0 + 0.5);
	int trail = int(texel.g * 255.0 + 0.5);
	return trail != 0 ? 256 + trail : owner;
}

vec3 color_of(int index) {
	return texture(palette_tex, vec2((float(index) + 0.5) / 512.0, 0.5)).rgb;
}

void fragment() {
	ROUGHNESS = surface_roughness;

	// Katak markazlari to'ri: butun qiymat — katak markazi.
	vec2 p = UV * grid_size - vec2(0.5);
	vec2 base = floor(p);
	vec2 f = p - base;

	int ids[4] = int[](
		index_at(base),
		index_at(base + vec2(1.0, 0.0)),
		index_at(base + vec2(0.0, 1.0)),
		index_at(base + vec2(1.0, 1.0)));

	// To'rttasi ham bir xil bo'lsa — chegara yo'q, hisoblashga hojat
	// yo'q (piksellarning aksariyati shu yo'ldan o'tadi).
	if (ids[0] == ids[1] && ids[0] == ids[2] && ids[0] == ids[3]) {
		ALBEDO = color_of(ids[0]);
	} else {
		float weights[4] = float[](
			(1.0 - f.x) * (1.0 - f.y),
			f.x * (1.0 - f.y),
			(1.0 - f.x) * f.y,
			f.x * f.y);

		// Har bir nomzodga tushgan umumiy og'irlik.
		float totals[4] = float[](0.0, 0.0, 0.0, 0.0);
		for (int k = 0; k < 4; k++) {
			for (int j = 0; j < 4; j++) {
				if (ids[j] == ids[k]) {
					totals[k] += weights[j];
				}
			}
		}

		int best = 0;
		for (int k = 1; k < 4; k++) {
			if (totals[k] > totals[best]) {
				best = k;
			}
		}
		// Ikkinchi o'rin — boshqa egaga tegishli eng kuchli nomzod.
		int second = -1;
		for (int k = 0; k < 4; k++) {
			if (ids[k] != ids[best] && (second < 0 || totals[k] > totals[second])) {
				second = k;
			}
		}

		vec3 winner = color_of(ids[best]);
		if (second < 0) {
			ALBEDO = winner;
		} else {
			// Chegarani bir piksel kengligida yumshatamiz: `fwidth`
			// bitta ekran piksellga nechta katak to'g'ri kelishini
			// beradi.
			float pixel = max(max(fwidth(p.x), fwidth(p.y)), 0.0005);
			float lead = totals[best] - totals[second];
			float t = clamp(0.5 + 0.5 * lead / pixel, 0.5, 1.0);
			ALBEDO = mix(color_of(ids[second]), winner, t);
		}
	}
}
