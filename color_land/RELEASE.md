# Color Land — Google Play'ga chiqarish

Bu hujjat `.aab` fayl yasash va Google Play Console'ga yuklash tartibini
bosqichma-bosqich tushuntiradi.

## 0. Nima allaqachon tayyor

| Narsa | Holati |
|---|---|
| Package name (`applicationId`) | `com.mening.colorland` |
| Ilova nomi | `Color Land` |
| Orientatsiya | faqat portret (manifestda qulflangan) |
| Ikonka | klassik + adaptiv + monoxrom (Android 13 mavzuli ikonka) |
| Ishga tushish ekrani | brend rangi + belgi, har bir zichlik uchun |
| `minSdk` / `targetSdk` | 24 / 36 (Flutter 3.47 standarti, Play talabiga mos) |
| Versiya | `pubspec.yaml` dagi `version:` dan olinadi |
| Release imzolash | `android/key.properties` bo'lsa avtomatik ishlatiladi |

> **Diqqat:** `applicationId` ni Play'ga birinchi yuklashdan keyin
> **o'zgartirib bo'lmaydi**. `com.mening.colorland` sizga mos bo'lmasa,
> hozir o'zgartiring: `android/app/build.gradle.kts` dagi `namespace` va
> `applicationId`, hamda `android/app/src/main/kotlin/.../MainActivity.kt`
> dagi `package` qatori.

## 1. Kerakli dasturlar

### Windows'da noldan sozlash

Jami ~12 GB joy va 30–60 daqiqa vaqt ketadi. Har bosqichdan keyin
tekshiruv buyrug'i berilgan — biror joyda to'xtasa, o'sha yerni hal
qilib keyingisiga o'ting.

**1-qadam. Git va Android Studio.** PowerShell'da:

```powershell
winget install --id Git.Git -e
winget install --id Google.AndroidStudio -e
```

**2-qadam. Android Studio'ni bir marta oching.** U ishga tushganda sozlash
ustasi (Setup Wizard) Android SDK ni yuklaydi — oxirigacha kuting.

So'ng SDK ning buyruq qatori vositalarini yoqing (busiz litsenziyalarni
qabul qilib bo'lmaydi):

> **Settings** → **Languages & Frameworks** → **Android SDK** →
> **SDK Tools** yorlig'i → **Android SDK Command-line Tools (latest)**
> katagiga belgi qo'ying → **Apply**.

**3-qadam. Flutter.** Yangi PowerShell oynasida:

```powershell
$zip = "$env:TEMP\flutter.zip"
curl.exe -L -o $zip "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.47.6-stable.zip"
New-Item -ItemType Directory -Force -Path C:\src | Out-Null
tar.exe -xf $zip -C C:\src
Remove-Item $zip

$old = [Environment]::GetEnvironmentVariable("Path", "User")
if ($old -notlike "*C:\src\flutter\bin*") {
  [Environment]::SetEnvironmentVariable("Path", "$old;C:\src\flutter\bin", "User")
}
```

`C:\src\flutter` ga ochish muhim: `C:\Program Files` ichiga qo'ysangiz
Flutter ruxsat xatolari beradi.

**4-qadam. PowerShell'ni yopib qaytadan oching** (PATH yangilanishi uchun):

```powershell
flutter --version
flutter doctor
```

**5-qadam. Android litsenziyalarini qabul qiling:**

```powershell
flutter doctor --android-licenses
```

Har bir savolga `y` deb javob bering. So'ng `flutter doctor` da
`[✓] Android toolchain` chiqishi kerak.

`cmdline-tools component is missing` degan xato chiqsa — 2-qadamdagi
"Android SDK Command-line Tools" katagi belgilanmagan.

**6-qadam. Loyihani oling:**

```powershell
cd $env:USERPROFILE
git clone https://github.com/shogoyos-dotcom/birga.git
cd birga
git checkout claude/dazzling-turing-2248jt
cd color_land
flutter pub get
flutter test
```

Testlar o'tsa — hammasi tayyor, 2-bo'limdan davom eting.

### Boshqa tizimlar

- Flutter SDK (barqaror kanal, 3.47.6 yoki undan yangi)
- Android SDK (Android Studio bilan yoki `cmdline-tools` orqali)
- JDK 17 yoki 21

Tekshirish:

```bash
flutter doctor
```

`Android toolchain` qatori yashil bo'lishi kerak. Litsenziyalar so'ralsa:

```bash
flutter doctor --android-licenses
```

