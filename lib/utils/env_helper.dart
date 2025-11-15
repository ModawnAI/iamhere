import 'package:flutter/foundation.dart';

/// Helper class to read environment variables from JavaScript (web only)
class EnvHelper {
  /// Get NIKE_2_GLB_URL from window.ENV (web) or return fallback
  static String getNike2GlbUrl() {
    if (kIsWeb) {
      // On web, env.js will set window.ENV.NIKE_2_GLB_URL
      // For now, we'll use the fallback since we can't easily read from JS
      // In production, you'll edit env.js directly with the Blob URL
      return 'nike.glb'; // Fallback - edit web/env.js after Blob upload
    }
    return ''; // Not used on non-web platforms
  }
}
