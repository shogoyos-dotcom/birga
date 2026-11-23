#!/usr/bin/env python3
"""Phase 2 yangi matnlari: HUD va ekranga kerakli tarjimalar."""
import json
import pathlib

NEW = {
    "yourTerritory": {
        "en": "Your Territory", "ru": "Ваша территория",
        "uz": "Sizning hududingiz", "tr": "Bölgeniz",
        "kk": "Сіздің аумағыңыз", "es": "Tu territorio",
        "pt": "Seu território", "fr": "Votre territoire",
        "de": "Dein Territorium", "id": "Wilayah Anda",
        "zh": "你的领地", "ja": "あなたの領土", "ko": "내 영토",
        "hi": "आपका क्षेत्र", "ar": "أرضك",
    },
    "tabContinents": {
        "en": "Continents", "ru": "Континенты",
        "uz": "Qit'alar", "tr": "Kıtalar",
        "kk": "Құрлықтар", "es": "Continentes",
        "pt": "Continentes", "fr": "Continents",
        "de": "Kontinente", "id": "Benua",
        "zh": "大洲", "ja": "大陸", "ko": "대륙",
        "hi": "महाद्वीप", "ar": "القارات",
    },
    "tabCountries": {
        "en": "Countries", "ru": "Страны",
        "uz": "Mamlakatlar", "tr": "Ülkeler",
        "kk": "Елдер", "es": "Países",
        "pt": "Países", "fr": "Pays",
        "de": "Länder", "id": "Negara",
        "zh": "国家", "ja": "国", "ko": "국가",
        "hi": "देश", "ar": "الدول",
    },
    "tabCities": {
        "en": "Cities", "ru": "Города",
        "uz": "Shaharlar", "tr": "Şehirler",
        "kk": "Қалалар", "es": "Ciudades",
        "pt": "Cidades", "fr": "Villes",
        "de": "Städte", "id": "Kota",
        "zh": "城市", "ja": "都市", "ko": "도시",
        "hi": "शहर", "ar": "المدن",
    },
    "tabFlags": {
        "en": "Flags", "ru": "Флаги",
        "uz": "Bayroqlar", "tr": "Bayraklar",
        "kk": "Жалаулар", "es": "Banderas",
        "pt": "Bandeiras", "fr": "Drapeaux",
        "de": "Flaggen", "id": "Bendera",
        "zh": "国旗", "ja": "旗", "ko": "국기",
        "hi": "झंडे", "ar": "الأعلام",
    },
    "tabRewards": {
        "en": "Rewards", "ru": "Награды",
        "uz": "Mukofotlar", "tr": "Ödüller",
        "kk": "Марапаттар", "es": "Recompensas",
        "pt": "Recompensas", "fr": "Récompenses",
        "de": "Belohnungen", "id": "Hadiah",
        "zh": "奖励", "ja": "報酬", "ko": "보상",
        "hi": "पुरस्कार", "ar": "المكافآت",
    },
    "worldExpedition": {
        "en": "World Expedition", "ru": "Мировая экспедиция",
        "uz": "Dunyo sayohati", "tr": "Dünya Seferi",
        "kk": "Әлем экспедициясы", "es": "Expedición Mundial",
        "pt": "Expedição Mundial", "fr": "Expédition Mondiale",
        "de": "Welt-Expedition", "id": "Ekspedisi Dunia",
        "zh": "世界探险", "ja": "世界遠征", "ko": "세계 탐험",
        "hi": "विश्व अभियान", "ar": "رحلة العالم",
    },
}

def main():
    path = pathlib.Path("data/strings.json")
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)

    for key, trans in NEW.items():
        for lang, text in trans.items():
            if lang in data:
                data[lang][key] = text

    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")

    print(f"Qo'shildi: {len(NEW)} ta yangi kalit.")

if __name__ == "__main__":
    main()
