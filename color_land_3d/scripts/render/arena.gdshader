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

// Hudud chetidagi hoshiya kengligi (ovoz birligida).
// Hoshiya skinning urg'u rangida bo'ladi — tarvuzda yashil po'st, muzda och moviy.
const float RIM_WIDTH = 0.70;

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
	vec2 p = cell_pos - vec2(0.5);
	vec2 base = floor(p);
	vec2 f = p - base;

	// Eng yaqin 4 katak — tez yo'l va egalik chegaralari uchun
	vec4 t00 = cell_texel(base);
	vec4 t10 = cell_texel(base + vec2(1.0, 0.0));
	vec4 t01 = cell_texel(base + vec2(0.0, 1.0));
	vec4 t11 = cell_texel(base + vec2(1.0, 1.0));

	int near_owner[4] = int[](
		int(t00.r * 255.0 + 0.5), int(t10.r * 255.0 + 0.5),
		int(t01.r * 255.0 + 0.5), int(t11.r * 255.0 + 0.5));

	// Suv burchaklariga eng yaqin qo'shni quruqlik burchagining egasi biriktiriladi
	// Bu qirg'oq bo'ylab uzluksiz, zinapoyasiz silliq o'tishni ta'minlaydi
	if (near_owner[0] == WATER && near_owner[1] != WATER) near_owner[0] = near_owner[1];
	if (near_owner[0] == WATER && near_owner[2] != WATER) near_owner[0] = near_owner[2];
	if (near_owner[1] == WATER && near_owner[0] != WATER) near_owner[1] = near_owner[0];
	if (near_owner[1] == WATER && near_owner[3] != WATER) near_owner[1] = near_owner[3];
	if (near_owner[2] == WATER && near_owner[0] != WATER) near_owner[2] = near_owner[0];
	if (near_owner[2] == WATER && near_owner[3] != WATER) near_owner[2] = near_owner[3];
	if (near_owner[3] == WATER && near_owner[1] != WATER) near_owner[3] = near_owner[1];
	if (near_owner[3] == WATER && near_owner[2] != WATER) near_owner[3] = near_owner[2];
	if (near_owner[0] == WATER && near_owner[3] != WATER) near_owner[0] = near_owner[3];
	if (near_owner[3] == WATER && near_owner[0] != WATER) near_owner[3] = near_owner[0];
	if (near_owner[1] == WATER && near_owner[2] != WATER) near_owner[1] = near_owner[2];
	if (near_owner[2] == WATER && near_owner[1] != WATER) near_owner[2] = near_owner[1];

	vec3 shade;
	int win_owner = near_owner[0];
	bool same = (near_owner[0] == near_owner[1])
		&& (near_owner[0] == near_owner[2])
		&& (near_owner[0] == near_owner[3]);

	if (same) {
		// Eng yaqin 4 katak bir xil bo'lsa — tezkor to'g'ri chizish
		shade = with_avatar(win_owner,
			skin_shade(win_owner, color_of(win_owner), cell_pos),
			cell_pos);
	} else {
		// Hudud chegarasi: 4x4 doiraviy radial izotrop silliqlash (quartic kernel)
		// Radial masofa tufayli zinapoya va to'rtburchak shakllar butunlay yo'qoladi,
		// chegaralar tabiiy va egri chiziqli bo'ladi.
		float score[4] = float[](0.0, 0.0, 0.0, 0.0);
		float total_w = 0.0;
		for (int dy = -1; dy <= 2; dy++) {
			for (int dx = -1; dx <= 2; dx++) {
				vec2 offset = vec2(float(dx), float(dy));
				vec2 delta = offset - f;
				float r2 = dot(delta, delta);
				if (r2 >= 4.84) {
					continue;
				}
				float t = 1.0 - r2 / 4.84;
				float w = t * t;
				total_w += w;
				int owner = int(cell_texel(base + offset).r * 255.0 + 0.5);
				if (owner == WATER) {
					owner = near_owner[0];
				}
				for (int k = 0; k < 4; k++) {
					if (near_owner[k] == owner) {
						score[k] += w;
					}
				}
			}
		}

		if (total_w > 0.0001) {
			float inv_w = 1.0 / total_w;
			score[0] *= inv_w;
			score[1] *= inv_w;
			score[2] *= inv_w;
			score[3] *= inv_w;
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
			skin_shade(near_owner[best], color_of(near_owner[best]), cell_pos),
			cell_pos);

		// Hudud chetidagi hoshiya: chegaraga yaqin joy skin rangida bo'yaladi
		float second_score = (second >= 0) ? score[second] : 0.0;
		float gap = score[best] - second_score;
		if (near_owner[best] > 0 && gap < RIM_WIDTH && second >= 0) {
			vec3 rim = color_of(256 + near_owner[best]);
			shade = mix(rim, shade, smoothstep(0.0, RIM_WIDTH, gap));
		}
		if (second >= 0) {
			vec3 other = with_avatar(near_owner[second],
				skin_shade(near_owner[second], color_of(near_owner[second]), cell_pos),
				cell_pos);
			float gap2 = second_score - score[best];
			if (near_owner[second] > 0 && -gap2 < RIM_WIDTH) {
				vec3 rim2 = color_of(256 + near_owner[second]);
				other = mix(rim2, other, smoothstep(0.0, RIM_WIDTH, -gap2));
			}
			float pixel = max(max(fwidth(p.x), fwidth(p.y)), 0.0005);
			float lead = (score[best] - second_score) / pixel;
			shade = mix(other, shade, clamp(0.5 + 0.5 * lead, 0.5, 1.0));
		}
	}

	// Qirg'oq sohili (beach sand transition) — faqat egasiz quruqlikda (win_owner == 0).
	// Egallangan hudud ichida sariq tirqishlar yoki to'rtburchaklar hosil qilmaydi.
	if (win_owner == 0) {
		float water_dist = mix(mix(t00.b, t10.b, f.x), mix(t01.b, t11.b, f.x), f.y) * 4.0;
		if (water_dist < beach_width) {
			float t = smoothstep(0.15, beach_width, water_dist);
			shade = mix(beach_color, shade, t);
		}
	}

	// Yumshoq multfilm quyosh nuri (subtle organic relief)
	vec2 terr_uv = cell_pos * 0.06;
	float terr_var = sin(terr_uv.x * 2.5) * cos(terr_uv.y * 2.5) * 0.035;
	shade *= (0.97 + terr_var);

	ALBEDO = shade;
}
