shader_type spatial;
// Yuza **yoritilmaydi**: multfilm uslubida maydon tekis rangda
// bo'lishi kerak. Yoritilganda och rang (masalan #eafbf4) quyosh
// ostida oqarib ketardi va hudud ranglari ham xira chiqardi.
// Yon devorlar alohida material bilan yoritiladi — 3D hajm
// shundan bilinadi.
render_mode unshaded;

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

// Suv kataklarining belgisi egalik kanalida (PaintLayer.WATER).
// Ular ovoz berishda qatnashmaydi: aks holda qirg'oqda 4x4 oynaga
// tushgan suv "egasiz" bo'lib ovoz berar va hudud rangini oq
// hoshiya kesib o'tardi.
const int WATER = 255;

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
uniform vec3 beach_color = vec3(0.99, 0.88, 0.28);
uniform float beach_width : hint_range(0.5, 3.5) = 1.8;

// Ovoz oynasining radiusi (katak) va kengligi.
//
// Kataklarga tushirilgan doira o'z o'qlari yonida uzun **to'g'ri**
// qatorlarga aylanadi: masalan 13 katak radiusli doirada 4 katakli
// tekis qism bo'ladi. Radiusi 1.5 katak bo'lgan oyna bunday
// qatorni yumshata olmaydi — faqat burchaklarini kesadi, va
// chegara ko'pburchak bo'lib ko'rinadi. Shuning uchun oyna
// to'g'ri qatordan kengroq bo'lishi kerak.
const int VOTE_R = 3;
const int VOTE_W = 2 * VOTE_R;

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

// Ovoz og'irligi: tor va keng splayn yig'indisi.
//
// Tor splayn (±2 katak) markazdagi katakni ustun qilib turadi —
// bir katak kengligidagi tilim ham ekranda qolishi kerak, aks
// holda egallangan yer ko'rinmay qolardi. Keng splayn (±VOTE_R)
// esa uzun to'g'ri qatorlarni yumshatadi.
//
// WIDE_MIX — keng qismning ulushi. Markazdagi katakning ulushi
// 0.667*(1+k) / (1 + 1.506*k) ga teng; u 0.5 dan oshib turishi
// uchun k 1.9 dan kichik bo'lishi shart.
const float WIDE_MIX = 0.7;

// Hudud chetidagi hoshiya kengligi (ovoz birligida; 0.35 taxminan
// bir katak). Hoshiya skinning urg'u rangida bo'ladi — tarvuzda
// yashil po'st, muzda och moviy.
const float RIM_WIDTH = 0.80;

float vote_weight(float x) {
	return weight_of(x) + WIDE_MIX * weight_of(x * (2.0 / float(VOTE_R)));
}

vec4 cell_texel(vec2 cell) {
	// textureLod: namuna shartli shoxobchalar ichida ham olinadi,
	// hosila hisoblanishi shart emas.
	return textureLod(index_tex, (cell + vec2(0.5)) / grid_size, 0.0);
}

vec4 palette_of(int index) {
	return textureLod(palette_tex,
		vec2((float(index) + 0.5) / 768.0, 0.5), 0.0);
}

vec3 color_of(int index) {
	return palette_of(index).rgb;
}

// ——— Hudud naqshlari ———
//
// Naqsh raqami rang jadvalining 512+ID katagidan, **alfa**
// kanalidan o'qiladi (0 — tekis): rang kanallari sRGB dan
// chiziqliga o'giriladi va butun son ularda omon qolmaydi.
// Naqsh o'yinchining o'z rangi ustiga chiziladi, shuning uchun
// maydonda kim kimligi baribir bilinadi.

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

// Katak to'rida tasodifiy joylashgan dog'lar. `density` — dog'
// qanchalik katta, `cell` — naqsh to'rining qadami.
float blobs(vec2 at, float cell_size, float radius, float seed) {
	vec2 grid_at = at / cell_size;
	vec2 base = floor(grid_at);
	float best = 1.0;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 cell = base + vec2(float(i), float(j));
			vec2 jitter = vec2(hash21(cell + seed),
				hash21(cell + seed + 7.1));
			float d = length(grid_at - (cell + 0.2 + jitter * 0.6));
			best = min(best, d);
		}
	}
	return 1.0 - smoothstep(radius, radius + 0.12, best);
}

