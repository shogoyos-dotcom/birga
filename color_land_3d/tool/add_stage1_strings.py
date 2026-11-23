#!/usr/bin/env python3
"""1-bosqich uchun yangi matnlar: uslub nomi va minikarta tomoni."""
import json
import pathlib

NEW = {
    "themePaper": {c: "Paper" for c in [
        "en", "ru", "uz", "tr", "kk", "es", "pt", "fr", "de", "id",
        "zh", "ja", "ko", "hi", "ar"]},
    "sideLeft": {
        "en": "Left", "ru": "Слева", "uz": "Chapda", "tr": "Solda",
        "kk": "Солда", "es": "Izquierda", "pt": "Esquerda",
        "fr": "Gauche", "de": "Links", "id": "Kiri", "zh": "左侧",
        "ja": "左", "ko": "왼쪽", "hi": "बाएँ", "ar": "يسار",
    },
    "sideRight": {
        "en": "Right", "ru": "Справа", "uz": "O‘ngda", "tr": "Sağda",
        "kk": "Оңда", "es": "Derecha", "pt": "Direita", "fr": "Droite",
        "de": "Rechts", "id": "Kanan", "zh": "右侧", "ja": "右",
        "ko": "오른쪽", "hi": "दाएँ", "ar": "يمين",
    },
    "sideOff": {
        "en": "Off", "ru": "Выкл", "uz": "O‘chiq", "tr": "Kapalı",
        "kk": "Өшірулі", "es": "Apagado", "pt": "Desligado",
        "fr": "Désactivé", "de": "Aus", "id": "Mati", "zh": "关闭",
        "ja": "オフ", "ko": "끄기", "hi": "बंद", "ar": "إيقاف",
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
    raise SystemExit(f"kalitlar soni teng emas: {sizes}")
PATH.write_text(
    json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"tayyor: har tilda {next(iter(sizes.values()))} kalit")
