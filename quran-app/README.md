# السراج في بيان غريب القرآن — تطبيق فلاتر

تطبيق فلاتر 100% دون إنترنت لكتاب «السراج في بيان غريب القرآن»، يعرض صفحات الكتاب كصور مع بحث نصي ووضع مراجعة.

## المميزات

### القائمة الرئيسية (فهرس السور)

- **ثلاثة أوضاع** عبر شريط أزرار واحد:
  - **المطالعة** — فتح صفحات الكتاب في عارض الصفحات.
  - **التحقق** — شاشة مقارنة بين صورة الصفحة وقائمة الكلمات الغريبة (المعجم).
  - **اختبر نفسك** — وضع الاختبار على الكلمات الغريبة (لكل سورة أو «كل القرآن»).
- **شبكة السور** تعرض رقم السورة والتصنيف (مكية/مدنية)، رقم الصفحة، وعدد الكلمات الغريبة، مع تعطيل السور غير المتاحة.
- **شريط تحكم عائم قابل للطي** (البحث + أزرار الأوضاع):
  - يختفي عند التمرير للأسفل ويظهر عند التمرير للأعلى، بحركة انزلاق ناعمة (~450ms، منحنى easeInOutCubic) مع تلاشٍ خفيف — والظهور في الأعلى متحرك أيضًا ولا يقفز.
  - قرب أعلى القائمة (≤ 40 بكسل) يبقى الشريط ظاهرًا دائمًا.
  - نموذج «طبقة عائمة»: الشبكة ممتدة بالكامل تحت الشريط، والحافة العليا للمحتوى تتبع أسفل الشريط إطارًا بإطار (لا فراغ ولا تداخل)، وأول سورتين (الفاتحة والبقرة) تلتصقان أسفل الأزرار عند السكون.
  - عند الكتابة في البحث ينطوي صف الأزرار الثلاثة (~300ms) ويعود عند المسح، ويبقى حقل البحث ثابتًا فوق النتائج.

### البحث

- **بحث فوري حي** أثناء الكتابة يعرض النتائج مباشرةً.
- **شاشة نتائج كاملة** عند تأكيد البحث.
- تطبيع عربي للاستعلام (إزالة التشكيل وتوحيد الألف) ومطابقته مع قيم `*_normalized`.

### عارض الصفحات (المطالعة)

- عرض صورة الصفحة مع **تكبير/تصغير** (نقر مزدوج + إيماءات) والتنقّل بين الصفحات.

### شاشة التحقق

- **عرض جنبًا إلى جنب**: صورة الصفحة + قائمة معجم الكلمات الغريبة لنفس الصفحة.
- **فاصل قابل للسحب** لضبط المساحة: اسحب الفاصل لإعطاء صورة الصفحة مساحة أكبر أو أصغر (عمودي في الوضع الطولي، أفقي في الشاشات العريضة)، ونقر مزدوج على الفاصل يعيد النسبة الافتراضية.
- **تحكم بحجم الخط** (+ / −) لقائمة المعجم.
- تنقّل بين الصفحات مع تطبيق التخطيط الدقيق (بالبكسل) لحظيًا أثناء السحب.

### الاختبار (اختبر نفسك)

- أسئلة على الكلمات الغريبة لكل سورة، أو وضع **«كل القرآن»** بأسئلة مستمرة من جميع السور، مع **شاشة نتائج** في النهاية.

### عام

- **الوضع النهاري/الليلي** قابل للتبديل من رأس الشاشة الرئيسية.
- واجهة **RTL** بخط **Amiri** المضمّن.
- يعمل **دون إنترنت بالكامل** (الصفحات والبيانات مضمّنة كموارد).

## البنية

