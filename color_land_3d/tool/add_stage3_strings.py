#!/usr/bin/env python3
"""3-bosqich matnlari: kuchaytirgichlar, sferalar, natija ekrani."""
import json
import pathlib

LANGS = ["en", "ru", "uz", "tr", "kk", "es", "pt", "fr", "de", "id",
         "zh", "ja", "ko", "hi", "ar"]

NEW = {
    "powerups": {
        "en": "Power-ups", "ru": "Усилители", "uz": "Kuchaytirgichlar",
        "tr": "Güçlendirmeler", "kk": "Күшейткіштер",
        "es": "Mejoras", "pt": "Melhorias", "fr": "Bonus",
        "de": "Boosts", "id": "Penguat", "zh": "强化", "ja": "強化",
        "ko": "강화", "hi": "पावर-अप", "ar": "التحسينات",
    },
    "powerFever": {
        "en": "Fever", "ru": "Рывок", "uz": "Shiddat", "tr": "Coşku",
        "kk": "Қарқын", "es": "Fiebre", "pt": "Febre", "fr": "Fièvre",
        "de": "Fieber", "id": "Demam", "zh": "狂热", "ja": "フィーバー",
        "ko": "피버", "hi": "फीवर", "ar": "الحماس",
    },
    "powerFeverInfo": {
        "en": "Speed boost at the start of each run",
        "ru": "Ускорение в начале каждой игры",
        "uz": "Har o‘yin boshida tezlik oshadi",
        "tr": "Her turun başında hız artar",
        "kk": "Әр ойын басында жылдамдық артады",
        "es": "Impulso de velocidad al empezar",
        "pt": "Impulso de velocidade no início",
        "fr": "Gain de vitesse au départ",
        "de": "Geschwindigkeitsschub beim Start",
        "id": "Tambahan kecepatan saat mulai",
        "zh": "每局开局提速", "ja": "開始時にスピードアップ",
        "ko": "시작할 때 속도 증가",
        "hi": "हर दौर की शुरुआत में तेज़ी",
        "ar": "زيادة السرعة في بداية كل جولة",
    },
    "powerMagnet": {
        "en": "Magnet", "ru": "Магнит", "uz": "Magnit", "tr": "Mıknatıs",
        "kk": "Магнит", "es": "Imán", "pt": "Ímã", "fr": "Aimant",
        "de": "Magnet", "id": "Magnet", "zh": "磁铁", "ja": "マグネット",
        "ko": "자석", "hi": "मैग्नेट", "ar": "مغناطيس",
    },
    "powerMagnetInfo": {
        "en": "Pulls in nearby coins", "ru": "Притягивает монеты рядом",
        "uz": "Yaqindagi tangalarni tortadi",
        "tr": "Yakındaki paraları çeker",
        "kk": "Жақындағы тиындарды тартады",
        "es": "Atrae las monedas cercanas",
        "pt": "Atrai moedas próximas",
        "fr": "Attire les pièces proches",
        "de": "Zieht Münzen in der Nähe an",
        "id": "Menarik koin di dekatnya",
        "zh": "吸取附近的金币", "ja": "近くのコインを引き寄せる",
        "ko": "근처 코인을 끌어당김",
        "hi": "पास के सिक्के खींचता है",
        "ar": "يجذب العملات القريبة",
    },
    "powerPassive": {
        "en": "Bonus coins", "ru": "Бонусные монеты",
        "uz": "Qo‘shimcha tanga", "tr": "Bonus para",
        "kk": "Қосымша тиын", "es": "Monedas extra",
        "pt": "Moedas extra", "fr": "Pièces bonus",
        "de": "Bonusmünzen", "id": "Koin bonus", "zh": "额外金币",
        "ja": "ボーナスコイン", "ko": "보너스 코인",
        "hi": "बोनस सिक्के", "ar": "عملات إضافية",
    },
    "powerPassiveInfo": {
        "en": "Extra coins at the end of every run",
        "ru": "Дополнительные монеты в конце игры",
        "uz": "Har o‘yin oxirida qo‘shimcha tanga",
        "tr": "Her turun sonunda ek para",
        "kk": "Әр ойын соңында қосымша тиын",
        "es": "Monedas extra al final de cada partida",
        "pt": "Moedas extra ao fim de cada partida",
        "fr": "Pièces en plus à la fin de chaque partie",
        "de": "Zusätzliche Münzen am Ende jeder Runde",
        "id": "Koin tambahan di akhir permainan",
        "zh": "每局结束获得额外金币",
        "ja": "ゲーム終了時に追加コイン",
        "ko": "매 게임 종료 시 추가 코인",
        "hi": "हर दौर के अंत में अतिरिक्त सिक्के",
        "ar": "عملات إضافية في نهاية كل جولة",
    },
    "levelMax": {
        "en": "MAX", "ru": "МАКС", "uz": "MAKS", "tr": "MAKS",
        "kk": "МАКС", "es": "MÁX", "pt": "MÁX", "fr": "MAX",
        "de": "MAX", "id": "MAKS", "zh": "满级", "ja": "最大",
        "ko": "최대", "hi": "अधिकतम", "ar": "الأقصى",
    },
    "levelShort": {
        "en": "Lv %d", "ru": "Ур. %d", "uz": "%d-daraja",
        "tr": "Sv %d", "kk": "%d-деңгей", "es": "Niv %d",
        "pt": "Nív %d", "fr": "Niv %d", "de": "St. %d",
        "id": "Lv %d", "zh": "%d 级", "ja": "Lv %d", "ko": "%d 레벨",
        "hi": "स्तर %d", "ar": "مستوى %d",
    },
    "upgrade": {
        "en": "Upgrade", "ru": "Улучшить", "uz": "Oshirish",
        "tr": "Yükselt", "kk": "Жақсарту", "es": "Mejorar",
        "pt": "Melhorar", "fr": "Améliorer", "de": "Verbessern",
        "id": "Tingkatkan", "zh": "升级", "ja": "強化", "ko": "강화",
        "hi": "अपग्रेड", "ar": "ترقية",
    },
    "gotShield": {
        "en": "Shield!", "ru": "Щит!", "uz": "Qalqon!",
        "tr": "Kalkan!", "kk": "Қалқан!", "es": "¡Escudo!",
        "pt": "Escudo!", "fr": "Bouclier !", "de": "Schild!",
        "id": "Perisai!", "zh": "护盾！", "ja": "シールド！",
        "ko": "방어막!", "hi": "कवच!", "ar": "درع!",
    },
    "gotDash": {
        "en": "Speed!", "ru": "Скорость!", "uz": "Tezlik!",
        "tr": "Hız!", "kk": "Жылдамдық!", "es": "¡Velocidad!",
        "pt": "Velocidade!", "fr": "Vitesse !",
        "de": "Geschwindigkeit!", "id": "Kecepatan!", "zh": "加速！",
        "ja": "スピード！", "ko": "속도!", "hi": "रफ़्तार!",
        "ar": "سرعة!",
    },
    "shieldSaved": {
        "en": "Shield saved you", "ru": "Щит спас вас",
        "uz": "Qalqon saqlab qoldi", "tr": "Kalkan seni kurtardı",
        "kk": "Қалқан сақтап қалды", "es": "El escudo te salvó",
        "pt": "O escudo te salvou", "fr": "Le bouclier t’a sauvé",
        "de": "Das Schild hat dich gerettet",
        "id": "Perisai menyelamatkanmu", "zh": "护盾救了你",
        "ja": "シールドが守った", "ko": "방어막이 막아냈다",
        "hi": "कवच ने बचा लिया", "ar": "أنقذك الدرع",
    },
    "coinsFound": {
        "en": "Coins collected", "ru": "Собрано монет",
        "uz": "Terilgan tanga", "tr": "Toplanan para",
        "kk": "Жиналған тиын", "es": "Monedas recogidas",
        "pt": "Moedas coletadas", "fr": "Pièces ramassées",
        "de": "Gesammelte Münzen", "id": "Koin terkumpul",
        "zh": "收集的金币", "ja": "集めたコイン", "ko": "모은 코인",
        "hi": "जमा सिक्के", "ar": "العملات المجموعة",
    },
    "bonusRow": {
        "en": "Bonus", "ru": "Бонус", "uz": "Bonus", "tr": "Bonus",
        "kk": "Бонус", "es": "Bono", "pt": "Bônus", "fr": "Bonus",
        "de": "Bonus", "id": "Bonus", "zh": "奖励", "ja": "ボーナス",
        "ko": "보너스", "hi": "बोनस", "ar": "مكافأة",
    },
    "bestPercent": {
        "en": "Best %.2f%%", "ru": "Лучший %.2f%%",
        "uz": "Eng yaxshi %.2f%%", "tr": "En iyi %.2f%%",
        "kk": "Үздік %.2f%%", "es": "Mejor %.2f%%",
        "pt": "Melhor %.2f%%", "fr": "Record %.2f%%",
        "de": "Bestwert %.2f%%", "id": "Terbaik %.2f%%",
        "zh": "最佳 %.2f%%", "ja": "最高 %.2f%%", "ko": "최고 %.2f%%",
        "hi": "सर्वश्रेष्ठ %.2f%%", "ar": "الأفضل %.2f%%",
    },
}

PATH = pathlib.Path(__file__).resolve().parent.parent / "data" / "strings.json"
data = json.loads(PATH.read_text(encoding="utf-8"))
for key, rows in NEW.items():
    missing = set(data) - set(rows)
    if missing:
        raise SystemExit(f"{key}: tarjima yetishmaydi: {sorted(missing)}")
    for code in data:
        data[code][key] = rows[code]

sizes = {code: len(table) for code, table in data.items()}
if len(set(sizes.values())) != 1:
    raise SystemExit(f"tillarda kalit soni teng emas: {sizes}")
PATH.write_text(
    json.dumps(data, ensure_ascii=False, indent="\t", sort_keys=True) + "\n",
    encoding="utf-8")
print(f"{len(NEW)} kalit qo'shildi, har tilda {next(iter(sizes.values()))} kalit")
