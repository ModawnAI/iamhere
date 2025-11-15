import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Comprehensive camera permission service
/// Ensures iOS is always aware this app uses camera
class CameraPermissionService {
  static const String _tag = '🎥 CameraPermissionService';
  
  /// Aggressively request camera permission with multiple retry attempts
  static Future<bool> ensureCameraPermission(BuildContext context) async {
    print('$_tag: Starting comprehensive camera permission check...');
    
    try {
      // Step 1: Initial status check
      PermissionStatus status = await Permission.camera.status;
      print('$_tag: Initial permission status: $status');
      
      // Step 2: If not granted, request with explanation
      if (status != PermissionStatus.granted) {
        // Show user why we need camera BEFORE requesting
        final shouldRequest = await _showPermissionExplanation(context);
        if (!shouldRequest) {
          print('$_tag: User declined permission explanation');
          return false;
        }
        
        // Request permission
        print('$_tag: Requesting camera permission...');
        status = await Permission.camera.request();
        print('$_tag: Permission request result: $status');
      }
      
      // Step 3: Handle different permission states
      switch (status) {
        case PermissionStatus.granted:
          print('$_tag: ✅ Camera permission granted!');
          return true;
          
        case PermissionStatus.denied:
          print('$_tag: ❌ Camera permission denied');
          await _handleDeniedPermission(context);
          return false;
          
        case PermissionStatus.permanentlyDenied:
          print('$_tag: ❌ Camera permission permanently denied');
          await _handlePermanentlyDeniedPermission(context);
          return false;
          
        case PermissionStatus.restricted:
          print('$_tag: ❌ Camera permission restricted');
          await _handleRestrictedPermission(context);
          return false;
          
        default:
          print('$_tag: ❓ Unknown permission status: $status');
          return false;
      }
    } catch (e) {
      print('$_tag: ❌ Error during permission request: $e');
      await _handlePermissionError(context, e);
      return false;
    }
  }
  
  /// Check if camera permission is currently granted
  static Future<bool> isCameraPermissionGranted() async {
    try {
      final status = await Permission.camera.status;
      print('$_tag: Current permission status: $status');
      return status == PermissionStatus.granted;
    } catch (e) {
      print('$_tag: Error checking permission status: $e');
      return false;
    }
  }
  
  /// Force a camera permission request (for aggressive permission seeking)
  static Future<PermissionStatus> forceRequestCameraPermission() async {
    try {
      print('$_tag: 🚀 FORCE requesting camera permission...');
      final status = await Permission.camera.request();
      print('$_tag: Force request result: $status');
      return status;
    } catch (e) {
      print('$_tag: Error during force request: $e');
      return PermissionStatus.denied;
    }
  }
  
  /// Show detailed explanation of why camera is needed
  static Future<bool> _showPermissionExplanation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.camera_alt, color: Colors.blue, size: 28),
              const SizedBox(width: 12),
              const Text('Camera Access Required'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'IAMHERE needs camera access to provide amazing AR experiences!',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text('What we use your camera for:'),
              const SizedBox(height: 8),
              _buildFeatureItem('📱', 'View products in your real space'),
              _buildFeatureItem('🎯', 'Place virtual items accurately'),
              _buildFeatureItem('✨', 'Create immersive shopping experiences'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Your privacy is protected. We never save or share camera data.',
                        style: TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Allow Camera'),
            ),
          ],
        );
      },
    ) ?? false;
  }
  
  static Widget _buildFeatureItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
  
  /// Handle denied permission
  static Future<void> _handleDeniedPermission(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              const SizedBox(width: 8),
              const Text('Camera Access Denied'),
            ],
          ),
          content: const Text(
            'Camera access was denied. You can change this in your device settings later if you want to try AR features.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }
  
  /// Handle permanently denied permission
  static Future<void> _handlePermanentlyDeniedPermission(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.block, color: Colors.red),
              const SizedBox(width: 8),
              const Text('Camera Access Required'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Camera access is permanently disabled. To enable AR features:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) ...[
                const Text('📱 iOS Steps:'),
                const SizedBox(height: 8),
                _buildStep('1.', 'Tap "Open Settings" below'),
                _buildStep('2.', 'Find "Iamhere Demo" in the app list'),
                _buildStep('3.', 'Toggle ON the Camera permission'),
                _buildStep('4.', 'Return to this app'),
              ] else ...[
                const Text('🤖 Android Steps:'),
                const SizedBox(height: 8),
                _buildStep('1.', 'Open Settings'),
                _buildStep('2.', 'Go to Apps > Iamhere Demo'),
                _buildStep('3.', 'Tap Permissions'),
                _buildStep('4.', 'Enable Camera'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }
  
  static Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              number,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
  
  /// Handle restricted permission (parental controls, etc.)
  static Future<void> _handleRestrictedPermission(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Camera Access Restricted'),
          content: const Text(
            'Camera access is restricted on this device, possibly due to parental controls or device management policies.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
  
  /// Handle permission errors
  static Future<void> _handlePermissionError(BuildContext context, dynamic error) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Error'),
          content: Text(
            'An error occurred while requesting camera permission: $error\n\n'
            'Please try again or check your device settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
} 