vec3 skin_shade(int owner, vec3 base, vec2 at) {
	int pattern = int(palette_of(512 + owner).a * 255.0 + 0.5);
	if (pattern == 0) {
		return base;
	}
	vec3 accent = color_of(256 + owner);
	float mask = 0.0;
	if (pattern == 1) {
		// Urug'lar — tarvuz.
		mask = blobs(at, 5.0, 0.11, 0.0);
	} else if (pattern == 2) {
		// Mayda rangli chiziqchalar — donut sepmasi.
		vec2 turned = vec2(at.x + at.y, at.y - at.x) * 0.5;
		mask = blobs(turned, 4.5, 0.1, 3.0)
			+ blobs(turned + 2.0, 4.5, 0.08, 9.0) * 0.8;
	} else if (pattern == 3) {
		// Muz yoriqlari — to'rsimon chiziqlar.
		vec2 cell = at / 9.0;
		vec2 edge = abs(fract(cell + vec2(sin(cell.y), cos(cell.x)) * 0.2)
			- 0.5);
		mask = 1.0 - smoothstep(0.03, 0.07, min(edge.x, edge.y));
	} else if (pattern == 4) {
		// Lava cho'g'i — yirik, yumshoq dog'lar.
		mask = blobs(at, 10.0, 0.3, 1.0) * 0.75;
	} else if (pattern == 5) {
		// Yulduzlar — mayda, siyrak.
		mask = blobs(at, 6.0, 0.06, 5.0);
	} else if (pattern == 6) {
		// Barglar — cho'zilgan dog'lar.
		mask = blobs(at * vec2(1.0, 1.9), 8.0, 0.2, 2.0);
	} else {
		// Sitrus bo'laklari — markazdan tarqalgan nurlar.
		float a = atan(at.y - 40.0, at.x - 40.0);
		mask = 1.0 - smoothstep(0.05, 0.12, abs(fract(a * 2.4) - 0.5));
		mask *= 0.5;
	}
	return mix(base, accent, clamp(mask, 0.0, 1.0) * 0.9);
}

