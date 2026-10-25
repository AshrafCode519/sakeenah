# وثيقة خطة العمل والمواصفات الفنية لمشروع "سَكينة / بيان"
## تطبيق القرآن الكريم والأذكار الذكي متعدد المنصات (Android, iOS, Windows, Linux)

---

## 1. ملخص المشروع (Executive Summary)

* **الرؤية:** دمج أفضل المزايا من تطبيقي **"آية" (Ayah)** و**"أذكار المسلم" (Athkar)** في تطبيق موحد عالي الجودة يدعم الهواتف وسطح المكتب (مع تركيز خاص على توفير تجربة أصلية لأنظمة Windows وLinux تفتقر إليها المنظومة البرمجية الإسلامية حالياً).
* **القيمة الأساسية:**
  1. مصحف عالي الدقة مبني على طبعة مجمع الملك فهد مع تفسير مختصر وتلاوات متزامنة (بروح تطبيق آية).
  2. نظام أذكار تلقائي يظهر على الشاشة دورياً بدون مقاطعة سير العمل عبر الجوال وسطح المكتب (بروح أذكار المسلم).
  3. مزامنة فورية لمواضع الختمة، الملاحظات، وإحصائيات الورد اليومي بين كل أجهزة المستخدم بنهج **Offline-First**.

---

## 2. المكدس التقني المعتمد (Tech Stack Architecture)

| الطبقة التقنية | التقنية المختارة | سبب الاختيار |
| :--- | :--- | :--- |
| **إطار الواجهات (Cross-Platform)** | **Flutter (Dart)** | كود واحد لكافة المنصات، دعم ممتاز للرسم المتجه والخطوط العربية، وأداء 60-120fps على Linux وWindows والجوال دون ثقل أطر المتصفحات كـ Electron. |
| **قاعدة البيانات المحلية (Offline-First)** | **Drift (SQLite)** | ضمان سرعة استرجاع نصوص المصحف والتفاسير بدون اتصال، وحفظ الأذكار ومواقع القراءة محلياً وموثوقاً. |
| **الخلفية والمزامنة السحابية** | **Supabase (PostgreSQL + Realtime)** | إدارة تسجيل الدخول السلس، ومزامنة مواضع الختمات، الفواصل، والملاحظات التدبرية لحظياً بين الأجهزة. |
| **محرك الصوت والتلاوات** | **just_audio + audio_service** | تشغيل التلاوات في الخلفية، التخزين المؤقت (Audio Caching)، وإظهار تحكمات الصوت على شاشة القفل وإشعارات النظام. |
| **تكامل سطح المكتب (Desktop APIs)** | **window_manager + system_tray** | تفعيل تشغيل التطبيق في صينية النظام (Tray Bar)، والنوافذ المنبثقة الطافية غير المقاطعة للعمل (Floating Overlay/Toast). |

---

## 3. هندسة الخصائص الرئيسية (Core Features)

### أ. محرك المصحف والتفسير (مستوحى من "آية")
* **رسم المصحف:** استخدام خطوط مجمع الملك فهد المتجهة أو صور الصفحات الرقمية عالية الدقة بنمط صفحات مريحة للعين (وضع النهار الورقي، والوضع الليلي الحقيقي).
* **المختصر في التفسير وغريب القرآن:** نافذة سفلية/جانبية فورية بضغطة واحدة على أي آية توضح المعنى والمفردات الصعبة.
* **التلاوة المتزامنة مع التظليل:** تظليل الآية المقروءة كلمة بكلمة أو آية بآية مع إمكانية التكرار الذاتي للتحفيظ.
* **صانع بطاقات الآيات:** تحويل أي آية مع تفسيرها إلى بطاقة مصورة بتنسيق خطوط راقٍ ومشاركتها مباشرة على وسائل التواصل.

### ب. محرك الأذكار والظهور الذكي (مستوحى من "أذكار المسلم")
* **الظهور التلقائي (Auto-Floating Athkar):**
  * **على Android:** نافذة منبثقة خفيفة عائمة (Overlay) تظهر ذكراً لبضع ثوانٍ وتختفي بهدوء، مع تحكم دقيق بمعدل الظهور وساعات الإسكات.
  * **على Windows وLinux:** إشعار منبثق لطيف في زاوية الشاشة فوق البرامج أو سطر نصي صغير يمر في شريط المهام/العلوي دورياً دون مقاطعة لوحة المفاتيح.
* **السبحة الرقمية السريعة (Quick Clicker):**
  * ودجت مصغر على الشاشة أو اختصار لوحة مفاتيح عام (`Global Hotkey` مثل `Ctrl + Alt + Z`) للتسبيح بنقرة سريعة أثناء العمل.
