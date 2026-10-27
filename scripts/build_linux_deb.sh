#!/bin/bash
# ==============================================================================
# سكينة - سكريبت إنشاء حزمة تثبيت دبيان/أوبونتو الرسمية (Debian / Ubuntu .deb Package)
# ==============================================================================

set -e

VERSION="1.0.0"
ARCH="amd64"
PACKAGE_NAME="sakeenah"
DEB_DIR="build/debian/${PACKAGE_NAME}_${VERSION}_${ARCH}"
BUNDLE_DIR="build/linux/x64/release/bundle"

echo "=========================================================="
echo "    إنشاء حزمة التثبيت الرسمية لنظام لينكس (.deb Package)   "
echo "=========================================================="

# 1. بناء المشروع إذا لم يكن مبنياً
if [ ! -d "$BUNDLE_DIR" ]; then
    echo "⚙️ جاري بناء التطبيق أولاً..."
    flutter build linux --release
fi

echo "📦 تجهيز شجرة ملفات حزمة دبيان..."
rm -rf "$DEB_DIR"
mkdir -p "$DEB_DIR/DEBIAN"
mkdir -p "$DEB_DIR/usr/lib/$PACKAGE_NAME"
mkdir -p "$DEB_DIR/usr/bin"
mkdir -p "$DEB_DIR/usr/share/applications"
mkdir -p "$DEB_DIR/usr/share/icons/hicolor/256x256/apps"

# 2. إنشاء ملف التحكم DEBIAN/control
cat << 'EOF' > "$DEB_DIR/DEBIAN/control"
Package: sakeenah
Version: 1.0.0
Section: utils
Priority: optional
Architecture: amd64
Maintainer: Sakeenah App Team <support@sakeenah.app>
Depends: libgtk-3-0, libglib2.0-0, libstdc++6, libgstreamer1.0-0, libgstreamer-plugins-base1.0-0
Description: Sakeenah - Islamic Quran, Athkar, and Prayer Times App
 تطبيق سَكينة للقرآن الكريم مع تصفح صفحات المصحف النبوي،
 وأذكار الصباح والمساء كاملة مع التكرارات، ومواقيت الصلاة الدقيقة لكافة المحافظات،
 والمسبحة الإلكترونية مع الدعم الكامل للوضع الليلي والهوية الإسلامية.
EOF

# 3. نسخ مخرجات البناء (Bundle) إلى /usr/lib/sakeenah/
echo "📋 نسخ ملفات التشغيل والمكتبات..."
cp -r "$BUNDLE_DIR"/* "$DEB_DIR/usr/lib/$PACKAGE_NAME/"

# 4. إنشاء ملف تشغيل تنفيذي في /usr/bin/sakeenah
cat << 'EOF' > "$DEB_DIR/usr/bin/sakeenah"
#!/bin/bash
exec /usr/lib/sakeenah/sakeenah "$@"
EOF
chmod +x "$DEB_DIR/usr/bin/sakeenah"

# 5. نسخ ملف اختصار سطح المكتب والبرامج والأيقونة
cp linux/sakeenah.desktop "$DEB_DIR/usr/share/applications/"
if [ -f "linux/sakeenah.png" ]; then
    cp linux/sakeenah.png "$DEB_DIR/usr/share/icons/hicolor/256x256/apps/sakeenah.png"
fi

# 6. بناء الحزمة بواسطة dpkg-deb
echo "🔨 تجميع حزمة التثبيت (${PACKAGE_NAME}_${VERSION}_${ARCH}.deb)..."
dpkg-deb --build --root-owner-group "$DEB_DIR" "build/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"

echo ""
echo "=========================================================="
echo "🎉 تم إنشاء حزمة التثبيت بنجاح:"
echo "   build/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"
echo ""
echo "لتثبيت التطبيق على أوبونتو أو دبيان أو لينكس منت:"
echo "   sudo apt install ./build/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"
echo "أو:"
echo "   sudo dpkg -i ./build/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"
echo "=========================================================="
