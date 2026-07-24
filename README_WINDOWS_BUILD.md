# راهنمای بیلد ویندوز — چک شارژ سالن

این بسته شامل تمام فایل‌های لازم برای ساخت یک نصاب تک‌فایلی ویندوز (`CheckHallCharge-Setup.exe`) از سورس‌کد Flutter پروژه‌ی «چک شارژ سالن» است.

## ⚠️ نکته‌ی مهم درباره‌ی محیط ساخت

`flutter build windows` فقط روی **ویندوز** اجرا می‌شود (محدودیت hard-coded خود Flutter) — نه روی Linux یا macOS. برای این کار دو راه دارید:

- **راه ۱ (ساده‌ترین):** بسته را روی یک ویندوز ۱۰/۱�۱ باز کنید و روی `build_installer.bat` دو بار کلیک کنید.
- **راه ۲ (بدون نیاز به ویندوز محلی):** فایل‌ها را به یک repo در GitHub بفرستید (همراه با پوشه‌ی `.github/workflows/` این بسته) و GitHub Actions به‌صورت خودکار در فضای ابری `.exe` را می‌سازد.

> **تست شده:** خود Flutter روی Linux پیام می‌دهد: `"build windows" only supported on Windows hosts."` — هیچ راه cross-compile رسمی وجود ندارد.

## محتویات بسته

```
check_hall_charge_build_pack/
├── build_installer.bat             ← راه ۱: روی ویندوز اجرا کنید
├── CheckHallCharge.iss             ← اسکریپت Inno Setup (هر دو راه این را صدا می‌زنند)
├── .github/workflows/build-windows.yml  ← راه ۲: workflow برای GitHub Actions
├── README_WINDOWS_BUILD.md         ← همین فایل
└── win_project/                    ← سورس‌کد کامل Flutter (دست‌نخورده)
    ├── lib/                        ← منطق برنامه (دست نزنید)
    ├── assets/                     ← فونت Vazirmatn
    ├── pubspec.yaml
    └── ...
```

## پیش‌نیازها (روی ویندوز ۱۰ یا ۱۱)

سه مورد زیر را فقط یک بار نصب کنید:

### ۱) Flutter SDK (نسخه‌ی پایدار)
- آدرس: https://docs.flutter.dev/get-started/install/windows/desktop
- پس از نصب، مطمئن شوید `flutter.bat` روی `PATH` سیستم باشد:
  - PowerShell یا CMD باز کنید → `flutter --version` باید خروجی بدهد.
- (اختیاری) Flutter Doctor را اجرا کنید تا وضعیت ابزارها را ببینید:
  ```
  flutter doctor
  ```

### ۲) Visual Studio 2022 (یا فقط Build Tools) با C++
- آدرس Build Tools: https://visualstudio.microsoft.com/visual-cpp-build-tools/
- هنگام نصب، تیک workload زیر را بزنید:
  - **Desktop development with C++**
- این مؤلفه‌ها باید نصب شوند:
  - MSVC v143 - VS 2022 C++ x64/x86 build tools
  - Windows 11 SDK (یا Windows 10 SDK)
  - C++ CMake tools for Windows

> نکته: Visual Studio Code کافی نیست — منظور Visual Studio کامل (یا حداقل Build Tools) است.

