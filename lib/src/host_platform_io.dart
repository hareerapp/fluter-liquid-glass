import 'dart:io' show Platform;

(String, String)? hostPlatform() =>
    (Platform.operatingSystem, Platform.operatingSystemVersion);
