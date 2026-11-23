#!/usr/bin/env python3
"""Do'kon bo'limlari uchun izoh matnlarini qo'shadi.

Kalitlar 15 tilning hammasiga yoziladi; birortasi tushib qolsa
skript xato bilan to'xtaydi.
"""
import json
import pathlib

NEW = {
    "tabSkinsHint": {
        "en": "How your ball looks on the field. The colour stays yours.",
        "ru": "Как выглядит ваш шар на поле. Цвет остаётся вашим.",
        "uz": "Sharingiz maydonda qanday ko‘rinadi. Rang o‘zingizniki qoladi.",
        "tr": "Topunuzun sahadaki görünümü. Renk sizin kalır.",
        "kk": "Шарыңыз алаңда қалай көрінеді. Түс өзіңіздікі қалады.",
        "es": "Cómo se ve tu bola en el campo. El color sigue siendo tuyo.",
        "pt": "Como sua bola aparece no campo. A cor continua sendo sua.",
        "fr": "L’aspect de votre boule sur le terrain. La couleur reste la vôtre.",
        "de": "Wie deine Kugel im Feld aussieht. Die Farbe bleibt deine.",
        "id": "Tampilan bola Anda di arena. Warnanya tetap milik Anda.",
        "zh": "你的小球在场上的样子。颜色仍然是你的。",
        "ja": "フィールドでのボールの見た目。色はそのままです。",
        "ko": "필드에서 공이 보이는 모습. 색은 그대로입니다.",
        "hi": "मैदान में आपकी गेंद कैसी दिखती है। रंग आपका ही रहता है।",
        "ar": "شكل كرتك في الملعب. يبقى اللون لك.",
    },
    "tabTrailsHint": {
        "en": "The ribbon you leave behind while outside your land.",
        "ru": "Лента, которая тянется за вами вне вашей земли.",
        "uz": "Hududingizdan tashqarida orqangizda qoladigan lenta.",
        "tr": "Kendi toprağınızın dışındayken arkanızda kalan şerit.",
        "kk": "Өз жеріңізден тыс жерде артыңызда қалатын таспа.",
        "es": "La estela que dejas fuera de tu territorio.",
        "pt": "O rastro que você deixa fora do seu território.",
        "fr": "La traînée que vous laissez hors de votre territoire.",
        "de": "Die Spur, die du außerhalb deines Gebiets hinterlässt.",
        "id": "Jejak yang Anda tinggalkan di luar wilayah sendiri.",
        "zh": "离开自己领地时身后拖出的轨迹。",
        "ja": "自分の陣地の外で後ろに残る軌跡。",
        "ko": "자기 땅 밖에서 뒤에 남는 자취입니다.",
        "hi": "अपने इलाके के बाहर पीछे छूटने वाली लकीर।",
        "ar": "الأثر الذي تتركه خارج أرضك.",
    },
    "tabEffectsHint": {
        "en": "What bursts out when you close a loop and take land.",
        "ru": "Что вспыхивает, когда вы замыкаете петлю и забираете землю.",
        "uz": "Halqani yopib hudud egallaganingizda chiqadigan effekt.",
        "tr": "Halkayı kapatıp toprak aldığınızda ne patlar.",
        "kk": "Шеңберді жауып, жер алғанда не шашырайды.",
        "es": "Lo que estalla al cerrar el circuito y conquistar terreno.",
        "pt": "O que explode quando você fecha o laço e toma terreno.",
        "fr": "Ce qui jaillit quand vous bouclez la boucle et prenez du terrain.",
        "de": "Was aufblitzt, wenn du die Schleife schließt und Land nimmst.",
        "id": "Yang meletup saat Anda menutup lingkaran dan merebut wilayah.",
        "zh": "合围成功、占下土地时迸发的特效。",
        "ja": "輪を閉じて陣地を取ったときに弾ける演出。",
        "ko": "고리를 닫고 땅을 차지할 때 터지는 연출입니다.",
        "hi": "जब आप घेरा पूरा कर ज़मीन लेते हैं तब फूटने वाला असर।",
        "ar": "ما ينفجر عند إغلاق الحلقة والاستيلاء على الأرض.",
    },
    "tabSpecialHint": {
        "en": "Badges that money cannot buy — only your records open them.",
        "ru": "Знаки, которые не продаются: их открывают только рекорды.",
        "uz": "Pulga sotilmaydigan nishonlar — ularni faqat rekord ochadi.",
        "tr": "Parayla alınmayan rozetler — sadece rekorlar açar.",
        "kk": "Ақшаға сатылмайтын белгілер — оларды тек рекорд ашады.",
        "es": "Distintivos que no se compran: solo tus récords los abren.",
        "pt": "Emblemas que não se compram: só os seus recordes os abrem.",
        "fr": "Des insignes qui ne s’achètent pas : seuls vos records les ouvrent.",
        "de": "Abzeichen, die man nicht kaufen kann — nur Rekorde öffnen sie.",
        "id": "Lencana yang tak bisa dibeli — hanya rekor yang membukanya.",
        "zh": "买不到的徽章，只有纪录才能解锁。",
        "ja": "お金では買えない記章。記録だけが解放します。",
        "ko": "돈으로 살 수 없는 휘장. 기록만이 열어 줍니다.",
        "hi": "पैसे से न मिलने वाले निशान — इन्हें सिर्फ़ रिकॉर्ड खोलते हैं।",
        "ar": "شارات لا تُشترى — سجلاتك وحدها تفتحها.",
    },
    "cosmeticNote": {
        "en": "Looks only. Speed, size and capture power are the same for everyone.",
        "ru": "Только внешний вид. Скорость, размер и сила захвата у всех одинаковы.",
        "uz": "Faqat ko‘rinish. Tezlik, o‘lcham va egallash kuchi hammada bir xil.",
        "tr": "Yalnızca görünüm. Hız, boyut ve ele geçirme gücü herkeste aynı.",
        "kk": "Тек сыртқы түрі. Жылдамдық, өлшем және басып алу күші бәрінде бірдей.",
        "es": "Solo apariencia. Velocidad, tamaño y poder de captura son iguales para todos.",
        "pt": "Apenas aparência. Velocidade, tamanho e poder de captura são iguais para todos.",
        "fr": "Apparence seulement. Vitesse, taille et puissance de capture sont identiques pour tous.",
        "de": "Nur Optik. Tempo, Größe und Eroberungskraft sind für alle gleich.",
        "id": "Hanya tampilan. Kecepatan, ukuran, dan kekuatan merebut sama untuk semua.",
        "zh": "仅改变外观。速度、体积与占地能力对所有人相同。",
        "ja": "見た目だけです。速度・大きさ・占領力は全員同じ。",
        "ko": "겉모습만 바뀝니다. 속도와 크기, 점령력은 모두 같습니다.",
        "hi": "सिर्फ़ दिखावट। रफ़्तार, आकार और कब्ज़े की ताक़त सबके लिए समान है।",
        "ar": "المظهر فقط. السرعة والحجم وقوة الاستيلاء متساوية للجميع.",
    },
    "wornSet": {
        "en": "Your look",
        "ru": "Ваш облик",
        "uz": "Sizning ko‘rinishingiz",
        "tr": "Görünümünüz",
        "kk": "Сіздің келбетіңіз",
        "es": "Tu aspecto",
        "pt": "Seu visual",
        "fr": "Votre allure",
        "de": "Dein Look",
        "id": "Tampilan Anda",
        "zh": "你的外观",
        "ja": "あなたの見た目",
        "ko": "내 모습",
        "hi": "आपका रूप",
        "ar": "مظهرك",
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
