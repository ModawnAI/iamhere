import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:iamhere_demo/screens/main_screen.dart';
import 'package:iamhere_demo/services/camera_permission_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style for better branding
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  // Request camera permission immediately on app startup
  _requestCameraPermissionOnStartup();
  
  runApp(const MyApp());
}

/// Aggressively request camera permission on app startup
/// This ensures iOS is immediately aware this app uses camera
Future<void> _requestCameraPermissionOnStartup() async {
  try {
    // Wait for app to fully initialize
    await Future.delayed(const Duration(milliseconds: 100));
    
    print('🎥 MAIN: Starting ULTRA-AGGRESSIVE camera permission requests...');
    
    // Method 1: Direct permission request
    try {
      final status1 = await Permission.camera.request();
      print('🎥 MAIN: Direct request result: $status1');
    } catch (e) {
      print('🎥 MAIN: Direct request error: $e');
    }
    
    // Method 2: Check then request
    try {
      final currentStatus = await Permission.camera.status;
      print('🎥 MAIN: Current status: $currentStatus');
      
      if (currentStatus != PermissionStatus.granted) {
        final status2 = await Permission.camera.request();
        print('🎥 MAIN: Secondary request result: $status2');
      }
    } catch (e) {
      print('🎥 MAIN: Secondary request error: $e');
    }
    
    // Method 3: Multiple rapid-fire requests to force iOS recognition
    for (int i = 0; i < 3; i++) {
      try {
        await Future.delayed(const Duration(milliseconds: 200));
        final status = await Permission.camera.request();
        print('🎥 MAIN: Rapid request $i result: $status');
        
        if (status == PermissionStatus.granted) {
          print('🎥 MAIN: ✅ SUCCESS! Camera permission granted on attempt $i');
          break;
        }
      } catch (e) {
        print('🎥 MAIN: Rapid request $i error: $e');
      }
    }
    
    // Final status check
    final finalStatus = await Permission.camera.status;
    print('🎥 MAIN: 🏁 FINAL camera permission status: $finalStatus');
    
    if (finalStatus == PermissionStatus.granted) {
      print('🎥 MAIN: 🎉 CAMERA PERMISSION SUCCESSFULLY GRANTED!');
    } else {
      print('🎥 MAIN: ⚠️ Camera permission not granted, but app will continue');
    }
    
  } catch (e) {
    print('🎥 MAIN: ❌ Critical error during permission requests: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Aggressively request camera permission as soon as the app widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _aggressivelyRequestCameraPermission();
    });
  }

  /// Multiple aggressive attempts to request camera permission
  Future<void> _aggressivelyRequestCameraPermission() async {
    print('🎥 MyApp: Starting aggressive camera permission requests...');
    
    // Wait a bit for the app to fully initialize
    await Future.delayed(const Duration(milliseconds: 500));
    
    try {
      // Attempt 1: Force request
      await CameraPermissionService.forceRequestCameraPermission();
      
      // Attempt 2: Check and request again if needed
      final isGranted = await CameraPermissionService.isCameraPermissionGranted();
      if (!isGranted && mounted) {
        print('🎥 MyApp: First attempt failed, trying comprehensive permission flow...');
        await CameraPermissionService.ensureCameraPermission(context);
      }
      
      // Attempt 3: One more force request to be absolutely sure
      await Future.delayed(const Duration(milliseconds: 1000));
      await CameraPermissionService.forceRequestCameraPermission();
      
      // Final status check
      final finalStatus = await CameraPermissionService.isCameraPermissionGranted();
      print('🎥 MyApp: Final camera permission status: $finalStatus');
      
    } catch (e) {
      print('🎥 MyApp: Error during aggressive permission requests: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IAMHERE - AR Shopping',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          brightness: Brightness.light,
          primary: Colors.black,
          secondary: Colors.grey[800]!,
        ),
        useMaterial3: true,
        
        // Enhanced app bar theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        
        // Enhanced bottom navigation theme
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 8,
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 11,
          ),
        ),
        
        // Enhanced button themes
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
        ),
        
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        
        // Enhanced card theme
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        
        // Enhanced text theme
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 32,
            letterSpacing: -0.5,
          ),
          headlineMedium: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 24,
            letterSpacing: 0,
          ),
          titleLarge: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
          bodyLarge: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w400,
            fontSize: 16,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w400,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
      home: const MainScreen(),
    );
  }
}
