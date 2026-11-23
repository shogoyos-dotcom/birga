#!/usr/bin/env python3
"""5-bosqich matnlari: Qahramonlar, Profil statistikasi, Sozlamalar va Reklamasiz oynasi."""
import json
import pathlib

LANGS = ["en", "ru", "uz", "tr", "kk", "es", "pt", "fr", "de", "id",
         "zh", "ja", "ko", "hi", "ar"]

NEW = {
    # Navigatsiya
    "tabHeroes": {
        "en": "Heroes", "ru": "Герои", "uz": "Qahramonlar", "tr": "Kahramanlar",
        "kk": "Батырлар", "es": "Héroes", "pt": "Heróis", "fr": "Héros",
        "de": "Helden", "id": "Pahlawan", "zh": "英雄", "ja": "ヒーロー",
        "ko": "영웅", "hi": "नायक", "ar": "الأبطال"
    },
    "tabHome": {
        "en": "Home", "ru": "Главная", "uz": "Asosiy", "tr": "Ana Sayfa",
        "kk": "Басты", "es": "Inicio", "pt": "Início", "fr": "Accueil",
        "de": "Start", "id": "Beranda", "zh": "首页", "ja": "ホーム",
        "ko": "홈", "hi": "होम", "ar": "الرئيسية"
    },

    # Qahramon nomlari
    "heroCube": {
        "en": "Classic Cube", "ru": "Классический куб", "uz": "Klassik kub",
        "tr": "Klasik Küp", "kk": "Классикалық текше", "es": "Cubo clásico",
        "pt": "Cubo clássico", "fr": "Cube classique", "de": "Klassischer Würfel",
        "id": "Kubus klasik", "zh": "经典方块", "ja": "クラシックキューブ",
        "ko": "클래식 큐브", "hi": "क्लासिक क्यूब", "ar": "مكعب كلاسيكي"
    },
    "heroMelon": {
        "en": "Watermelon", "ru": "Арбуз", "uz": "Tarvuz", "tr": "Karpuz",
        "kk": "Қарбыз", "es": "Sandía", "pt": "Melancia", "fr": "Pastèque",
        "de": "Wassermelone", "id": "Semangka", "zh": "西瓜", "ja": "スイカ",
        "ko": "수박", "hi": "तरबूज", "ar": "بطيخ"
    },
    "heroPenguin": {
        "en": "Penguin", "ru": "Пингвин", "uz": "Pingvin", "tr": "Penguen",
        "kk": "Пингвин", "es": "Pingüino", "pt": "Pinguim", "fr": "Manchot",
        "de": "Pinguin", "id": "Penguin", "zh": "企鹅", "ja": "ペンギン",
        "ko": "펭귄", "hi": "पेंगुइन", "ar": "بطريق"
    },
    "heroGolem": {
        "en": "Magma Golem", "ru": "Лавовый голем", "uz": "Lava maxluqi",
        "tr": "Magma Devi", "kk": "Лава құбыжығы", "es": "Gólem de magma",
        "pt": "Golem de magma", "fr": "Golem de lave", "de": "Lava-Golem",
        "id": "Golem magma", "zh": "岩浆巨像", "ja": "マグマゴーレム",
        "ko": "마그마 골렘", "hi": "मैग्मा गोलेम", "ar": "غول الحمم"
    },
    "heroDeer": {
        "en": "Deer", "ru": "Олень", "uz": "Kiyik", "tr": "Geyik",
        "kk": "Бұғы", "es": "Ciervo", "pt": "Cervo", "fr": "Cerf",
        "de": "Hirsch", "id": "Rusa", "zh": "小鹿", "ja": "鹿",
        "ko": "사슴", "hi": "हिरण", "ar": "غزال"
    },
    "heroBear": {
        "en": "Polar Bear", "ru": "Белый медведь", "uz": "Oq ayiq",
        "tr": "Kutup Ayısı", "kk": "Ақ аю", "es": "Oso polar",
        "pt": "Urso polar", "fr": "Ours polaire", "de": "Eisbär",
        "id": "Beruang kutub", "zh": "北极熊", "ja": "ホッキョクグマ",
        "ko": "북극곰", "hi": "ध्रुवीय भालू", "ar": "دب قطبي"
    },
    "heroGingerbread": {
        "en": "Gingerbread", "ru": "Пряник", "uz": "Zanjabil odamcha",
        "tr": "Kurabiye Adam", "kk": "Зімбір адам", "es": "Galleta",
        "pt": "Biscoito", "fr": "Pain d'épices", "de": "Lebkuchen",
        "id": "Kue jahe", "zh": "姜饼人", "ja": "ジンジャーブレッド",
        "ko": "진저브레드", "hi": "जिंजरब्रेड", "ar": "خبز الزنجبيل"
    },
    "heroPirate": {
        "en": "Pirate Ship", "ru": "Пиратский корабль", "uz": "Qaroqchi kema",
        "tr": "Korsan Gemisi", "kk": "Қарақшы кемесі", "es": "Barco pirata",
        "pt": "Navio pirata", "fr": "Bateau pirate", "de": "Piratenschiff",
        "id": "Kapal bajak laut", "zh": "海盗船", "ja": "海賊船",
        "ko": "해적선", "hi": "समुद्री डाकू जहाज", "ar": "سفينة قراصنة"
    },
    "heroSeal": {
        "en": "Seal", "ru": "Тюлень", "uz": "Tyulen", "tr": "Fok",
        "kk": "Итбалық", "es": "Foca", "pt": "Foca", "fr": "Phoque",
        "de": "Seehund", "id": "Anjing laut", "zh": "海豹", "ja": "アザラシ",
        "ko": "물개", "hi": "सील", "ar": "فقمة"
    },
    "heroBalloon": {
        "en": "Air Balloon", "ru": "Воздушный шар", "uz": "Havo shari",
        "tr": "Uçan Balon", "kk": "Әуе шары", "es": "Globo aerostático",
        "pt": "Balão de ar", "fr": "Montgolfière", "de": "Heißluftballon",
        "id": "Balon udara", "zh": "热气球", "ja": "気球",
        "ko": "열기구", "hi": "हवाई गुब्बारा", "ar": "منطاد"
    },
    "heroDragon": {
        "en": "Dragon", "ru": "Дракон", "uz": "Ajdaho", "tr": "Ejderha",
        "kk": "Айдаһар", "es": "Dragón", "pt": "Dragão", "fr": "Dragon",
        "de": "Drache", "id": "Naga", "zh": "飞龙", "ja": "ドラゴン",
        "ko": "드래곤", "hi": "ड्रैगन", "ar": "تنين"
    },
    "heroChest": {
        "en": "Treasure Hunter", "ru": "Искатель сокровищ", "uz": "Xazina izlovchi",
        "tr": "Hazine Avcısı", "kk": "Қазына іздеуші", "es": "Cazatesoros",
        "pt": "Caçador de tesouros", "fr": "Chasseur de trésors", "de": "Schatzsucher",
        "id": "Pemburu harta", "zh": "宝藏猎人", "ja": "トレジャーハンター",
        "ko": "보물 사냥꾼", "hi": "खजाना शिकारी", "ar": "صياد الكنوز"
    },
    "heroSpeed": {
        "en": "Speed Runner", "ru": "Спринтер", "uz": "Tez yurar",
        "tr": "Sürat Koşucusu", "kk": "Жүйрік", "es": "Velocista",
        "pt": "Velocista", "fr": "Sprinter", "de": "Sprinter",
        "id": "Pelari cepat", "zh": "极速跑者", "ja": "スピードランナー",
        "ko": "스피드 러너", "hi": "तेज धावक", "ar": "العداء السريع"
    },
    "heroConqueror1": {
        "en": "Conqueror I", "ru": "Завоеватель I", "uz": "Fathchi I",
        "tr": "Fatih I", "kk": "Жаулаушы I", "es": "Conquistador I",
        "pt": "Conquistador I", "fr": "Conquérant I", "de": "Eroberer I",
        "id": "Penakluk I", "zh": "征服者 I", "ja": "征服者 I",
        "ko": "정복자 I", "hi": "विजेता I", "ar": "فاتح 1"
    },
    "heroConqueror3": {
        "en": "Conqueror II", "ru": "Завоеватель II", "uz": "Fathchi II",
        "tr": "Fatih II", "kk": "Жаулаушы II", "es": "Conquistador II",
        "pt": "Conquistador II", "fr": "Conquérant II", "de": "Eroberer II",
        "id": "Penakluk II", "zh": "征服者 II", "ja": "征服者 II",
        "ko": "정복자 II", "hi": "विजेता II", "ar": "فاتح 2"
    },
    "heroConqueror10": {
        "en": "Conqueror III", "ru": "Завоеватель III", "uz": "Fathchi III",
        "tr": "Fatih III", "kk": "Жаулаушы III", "es": "Conquistador III",
        "pt": "Conquistador III", "fr": "Conquérant III", "de": "Eroberer III",
        "id": "Penakluk III", "zh": "征服者 III", "ja": "征服者 III",
        "ko": "정복자 III", "hi": "विजेता III", "ar": "فاتح 3"
    },
    "heroBooster30": {
        "en": "Powered Up", "ru": "Энергичный", "uz": "Quvvat egasi",
        "tr": "Güç Dolu", "kk": "Қуатты", "es": "Energizado",
        "pt": "Energizado", "fr": "Suralimenté", "de": "Geladen",
        "id": "Bertenaga", "zh": "能量满载", "ja": "パワーアップ",
        "ko": "파워 업", "hi": "ऊर्जावान", "ar": "مشحون بالقدرة"
    },
    "heroBooster60": {
        "en": "Mega Power", "ru": "Мега сила", "uz": "Katta quvvat",
        "tr": "Mega Güç", "kk": "Зор қуат", "es": "Megapotencia",
        "pt": "Mega poder", "fr": "Méga puissance", "de": "Megakraft",
        "id": "Kekuatan mega", "zh": "超强力", "ja": "メガパワー",
        "ko": "메가 파워", "hi": "महा शक्ति", "ar": "قوة خارقة"
    },
    "heroPhoenix1": {
        "en": "Phoenix I", "ru": "Феникс I", "uz": "Qaqnus I",
        "tr": "Anka I", "kk": "Самұрық I", "es": "Fénix I",
        "pt": "Fênix I", "fr": "Phénix I", "de": "Phönix I",
        "id": "Feniks I", "zh": "不死鸟 I", "ja": "不死鳥 I",
        "ko": "불사조 I", "hi": "फीनिक्स I", "ar": "عنقاء 1"
    },
    "heroPhoenix5": {
        "en": "Phoenix II", "ru": "Феникс II", "uz": "Qaqnus II",
        "tr": "Anka II", "kk": "Самұрық II", "es": "Fénix II",
        "pt": "Fênix II", "fr": "Phénix II", "de": "Phönix II",
        "id": "Feniks II", "zh": "不死鸟 II", "ja": "不死鳥 II",
        "ko": "불사조 II", "hi": "फीनिक्स II", "ar": "عنقاء 2"
    },
    "heroPhoenix15": {
        "en": "Phoenix III", "ru": "Феникс III", "uz": "Qaqnus III",
        "tr": "Anka III", "kk": "Самұрық III", "es": "Fénix III",
        "pt": "Fênix III", "fr": "Phénix III", "de": "Phönix III",
        "id": "Feniks III", "zh": "不死鸟 III", "ja": "不死鳥 III",
        "ko": "불사조 III", "hi": "फीनिक्स III", "ar": "عنقاء 3"
    },

    # Topshiriq matnlari
    "taskFree": {
        "en": "Unlocked", "ru": "Открыто", "uz": "Ochiq", "tr": "Açık",
        "kk": "Ашық", "es": "Desbloqueado", "pt": "Desbloqueado",
        "fr": "Débloqué", "de": "Freigeschaltet", "id": "Terbuka",
        "zh": "已解锁", "ja": "解放済み", "ko": "해금됨", "hi": "खुला हुआ", "ar": "مفتوح"
    },
    "taskStreak": {
        "en": "Play %d days in a row", "ru": "Играйте %d дн. подряд", "uz": "%d kun ketma-ket o‘yna",
        "tr": "%d gün üst üste oyna", "kk": "%d күн қатарынан ойна", "es": "Juega %d días seguidos",
        "pt": "Jogue %d dias seguidos", "fr": "Jouez %d jours d'affilée", "de": "Spiele %d Tage in Folge",
        "id": "Main %d hari berurutan", "zh": "连续玩 %d 天", "ja": "%d日連続でプレイ",
        "ko": "%d일 연속 플레이", "hi": "लगातार %d दिन खेलें", "ar": "العب %d أيام متتالية"
    },
    "taskMatches": {
        "en": "Play %d games", "ru": "Сыграйте %d игр", "uz": "%d ta o‘yin o‘yna",
        "tr": "%d oyun oyna", "kk": "%d ойын ойна", "es": "Juega %d partidas",
        "pt": "Jogue %d partidas", "fr": "Faites %d parties", "de": "Spiele %d Spiele",
        "id": "Mainkan %d game", "zh": "玩 %d 局游戏", "ja": "%d回プレイ",
        "ko": "%d판 플레이", "hi": "%d खेल खेलें", "ar": "العب %d مباريات"
    },
    "taskKills": {
        "en": "Eliminate %d opponents", "ru": "Устраните %d противников", "uz": "%d ta raqibni yo‘qot",
        "tr": "%d rakip ele", "kk": "%d қарсыласты жой", "es": "Elimina %d oponentes",
        "pt": "Elimine %d oponentes", "fr": "Éliminez %d adversaires", "de": "Eliminiere %d Gegner",
        "id": "Kalahkan %d lawan", "zh": "消灭 %d 名对手", "ja": "%d人の相手を撃破",
        "ko": "%d명의 적 처치", "hi": "%d विरोधियों को हराएं", "ar": "اهزم %d خصوم"
    },
    "taskSpheres": {
        "en": "Use %d orbs", "ru": "Используйте %d сфер", "uz": "%d ta sfera ishlat",
        "tr": "%d küre kullan", "kk": "%d сфера қолдан", "es": "Usa %d orbes",
        "pt": "Use %d orbes", "fr": "Utilisez %d orbes", "de": "Nutze %d Sphären",
        "id": "Gunakan %d bola", "zh": "使用 %d 个能量球", "ja": "%d個のオーブを使用",
        "ko": "%d개의 구체 사용", "hi": "%d क्षेत्रों का उपयोग करें", "ar": "استخدم %d كرات"
    },
    "taskCountries": {
        "en": "Complete %d countries", "ru": "Завершите %d стран", "uz": "%d ta mamlakatni egalla",
        "tr": "%d ülkeyi tamamla", "kk": "%d елді аяқта", "es": "Completa %d países",
        "pt": "Conclua %d países", "fr": "Conquérez %d pays", "de": "Erobere %d Länder",
        "id": "Selesaikan %d negara", "zh": "征服 %d 个国家", "ja": "%dか国を制覇",
        "ko": "%d개국 정복", "hi": "%d देश पूरे करें", "ar": "أكمل %d بلدان"
    },
    "taskUpgrades": {
        "en": "Use %d power-ups", "ru": "Используйте %d усилений", "uz": "%d ta kuchaytirgich ishlat",
        "tr": "%d güçlendirme kullan", "kk": "%d күшейткіш қолдан", "es": "Usa %d mejoras",
        "pt": "Use %d melhorias", "fr": "Utilisez %d bonus", "de": "Nutze %d Boosts",
        "id": "Gunakan %d penguat", "zh": "使用 %d 次强化", "ja": "%d回強化を使用",
        "ko": "%d번 강화 사용", "hi": "%d पावर-अप का उपयोग करें", "ar": "استخدم %d تحسينات"
    },
    "taskRevives": {
        "en": "Revive %d times", "ru": "Возродитесь %d раз", "uz": "%d marta tiril",
        "tr": "%d kez canlan", "kk": "%d рет қайта тіріл", "es": "Revive %d veces",
        "pt": "Renasça %d vezes", "fr": "Revenez %d fois", "de": "Wiederbelee %d Mal",
        "id": "Bangkit %d kali", "zh": "复活 %d 次", "ja": "%d回復活",
        "ko": "%d회 부활", "hi": "%d बार पुनर्जीवित हों", "ar": "انتعش %d مرات"
    },

    # Profil va statistika
    "saveProgress": {
        "en": "Save your progress", "ru": "Сохраните свой прогресс", "uz": "Progressni saqlang",
        "tr": "İlerlemeni kaydet", "kk": "Прогрессіңізді сақтаңыз", "es": "Guarda tu progreso",
        "pt": "Salve seu progresso", "fr": "Sauvegardez vos progrès", "de": "Fortschritt speichern",
        "id": "Simpan progres Anda", "zh": "保存你的进度", "ja": "進行状況を保存",
        "ko": "진행 상황 저장", "hi": "अपनी प्रगति सहेजें", "ar": "احفظ تقدمك"
    },
    "googleLogin": {
        "en": "Sign in with Google", "ru": "Войти с помощью Google", "uz": "Google bilan kirish",
        "tr": "Google ile giriş yap", "kk": "Google арқылы кіру", "es": "Acceder con Google",
        "pt": "Entrar com o Google", "fr": "Se connecter avec Google", "de": "Über Google anmelden",
        "id": "Masuk dengan Google", "zh": "使用 Google 登录", "ja": "Googleでログイン",
        "ko": "Google 계정으로 로그인", "hi": "Google से साइन इन करें", "ar": "تسجيل الدخول باستخدام Google"
    },
    "googleLoginHint": {
        "en": "Sign in to save or restore your data", "ru": "Войдите, чтобы сохранить или восстановить данные",
        "uz": "Ma'lumotlarni saqlash yoki tiklash uchun kiring", "tr": "Verilerinizi kaydetmek veya geri yüklemek için giriş yapın",
        "kk": "Деректерді сақтау немесе қалпына келтіру үшін кіріңіз", "es": "Inicia sesión para guardar o restaurar tus datos",
        "pt": "Faça login para salvar ou restaurar seus dados", "fr": "Connectez-vous pour enregistrer vos données",
        "de": "Melde dich an, um Daten zu sichern", "id": "Masuk untuk menyimpan atau memulihkan data",
        "zh": "登录以保存或恢复你的游戏数据", "ja": "データを保存または復元するためにログイン",
        "ko": "데이터를 저장하거나 복원하려면 로그인하세요", "hi": "अपना डेटा सहेजने या पुनर्स्थापित करने के लिए साइन इन करें",
        "ar": "سجّل الدخول لحفظ بياناتك أو استعادتها"
    },
    "statistics": {
        "en": "Statistics", "ru": "Статистика", "uz": "Statistika", "tr": "İstatistikler",
        "kk": "Статистика", "es": "Estadísticas", "pt": "Estatísticas", "fr": "Statistiques",
        "de": "Statistiken", "id": "Statistik", "zh": "数据统计", "ja": "統計",
        "ko": "통계", "hi": "आंकड़े", "ar": "الإحصائيات"
    },
    "league": {
        "en": "League", "ru": "Лига", "uz": "Liga", "tr": "Lig",
        "kk": "Лига", "es": "Liga", "pt": "Liga", "fr": "Ligue",
        "de": "Liga", "id": "Liga", "zh": "联赛", "ja": "リーグ",
        "ko": "리그", "hi": "लीग", "ar": "الدوري"
    },
    "leagueBronze": {
        "en": "Bronze I", "ru": "Бронза I", "uz": "Bronza I", "tr": "Bronz I",
        "kk": "Қола I", "es": "Bronce I", "pt": "Bronze I", "fr": "Bronze I",
        "de": "Bronze I", "id": "Perunggu I", "zh": "青铜 I", "ja": "ブロンズ I",
        "ko": "브론즈 I", "hi": "कांस्य I", "ar": "برونزي 1"
    },
    "leagueSilver": {
        "en": "Silver I", "ru": "Серебро I", "uz": "Kumush I", "tr": "Gümüş I",
        "kk": "Күміс I", "es": "Plata I", "pt": "Prata I", "fr": "Argent I",
        "de": "Silber I", "id": "Perak I", "zh": "白银 I", "ja": "シルバー I",
        "ko": "실버 I", "hi": "रजत I", "ar": "فضي 1"
    },
    "leagueGold": {
        "en": "Gold I", "ru": "Золото I", "uz": "Oltin I", "tr": "Altın I",
        "kk": "Алтын I", "es": "Oro I", "pt": "Ouro I", "fr": "Or I",
        "de": "Gold I", "id": "Emas I", "zh": "黄金 I", "ja": "ゴールド I",
        "ko": "골드 I", "hi": "स्वर्ण I", "ar": "ذهبي 1"
    },
    "leagueDiamond": {
        "en": "Diamond I", "ru": "Алмаз I", "uz": "Olmos I", "tr": "Elmas I",
        "kk": "Гауһар I", "es": "Diamante I", "pt": "Diamante I", "fr": "Diamant I",
        "de": "Diamant I", "id": "Berlian I", "zh": "钻石 I", "ja": "ダイヤ I",
        "ko": "다이아몬드 I", "hi": "हीरा I", "ar": "ماسي 1"
    },
    "eliminations": {
        "en": "Eliminations", "ru": "Устранения", "uz": "Yo‘q qilishlar", "tr": "Elemeler",
        "kk": "Жоюлар", "es": "Eliminaciones", "pt": "Eliminações", "fr": "Éliminations",
        "de": "Eliminierungen", "id": "Eliminasi", "zh": "击杀数", "ja": "撃破数",
        "ko": "처치 수", "hi": "निष्कासन", "ar": "الإقصاءات"
    },
    "countries": {
        "en": "Countries", "ru": "Страны", "uz": "Mamlakatlar", "tr": "Ülkeler",
        "kk": "Елдер", "es": "Países", "pt": "Países", "fr": "Pays",
        "de": "Länder", "id": "Negara", "zh": "国家", "ja": "国",
        "ko": "국가", "hi": "देश", "ar": "البلدان"
    },
    "perfectWins": {
        "en": "100% Wins", "ru": "100% Победы", "uz": "100% G‘alabalar", "tr": "%100 Zaferler",
        "kk": "100% Жеңістер", "es": "Victorias 100%", "pt": "Vitórias 100%", "fr": "Victoires 100%",
        "de": "100%-Siege", "id": "Kemenangan 100%", "zh": "100% 完全胜利", "ja": "100%完全勝利",
        "ko": "100% 완승", "hi": "100% जीत", "ar": "انتصارات 100%"
    },

    # Sozlamalar va reklamasiz
    "restorePurchases": {
        "en": "Restore purchases", "ru": "Восстановить покупки", "uz": "Xaridlarni tiklash",
        "tr": "Satın alımları geri yükle", "kk": "Сатып алуларды қалпына келтіру",
        "es": "Restaurar compras", "pt": "Restaurar compras", "fr": "Restaurer les achats",
        "de": "Einkäufe wiederherstellen", "id": "Pulihkan pembelian", "zh": "恢复购买",
        "ja": "購入を復元", "ko": "구매 복원", "hi": "खरीदारी पुनर्स्थापित करें", "ar": "استعادة المشتريات"
    },
    "yourData": {
        "en": "Your data", "ru": "Ваши данные", "uz": "Ma'lumotlaringiz", "tr": "Verileriniz",
        "kk": "Сіздің деректеріңіз", "es": "Tus datos", "pt": "Seus dados", "fr": "Vos données",
        "de": "Deine Daten", "id": "Data Anda", "zh": "你的数据", "ja": "あなたのデータ",
        "ko": "내 데이터", "hi": "आपका डेटा", "ar": "بياناتك"
    },
    "helpSupport": {
        "en": "Help & support", "ru": "Помощь и поддержка", "uz": "Yordam va qo‘llab-quvvatlash",
        "tr": "Yardım ve destek", "kk": "Көмек және қолдау", "es": "Ayuda y soporte",
        "pt": "Ajuda e suporte", "fr": "Aide et support", "de": "Hilfe & Support",
        "id": "Bantuan & dukungan", "zh": "帮助与支持", "ja": "ヘルプとサポート",
        "ko": "도움말 및 지원", "hi": "मदद और समर्थन", "ar": "المساعدة والدعم"
    },
    "promoCode": {
        "en": "Redeem code", "ru": "Активировать код", "uz": "Promokodni faollashtirish",
        "tr": "Kodu kullan", "kk": "Промокодты іске қосу", "es": "Canjear código",
        "pt": "Resgatar código", "fr": "Activer le code", "de": "Code einlösen",
        "id": "Tukarkan kode", "zh": "兑换码", "ja": "コードを引き換える",
        "ko": "코드 등록", "hi": "कोड भुनाएं", "ar": "استرداد الرمز"
    },
    "removeAdsQuestion": {
        "en": "Remove ads?", "ru": "Удалить рекламу?", "uz": "Reklamani o‘chirish?",
        "tr": "Reklamları kaldır?", "kk": "Жарнаманы өшіру керек пе?", "es": "¿Eliminar anuncios?",
        "pt": "Remover anúncios?", "fr": "Supprimer les pubs ?", "de": "Werbung entfernen?",
        "id": "Hapus iklan?", "zh": "去广告？", "ja": "広告を削除しますか？",
        "ko": "광고를 제거하시겠습니까?", "hi": "विज्ञापन हटाएं?", "ar": "إزالة الإعلانات؟"
    },
    "removeAdsBullet1": {
        "en": "Remove forced ads during and after games", "ru": "Убрать обязательную рекламу во время и после игр",
        "uz": "O‘yin payti va undan keyingi majburiy reklamalarni o‘chirish", "tr": "Oyun sırasındaki ve sonrasındaki zorunlu reklamları kaldır",
        "kk": "Ойын кезіндегі және одан кейінгі міндетті жарнаманы өшіру", "es": "Elimina los anuncios obligatorios durante y tras las partidas",
        "pt": "Remova anúncios obrigatórios durante e após as partidas", "fr": "Supprime les publicités forcées pendant et après les parties",
        "de": "Entfernt Zwangswerbung während und nach den Spielen", "id": "Hapus iklan wajib selama dan setelah game",
        "zh": "去除游戏过程和结束后出现的强制性广告", "ja": "ゲーム中およびゲーム後の強制広告を非表示にする",
        "ko": "게임 도중 및 종료 후 필수 광고 제거", "hi": "खेल के दौरान और बाद में अनिवार्य विज्ञापन हटाएं",
        "ar": "إزالة الإعلانات الإلزامية أثناء وبعد المباريات"
    },
    "removeAdsBullet2": {
        "en": "You can still watch optional rewarded videos", "ru": "Вы все еще сможете смотреть видео за награды",
        "uz": "Mukofotli videolarni ko‘rish imkoni saqlanib qoladi", "tr": "Ödüllü videoları izleme imkanı devam eder",
        "kk": "Сыйақылы бейнелерді көру мүмкіндігі сақталады", "es": "Aún podrás ver vídeos de recompensa opcionales",
        "pt": "Você ainda poderá assistir a vídeos com recompensa", "fr": "Vous pouvez toujours regarder des vidéos avec récompense",
        "de": "Du kannst weiterhin freiwillig Videos für Belohnungen ansehen", "id": "Anda masih bisa menonton video berhadiah opsional",
        "zh": "依然可以通过观看激励视频获得额外奖励", "ja": "報酬付きの動画は引き続き任意で視聴可能",
        "ko": "보상형 비디오는 계속 선택적으로 시청 가능합니다", "hi": "आप अभी भी पुरस्कारों के लिए वैकल्पिक वीडियो देख सकते हैं",
        "ar": "لا يزال بإمكانك مشاهدة مقاطع الفيديو بمكافآت اختيارية"
    },
    "oneDay": {
        "en": "1 Day", "ru": "1 день", "uz": "1 kun", "tr": "1 Gün",
        "kk": "1 күн", "es": "1 día", "pt": "1 dia", "fr": "1 jour",
        "de": "1 Tag", "id": "1 hari", "zh": "1 天", "ja": "1日",
        "ko": "1일", "hi": "1 दिन", "ar": "يوم واحد"
    },
    "forever": {
        "en": "Forever", "ru": "Навсегда", "uz": "Umrbod", "tr": "Sonsuza Dek",
        "kk": "Мәңгі", "es": "Para siempre", "pt": "Para sempre", "fr": "Pour toujours",
        "de": "Für immer", "id": "Selamanya", "zh": "永久", "ja": "永久",
        "ko": "영구", "hi": "हमेशा के लिए", "ar": "للأبد"
    },
    "stateOn": {
        "en": "ON", "ru": "ВКЛ", "uz": "YOQ", "tr": "AÇIK",
        "kk": "ҚОСУ", "es": "SÍ", "pt": "LIG", "fr": "OUI",
        "de": "AN", "id": "AKTIF", "zh": "开", "ja": "ON",
        "ko": "켜짐", "hi": "चालू", "ar": "تشغيل"
    },
    "stateOff": {
        "en": "OFF", "ru": "ВЫКЛ", "uz": "O‘CH", "tr": "KAPALI",
        "kk": "ӨШІРУ", "es": "NO", "pt": "DESL", "fr": "NON",
        "de": "AUS", "id": "MATI", "zh": "关", "ja": "OFF",
        "ko": "꺼짐", "hi": "बंद", "ar": "إيقاف"
    },
    "sideLeft": {
        "en": "LEFT", "ru": "ЛЕВО", "uz": "CHAP", "tr": "SOL",
        "kk": "СОЛ", "es": "IZQ", "pt": "ESQ", "fr": "GAUCHE",
        "de": "LINKS", "id": "KIRI", "zh": "左", "ja": "左",
        "ko": "왼쪽", "hi": "बायां", "ar": "يسار"
    },
    "sideRight": {
        "en": "RIGHT", "ru": "ПРАВО", "uz": "O‘NG", "tr": "SAĞ",
        "kk": "ОҢ", "es": "DER", "pt": "DIR", "fr": "DROITE",
        "de": "RECHTS", "id": "KANAN", "zh": "右", "ja": "右",
        "ko": "오른쪽", "hi": "दायां", "ar": "يمين"
    },
}

def main():
    root = pathlib.Path(__file__).resolve().parent.parent
    path = root / "data" / "strings.json"
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)

    count = 0
    for key, trans in NEW.items():
        for lang in LANGS:
            if lang in data:
                val = trans.get(lang, trans.get("en", key))
                data[lang][key] = val
                count += 1

    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"Added {len(NEW)} keys ({count} translations) to {path}")

if __name__ == "__main__":
    main()
