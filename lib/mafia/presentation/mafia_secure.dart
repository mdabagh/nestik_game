import 'package:flutter/services.dart';

// ============================================================
// Privacy — جلوگیری از دیده شدن نقش در Recent Apps
// ============================================================

/// اندروید: با روشن کردن FLAG_SECURE محتوای Activity در اسکرین‌شات و
/// Recent Apps نمایش داده نمی‌شود. (در iOS راهکار دیگری لازم است.)
class SecureWindow {
  static const MethodChannel _channel = MethodChannel('com.nestic.game/secure');

  /// هنگام ورود به صفحه‌ی توزیع کارت‌ها true و پس از خروج false شود.
  static Future<void> setSecure(bool secure) async {
    try {
      await _channel.invokeMethod<void>('setSecure', secure);
    } on PlatformException {
      // روی پلتفرم‌های پشتیبانی‌نشده بی‌صدا نادیده می‌گیریم.
    } on MissingPluginException {
      // اتصال به اندروید برقرار نیست — نادیده.
    }
  }
}
