#!/bin/bash
# ==============================================================================
# سكينة - سكريبت بناء وتجهيز تطبيق سطح المكتب لنظام لينكس (Linux Desktop App)
# Sakeenah - Flutter Linux Desktop Build Script
# ==============================================================================

set -e

echo "=========================================================="
echo "  بدء بناء تطبيق سَكينة لنظام لينكس (Sakeenah Linux Desktop)  "
echo "=========================================================="

# 1. التحقق من تثبيت فلاتر
if ! command -v flutter &> /dev/null; then
    echo "❌ خطأ: محرك Flutter غير مثبت أو غير مضاف إلى مسار النظام (PATH)."
    echo "يرجى تثبيت Flutter وإضافته إلى PATH ثم إعادة تشغيل السكريبت."
    exit 1
fi

echo "✅ محرك Flutter متوفر: $(flutter --version | head -n 1)"

# 2. تفعيل دعم سطح المكتب للينكس
echo "⚙️ تفعيل دعم Linux Desktop في Flutter..."
flutter config --enable-linux-desktop

# 3. التحقق من تثبيت مكتبات البناء (Build Dependencies)
echo "📦 التحقق من حزم ومكتبات النظام الأساسية (GTK3, Clang, CMake, Ninja, GStreamer)..."
MISSING_DEPS=()
for pkg in clang cmake ninja pkg-config; do
    if ! command -v "$pkg" &> /dev/null; then
        MISSING_DEPS+=("$pkg")
    fi
done

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    echo "⚠️ الحزم التالية ناقصة: ${MISSING_DEPS[*]}"
    echo "يمكنك تثبيتها على توزيعات أوبونتو/دبيان بتنفيذ:"
    echo "sudo apt-get update && sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev"
fi

# 4. تنزيل حزم المشروع
echo "📥 تنزيل حزم فلاتر (flutter pub get)..."
flutter pub get

# 5. بناء التطبيق بنمط الإنتاج (Release)
echo "🚀 جاري بناء تطبيق لينكس (flutter build linux --release)..."
flutter build linux --release

BUNDLE_DIR="build/linux/x64/release/bundle"

if [ -d "$BUNDLE_DIR" ]; then
    echo "✅ تم بناء التطبيق بنجاح داخل: $BUNDLE_DIR"
    
    # 6. ضغط الحزمة إلى ملف tar.gz جاهز للنقل والتشغيل
    TAR_NAME="sakeenah-linux-x64.tar.gz"
    echo "📦 جاري ضغط الحزمة إلى $TAR_NAME..."
    tar -czf "$TAR_NAME" -C "$BUNDLE_DIR" .
    echo "🎉 تم إنشاء الحزمة المضغوطة بنجاح: $TAR_NAME"
    echo ""
    echo "لتشغيل التطبيق على أي جهاز لينكس:"
    echo "  1. فك الضغط: tar -xzf $TAR_NAME -C sakeenah-app"
    echo "  2. التشغيل: cd sakeenah-app && ./sakeenah"
else
    echo "❌ فشل العثور على مخرجات البناء في $BUNDLE_DIR"
    exit 1
fi

echo "=========================================================="
echo "            اكتمل البناء بنجاح والحمد لله                "
echo "=========================================================="
