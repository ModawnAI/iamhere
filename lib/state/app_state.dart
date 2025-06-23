import 'package:flutter/foundation.dart';

/// Singleton class for managing global application state
class AppState {
  // Private constructor to prevent direct instantiation
  AppState._() {
    // Automatically preload the Nike 3D model
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
  void _preloadModel() {
    // Set the path to the preloaded Nike model
    selectedModelPath.value = 'lib/data/nike.glb';
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