```
quran-app/
├── lib/                   # كود التطبيق (إنجليزي للتوافق)
│   ├── main.dart          # نقطة البداية + إعداد RTL والخط
│   ├── theme.dart         # الوضع النهاري/الليلي + ألوان البطاقات
│   ├── data/              # بيانات ثابتة (قائمة السور kQuranSurahs …)
│   ├── models/            # نماذج JSON
│   ├── screens/           # الرئيسية / النتائج / عارض الصفحات / التحقق / الاختبار / نتيجة الاختبار
│   ├── services/          # تحميل البيانات والبحث + تطبيع العربية
│   ├── utils/             # أدوات مساعدة (الأرقام العربية …)
│   └── widgets/           # مكونات مشتركة (SearchResultCard …)
├── assets/
│   ├── fonts/             # خط Amiri (مضمّن)
│   ├── icon/              # أيقونة التطبيق (مصدر توليد أيقونات المنصات)
│   ├── images/            # صور الصفحات (تُنشأ بواسطة السكربت)
│   ├── json/              # ملفات JSON للصفحات (تُنشأ بواسطة السكربت)
│   ├── sounds/            # أصوات الاختبار
│   └── surah_index.json   # فهرس السور (يُنشأ بواسطة السكربت)
├── android/
│   ├── key.properties     # بيانات توقيع الإصدار (لا تُرفع على git!)
│   └── app/upload-keystore.jks  # مفتاح التوقيع (لا يُرفع على git!)
├── sync_resources.py      # نسخ الموارد + توليد الفهرس
└── pubspec.yaml
```

## المصادر