// Hudud butun yuzasini egallagan o'yinchining milliy bayrog'i dizayni bilan qoplaydi.
vec3 with_avatar(int owner, vec3 base, vec2 cell_pos) {
	if (owner <= 0 || avatar_alpha <= 0.0) {
		return base;
	}
	vec4 place = texelFetch(avatar_data, ivec2(owner, 0), 0);
	if (place.b <= 0.0 || place.a <= 0.0) {
		return base;
	}
	// Kengaytirilgan hudud bo'yicha nisbiy koordinatalar [0.0 .. 1.0]:
	vec2 rel = (cell_pos - vec2(place.r, place.g)) / (2.0 * vec2(place.b, place.a)) + vec2(0.5);
	if (rel.x < 0.0 || rel.x > 1.0 || rel.y < 0.0 || rel.y > 1.0) {
		return base;
	}

	// Bayroq qirralarida silliq o'tish (edge fade) — noqulay cho'zilishlarni oldini oladi
	float edge_fade = smoothstep(0.0, 0.04, rel.x) * smoothstep(1.0, 0.96, rel.x)
		* smoothstep(0.0, 0.04, rel.y) * smoothstep(1.0, 0.96, rel.y);

	vec2 local = clamp(rel, 0.005, 0.995);

	// Har o'yinchiga ikkita katak: 0 — bosh belgisi, 1 — bayroq.
	float tile = float((owner - 1) * 2 + 1);
	vec2 at = vec2(mod(tile, avatar_grid.x), floor(tile / avatar_grid.x));
	vec4 flag_color = textureLod(avatar_tex, (at + local) / avatar_grid, 0.0);

	// Nepal kabi shaffof fonga ega bayroqlarni va chekka hududlarni silliq qorishtirish
	return mix(base, flag_color.rgb, flag_color.a * avatar_alpha * edge_fade);
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
	// Suv nomzod bo'lolmaydi: eng yaqin katak suv bo'lsa, uning
	// o'rniga quruqlikdagi qo'shnisi olinadi.
	int land_pick = 0;
	for (int k = 0; k < 4; k++) {
		if (near_owner[k] != WATER) {
			land_pick = near_owner[k];
			break;
		}
	}
	for (int k = 0; k < 4; k++) {
		if (near_owner[k] == WATER) {
			near_owner[k] = land_pick;
		}
	}

	// Bir ekran pikseliga nechta katak to'g'ri keladi — chegarani
	// shunga qarab yumshatamiz.
	float pixel = max(max(fwidth(p.x), fwidth(p.y)), 0.0005);

	vec3 shade;
	int win_owner = near_owner[0];
	bool same = near_owner[0] == near_owner[1]
		&& near_owner[0] == near_owner[2]
		&& near_owner[0] == near_owner[3];
	if (same) {
		// Eng yaqin to'rttasi bir xil bo'lsa, keng oyna ham shu egani
		// tanlaydi (uning ulushi har doim yarmidan ko'p) — qolgan 12
		// katakni o'qishning hojati yo'q.
		shade = with_avatar(near_owner[0],
			skin_shade(near_owner[0], color_of(near_owner[0]), cell_pos),
			cell_pos);
	} else {
		// ——— Hudud: VOTE_W x VOTE_W katak bo'yicha ovoz berish.
		//
		// Og'irlik kubik B-splayn, lekin argumenti siqilgan:
		// splayn ±2 da tugaydi, oyna esa ±VOTE_R gacha boradi.
		float wx[VOTE_W];
		float wy[VOTE_W];
		for (int i = 0; i < VOTE_W; i++) {
			float at = float(i - VOTE_R + 1);
			wx[i] = vote_weight(at - f.x);
			wy[i] = vote_weight(at - f.y);
		}
		float score[4] = float[](0.0, 0.0, 0.0, 0.0);
		for (int j = 0; j < VOTE_W; j++) {
			for (int i = 0; i < VOTE_W; i++) {
				int owner = int(cell_texel(base + vec2(
					float(i - VOTE_R + 1), float(j - VOTE_R + 1))).r
					* 255.0 + 0.5);
				if (owner == WATER) {
					continue;
				}
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
		win_owner = near_owner[best];
		int second = -1;
		for (int k = 0; k < 4; k++) {
			if (near_owner[k] != near_owner[best]
					&& (second < 0 || score[k] > score[second])) {
				second = k;
			}
		}

		shade = with_avatar(near_owner[best],
			skin_shade(near_owner[best], color_of(near_owner[best]),
				cell_pos), cell_pos);
		// Hudud chetidagi hoshiya: chegaraga yaqin joy skin
		// rangida bo'yaladi. Faqat shu yerda hisoblanadi —
		// ichkarida eng yaqin to'rt katak bir xil va tez yo'l
		// ishlaydi, demak hoshiya chegaradan nariga o'tmaydi.
		float gap = score[best] - score[second < 0 ? best : second];
		if (near_owner[best] > 0 && gap < RIM_WIDTH) {
			vec3 rim = color_of(256 + near_owner[best]);
			shade = mix(rim, shade, smoothstep(0.0, RIM_WIDTH, gap));
		}
		if (second >= 0) {
			vec3 other = with_avatar(near_owner[second],
				skin_shade(near_owner[second],
					color_of(near_owner[second]), cell_pos), cell_pos);
			float gap2 = score[second] - score[best];
			if (near_owner[second] > 0 && -gap2 < RIM_WIDTH) {
				vec3 rim2 = color_of(256 + near_owner[second]);
				other = mix(rim2, other, smoothstep(0.0, RIM_WIDTH, -gap2));
			}
			float lead = (score[best] - score[second]) / pixel;
			shade = mix(other, shade, clamp(0.5 + 0.5 * lead, 0.5, 1.0));
		}
	}

	// Qirg'oq sohili (beach sand transition)
	if (win_owner == 0) {
		float water_dist = 99.0;
		for (int dy = -2; dy <= 2; dy++) {
			for (int dx = -2; dx <= 2; dx++) {
				vec4 c = cell_texel(base + vec2(float(dx), float(dy)));
				if (int(c.r * 255.0 + 0.5) == WATER) {
					float d = length(f - vec2(float(dx), float(dy)));
					water_dist = min(water_dist, d);
				}
			}
		}
		if (water_dist < beach_width) {
			float t = smoothstep(0.3, beach_width, water_dist);
			shade = mix(beach_color, shade, t);
		}
	}

	// Yumshoq multfilm quyosh nuri (subtle organic relief)
	vec2 terr_uv = cell_pos * 0.06;
	float terr_var = sin(terr_uv.x * 2.5) * cos(terr_uv.y * 2.5) * 0.035;
	shade *= (0.97 + terr_var);

	ALBEDO = shade;
}
