#!/bin/bash
# Color Land — Claude Code cloud muhiti uchun setup skripti.
#
# Buni muhit sozlamalaridagi "Setup script" maydoniga nusxalang
# (environment selector -> Cloud -> muhit ustida ⚙ -> Setup script).
#
# Nima qiladi: Flutter SDK va Android SDK ni o'rnatadi — ularning ikkalasi
# ham cloud sessiyalarda oldindan mavjud emas. Java (OpenJDK 21), Gradle va
# git allaqachon o'rnatilgan, shuning uchun ularga tegilmaydi.
#
# TARMOQ TALABI: muhitning Network access darajasi `dl.google.com` ga ruxsat
# berishi kerak (Full, yoki Custom + dl.google.com va maven.google.com).
# Trusted darajasida Android SDK yuklanmaydi va skript buni aytib o'tadi.
#
# Qoidalar (hujjatdan): skript root ostida ishlaydi, 0 bilan tugashi shart
# (aks holda sessiya ishga tushmaydi) va ~5 daqiqaga sig'sa muhit keshlanadi
# — keyingi sessiyalar tayyor diskdan boshlanadi.

set -u

FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.6}"
FLUTTER_HOME="${FLUTTER_HOME:-/opt/flutter}"
ANDROID_HOME="${ANDROID_HOME:-/opt/android-sdk}"
PROFILE_FILE="${PROFILE_FILE:-/etc/profile.d/99-flutter-android.sh}"

# Android SDK paketlari — Flutter 3.47 ning standart darajalariga mos.
# NDK ataylab yo'q: sof Dart/Flutter ilovasiga kerak emas va ~1 GB joy oladi.
ANDROID_PACKAGES=(
  "platform-tools"
  "platforms;android-36"
  "build-tools;36.0.0"
)

CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

log() { echo "[setup] $*"; }

install_flutter() {
  if [ -x "$FLUTTER_HOME/bin/flutter" ]; then
    log "Flutter allaqachon bor: $FLUTTER_HOME"
    return 0
  fi
  log "Flutter $FLUTTER_VERSION yuklanmoqda..."
  mkdir -p "$(dirname "$FLUTTER_HOME")"
  local tmp
  tmp="$(mktemp -d)"
  if ! curl -fsSL -o "$tmp/flutter.tar.xz" "$FLUTTER_URL"; then
    log "XATO: Flutter yuklanmadi ($FLUTTER_URL)"
    rm -rf "$tmp"
    return 1
  fi
  # -J : xz; ko'p yadroli ochish uchun xz mavjud bo'lsa undan foydalanamiz.
  if command -v xz >/dev/null 2>&1; then
    xz -T0 -dc "$tmp/flutter.tar.xz" | tar -x -C "$(dirname "$FLUTTER_HOME")"
  else
    tar -xf "$tmp/flutter.tar.xz" -C "$(dirname "$FLUTTER_HOME")"
  fi
  rm -rf "$tmp"
  # Arxiv ichidagi papka nomi "flutter"; boshqa joyga o'rnatilsa ko'chiramiz.
  if [ "$FLUTTER_HOME" != "$(dirname "$FLUTTER_HOME")/flutter" ]; then
    mv "$(dirname "$FLUTTER_HOME")/flutter" "$FLUTTER_HOME"
  fi
  log "Flutter o'rnatildi."
}

install_android() {
  if [ -x "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
    log "Android cmdline-tools allaqachon bor."
  else
    log "Android cmdline-tools yuklanmoqda..."
    mkdir -p "$ANDROID_HOME/cmdline-tools"
    local tmp
    tmp="$(mktemp -d)"
    if ! curl -fsSL -o "$tmp/cmdline.zip" "$CMDLINE_TOOLS_URL"; then
      log "XATO: cmdline-tools yuklanmadi."
      log "      Muhitning Network access sozlamasi dl.google.com ga ruxsat"
      log "      berishi kerak (Full yoki Custom + dl.google.com)."
      rm -rf "$tmp"
      return 1
    fi
    unzip -q "$tmp/cmdline.zip" -d "$tmp/x"
    mv "$tmp/x/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
    rm -rf "$tmp"
  fi

  export ANDROID_HOME ANDROID_SDK_ROOT="$ANDROID_HOME"
  local sdkmanager="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"

  log "Android litsenziyalari qabul qilinmoqda..."
  yes | "$sdkmanager" --licenses >/dev/null 2>&1 || true

  log "Android paketlari o'rnatilmoqda: ${ANDROID_PACKAGES[*]}"
  if ! "$sdkmanager" --install "${ANDROID_PACKAGES[@]}" >/dev/null 2>&1; then
    log "XATO: Android paketlari o'rnatilmadi."
    return 1
  fi
  log "Android SDK o'rnatildi."
}

started=$SECONDS

install_flutter &
flutter_pid=$!
install_android &
android_pid=$!

wait "$flutter_pid"; flutter_ok=$?
wait "$android_pid"; android_ok=$?

# Flutter ni Android SDK ga ulaymiz va Android artefaktlarini oldindan
# yuklaymiz — shunda birinchi `flutter build` da kutish bo'lmaydi.
if [ "$flutter_ok" -eq 0 ]; then
  export PATH="$FLUTTER_HOME/bin:$PATH"
  git config --global --add safe.directory "$FLUTTER_HOME" || true
  flutter --disable-analytics >/dev/null 2>&1 || true
  if [ "$android_ok" -eq 0 ]; then
    flutter config --android-sdk "$ANDROID_HOME" >/dev/null 2>&1 || true
  fi
  log "Flutter Android artefaktlari oldindan yuklanmoqda..."
  flutter precache --android --no-ios --no-linux --no-macos --no-web \
    --no-windows >/dev/null 2>&1 || true
fi

# PATH ni keyingi hamma qobiqlar uchun saqlaymiz.
mkdir -p "$(dirname "$PROFILE_FILE")"
cat > "$PROFILE_FILE" <<EOF
export ANDROID_HOME="$ANDROID_HOME"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$FLUTTER_HOME/bin:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$PATH"
EOF
chmod +x "$PROFILE_FILE"
# profile.d faqat login qobiqlarda o'qiladi, shuning uchun .bashrc ga ham.
for rc in /root/.bashrc /root/.profile; do
  [ -f "$rc" ] || touch "$rc"
  grep -q "$PROFILE_FILE" "$rc" 2>/dev/null || \
    echo ". $PROFILE_FILE" >> "$rc"
done

log "tugadi: ${SECONDS}s (flutter=$flutter_ok android=$android_ok)"
if [ "$flutter_ok" -ne 0 ] || [ "$android_ok" -ne 0 ]; then
  log "DIQQAT: biror qism o'rnatilmadi — yuqoridagi xabarlarga qarang."
fi

# Sessiya baribir ishga tushsin: hech qachon nolga teng bo'lmagan kod bilan
# chiqmaymiz (hujjat talabi).
exit 0