* **حلقات الأوراد اليومية (Daily Wird Rings):** دوائر دقيقة تمتلئ عند إتمام: (أذكار الصباح، أذكار المساء، ورد القرآن، والمقدار المستهدف من الاستغفار).

### ج. الختمة السحابية والملاحظات (Cross-Platform Khatmah)
* قرأت ورداً على الهاتف في المواصلات $\rightarrow$ تفتح حاسوبك (لينكس أو ويندوز) في المساء فتجد علامة الفاصل في نفس الآية فوراً.
* سجل التدبر: مساحة خاصة لحفظ الآيات المفضلة وكتابة الخواطر والتدبرات ومزامنتها بين أجهزتك.

---

## 4. تصميم قاعدة البيانات (Database Schema)

```sql
-- 1. جدول المستخدمين
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE,
    display_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. جدول تقدم الختمات والمواضع
CREATE TABLE khatmah_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title TEXT DEFAULT 'ختمتي الحالية',
    current_surah INT NOT NULL DEFAULT 1,
    current_ayah INT NOT NULL DEFAULT 1,
    current_page INT NOT NULL DEFAULT 1,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. جدول التدبر والملاحظات الشخصية
CREATE TABLE reflections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    surah_number INT NOT NULL,
    ayah_number INT NOT NULL,
    reflection_text TEXT NOT NULL,
    is_favorite BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. سجل إحصائيات الأذكار اليومية
CREATE TABLE daily_athkar_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    log_date DATE DEFAULT CURRENT_DATE,
    morning_athkar_done BOOLEAN DEFAULT FALSE,
    evening_athkar_done BOOLEAN DEFAULT FALSE,
    tasbih_count INT DEFAULT 0,
    quran_pages_read INT DEFAULT 0,
    CONSTRAINT unique_user_day UNIQUE(user_id, log_date)
);
```

---

## 5. خارطة الطريق ومراحل التنفيذ (Roadmap)

```
[ المرحلة 1: تجهيز الأصول والبيانات وتصميم الواجهات ]
 ├── استيراد قاعدة بيانات القرآن الكريم المعتمدة وتفاسير "المختصر في التفسير"
 ├── جمع وتدقيق نصوص الأذكار وتصنيفاتها وفوائدها من المصادر الموثوقة
 └── تصميم شاشات المصحف والأذكار والودجت العائم في Figma بتنسيق متجاوب (Desktop & Mobile)

[ المرحلة 2: بناء النواة البرمجية بدون اتصال (Local MVP) ]
 ├── إنشاء مشروع Flutter لجميع المنصات (Android, iOS, Windows, Linux)
 ├── بناء عارض المصحف بدقة عالية وتحميل سريع للصفحات
 ├── تشغيل مشغل الصوت (just_audio) مع تظليل الآيات
 └── بناء مكتبة الأذكار والسبحة الرقمية وتخزين التقدم في SQLite محلياً عبر Drift

[ المرحلة 3: ميزات النوافذ العائمة ودمج النظام ]
 ├── Android: بناء خدمة النافذة المنبثقة الطافية للأذكار فوق الشاشات (Floating Service)
 ├── Windows & Linux: برمجة أيقونة صينية النظام (System Tray) والإشعارات الهادئة
 └── تفعيل اختصارات الكيبورد العامة (Global Shortcuts) للتسبيح واستعراض الذكر التالي

[ المرحلة 4: المزامنة السحابية ومولد البطاقات ]
 ├── ربط Supabase Auth وتفعيل المزامنة اللحظية للختمات بين الجوال والحاسوب
 ├── بناء ميزة تصدير بطاقات الآيات كصور أنيقة وعالية الدقة للمشاركة
 └── دوائر متابعة الأوراد اليومية والإحصائيات الأسبوعية والشهرية

[ المرحلة 5: الاختبار والتجميع والتوزيع ]
 ├── تحسين استهلاك الذاكرة والمعالج في الخلفية ليبقى تحت 50MB RAM على سطح المكتب
 ├── حزم Linux: إنشاء وتجهيز Flatpak و Snap لتغطية توزيعات (Ubuntu, Arch, Fedora)
 ├── حزم Windows: إنشاء مثبت خفيف بصيغة MSIX و Inno Setup EXE
 └── حزم Mobile: تصدير ورفع النسخ لمتجري Google Play و Apple App Store
```

---

## 6. خطوات البدء الفوري

1. إنشاء المشروع عبر سطر الأوامر:
   ```bash
   flutter create --org com.sakeenah --platforms=android,ios,windows,linux sakeenah_app
   ```
2. تثبيت الحزم الجوهرية:
   * `drift`, `sqlite3_flutter_libs` لقاعدة البيانات المحلية.
   * `window_manager`, `system_tray` لسطح المكتب.
   * `just_audio`, `audio_service` للتلاوات.
   * `supabase_flutter` لمزامنة الختمات والملاحظات.