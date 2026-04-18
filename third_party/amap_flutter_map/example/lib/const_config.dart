import 'package:amap_flutter_base/amap_flutter_base.dart';

class ConstConfig {
  static const AMapApiKey amapApiKeys =
      AMapApiKey(
        androidKey: String.fromEnvironment('AMAP_ANDROID_KEY'),
        iosKey: String.fromEnvironment('AMAP_IOS_KEY'),
      );
  static const AMapPrivacyStatement amapPrivacyStatement =
      AMapPrivacyStatement(hasContains: true, hasShow: true, hasAgree: true);
}