- صفحات الكتاب: `C:\Users\devtips\Documents\pdf-to-images\pages\` (صور + JSON لكل صفحة).
- `menu.json` في مجلد المصدر هو المرجع للترتيب والأسماء والتصنيف وعدد الكلمات الغريبة لكل سورة.

## الأوامر الكاملة (بناء / اختبار / إصدار)

> على هذا الجهاز مسار فلاتر هو `C:\flutter\bin\flutter` (غير مضاف إلى PATH)،
> وقد تحتاج لكتابة `C:/flutter/bin/flutter` بدلًا من `flutter`.

### فحص وتحضير البيئة

```
C:/flutter/bin/flutter --version         # إصدار فلاتر
C:/flutter/bin/flutter doctor            # حالة الأدوات (أندرويد/ويندوز/ويب)
C:/flutter/bin/flutter pub get           # تحميل الحزم بعد تعديل pubspec.yaml
C:/flutter/bin/dart run flutter_launcher_icons   # توليد أيقونات المنصات من assets/icon/app_icon.png
C:/flutter/bin/flutter clean             # تنظيف كامل (يمسح build/)
```

### الموارد

```
python sync_resources.py                 # نسخ صور/JSON وتوليد surah_index.json (المصدر: pdf-to-images)
```

### الفحص (Analyze) والاختبارات (Test)

```
C:/flutter/bin/flutter analyze           # فحص الأكواد والتزام lint
C:/flutter/bin/flutter test              # تشغيل الاختبارات
```

### التطوير والاختبار على الجهاز

```
C:/flutter/bin/flutter run               # تشغيل مباشر على الجهاز المتصل
C:/flutter/bin/flutter run -d windows    # تشغيل على ويندوز
C:/flutter/bin/flutter run -d chrome     # تشغيل على المتصفح
```

### أندرويد

```
C:/flutter/bin/flutter build apk --release                                          # APK (توقيع الإصدار تلقائيًا)
C:/flutter/bin/flutter build apk --release --target-platform android-arm64,android-arm   # APK أصغر (~64MB) لمعماريات الهواتف فقط
C:/flutter/bin/flutter build appbundle --release    # AAB لنشر Play Store
```

### ويندوز

```
C:/flutter/bin/flutter build windows --release
```

> إذا غيّرت اسم التطبيق في `windows/CMakeLists.txt` ولن يعمل البناء، احذف `build/windows` ثم أعد البناء
> (أو نفّذ `flutter clean`)، لأن CMake يخبئ الاسم القديم.

### ويب

```
C:/flutter/bin/flutter build web --release
```

### التثبيت على جهاز أندرويد (USB)

يتطلب تفعيل «خيارات المطور» و«تصحيح أوسب» على الهاتف (الإعدادات ← لمحة عن الهاتف ← اضغط رقم الإصدار 7 مرات).

```
C:/Users/devtips/AppData/Local/Android/Sdk/platform-tools/adb devices
C:/Users/devtips/AppData/Local/Android/Sdk/platform-tools/adb install -r "build/app/outputs/flutter-apk/app-release.apk"
C:/Users/devtips/AppData/Local/Android/Sdk/platform-tools/adb uninstall com.siraj.alsiraj
C:/Users/devtips/AppData/Local/Android/Sdk/platform-tools/adb shell monkey -p com.siraj.alsiraj -c android.intent.category.LAUNCHER 1   # تشغيل التطبيق
```

> ملاحظة: أخطاء التثبيت الصامتة على سامسونج سببها عادةً توقيع مختلف عن نسخة مثبّتة مسبقًا —
> احذف النسخة القديمة أولًا، أو استخدم `adb install` لإظهار السبب الحقيقي.

### التحقق من التوقيع

```
C:/Users/devtips/AppData/Local/Android/Sdk/build-tools/36.0.0/apksigner verify --print-certs "build/app/outputs/flutter-apk/app-release.apk"
```

## التوقيع (Release Signing)

يحصل تطبيق الإصدار على توقيعه من مفتاح مخصص (وليس مفاتيح التصحيح):

| العنصر | القيمة |
|---|---|
| الملف | `android/app/upload-keystore.jks` |
| الاسم المستعار (alias) | `upload` |
| صاحب المفتاح | CN=Siraj App, OU=Mobile, O=Siraj, C=MA |
| الصلاحية | 10,000 يوم |
| SHA-256 | `ca438e3d826a9bc31cfcf0424f39f138a5dfbc3f51bb02b12880bfb7cc1d71c6` |

- تُقرأ البيانات تلقائيًا من `android/key.properties` أثناء البناء.
- كلمة المرور موجودة في `android/key.properties` فقط ولا تُكتب في README (المستودع عام) —
  أي فقدان لها يعني استحالة تحديث التطبيق مستقبلًا. احفظ نسخة 
  `upload-keystore.jks` + `key.properties` في مكان آمن.
- إذا حُذف `key.properties` يتراجع البناء تلقائيًا إلى توقيع التصحيح (debug) حتى لا يتعطل.

### إعداد جهاز جديد (استعادة مفاتيح التوقيع)

المستودع لا يحتوي على مفاتيح التوقيع إطلاقًا (كلاهما gitignored). بعد `git clone` + `flutter pub get`
على جهاز جديد، انسخ ملفين فقط من النسخة الاحتياطية (MEGA):

```
<repo>\android\key.properties          # من الأرشيف الاحتياطي كما هو
<repo>\android\app\upload-keystore.jks # مفتاح التوقيع من الأرشيف
```

- `build.gradle.kts` يقرأ `android/key.properties` تلقائيًا، و`storeFile=upload-keystore.jks`
  يُحلّ نسبيًا إلى مجلد `android/app/`. لا حاجة لأي إعداد آخر.
- بعد النسخ تحقق: `git status` — لا يجوز أن يظهر أي من الملفين (كلاهما gitignored).
- إذا غاب `key.properties` يُبنى التطبيق بتوقيع التصحيح (debug) ويُرفض عند الرفع إلى
  Play — تحقق قبل البناء أن الملفين موجودان.

## المخرجات

| المنصة | الملف |
|---|---|
| أندرويد (APK) | `build/app/outputs/flutter-apk/app-release.apk` (حوالي 64MB بأمر `--target-platform`، أو ~82MB بدونه) |
| أندرويد (AAB — متجر) | `build/app/outputs/bundle/release/app-release.aab` |
| ويندوز | `build/windows/x64/runner/Release/AlSiraj.exe` |
| ويب | `build/web/index.html` |

## المصادر والحقوق (Attribution)

- نصوص الآيات القرآنية المضمّنة في ملفات JSON مأخوذة من مشروع تنزيل (Tanzil Project) — نص المصحف بالرسم العثماني، الإصدار 1.1.
  - المصدر: [tanzil.net](https://tanzil.net)
  - الترخيص: Creative Commons Attribution 3.0 (CC BY 3.0)
  - النص منسوخ حرفيًا دون أي تعديل، كما تشترط رخصة الاستخدام.

## ملاحظات

- ملفات `assets/images/` و `assets/json/` و `assets/surah_index.json` **مولّدة** ولا تُرفع على git.
- إذا أضاف الباحث المزيد من الصفحات، أعد تشغيل `python sync_resources.py` ثم أعد البناء.
- البحث يطابق قيم `*_normalized` من ملفات JSON مع تطبيع الاستعلام (إزالة التشكيل وتوحيد الألف).
- التطبيق ثنائي اللغة RTL، باسم «السراج في بيان غريب القرآن».