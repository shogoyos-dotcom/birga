# Color Land 3D — Release Notes v1.00.001

## Ma'lumotlar
- **Versiya**: 1.00.001
- **Android versionCode**: 1000001
- **Paket identifikatori**: com.shogoyos.colorland3d
- **Qurilma arxitekturasi**: Android ARM64 (IL2CPP)
- **Hajmi**: 50 756 319 bayt (48,40 MB)
- **SHA-256**: `4674680b92b45b5470fc52392de6a2870235156e20549f29466717cdec02ece3`
- **Dvigatel**: Unity 6 (6000.6.7f1)
- **Status**: READY_FOR_TEST

## Ushbu relizdagi yangiliklar va o'zgarishlar
1. **Doimiy versiyalash va Android APK yetkazib berish tizimi**:
   - `MAJOR.MINOR.PATCH` ("1.00.001") formati qat'iy joriy qilindi.
   - `Application.version`, `PlayerSettings.bundleVersion`, Android `bundleVersionCode` va o'yin ichidagi versiya displeyi to'liq sinxronlashtirildi.
2. **Sozlamalar va O'yin haqida modali (Settings -> About)**:
   - Asosiy menyuga yangi Sozlamalar tugmasi va oynasi qo'shildi.
   - O'yin ichida o'rnatilgan versiya (1.00.001), Unity 6, ARM64 va paket nomi ko'rinadi.
3. **Foydalanuvchi ma'lumotlarini asrash tizimi (SaveManager)**:
   - Sxema versiyalash (`SchemaVersion = 1`) va zaxiralash joriy etildi.
   - Tangalar, gemlar, ochilgan terilar, kunlik mukofotlar va til sozlamalari yangilanishlar va orqaga qaytishlar (rollback) vaqtida saqlanadi.
4. **Orqaga qaytish va Qayta tiklash tizimi (Rollback & Recovery)**:
   - Avvalgi versiyalarni bir buyruq bilan tiklash va Android OS blokirovkasisiz ustma-ust o'rnatish uchun Recovery Build rejimi ta'minlandi.
5. **Phase 8.4 tuzatishlari to'liq kiritilgan**:
   - 15 tilda qulay barmoq bilan siljitish (touch scroll) imkonini beruvchi Language Picker.
   - To'liq ruscha interfeys, xaritalar, do'kon, shaharlar va bildirishnomalar.
   - Hudud egallash va qirg'oqlar bo'ylab xatosiz siljish.
   - O'z xavfsiz hududiga qochib qutulish mexanizmiga ega xavf to'lqini (trail danger).

## Sinov ko'rsatmalari
1. Ushbu APK ni Android ARM64 qurilmaga o'rnating.
2. Asosiy menyudan **НАСТРОЙКИ** tugmasini bosing va versiya **1.00.001** deb ko'rsatilganini tekshiring.
3. O'yin o'ynang, shahar egallang, tildan tilga o'tib ko'ring.