## 2. Imzolash kalitini (keystore) yaratish

Kalit — ilovangizning "pasporti". **Uni yo'qotsangiz, ilovaga boshqa hech
qachon yangilanish chiqara olmaysiz.** Shuning uchun:

- kalit faylini va parollarni ishonchli joyda (parol menejeri, zahira disk)
  saqlang;
- git ga **hech qachon** qo'shmang (`android/.gitignore` buni bloklaydi).

Kalit `keytool` bilan yaratiladi — u JDK tarkibida keladi. Android Studio
o'rnatilgan bo'lsa, JDK allaqachon bor.

**Windows (PowerShell).** Avval `keytool` ni toping:

```powershell
# Android Studio bilan kelgan JDK (eng ko'p uchraydigan joy):
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -help
```

Ishlasa, kalitni shu bilan yarating:

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" `
  -genkey -v `
  -keystore "$env:USERPROFILE\color-land-upload.jks" `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -alias upload
```

`keytool` topilmasa, alohida JDK o'rnating (Temurin yoki Microsoft Build of
OpenJDK) va `keytool` ni uning `bin` papkasidan ishga tushiring.

**macOS / Linux:**

```bash
keytool -genkey -v \
  -keystore ~/color-land-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Buyruq ketma-ket so'raydi:

1. **keystore paroli** — o'ylab toping va yozib qo'ying (ekranda ko'rinmaydi);
2. o'sha parolni takrorlash;
3. ism-familiya, bo'lim, tashkilot, shahar, viloyat, davlat kodi (`UZ`) —
   bular sertifikat ichida qoladi, lekin Play'da foydalanuvchiga
   ko'rsatilmaydi, shuning uchun istalgan haqiqiy ma'lumot bo'laveradi;
4. tasdiq: `yes` deb yozing;
5. **kalit paroli** — Enter bosib keystore paroli bilan bir xil qilsangiz
   bo'ladi (shunda `key.properties` da ikkalasi bir xil yoziladi).

`-validity 10000` — ~27 yil. Play 2033-yildan keyin tugaydigan kalitni qabul
qilmaydi, shuning uchun uzoq muddat qo'ying.

Natijada `color-land-upload.jks` fayli paydo bo'ladi. **Shu faylni va
parolni yo'qotmang** — zahira nusxasini parol menejeriga yoki ishonchli
bulutga qo'ying.

## 3. `key.properties` faylini yaratish

`android/key.properties` fayli (git ga tushmaydi):

```properties
storePassword=YUQORIDA_KIRITGAN_KEYSTORE_PAROLI
keyPassword=YUQORIDA_KIRITGAN_KALIT_PAROLI
keyAlias=upload
storeFile=C:/Users/Shogiyos/color-land-upload.jks
```

`storeFile` — faylgacha **to'liq yo'l**. Windows'da ham **oldinga qiya
chiziq** (`/`) ishlating: `.properties` faylida teskari chiziq maxsus
belgi hisoblanadi va `C:\Users\...` noto'g'ri o'qiladi. (Teskari chiziqni
ishlatmoqchi bo'lsangiz, har birini ikkitalab yozing: `C:\\Users\\...`.)

Bu fayl bo'lmasa loyiha baribir quriladi — faqat debug kalit bilan
imzolanadi, ya'ni Play uchun yaramaydi. Buyruq oxirida buni tekshirasiz
(5-bosqichga qarang).

## 4. Versiyani qo'yish

`pubspec.yaml`:

```yaml
version: 1.0.0+1
```

- `1.0.0` — foydalanuvchi ko'radigan versiya (`versionName`);
- `+1` — `versionCode`. **Play'ga har safar yuklaganda bu raqam oldingisidan
  katta bo'lishi shart.** Ikkinchi yuklashda `1.0.1+2`, keyin `1.0.2+3` va h.k.

## 5. `.aab` yasash

```bash
cd color_land
flutter clean
flutter pub get
flutter build appbundle --release
```

Natija:

```
build/app/outputs/bundle/release/app-release.aab   (~49 MB)
```

Hajmdan cho'chimang: `.aab` ichida uchta protsessor arxitekturasi
(arm64-v8a, armeabi-v7a, x86_64) birga turadi. Google Play har bir
telefonga faqat o'ziga keragini yuboradi — haqiqiy yuklab olish hajmi
ancha kichik (arm64 telefon uchun ~20 MB atrofida).

Imzo to'g'ri qo'yilganini tekshirish:

```bash
unzip -p build/app/outputs/bundle/release/app-release.aab \
  META-INF/*.RSA | keytool -printcert
```

Chiqqan `Owner:` qatori siz 2-bosqichda kiritgan ma'lumotlarga mos kelsa —
hammasi joyida. Agar `CN=Android Debug` chiqsa, `key.properties` topilmagan:
fayl nomi va yo'lini tekshiring.

Telefonda sinash uchun (`.aab` ni to'g'ridan-to'g'ri o'rnatib bo'lmaydi):

```bash
flutter build apk --release          # build/app/outputs/flutter-apk/app-release.apk
flutter install --release            # ulangan qurilmaga o'rnatadi
```

APK ni fayl sifatida telefonga tashlab ham o'rnatsa bo'ladi — bunda
telefon sozlamalarida "noma'lum manbalardan o'rnatish" ruxsatini berish
kerak bo'ladi.

### Qurilgan ilovani tekshirish

`.aab` yoki APK ichidagi narsani ko'rish uchun (Android SDK ning
`build-tools` papkasidan):

