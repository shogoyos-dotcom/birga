/// Tuvalga to'g'ridan-to'g'ri chiziladigan matnlar uchun zaxira shriftlar.
///
/// `ui.Paragraph` Flutter mavzusidagi shriftni bilmaydi: qurilmada tizim
/// shrifti ishlatiladi, widget testlarida esa tizim shriftlari umuman
/// yo'q va matn kvadratchalar bo'lib chiqadi. Skrinshot vositasi shu
/// yerga o'zi yuklagan shrift nomini yozadi.
///
/// Qurilmada `null` — o'zgarish yo'q.
List<String>? canvasFontFallback;

/// Tuvaldagi matnlarning asosiy shrifti.
///
/// Qurilmada `null` — tizim shrifti olinadi. Testlarda esa standart
/// shrift (Ahem) har bir belgini to'la kvadrat qilib chizadi, shuning
/// uchun zaxira ro'yxati ishlamaydi: asosiy shriftni aniq ko'rsatish
/// kerak.
String? canvasFontFamily;
