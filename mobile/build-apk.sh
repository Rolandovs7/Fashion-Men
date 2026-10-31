#!/bin/bash
# ============================================================
# build-apk.sh — Compila el APK de MenStyle con todos los fixes
# Uso: bash build-apk.sh
# ============================================================

set -e  # Detener si algo falla

MOBILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$MOBILE_DIR"

echo "=========================================="
echo "  MenStyle - Build APK Release"
echo "=========================================="
echo ""

# ------------------------------------------------------------
# 1. Verificar JDK 21
# ------------------------------------------------------------
JDK_21="/usr/lib/jvm/java-21-openjdk-amd64"

if [ ! -d "$JDK_21" ]; then
    echo "❌ No se encontró JDK 21 en $JDK_21"
    echo "   Instálalo con: sudo apt install -y openjdk-21-jdk"
    exit 1
fi

echo "✅ JDK 21 encontrado en $JDK_21"
echo ""

# ------------------------------------------------------------
# 2. Configurar Flutter para usar JDK 21
# ------------------------------------------------------------
echo "→ Configurando Flutter para usar JDK 21..."
flutter config --jdk-dir="$JDK_21" > /dev/null 2>&1
echo "✅ Flutter configurado con JDK 21"
echo ""

# ------------------------------------------------------------
# 3. Crear proguard-rules.pro si no existe
# ------------------------------------------------------------
PROGUARD_FILE="android/app/proguard-rules.pro"

if [ ! -f "$PROGUARD_FILE" ]; then
    echo "→ Creando $PROGUARD_FILE..."
    cat > "$PROGUARD_FILE" << 'PROGUARD_EOF'
# ============================================================
# Reglas ProGuard para flutter_stripe 11.x
# Resuelve: R8 Missing class com.stripe.android.pushProvisioning.*
# ============================================================

# Mantener todas las clases de Stripe
-keep class com.stripe.** { *; }

# Ignorar advertencias de pushProvisioning
-dontwarn com.stripe.**
-dontwarn com.stripe.android.pushProvisioning.**
-dontwarn com.reactnativestripesdk.pushprovisioning.**

# Mantener clases específicas
-keep class com.stripe.android.pushProvisioning.** { *; }
-keep class com.reactnativestripesdk.pushprovisioning.** { *; }
PROGUARD_EOF
    echo "✅ proguard-rules.pro creado"
else
    echo "✅ proguard-rules.pro ya existe"
fi
echo ""

# ------------------------------------------------------------
# 4. Verificar si build.gradle.kts ya tiene proguardFiles
# ------------------------------------------------------------
GRADLE_FILE="android/app/build.gradle.kts"

if grep -q "proguard-rules.pro" "$GRADLE_FILE"; then
    echo "✅ build.gradle.kts ya referencia proguard-rules.pro"
else
    echo "⚠️  build.gradle.kts NO tiene referencia a proguard-rules.pro"
    echo ""
    echo "   Debes editarlo manualmente y agregar dentro de buildTypes.release:"
    echo ""
    echo "   isMinifyEnabled = true"
    echo "   isShrinkResources = true"
    echo "   proguardFiles("
    echo "       getDefaultProguardFile(\"proguard-android-optimize.txt\"),"
    echo "       \"proguard-rules.pro\""
    echo "   )"
    echo ""
    echo "   Después de editarlo, vuelve a ejecutar este script."
    echo ""
    read -p "   ¿Ya lo editaste? (s/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo "   Edita $GRADLE_FILE y vuelve a ejecutar."
        exit 1
    fi
fi
echo ""

# ------------------------------------------------------------
# 5. Clean + pub get
# ------------------------------------------------------------
echo "→ Limpiando build anterior..."
flutter clean > /dev/null 2>&1
echo "✅ Limpieza completa"
echo ""

echo "→ Descargando dependencias..."
flutter pub get
echo ""

# ------------------------------------------------------------
# 6. Compilar APK
# ------------------------------------------------------------
echo "→ Compilando APK release (esto puede tardar 5-15 min)..."
echo ""
flutter build apk --release

# ------------------------------------------------------------
# 7. Verificar resultado
# ------------------------------------------------------------
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

if [ -f "$APK_PATH" ]; then
    echo ""
    echo "=========================================="
    echo "  ✅ APK generado exitosamente"
    echo "=========================================="
    ls -lh "$APK_PATH"
    echo ""
    echo "Ruta completa: $MOBILE_DIR/$APK_PATH"
    echo ""
    echo "Para instalarlo en tu teléfono:"
    echo "  1. Copia el APK al teléfono (USB, Drive, WhatsApp)"
    echo "  2. Ábrelo en el teléfono"
    echo "  3. Permite instalar de fuentes desconocidas"
else
    echo ""
    echo "❌ Build falló. El APK no se generó."
    exit 1
fi