```bash
aapt2 dump badging build/app/outputs/flutter-apk/app-release.apk | head
```

Kutilayotgan natija:

```
package: name='com.mening.colorland' versionCode='1' versionName='1.0.0'
targetSdkVersion:'36'
application-label:'Color Land'
```

APK ning imzosini `apksigner` osonroq ko'rsatadi:

```bash
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```

## 6. Play Console'ga yuklash

1. [Play Console](https://play.google.com/console) da dasturchi akkaunti
   oching (bir martalik $25).
2. **Create app** → nom `Color Land`, til, "Game", "Free".
3. **Release → Production → Create new release** → `.aab` faylni yuklang.
4. **Play App Signing** ni yoqing (standart bo'yicha yoqilgan). Sizning
   kalitingiz "upload key" bo'lib qoladi, Google o'z kaliti bilan qayta
   imzolaydi — kalitni yo'qotsangiz tiklash imkoni bo'ladi.

### Kerakli materiallar

`flutter test tool/icon_test.dart` buyrug'i quyidagilarni tayyorlaydi:

| Fayl | Nima uchun |
|---|---|
| `build/play/icon_512.png` | do'kon ikonkasi (512×512 PNG) |
| `build/play/feature_1024x500.png` | "Feature graphic" (1024×500) |

Skrinshotlar (kamida 2 ta, telefon uchun):

```bash
flutter test tool/screenshot_test.dart
# build/shot_menu.png, build/shot_game.png, build/shot_result.png
```

Yoki haqiqiy qurilmadan oling — Play uchun shunisi yaxshiroq.

### To'ldiriladigan anketalar

- **Data safety** — ilova hech qanday ma'lumot yig'maydi va yubormaydi.
  Yagona saqlanadigan narsa — rekord, rang va til, ular `shared_preferences`
  orqali **faqat telefonning o'zida** turadi. "No data collected" deb
  belgilang.
- **Content rating** — anketani to'ldiring; o'yinda zo'ravonlik, reklama va
  xaridlar yo'q, odatda "Everyone / 3+" chiqadi.
- **Target audience** — bolalar uchun mo'ljallangan bo'lsa, qo'shimcha
  qoidalar (Families policy) qo'llanadi.
- **Privacy policy** — hech narsa yig'ilmasa ham Play havola so'raydi.
  Oddiy bir sahifali matn yetadi (GitHub Pages yoki shunga o'xshash joyda).

## 7. Keyingi yangilanishlar

```bash
# pubspec.yaml dagi version ni oshiring, masalan 1.0.1+2
flutter build appbundle --release
```

va Play Console'da yangi release yarating.

## Tez-tez uchraydigan xatolar

| Xato | Sababi va yechimi |
|---|---|
| `Keystore file not found` | `key.properties` dagi `storeFile` yo'li noto'g'ri. To'liq yo'l yozing. |
| `Version code 1 has already been used` | `pubspec.yaml` dagi `+N` ni oshiring. |
| `You uploaded an APK or Android App Bundle which is not signed` | `key.properties` topilmagan — `android/` papkasi ichida ekaniga ishonch hosil qiling. |
| `SDK location not found` | `ANDROID_HOME` o'rnatilmagan yoki `android/local.properties` da `sdk.dir` yo'q. |
| `Cannot run with sound null safety` | `flutter clean` qilib qayta quring. |
