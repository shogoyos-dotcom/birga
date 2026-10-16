#!/usr/bin/env python3
"""4-bosqich matnlari: mamlakatlar yo'li va pastki menyu."""
import json
import pathlib

NEW = {
    "journey": {
        "en": "Conquer the world", "ru": "Захвати мир",
        "uz": "Dunyoni egalla", "tr": "Dünyayı fethet",
        "kk": "Әлемді жаула", "es": "Conquista el mundo",
        "pt": "Conquiste o mundo", "fr": "Conquiers le monde",
        "de": "Erobere die Welt", "id": "Taklukkan dunia",
        "zh": "征服世界", "ja": "世界を征服", "ko": "세계 정복",
        "hi": "दुनिया जीतो", "ar": "اغزُ العالم",
    },
    "journeyDone": {
        "en": "%d of %d countries", "ru": "%d из %d стран",
        "uz": "%d / %d mamlakat", "tr": "%d / %d ülke",
        "kk": "%d / %d ел", "es": "%d de %d países",
        "pt": "%d de %d países", "fr": "%d sur %d pays",
        "de": "%d von %d Ländern", "id": "%d dari %d negara",
        "zh": "%d / %d 个国家", "ja": "%d / %d か国",
        "ko": "%d / %d 개국", "hi": "%d / %d देश",
        "ar": "%d من %d دولة",
    },
    "journeyWon": {
        "en": "Whole world conquered!", "ru": "Весь мир захвачен!",
        "uz": "Butun dunyo egallandi!", "tr": "Tüm dünya fethedildi!",
        "kk": "Бүкіл әлем жаулап алынды!",
        "es": "¡Mundo entero conquistado!",
        "pt": "Mundo inteiro conquistado!",
        "fr": "Le monde entier est conquis !",
        "de": "Die ganze Welt erobert!",
        "id": "Seluruh dunia ditaklukkan!", "zh": "全世界已征服！",
        "ja": "世界制覇！", "ko": "전 세계 정복!",
        "hi": "पूरी दुनिया जीत ली!", "ar": "تم غزو العالم كله!",
    },
    "countryDone": {
        "en": "%s conquered!", "ru": "%s захвачена!",
        "uz": "%s egallandi!", "tr": "%s fethedildi!",
        "kk": "%s жаулап алынды!", "es": "¡%s conquistado!",
        "pt": "%s conquistado!", "fr": "%s conquis !",
        "de": "%s erobert!", "id": "%s ditaklukkan!",
        "zh": "已征服 %s！", "ja": "%s を制覇！",
        "ko": "%s 정복!", "hi": "%s जीत लिया!", "ar": "تم غزو %s!",
    },
    "tabGear": {
        "en": "Gear", "ru": "Снаряжение", "uz": "Jihoz",
        "tr": "Donanım", "kk": "Жабдық", "es": "Equipo",
        "pt": "Equipo", "fr": "Équipement", "de": "Ausrüstung",
        "id": "Perlengkapan", "zh": "装备", "ja": "装備",
        "ko": "장비", "hi": "साज-सामान", "ar": "العتاد",
    },
    "points": {
        "en": "pts", "ru": "очк.", "uz": "ochko", "tr": "puan",
        "kk": "ұпай", "es": "pts", "pt": "pts", "fr": "pts",
        "de": "Pkt", "id": "poin", "zh": "分", "ja": "ポイント",
        "ko": "점", "hi": "अंक", "ar": "نقطة",
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
