import 'package:flutter/foundation.dart';
import 'dart:js_interop';

/// JavaScript window.ENV object
@JS('window.ENV')
external EnvConfig? get _env;

/// JavaScript ENV configuration
@JS()
@anonymous
extension type EnvConfig(JSObject _) implements JSObject {
  external String? get NIKE_2_GLB_URL;
}

/// Helper class to read environment variables from JavaScript (web only)
class EnvHelper {
  /// Get NIKE_2_GLB_URL from window.ENV (web) or return fallback
  static String getNike2GlbUrl() {
    if (kIsWeb) {
      try {
        final env = _env;
        final url = env?.NIKE_2_GLB_URL;

        // If URL is set and not empty, use it
        if (url != null && url.isNotEmpty) {
          print('📦 Using Blob URL from env.js: $url');
          return url;
        }

        // Otherwise use fallback
        print('📦 No Blob URL configured, using fallback: nike.glb');
        return 'nike.glb';
      } catch (e) {
        print('⚠️ Error reading env.js: $e');
        return 'nike.glb';
      }
    }
    return ''; // Not used on non-web platforms
  }
}
