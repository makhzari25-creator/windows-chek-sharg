import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

/// صفحه چک کردن شارژ (نسخه ویندوز)
/// 1. اگر فایل اکسل انتخاب نشده، اول از کاربر می‌خواهد فایل را انتخاب کند
/// 2. یک فیلد نامرئی و همیشه‌فوکوس، ورودی بارکدخوان سخت‌افزاری (که مثل صفحه‌کلید
///    عمل می‌کند و در پایان هر اسکن Enter می‌فرستد) را می‌گیرد
/// 3. بعد از هر اسکن، نتیجه نمایش داده می‌شود
/// 4. اگر بارکدخوان نتوانست کد را بخواند، دکمه «ورود دستی بارکد» در دسترس است
class CheckChargeScreen extends StatefulWidget {
  const CheckChargeScreen({super.key});

  @override
  State<CheckChargeScreen> createState() => _CheckChargeScreenState();
}

class _CheckChargeScreenState extends State<CheckChargeScreen> {
  bool _isProcessing = false;

  // فیلد نامرئی که همیشه فوکوس دارد و ورودی بارکدخوان سخت‌افزاری
  // (که مثل صفحه‌کلید کاراکترها را به‌سرعت تایپ و در پایان Enter می‌زند) را می‌گیرد
  final TextEditingController _scannerController = TextEditingController();
  final FocusNode _scannerFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refocusScanner());
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _scannerFocusNode.dispose();
    super.dispose();
  }

  /// فوکوس را دوباره روی فیلد بارکدخوان می‌گذارد (بعد از بستن دیالوگ‌ها یا کلیک روی صفحه)
  void _refocusScanner() {
    if (!mounted) return;
    if (!context.read<AppState>().hasFile) return;
    FocusScope.of(context).requestFocus(_scannerFocusNode);
  }

  Future<void> _pickExcelFile() async {
    final state = context.read<AppState>();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: false,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final path = file.path;
      if (path == null) return;

      final ok = await state.loadExcelFile(path, fileName: file.name);
      if (!mounted) return;
      if (ok) {
        _showSnack('فایل با موفقیت بارگذاری شد (${state.products.length} کالا).',
            color: const Color(0xFF43A047));
        _refocusScanner();
      } else {
        _showSnack(state.error ?? 'بارگذاری فایل ناموفق بود.', color: Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('خطا در انتخاب فایل: $e', color: Colors.red);
    }
  }

  /// وقتی بارکدخوان سخت‌افزاری کد را کامل می‌فرستد و در پایان Enter می‌زند
  Future<void> _onScannerSubmitted(String value) async {
    final code = value.trim();
    _scannerController.clear();
    if (code.isEmpty) {
      _refocusScanner();
      return;
    }
    await _processCode(code);
  }

  /// پردازش یک کد بارکد (چه از بارکدخوان، چه از ورود دستی)
  Future<void> _processCode(String code) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      // صدای تایید اسکن
      SystemSound.play(SystemSoundType.click);

      final state = context.read<AppState>();
      final wasComplete = state.isFullyComplete;
      final result = await state.recordScan(code);

      if (!mounted) return;
      await _showResultDialog(context, code, result, state);

      // اگر همین اسکن باعث تکمیل شدن همه کالاها شد، پیام بزرگ تکمیل را نشان بده
      if (!wasComplete && state.isFullyComplete) {
        if (!mounted) return;
        await _showAllCompleteDialog();
      }
    } finally {
      _isProcessing = false;
      _refocusScanner();
    }
  }

  /// ورود دستی کد بارکد، برای مواردی که بارکدخوان قادر به خواندن بارکد نیست
  Future<void> _showManualEntryDialog() async {
    final entered = await showDialog<String>(
      context: context,
      builder: (_) => const _ManualEntryDialog(),
    );

    final code = entered?.trim() ?? '';
    if (code.isEmpty) {
      _refocusScanner();
      return;
    }

    await _processCode(code);
  }

  /// پیام بزرگ تکمیل شدن همه کالاها
  Future<void> _showAllCompleteDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFF43A047).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.celebration_rounded,
                color: Color(0xFF43A047),
                size: 68,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'تکمیل شد!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Color(0xFF43A047),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'همه کالاهای شارژ سالن به تعداد لازم اسکن شدند.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF43A047),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
              ),
              child: const Text('باشه'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showResultDialog(
    BuildContext ctx,
    String code,
    ScanResult result,
    AppState state,
  ) async {
    final product = state.findProduct(code);
    final scanned = state.scannedCountFor(code);

    String title;
    String message;
    Color color;
    IconData icon;

    switch (result) {
      case ScanResult.notFound:
        title = 'این کالا در شارژ سالن نیست';
        message = 'کد: $code';
        color = const Color(0xFFE53935);
        icon = Icons.error_outline_rounded;
        break;
      case ScanResult.scanned:
        title = 'اسکن شد';
        message = '${product?.title ?? ""}\n'
            'اسکن شده: $scanned از ${product?.requiredCount ?? 0}';
        color = const Color(0xFF1565C0);
        icon = Icons.check_circle_outline_rounded;
        break;
      case ScanResult.justCompleted:
        title = 'شارژ این کالا کامل شد';
        message = '${product?.title ?? ""}\n'
            'اسکن شده: $scanned از ${product?.requiredCount ?? 0}';
        color = const Color(0xFF43A047);
        icon = Icons.verified_rounded;
        break;
      case ScanResult.alreadyComplete:
        title = 'شارژ این کالا قبلاً کامل شده';
        message = '${product?.title ?? ""}\n'
            'اسکن شده: $scanned از ${product?.requiredCount ?? 0}';
        color = const Color(0xFF43A047);
        icon = Icons.verified_rounded;
        break;
    }

    if (!mounted) return;
    await showDialog(
      context: ctx,
      barrierDismissible: true,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 52),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
              ),
              child: const Text('ادامه اسکن'),
            ),
          ),
        ],
      ),
    );
    // بعد از بسته شدن دیالوگ، فوکوس را به فیلد بارکدخوان برگردان
    _refocusScanner();
  }

  void _showSnack(String message, {Color color = Colors.black87}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _showResetDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ریست شمارنده‌ها'),
        content: const Text(
          'آیا مطمئن هستید که می‌خواهید شمارنده همه کالاها را صفر کنید؟ '
          'لیست کالاها باقی می‌ماند.',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('ریست'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await context.read<AppState>().resetCounters();
      _showSnack('شمارنده‌ها ریست شدند.', color: const Color(0xFF43A047));
    }
    _refocusScanner();
  }

  Future<void> _showReplaceFileDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('جایگزینی فایل اکسل'),
        content: const Text(
          'با انتخاب فایل جدید، لیست کالاها جایگزین می‌شود. '
          'شمارنده‌های کالاهای موجود که در فایل جدید هم هستند، حفظ می‌شوند.',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('انتخاب فایل'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _pickExcelFile();
    } else {
      _refocusScanner();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (state.loading && !state.hasFile) {
      return Scaffold(
        appBar: AppBar(title: const Text('چک کردن شارژ')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!state.hasFile) {
      // مرحله 1: انتخاب فایل اکسل
      return Scaffold(
        appBar: AppBar(title: const Text('چک کردن شارژ')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.table_view_rounded,
                    size: 70,
                    color: Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'ابتدا فایل اکسل شارژ سالن را انتخاب کنید',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'فرمت‌های پشتیبانی‌شده: xlsx و xls',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 70,
                  child: ElevatedButton.icon(
                    onPressed: _pickExcelFile,
                    icon: const Icon(Icons.file_upload_rounded, size: 30),
                    label: const Text('انتخاب فایل اکسل'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // مرحله 2: نمایش وضعیت آماده‌به‌کار بارکدخوان + پنل وضعیت
    return GestureDetector(
      // با کلیک روی هر جای صفحه، فوکوس به فیلد بارکدخوان برمی‌گردد
      onTap: _refocusScanner,
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('چک کردن شارژ'),
          actions: [
            IconButton(
              icon: const Icon(Icons.keyboard_alt_rounded),
              tooltip: 'ورود دستی بارکد',
              onPressed: _showManualEntryDialog,
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'ریست شمارنده‌ها',
              onPressed: _showResetDialog,
            ),
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded),
              tooltip: 'جایگزینی فایل اکسل',
              onPressed: _showReplaceFileDialog,
            ),
          ],
        ),
        body: Column(
          children: [
            // نوار اطلاعات فایل
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFF1565C0).withOpacity(0.08),
              child: Row(
                children: [
                  const Icon(Icons.table_chart_rounded,
                      color: Color(0xFF1565C0), size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.excelFileName ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1565C0),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${state.products.length} کالا',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            // بخش وضعیت بارکدخوان سخت‌افزاری (به‌جای پیش‌نمایش دوربین)
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: const Color(0xFF0F172A),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 70,
                              color: Color(0xFF42A5F5),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'آماده دریافت از بارکدخوان',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'بارکد را با دستگاه بارکدخوان اسکن کنید',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'اگر دستگاه بارکد را نخواند، از دکمه «ورود دستی بارکد» بالای صفحه استفاده کنید',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // فیلد نامرئی که ورودی بارکدخوان سخت‌افزاری (شبیه صفحه‌کلید) را می‌گیرد
                  Positioned(
                    left: -500,
                    top: 0,
                    child: SizedBox(
                      width: 10,
                      height: 10,
                      child: TextField(
                        controller: _scannerController,
                        focusNode: _scannerFocusNode,
                        autofocus: true,
                        showCursor: false,
                        // بارکدخوان‌های سخت‌افزاری معمولاً بعد از هر اسکن یک Enter می‌فرستند
                        onSubmitted: _onScannerSubmitted,
                        decoration: const InputDecoration(border: InputBorder.none),
                      ),
                    ),
                  ),

                  // بنر بزرگ تکمیل شدن همه کالاها
                  if (state.isFullyComplete)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 12),
                        color: const Color(0xFF43A047),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_rounded,
                                color: Colors.white, size: 26),
                            SizedBox(width: 8),
                            Text(
                              'تکمیل شد',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // پنل وضعیت کالاها
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'آخرین وضعیت کالاها',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '${_countCompleted(state)}/${state.products.length} تکمیل‌شده',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF43A047),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _LastScannedList(state: state),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _countCompleted(AppState state) {
    int c = 0;
    for (final p in state.products) {
      final scanned = state.scannedCountFor(p.code);
      if (p.requiredCount > 0 && scanned >= p.requiredCount) {
        c++;
      }
    }
    return c;
  }
}

/// لیست آخرین کالاهای اسکن‌شده یا همه کالاها
class _LastScannedList extends StatelessWidget {
  final AppState state;
  const _LastScannedList({required this.state});

  @override
  Widget build(BuildContext context) {
    // ابتدا کالاهای اسکن‌شده، بعد بقیه
    final sorted = [...state.products]..sort((a, b) {
        final sa = state.scannedCountFor(a.code);
        final sb = state.scannedCountFor(b.code);
        if (sa > 0 && sb == 0) return -1;
        if (sa == 0 && sb > 0) return 1;
        if (sa > 0 && sb > 0) return sb.compareTo(sa);
        return 0;
      });

    if (sorted.isEmpty) {
      return const Center(
        child: Text('هنوز کالایی اسکن نشده است.'),
      );
    }

    return ListView.separated(
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final p = sorted[i];
        final scanned = state.scannedCountFor(p.code);
        final isComplete =
            p.requiredCount > 0 && scanned >= p.requiredCount;
        final hasProgress = scanned > 0;

        return ListTile(
          dense: true,
          leading: Icon(
            isComplete
                ? Icons.verified_rounded
                : hasProgress
                    ? Icons.pending_actions_rounded
                    : Icons.radio_button_unchecked_rounded,
            color: isComplete
                ? const Color(0xFF43A047)
                : hasProgress
                    ? const Color(0xFFFFA726)
                    : Colors.grey,
          ),
          title: Text(
            p.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            'کد: ${p.code}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isComplete
                  ? const Color(0xFF43A047).withOpacity(0.15)
                  : hasProgress
                      ? const Color(0xFFFFA726).withOpacity(0.15)
                      : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$scanned / ${p.requiredCount}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isComplete
                    ? const Color(0xFF43A047)
                    : hasProgress
                        ? const Color(0xFFFFA726)
                        : Colors.black54,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// کادر ورود دستی بارکد؛ برای بارکدهایی که بارکدخوان قادر به خواندنشان نیست
class _ManualEntryDialog extends StatefulWidget {
  const _ManualEntryDialog();

  @override
  State<_ManualEntryDialog> createState() => _ManualEntryDialogState();
}

class _ManualEntryDialogState extends State<_ManualEntryDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('ورود دستی بارکد'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.left,
        keyboardType: TextInputType.text,
        decoration: const InputDecoration(
          hintText: 'کد بارکد را وارد کنید',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('انصراف'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('ثبت'),
        ),
      ],
    );
  }
}