### ۳) Inno Setup 6
- آدرس: https://jrsoftware.org/isdl.php
- هنگام نصب، گزینه‌ی «Install Inno Setup Preprocessor» را تیک بزنید.
- مسیر پیش‌فرض نصب: `C:\Program Files (x86)\Inno Setup 6\`

## روش ۲: ساخت در فضای ابری با GitHub Actions (بدون نیاز به ویندوز)

اگر ویندوز در دسترس ندارید، می‌توانید build را به GitHub Actions بسپارید — این سرویس Windows runner رایگان دارد.

### مراحل

1. یک حساب کاربری رایگان GitHub بسازید (اگر ندارید): https://github.com/signup
2. یک repo جدید خصوصی یا عمومی بسازید (مثلاً `check-hall-charge`).
3. کل محتویات این بسته را در repo آپلود کنید. مهم: پوشه‌ی `.github/workflows/build-windows.yml` حتماً در ریشه‌ی repo باشد.
   - ساختار مورد انتظار در ریشه‌ی repo:
     ```
     .github/workflows/build-windows.yml
     CheckHallCharge.iss
     win_project/...
     ```
4. به تب **Actions** در repo بروید.
5. در سمت چپ روی **Build Windows Installer** کلیک کنید.
6. دکمه‌ی **Run workflow** (آبی رنگ، سمت راست) را بزنید و دوباره **Run workflow** را تأیید کنید.
7. حدود ۵ تا ۱۵ دقیقه صبر کنید تا build تمام شود.
8. وقتی workflow سبز شد، روی آن اجرا کلیک کنید → پایین صفحه، در بخش **Artifacts**، فایل `CheckHallCharge-Setup` را دانلود کنید.
9. فایل دانلودشده یک zip است که داخلش `CheckHallCharge-Setup.exe` هست. آن را روی هر ویندوز ۱۰/۱۱ با دو بار کلیک نصب کنید.

> **هزینه:** GitHub Actions برای حساب رایگان، ۲۰۰۰ دقیقه در ماه Windows runner رایگان می‌دهد. هر build این پروژه حدود ۱۰ دقیقه طول می‌کشد؛ یعنی می‌توانید ماهانه حدود ۲۰۰ بار build بگیرید.

> **خصوصی بودن:** repo می‌تواند خصوصی باشد؛ سورس شما از بیرون دیده نمی‌شود.

## روش ۱: بیلد دستی روی ویندوز

### روش سریع (تک‌کلیک)
1. کل بسته را روی ویندوز کپی کنید (مثلاً `C:\build\check_hall_charge_build_pack\`).
2. روی `build_installer.bat` دو بار کلیک کنید.
3. اسکریپت به‌ترتیب:
   - فعال‌سازی `windows-desktop` در Flutter
   - `flutter create . --platforms=windows` (ساخت پوشه‌ی `windows/` — به `lib/` هیچ آسیبی نمی‌زند)
   - `flutter pub get`
   - `flutter build windows --release`
   - کامپایل Inno Setup روی `CheckHallCharge.iss`
4. خروجی نهایی در:
   ```
   installer_output\CheckHallCharge-Setup.exe
   ```

### روش دستی (اگر خواستید مرحله‌به‌مرحله کنترل کنید)
دستورات زیر را در پوشه‌ی `win_project\` اجرا کنید:

```bat
flutter config --enable-windows-desktop
flutter create . --platforms=windows
flutter pub get
flutter build windows --release
```

سپس در پوشه‌ی ریشه (یک سطح بالاتر از `win_project`):

```bat
"%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe" CheckHallCharge.iss
```

## مسیر فایل خروجی نهایی

```
installer_output\CheckHallCharge-Setup.exe
```

این فایل:
- روی هر ویندوز ۱۰/۱۱ (۶۴ بیتی) با دو بار کلیک نصب می‌شود.
- شامل `check_hall_charge.exe` + تمام DLL های لازم + پوشه‌ی `data` است.
- شورتکات روی دسکتاپ و در Start Menu می‌سازد با نام «چک شارژ سالن».
- کاملاً آفلاین است؛ در زمان نصب یا اجرا هیچ اتصال اینترنتی لازم ندارد.
- در Add/Remove Programs قابل Uninstall است.

## عیب‌یابی

### «flutter» on PATH پیدا نشد
Flutter SDK نصب نیست یا روی PATH تنظیم نشده. دستور `flutter --version` را در یک CMD تازه باز شده بزنید؛ اگر خطای «command not found» گرفتید، Flutter را نصب یا PATH را اصلاح کنید.

### خطای «Visual Studio not installed» هنگام `flutter build windows`
Visual Studio Build Tools با C++ نصب نیست. به بخش پیش‌نیازها مراجعه کنید.
برای بررسی: `flutter doctor -v` را اجرا کنید؛ زیر `[!] Visual Studio - develop Windows apps` مشکل را نشان می‌دهد.

### «Inno Setup 6 on system پیدا نشد»
Inno Setup نصب نیست. به https://jrsoftware.org/isdl.php بروید و نسخه‌ی ۶ را نصب کنید.

### بیلد موفق ولی نصاب ساخته نشد
فایل لاگ کامل را در خروجی کنسول ببینید. معمولاً به دلیل وجود کاراکترهای غیر-ASCII در `.iss` است؛ مطمئن شوید فایل `CheckHallCharge.iss` با انکودینگ **UTF-8** ذخیره شده (پیش‌فرض همین‌طور است — تغییرش ندهید).

### فلتر نسخه‌ی اشتباه
این پروژه با Flutter SDK `^3.5.4` تست شده. اگر نسخه‌ی خیلی قدیمی دارید، ارتقا دهید.

## نکات فنی

- **بارکدخوان**: این نسخه از یک بارکدخوان سخت‌افزاری USB (که مثل کیبورد عمل می‌کند و در پایان Enter می‌فرستد) استفاده می‌کند؛ دوربین استفاده نمی‌شود.
- **آفلاین بودن**: هیچ پکیج dependency‌ای به اینترنت در زمان اجرا نیاز ندارد.
- **RTL**: تم و ویزارد نصاب راست‌چین است.
- **تغییر در lib/**: نیازی نیست؛ فایل‌های lib/ در این بسته همان نسخه‌ی اصلی شماست.
