@echo off
chcp 65001 >nul
setlocal enableextensions enabledelayedexpansion

REM ============================================================
REM  چک شارژ سالن - اسکریپت بیلد و پکیج‌سازی نصاب ویندوز
REM  فقط روی ویندوز 10/11 اجرا شود.
REM  خروجی نهایی: installer_output\CheckHallCharge-Setup.exe
REM ============================================================

set "ROOT=%~dp0"
cd /d "%ROOT%"

echo.
echo ============================================================
echo   Check Hall Charge - Windows Build ^& Installer Packager
echo ============================================================
echo.

REM ---------- مرحله 1: بررسی Flutter ----------
echo [1/8] بررسی نصب بودن Flutter SDK ...
where flutter >nul 2>nul
if errorlevel 1 (
    echo.
    echo [ERROR] flutter روی PATH پیدا نشد.
    echo        لطفاً Flutter SDK را از این آدرس نصب کنید:
    echo        https://docs.flutter.dev/get-started/install/windows/desktop
    echo        و مطمئن شوید flutter.bat روی PATH سیستم باشد.
    echo.
    pause
    exit /b 1
)
flutter --version
echo OK

REM ---------- مرحله 2: فعال‌سازی Desktop for Windows ----------
echo.
echo [2/8] فعال‌سازی Windows Desktop در Flutter ...
call flutter config --enable-windows-desktop
if errorlevel 1 goto :error
echo OK

REM ---------- مرحله 3: ساخت پوشه windows/ ----------
echo.
echo [3/8] ساخت scaffolding ویندوز (flutter create . --platforms=windows) ...
cd /d "%ROOT%win_project"
call flutter create . --platforms=windows
if errorlevel 1 (
    cd /d "%ROOT%"
    goto :error
)
echo OK

REM ---------- مرحله 4: pub get ----------
echo.
echo [4/8] دانلود پکیج‌های Dart (flutter pub get) ...
call flutter pub get
if errorlevel 1 (
    cd /d "%ROOT%"
    goto :error
)
echo OK

REM ---------- مرحله 5: build windows --release ----------
echo.
echo [5/8] بیلد Release برای ویندوز (flutter build windows --release) ...
call flutter build windows --release
if errorlevel 1 (
    echo.
    echo [ERROR] بیلد شکست خورد. شایع‌ترین دلیل: نبود Visual Studio Build Tools.
    echo        راه‌حل:
    echo          1) دانلود Visual Studio Build Tools:
    echo             https://visualstudio.microsoft.com/visual-cpp-build-tools/
    echo          2) هنگام نصب، workload زیر را تیک بزنید:
    echo             "Desktop development with C++"
    echo          3) شامل این مؤلفه‌ها باشد:
    echo             - MSVC v143 - VS 2022 C++ x64/x86 build tools
    echo             - Windows 11 SDK  (یا Windows 10 SDK)
    echo             - C++ CMake tools for Windows
    echo          4) پس از نصب، این اسکریپت را دوباره اجرا کنید.
    echo.
    cd /d "%ROOT%"
    pause
    exit /b 1
)
cd /d "%ROOT%"
echo OK

REM ---------- مرحله 6: بررسی فایل خروجی ----------
echo.
echo [6/8] بررسی وجود check_hall_charge.exe در پوشه‌ی Release ...
if not exist "%ROOT%win_project\build\windows\x64\runner\Release\check_hall_charge.exe" (
    echo [ERROR] فایل check_hall_charge.exe در مسیر زیر پیدا نشد:
    echo        %ROOT%win_project\build\windows\x64\runner\Release\
    pause
    exit /b 1
)
echo OK

REM ---------- مرحله 7: بررسی Inno Setup ----------
echo.
echo [7/8] بررسی نصب بودن Inno Setup 6 ...
set "ISCC="
if exist "%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe" set "ISCC=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"
if not defined ISCC if exist "%ProgramFiles%\Inno Setup 6\ISCC.exe" set "ISCC=%ProgramFiles%\Inno Setup 6\ISCC.exe"
if not defined ISCC for %%P in (ISCC.exe) do (
    if not "%%~$PATH:P"=="" set "ISCC=%%~$PATH:P"
)
if not defined ISCC (
    echo.
    echo [ERROR] Inno Setup 6 روی سیستم پیدا نشد.
    echo        برای نصب:
    echo          1) دانلود از https://jrsoftware.org/isdl.php
    echo          2) هنگام نصب، گزینه‌ی "Install Inno Setup Preprocessor" را تیک بزنید.
    echo          3) پس از نصب، این اسکریپت را دوباره اجرا کنید.
    echo.
    pause
    exit /b 1
)
echo Found: %ISCC%

REM ---------- مرحله 8: ساخت نصاب ----------
echo.
echo [8/8] ساخت نصاب تک‌فایلی با Inno Setup ...
if not exist "%ROOT%installer_output" mkdir "%ROOT%installer_output"
"%ISCC%" /Q "%ROOT%CheckHallCharge.iss"
if errorlevel 1 goto :error
echo OK

echo.
echo ============================================================
echo   نصاب نهایی ساخته شد!
echo.
echo   مسیر:
echo     %ROOT%installer_output\CheckHallCharge-Setup.exe
echo.
echo   این فایل را روی هر ویندوز 10/11 با دو بار کلیک نصب کنید.
echo   برنامه کاملاً آفلاین است و هیچ اتصال اینترنتی لازم ندارد.
echo ============================================================
echo.
pause
exit /b 0

:error
echo.
echo [ERROR] عملیات در یکی از مراحل بالا با خطا مواجه شد.
echo        پیام‌های بالا را بررسی کنید.
pause
exit /b 1
