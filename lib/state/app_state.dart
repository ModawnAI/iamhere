import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Singleton class for managing global application state
class AppState {
  // Private constructor to prevent direct instantiation
  AppState._() {
    // Initialize app state
    _preloadModel();
  }

  // Static instance variable
  static AppState? _instance;

  // Getter for singleton instance with lazy initialization
  static AppState get instance {
    _instance ??= AppState._();
    return _instance!;
  }

  // ValueNotifier for selected model path
  final ValueNotifier<String?> selectedModelPath = ValueNotifier<String?>(null);

  // Preload the Nike 3D model automatically
  Future<void> _preloadModel() async {
    try {
      print('📦 Starting to preload Nike model...');

      // On web, use asset path directly without file system
      if (kIsWeb) {
        print('📦 Web platform detected - using direct asset path');
        selectedModelPath.value = 'assets/nike_2.glb';
        print('📦 Nike model path set for web successfully!');
        return;
      }

      // Get the app's temporary directory
      final tempDir = await getTemporaryDirectory();
      final modelPath = '${tempDir.path}/nike_2.glb';

      // Check if the model already exists in temp directory
      final modelFile = File(modelPath);
      if (!modelFile.existsSync()) {
        print('📦 Copying model from assets to temp directory...');

        // Load the asset
        final data = await rootBundle.load('assets/nike_2.glb');
        final bytes = data.buffer.asUint8List();

        // Write to temporary file
        await modelFile.writeAsBytes(bytes);
        print('📦 Model copied successfully to: $modelPath');
      } else {
        print('📦 Model already exists in temp directory');
      }

      // Set the model path
      selectedModelPath.value = modelPath;
      print('📦 Nike model preloaded successfully!');
    } catch (e) {
      print('❌ Error preloading model: $e');
      // Don't set a model path if loading fails
    }
  }

  // Method to update the selected model path
  void updateSelectedModelPath(String? path) {
    selectedModelPath.value = path;
  }

  // Method to clear the selected model path
  void clearSelectedModelPath() {
    selectedModelPath.value = null;
  }

  // Getter to check if a model is selected
  bool get hasSelectedModel => selectedModelPath.value != null;

  // Dispose method for cleanup (to be called when app terminates)
  void dispose() {
    selectedModelPath.dispose();
  }
}
