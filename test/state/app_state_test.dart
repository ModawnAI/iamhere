import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere_demo/state/app_state.dart';

void main() {
  group('AppState Singleton Tests', () {
    test('should return the same instance when accessed multiple times', () {
      // Get first instance
      final instance1 = AppState.instance;
      
      // Get second instance
      final instance2 = AppState.instance;
      
      // Verify they are the same instance
      expect(instance1, same(instance2));
      expect(identical(instance1, instance2), isTrue);
    });
    
    test('should initialize with null selectedModelPath', () {
      final appState = AppState.instance;
      
      expect(appState.selectedModelPath.value, isNull);
      expect(appState.hasSelectedModel, isFalse);
    });
  });
  
  group('ValueNotifier Functionality Tests', () {
    late AppState appState;
    
    setUp(() {
      appState = AppState.instance;
      // Clear any previous state
      appState.clearSelectedModelPath();
    });
    
    test('should update selectedModelPath when updateSelectedModelPath is called', () {
      const testPath = '/test/model/path.glb';
      
      appState.updateSelectedModelPath(testPath);
      
      expect(appState.selectedModelPath.value, equals(testPath));
      expect(appState.hasSelectedModel, isTrue);
    });
    
    test('should clear selectedModelPath when clearSelectedModelPath is called', () {
      // First set a path
      appState.updateSelectedModelPath('/some/path.glb');
      expect(appState.hasSelectedModel, isTrue);
      
      // Then clear it
      appState.clearSelectedModelPath();
      
      expect(appState.selectedModelPath.value, isNull);
      expect(appState.hasSelectedModel, isFalse);
    });
    
    test('should notify listeners when model path changes', () {
      int notificationCount = 0;
      String? lastValue;
      
      // Add listener
      void listener() {
        notificationCount++;
        lastValue = appState.selectedModelPath.value;
      }
      
      appState.selectedModelPath.addListener(listener);
      
      // Update path
      appState.updateSelectedModelPath('/test1.glb');
      expect(notificationCount, equals(1));
      expect(lastValue, equals('/test1.glb'));
      
      // Update again
      appState.updateSelectedModelPath('/test2.glb');
      expect(notificationCount, equals(2));
      expect(lastValue, equals('/test2.glb'));
      
      // Clear path
      appState.clearSelectedModelPath();
      expect(notificationCount, equals(3));
      expect(lastValue, isNull);
      
      // Clean up
      appState.selectedModelPath.removeListener(listener);
    });
    
    test('should handle null values correctly', () {
      appState.updateSelectedModelPath(null);
      
      expect(appState.selectedModelPath.value, isNull);
      expect(appState.hasSelectedModel, isFalse);
    });
  });
  
  group('Edge Cases and Error Handling', () {
    test('should handle empty string path', () {
      final appState = AppState.instance;
      
      appState.updateSelectedModelPath('');
      
      expect(appState.selectedModelPath.value, equals(''));
      // Empty string is still considered as having a model
      expect(appState.hasSelectedModel, isTrue);
    });
    
    test('should handle very long paths', () {
      final appState = AppState.instance;
      final longPath = '/very/long/path/that/might/exceed/normal/limits/' + 
                      'with/many/subdirectories/and/a/really/long/filename_' +
                      'that_goes_on_and_on_and_on.glb';
      
      appState.updateSelectedModelPath(longPath);
      
      expect(appState.selectedModelPath.value, equals(longPath));
      expect(appState.hasSelectedModel, isTrue);
    });
    
    test('should handle rapid updates', () {
      final appState = AppState.instance;
      int notificationCount = 0;
      
      appState.selectedModelPath.addListener(() {
        notificationCount++;
      });
      
      // Rapid updates
      for (int i = 0; i < 100; i++) {
        appState.updateSelectedModelPath('/path$i.glb');
      }
      
      expect(notificationCount, equals(100));
      expect(appState.selectedModelPath.value, equals('/path99.glb'));
      
      appState.selectedModelPath.removeListener(() {});
    });
  });
} 