shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

// Arena ustki yuzasi: hudud, iz va avatar.
//
// Egalik ma'lumoti har katak uchun bitta piksel bo'lib keladi, arena
// esa ekranda o'nlab marta kattalashadi. "Nearest" filtr bilan chegara
// zinapoyaga aylanadi, "linear" bilan butun rang loyqa bo'ladi.
// Shuning uchun bu yerda **ovoz berish** ishlatiladi.
//
//  * Hudud chegarasi — 4x4 katak bo'yicha, kubik (B-splayn) og'irlik
//    bilan. Keng oyna tufayli zinapoya butunlay yo'qoladi va chegara
//    silliq egri chiziqqa aylanadi.
//  * Avatar — g'olib chiqqan egannikki, uning hududiga moslab
//    cho'ziladi va aynan shu hudud ichida ko'rinadi.

// R — hudud egasi (0..255). G (iz) bu yerda ishlatilmaydi: iz
// o'yinchining uzluksiz yo'li bo'yicha alohida lenta bo'lib chiziladi,
// chunki kataklardan chizilgan chiziq to'lqinli ko'rinadi.
uniform sampler2D index_tex : filter_nearest, repeat_disable;
// 512x1: 0 — egasiz quruqlik, 1..255 — hudud.
uniform sampler2D palette_tex : source_color, filter_nearest, repeat_disable;
// O'yinchilar avatarlari (COLS x rows katak).
uniform sampler2D avatar_tex : source_color, filter_linear, repeat_disable;
// 256x1 (RGBAF): R — markaz X, G — markaz Y, B — yarim o'lcham.
uniform sampler2D avatar_data : filter_nearest, repeat_disable;
uniform vec2 grid_size;
uniform vec2 avatar_grid = vec2(8.0, 4.0);
uniform float avatar_alpha : hint_range(0.0, 1.0) = 0.9;
uniform float surface_roughness : hint_range(0.0, 1.0) = 0.9;

// Kubik B-splayn: markazdagi katak ustun turadi, uzoqdagisi asta
// so'nadi — shuning uchun chegara silliq, rang esa toza chiqadi.
float weight_of(float x) {
	float a = abs(x);
	if (a < 1.0) {
		return (4.0 - 6.0 * a * a + 3.0 * a * a * a) / 6.0;
	}
	if (a < 2.0) {
		float t = 2.0 - a;
		return t * t * t / 6.0;
	}
	return 0.0;
}

vec4 cell_texel(vec2 cell) {
	// textureLod: namuna shartli shoxobchalar ichida ham olinadi,
	// hosila hisoblanishi shart emas.
	return textureLod(index_tex, (cell + vec2(0.5)) / grid_size, 0.0);
}

vec3 color_of(int index) {
	return textureLod(palette_tex,
		vec2((float(index) + 0.5) / 512.0, 0.5), 0.0).rgb;
}

// Hudud rangiga o'sha egannikki avatarni qo'shadi.
vec3 with_avatar(int owner, vec3 base, vec2 cell_pos) {
	if (owner <= 0 || avatar_alpha <= 0.0) {
		return base;
	}
	vec4 place = texelFetch(avatar_data, ivec2(owner, 0), 0);
	if (place.b <= 0.0) {
		return base;
	}
	vec2 local = (cell_pos - place.rg) / (2.0 * place.b) + vec2(0.5);
	if (local.x < 0.0 || local.x > 1.0 || local.y < 0.0 || local.y > 1.0) {
		return base;
	}
	// Har o'yinchiga ikkita katak: 0 — bosh belgisi, 1 — bayroq.
	float tile = float((owner - 1) * 2 + 1);
	vec2 at = vec2(mod(tile, avatar_grid.x), floor(tile / avatar_grid.x));
	vec4 glyph = textureLod(avatar_tex, (at + local) / avatar_grid, 0.0);
	return mix(base, glyph.rgb, glyph.a * avatar_alpha);
}

void fragment() {
	ROUGHNESS = surface_roughness;

	vec2 cell_pos = UV * grid_size;
	// Katak markazlari to'ri: butun qiymat — katak markazi.
	vec2 p = cell_pos - vec2(0.5);
	vec2 base = floor(p);
	vec2 f = p - base;

	// Eng yaqin 4 katak — tez yo'l uchun.
	vec4 t00 = cell_texel(base);
	vec4 t10 = cell_texel(base + vec2(1.0, 0.0));
	vec4 t01 = cell_texel(base + vec2(0.0, 1.0));
	vec4 t11 = cell_texel(base + vec2(1.0, 1.0));
	int near_owner[4] = int[](
		int(t00.r * 255.0 + 0.5), int(t10.r * 255.0 + 0.5),
		int(t01.r * 255.0 + 0.5), int(t11.r * 255.0 + 0.5));

	// Bir ekran pikseliga nechta katak to'g'ri keladi — chegarani
	// shunga qarab yumshatamiz.
	float pixel = max(max(fwidth(p.x), fwidth(p.y)), 0.0005);

	vec3 shade;
	bool same = near_owner[0] == near_owner[1]
		&& near_owner[0] == near_owner[2]
		&& near_owner[0] == near_owner[3];
	if (same) {
		// Eng yaqin to'rttasi bir xil bo'lsa, keng oyna ham shu egani
		// tanlaydi (uning ulushi har doim yarmidan ko'p) — qolgan 12
		// katakni o'qishning hojati yo'q.
		shade = with_avatar(near_owner[0],
			color_of(near_owner[0]), cell_pos);
	} else {
		// ——— Hudud: 4x4 katak bo'yicha ovoz berish.
		float wx[4];
		float wy[4];
		for (int i = 0; i < 4; i++) {
			wx[i] = weight_of(float(i) - 1.0 - f.x);
			wy[i] = weight_of(float(i) - 1.0 - f.y);
		}
		float score[4] = float[](0.0, 0.0, 0.0, 0.0);
		for (int j = 0; j < 4; j++) {
			for (int i = 0; i < 4; i++) {
				int owner = int(cell_texel(
					base + vec2(float(i) - 1.0, float(j) - 1.0)).r
					* 255.0 + 0.5);
				float w = wx[i] * wy[j];
				for (int k = 0; k < 4; k++) {
					if (near_owner[k] == owner) {
						score[k] += w;
					}
				}
			}
		}

		int best = 0;
		for (int k = 1; k < 4; k++) {
			if (score[k] > score[best]) {
				best = k;
			}
		}
		int second = -1;
		for (int k = 0; k < 4; k++) {
			if (near_owner[k] != near_owner[best]
					&& (second < 0 || score[k] > score[second])) {
				second = k;
			}
		}

		shade = with_avatar(near_owner[best],
			color_of(near_owner[best]), cell_pos);
		if (second >= 0) {
			vec3 other = with_avatar(near_owner[second],
				color_of(near_owner[second]), cell_pos);
			float lead = (score[best] - score[second]) / pixel;
			shade = mix(other, shade, clamp(0.5 + 0.5 * lead, 0.5, 1.0));
		}
	}

	ALBEDO = shade;
}
