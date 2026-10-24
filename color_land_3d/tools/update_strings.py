import json
import os

path = "color_land_3d/data/strings.json"
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

new_keys = {
    "heroes": {
        "en": "Heroes", "ru": "Герои", "uz": "Qahramonlar", "tr": "Kahramanlar",
        "kk": "Батырлар", "es": "Héroes", "pt": "Heróis", "fr": "Héros",
        "de": "Helden", "id": "Pahlawan", "zh": "英雄", "ja": "ヒーロー",
        "ko": "영웅", "hi": "नायक", "ar": "الأبطال"
    },
    "flags": {
        "en": "Flags", "ru": "Флаги", "uz": "Bayroqlar", "tr": "Bayraklar",
        "kk": "Жалаулар", "es": "Banderas", "pt": "Bandeiras", "fr": "Drapeaux",
        "de": "Flaggen", "id": "Bendera", "zh": "国旗", "ja": "国旗",
        "ko": "국기", "hi": "झंडे", "ar": "الأعلام"
    },
    "minimap": {
        "en": "Minimap", "ru": "Миникарта", "uz": "Kichik xarita", "tr": "Mini harita",
        "kk": "Шағын карта", "es": "Minimapa", "pt": "Minimapa", "fr": "Mini-carte",
        "de": "Minikarte", "id": "Peta mini", "zh": "小地图", "ja": "ミニマップ",
        "ko": "미니맵", "hi": "मिनीमैप", "ar": "الخريطة المصغّرة"
    },
    "shopTitle": {
        "en": "HEROES, FLAGS, CITIES & REWARDS",
        "ru": "ГЕРОИ, ФЛАГИ, ГОРОДА И НАГРАДЫ",
        "uz": "QAHRAMONLAR, BAYROQLAR, SHAHARLAR VA MUKOFOTLAR",
        "tr": "KAHRAMANLAR, BAYRAKLAR, ŞEHİRLER VE ÖDÜLLER",
        "kk": "БАТЫРЛАР, ЖАЛАУЛАР, ҚАЛАЛАР ЖӘНЕ СЫЙЛЫҚТАР",
        "es": "HÉROES, BANDERAS, CIUDADES Y RECOMPENSAS",
        "pt": "HERÓIS, BANDEIRAS, CIDADES E RECOMPENSAS",
        "fr": "HÉROS, DRAPEAUX, VILLES ET RÉCOMPENSES",
        "de": "HELDEN, FLAGGEN, STÄDTE & BELOHNUNGEN",
        "id": "PAHLAWAN, BENDERA, KOTA & HADIAH",
        "zh": "英雄、国旗、城市与奖励",
        "ja": "ヒーロー、国旗、都市、報酬",
        "ko": "영웅, 국기, 도시 및 보상",
        "hi": "नायक, झंडे, शहर और पुरस्कार",
        "ar": "الأبطال والأعلام والمدن والمكافآت"
    },
    "collectAndEarn": {
        "en": "COLLECT & EARN",
        "ru": "СОБИРАЙ И ЗАРАБАТЫВАЙ",
        "uz": "TO'PLANG VA YUTING",
        "tr": "TOPLA VE KAZAN",
        "kk": "ЖИНА ЖӘНЕ ТАП",
        "es": "COLECCIONA Y GANA",
        "pt": "COLETE E GANHE",
        "fr": "COLLECTIONNEZ ET GAGNEZ",
        "de": "SAMMELN & VERDIENEN",
        "id": "KUMPULKAN & DAPATKAN",
        "zh": "收集与赚取",
        "ja": "集めて獲得",
        "ko": "수집하고 획득하세요",
        "hi": "इकट्ठा करें और कमाएं",
        "ar": "اجمع واكسب"
    },
    "pillarFlags": {
        "en": "Capture\nFlags", "ru": "Захват\nфлагов", "uz": "Bayroqlar\negallash",
        "tr": "Bayrakları\nFethet", "kk": "Жалауларды\nалу", "es": "Captura\nBanderas",
        "pt": "Capturar\nBandeiras", "fr": "Capturer\nDrapeaux", "de": "Flaggen\nerobern",
        "id": "Rebut\nBendera", "zh": "占领\n国旗", "ja": "国旗を\n獲得",
        "ko": "국기\n점령", "hi": "झंडे\nकब्जा करें", "ar": "الاستيلاء\nعلى الأعلام"
    },
    "pillarCities": {
        "en": "Conquer\nCities", "ru": "Завоевание\nгородов", "uz": "Shaharlar\nistilosi",
        "tr": "Şehirleri\nFethet", "kk": "Қалаларды\nбағындыру", "es": "Conquista\nCiudades",
        "pt": "Conquistar\nCidades", "fr": "Conquérir\nVilles", "de": "Städte\nerobern",
        "id": "Taklukkan\nKota", "zh": "征服\n城市", "ja": "都市を\n征服",
        "ko": "도시\n정복", "hi": "शहर\nजीतें", "ar": "غزو\nالمدن"
    },
    "pillarRewards": {
        "en": "Earn\nRewards", "ru": "Награды и\nмонеты", "uz": "Mukofot\nyutish",
        "tr": "Ödüller\nKazan", "kk": "Сыйлықтар\nалу", "es": "Gana\nPremios",
        "pt": "Ganhar\nPrêmios", "fr": "Gagner\nRécompenses", "de": "Belohnungen\nverdienen",
        "id": "Dapatkan\nHadiah", "zh": "赚取\n奖励", "ja": "報酬を\n獲得",
        "ko": "보상\n획득", "hi": "पुरस्कार\nपाएं", "ar": "كسب\nالمكافآت"
    },
    "pillarHeroes": {
        "en": "Unlock\nHeroes", "ru": "Открытие\nгероев", "uz": "Qahramonlar\nochish",
        "tr": "Kahramanları\nAç", "kk": "Батырларды\nашу", "es": "Desbloquear\nHéroes",
        "pt": "Desbloquear\nHeróis", "fr": "Débloquer\nHéros", "de": "Helden\nfreischalten",
        "id": "Buka\nPahlawan", "zh": "解锁\n英雄", "ja": "ヒーローを\n解放",
        "ko": "영웅\n해금", "hi": "नायक\nअनलॉक करें", "ar": "فتح\nالأبطال"
    },
    "heroBonusDesc": {
        "en": "⚡ Speed +5%  •  ✨ Trail Glow",
        "ru": "⚡ Скорость +5%  •  ✨ Свечение следа",
        "uz": "⚡ Tezlik +5%  •  ✨ Yorqin iz",
        "tr": "⚡ Hız +5%  •  ✨ İz Parlaması",
        "kk": "⚡ Жылдамдық +5%  •  ✨ Із жарқылы",
        "es": "⚡ Velocidad +5%  •  ✨ Rastro brillante",
        "pt": "⚡ Velocidade +5%  •  ✨ Brilho do rastro",
        "fr": "⚡ Vitesse +5%  •  ✨ Traînée lumineuse",
        "de": "⚡ Tempo +5%  •  ✨ Leuchtspur",
        "id": "⚡ Kecepatan +5%  •  ✨ Jejak Berkilau",
        "zh": "⚡ 速度 +5%  •  ✨ 拖尾发光",
        "ja": "⚡ スピード +5%  •  ✨ トレイル発光",
        "ko": "⚡ 속도 +5%  •  ✨ 트레일 발광",
        "hi": "⚡ गति +5%  •  ✨ चमकदार निशान",
        "ar": "⚡ سرعة +5%  •  ✨ توهج الأثر"
    },
    "activeFlag": {
        "en": "✓ ACTIVE FLAG", "ru": "✓ АКТИВНЫЙ ФЛАГ", "uz": "✓ FAOL BAYROQ",
        "tr": "✓ AKTİF BAYRAK", "kk": "✓ БЕЛСЕНДІ ЖАЛАУ", "es": "✓ BANDERA ACTIVA",
        "pt": "✓ BANDEIRA ATIVA", "fr": "✓ DRAPEAU ACTIF", "de": "✓ AKTIVE FLAGGE",
        "id": "✓ BENDERA AKTIF", "zh": "✓ 当前国旗", "ja": "✓ 使用中の国旗",
        "ko": "✓ 활성 국기", "hi": "✓ सक्रिय झंडा", "ar": "✓ العلم النشط"
    },
    "activeFlagDesc": {
        "en": "This flag waves on your base pole and covers your captured territory",
        "ru": "Этот флаг развевается на вашей базе и покрывает вашу захваченную территорию",
        "uz": "Ushbu bayroq bazangiz ustunida hilpiraydi va egallangan hududingizni qoplaydi",
        "tr": "Bu bayrak üssünüzde dalgalanır ve fethettiğiniz bölgeyi kaplar",
        "kk": "Бұл жалау сіздің базаңызда желбіреп, басып алынған аумағыңызды жабады",
        "es": "Esta bandera ondea en tu base y cubre tu territorio conquistado",
        "pt": "Esta bandeira tremula em sua base e cobre seu território conquistado",
        "fr": "Ce drapeau flotte sur votre base et couvre votre territoire conquis",
        "de": "Diese Flagge weht an deiner Basis und bedeckt dein erobertes Gebiet",
        "id": "Bendera ini berkibar di markas Anda dan menutupi wilayah yang Anda kuasai",
        "zh": "此国旗将在您的基地飘扬并覆盖您占领的领土",
        "ja": "この国旗は拠点に掲げられ、獲得した領土を覆います",
        "ko": "이 국기는 기지에 게양되며 점령한 영토를 덮습니다",
        "hi": "यह झंडा आपके बेस पर लहराता है और आपके कब्जे वाले क्षेत्र को ढकता है",
        "ar": "يرفرف هذا العلم في قاعدتك ويغطي أراضيك المستولى عليها"
    },
    "searchFlagsHint": {
        "en": "Search by country name or ISO code (249 countries)...",
        "ru": "Поиск по названию страны или ISO коду (249 стран)...",
        "uz": "Mamlakat nomi yoki ISO kodi bo'yicha qidirish (249 ta davlat)...",
        "tr": "Ülke adı veya ISO koduna göre ara (249 ülke)...",
        "kk": "Ел атауы немесе ISO коды бойынша іздеу (249 ел)...",
        "es": "Buscar por país o código ISO (249 países)...",
        "pt": "Pesquisar por país ou código ISO (249 países)...",
        "fr": "Rechercher par pays ou code ISO (249 pays)...",
        "de": "Nach Land oder ISO-Code suchen (249 Länder)...",
        "id": "Cari berdasarkan nama negara atau kode ISO (249 negara)...",
        "zh": "按国家/地区名称或ISO代码搜索（249个国家）...",
        "ja": "国名またはISOコードで検索（249か国）...",
        "ko": "국가 이름 또는 ISO 코드로 검색 (249개국)...",
        "hi": "देश के नाम या ISO कोड से खोजें (249 देश)...",
        "ar": "البحث باسم الدولة أو رمز ISO (249 دولة)..."
    },
    "filterAll": {
        "en": "All (249)", "ru": "Все (249)", "uz": "Barchasi (249)",
        "tr": "Hepsi (249)", "kk": "Барлығы (249)", "es": "Todos (249)",
        "pt": "Todos (249)", "fr": "Tous (249)", "de": "Alle (249)",
        "id": "Semua (249)", "zh": "全部 (249)", "ja": "すべて (249)",
        "ko": "전체 (249)", "hi": "सभी (249)", "ar": "الكل (249)"
    },
    "filterPopular": {
        "en": "Popular", "ru": "Популярные", "uz": "Ommabop",
        "tr": "Popüler", "kk": "Танымал", "es": "Populares",
        "pt": "Populares", "fr": "Populaires", "de": "Beliebt",
        "id": "Populer", "zh": "热门", "ja": "人気",
        "ko": "인기", "hi": "लोकप्रिय", "ar": "شائعة"
    },
    "continentAsia": {
        "en": "Asia", "ru": "Азия", "uz": "Osiyo",
        "tr": "Asya", "kk": "Азия", "es": "Asia",
        "pt": "Ásia", "fr": "Asie", "de": "Asien",
        "id": "Asia", "zh": "亚洲", "ja": "アジア",
        "ko": "아시아", "hi": "एशिया", "ar": "آسيا"
    },
    "continentEurope": {
        "en": "Europe", "ru": "Европа", "uz": "Yevropa",
        "tr": "Avrupa", "kk": "Еуропа", "es": "Europa",
        "pt": "Europa", "fr": "Europe", "de": "Europa",
        "id": "Eropa", "zh": "欧洲", "ja": "ヨーロッパ",
        "ko": "유럽", "hi": "यूरोप", "ar": "أوروبا"
    },
    "continentAmerica": {
        "en": "America", "ru": "Америка", "uz": "Amerika",
        "tr": "Amerika", "kk": "Америка", "es": "América",
        "pt": "América", "fr": "Amérique", "de": "Amerika",
        "id": "Amerika", "zh": "美洲", "ja": "アメリカ",
        "ko": "아메리카", "hi": "अमेरिका", "ar": "أمريكا"
    },
    "continentAfrica": {
        "en": "Africa", "ru": "Африка", "uz": "Afrika",
        "tr": "Afrika", "kk": "Африка", "es": "África",
        "pt": "África", "fr": "Afrique", "de": "Afrika",
        "id": "Afrika", "zh": "非洲", "ja": "アフリカ",
        "ko": "아프리카", "hi": "अफ्रीका", "ar": "أفريقيا"
    },
    "continentOceania": {
        "en": "Oceania", "ru": "Океания", "uz": "Okeaniya",
        "tr": "Okyanusya", "kk": "Океания", "es": "Oceanía",
        "pt": "Oceania", "fr": "Océanie", "de": "Ozeanien",
        "id": "Oseania", "zh": "大洋洲", "ja": "オセアニア",
        "ko": "오세아니아", "hi": "ओशिनिया", "ar": "أوقيانوسيا"
    },
    "countryJourney": {
        "en": "Country Journey", "ru": "Путешествие по странам", "uz": "Mamlakatlar sarguzashti",
        "tr": "Ülke Yolculuğu", "kk": "Елдер саяхаты", "es": "Viaje de países",
        "pt": "Jornada de países", "fr": "Voyage des pays", "de": "Länderreise",
        "id": "Perjalanan Negara", "zh": "国家之旅", "ja": "国の旅",
        "ko": "국가 여정", "hi": "देश यात्रा", "ar": "رحلة البلدان"
    },
    "countriesConqueredCount": {
        "en": "%d / %d conquered", "ru": "%d / %d захвачено", "uz": "%d / %d egallangan",
        "tr": "%d / %d fethedildi", "kk": "%d / %d бағындырылды", "es": "%d / %d conquistados",
        "pt": "%d / %d conquistados", "fr": "%d / %d conquis", "de": "%d / %d erobert",
        "id": "%d / %d ditaklukkan", "zh": "%d / %d 已占领", "ja": "%d / %d 征服済み",
        "ko": "%d / %d 정복됨", "hi": "%d / %d जीते", "ar": "%d / %d تم الاستيلاء عليها"
    },
    "currentTarget": {
        "en": "Current Target", "ru": "Текущая цель", "uz": "Hozirgi nishon",
        "tr": "Mevcut Hedef", "kk": "Қазіргі мақсат", "es": "Objetivo actual",
        "pt": "Alvo atual", "fr": "Cible actuelle", "de": "Aktuelles Ziel",
        "id": "Target Saat Ini", "zh": "当前目标", "ja": "現在のターゲット",
        "ko": "현재 목표", "hi": "वर्तमान लक्ष्य", "ar": "الهدف الحالي"
    },
    "captureProgress": {
        "en": "Capture: %d / %d pts (%.0f%%)", "ru": "Захват: %d / %d очков (%.0f%%)", "uz": "Egallash: %d / %d ochko (%.0f%%)",
        "tr": "Fetih: %d / %d puan (%.0f%%)", "kk": "Алу: %d / %d ұпай (%.0f%%)", "es": "Captura: %d / %d pts (%.0f%%)",
        "pt": "Captura: %d / %d pts (%.0f%%)", "fr": "Capture: %d / %d pts (%.0f%%)", "de": "Eroberung: %d / %d Pkt (%.0f%%)",
        "id": "Rebut: %d / %d poin (%.0f%%)", "zh": "占领：%d / %d 分 (%.0f%%)", "ja": "獲得: %d / %d pt (%.0f%%)",
        "ko": "점령: %d / %d 점 (%.0f%%)", "hi": "कब्जा: %d / %d अंक (%.0f%%)", "ar": "الاستيلاء: %d / %d نقطة (%.0f%%)"
    },
    "conqueredCheck": {
        "en": "Conquered ✓", "ru": "Захвачено ✓", "uz": "Egallandi ✓",
        "tr": "Fethedildi ✓", "kk": "Бағындырылды ✓", "es": "Conquistado ✓",
        "pt": "Conquistado ✓", "fr": "Conquis ✓", "de": "Erobert ✓",
        "id": "Ditaklukkan ✓", "zh": "已征服 ✓", "ja": "征服済み ✓",
        "ko": "정복됨 ✓", "hi": "जीत लिया ✓", "ar": "تم الاستيلاء ✓"
    },
    "citiesModeDesc": {
        "en": "Capture large capitals and megapolises to earn coins!",
        "ru": "Захватывайте столицы и мегаполисы, чтобы зарабатывать монеты!",
        "uz": "Katta poytaxt va megapolislarni egallab tanga yutib oling!",
        "tr": "Büyük başkentleri ve metropolleri fethederek jeton kazanın!",
        "kk": "Тиын табу үшін ірі астаналар мен мегаполистерді бағындырыңыз!",
        "es": "¡Conquista grandes capitales y metrópolis para ganar monedas!",
        "pt": "Conquiste grandes capitais e metrópoles para ganhar moedas!",
        "fr": "Conquérez de grandes capitales et mégapoles pour gagner des pièces !",
        "de": "Erobere große Hauptstädte und Metropolen, um Münzen zu verdienen!",
        "id": "Taklukkan ibu kota dan kota besar untuk mendapatkan koin!",
        "zh": "占领大首都和大都市以赚取金币！",
        "ja": "大首都やメガロポリスを征服してコインを獲得しよう！",
        "ko": "대도시와 수도를 정복하고 코인을 획득하세요!",
        "hi": "सिक्के कमाने के लिए बड़ी राजधानियों और महानगरों पर कब्जा करें!",
        "ar": "استولِ على العواصم الكبرى والمدن لكسب العملات المعدنية!"
    },
    "capitalsWorldTour": {
        "en": "Capitals World Tour", "ru": "Мировой тур по столицам", "uz": "Poytaxtlar jahon safari",
        "tr": "Başkentler Dünya Turu", "kk": "Астаналар әлемдік туры", "es": "Gira mundial de capitales",
        "pt": "Turnê mundial pelas capitais", "fr": "Tour du monde des capitales", "de": "Hauptstadt-Welttour",
        "id": "Tur Dunia Ibu Kota", "zh": "世界首都之旅", "ja": "世界の首都ツアー",
        "ko": "세계 수도 투어", "hi": "राजधानियों का विश्व दौरा", "ar": "جولة العواصم العالمية"
    },
    "asianMegapolises": {
        "en": "Asian Megapolises", "ru": "Азиатские мегаполисы", "uz": "Osiyo megapolislari",
        "tr": "Asya Metropolleri", "kk": "Азия мегаполистері", "es": "Megaciudades asiáticas",
        "pt": "Megapóles asiáticas", "fr": "Mégalopoles asiatiques", "de": "Asiatische Megastädte",
        "id": "Megapolis Asia", "zh": "亚洲大都市", "ja": "アジアのメガシティ",
        "ko": "아시아 거대도시", "hi": "एशियाई महानगर", "ar": "المدن الآسيوية الكبرى"
    },
    "europeanCapitals": {
        "en": "European Capitals", "ru": "Европейские столицы", "uz": "Yevropa poytaxtlari",
        "tr": "Avrupa Başkentleri", "kk": "Еуропа астаналары", "es": "Capitales europeas",
        "pt": "Capitais europeias", "fr": "Capitales européennes", "de": "Europäische Hauptstädte",
        "id": "Ibu Kota Eropa", "zh": "欧洲首都", "ja": "ヨーロッパの首都",
        "ko": "유럽 수도", "hi": "यूरोपीय राजधानियाँ", "ar": "عواصم أوروبا"
    },
    "pacificPorts": {
        "en": "Pacific Ocean Ports", "ru": "Порты Тихого океана", "uz": "Tinch okeani portlari",
        "tr": "Büyük Okyanus Limanları", "kk": "Тынық мұхит порттары", "es": "Puertos del Océano Pacífico",
        "pt": "Portos do Oceano Pacífico", "fr": "Ports de l'océan Pacifique", "de": "Pazifische Häfen",
        "id": "Pelabuhan Samudra Pasifik", "zh": "太平洋港口", "ja": "太平洋の港湾",
        "ko": "태평양 항구", "hi": "प्रशांत महासागरीय बंदरगाह", "ar": "موانئ المحيط الهادئ"
    }
}

for lang in data:
    for k, v in new_keys.items():
        if lang in v:
            data[lang][k] = v[lang]
        else:
            data[lang][k] = v["en"]

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f"Successfully updated strings.json with {len(new_keys)} keys across {len(data)} languages.")
