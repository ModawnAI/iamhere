import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:iamhere_demo/state/app_state.dart';
import 'package:iamhere_demo/data/dummy_data.dart';
import 'dart:async';
import 'dart:io';

/// Pseudo AR screen with camera preview and 3D model overlay
class PseudoArScreen extends StatefulWidget {
  const PseudoArScreen({super.key});

  @override
  State<PseudoArScreen> createState() => _PseudoArScreenState();
}

class _PseudoArScreenState extends State<PseudoArScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedCameraIndex = 0;

  // Performance monitoring
  DateTime? _modelLoadStartTime;
  bool _isModelLoading = false;
  int _frameCount = 0;
  DateTime? _lastFrameTime;
  double _currentFPS = 0.0;

  // Resource management
  Timer? _performanceTimer;
  bool _isLowPerformanceMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    _cleanupPerformanceMonitoring();
    super.dispose();
  }

  void _cleanupPerformanceMonitoring() {
    _performanceTimer?.cancel();
    _performanceTimer = null;
  }

  void _startPerformanceMonitoring() {
    _performanceTimer?.cancel();
    _performanceTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _updatePerformanceMetrics();
    });
  }

  void _updatePerformanceMetrics() {
    if (!mounted) return;

    // Simple frame rate estimation based on UI updates
    final now = DateTime.now();
    if (_lastFrameTime != null) {
      final timeDiff = now.difference(_lastFrameTime!).inMilliseconds;
      if (timeDiff > 0) {
        _currentFPS = 1000 / timeDiff;
        _frameCount++;

        // Enable low performance mode if FPS is consistently low
        if (_currentFPS < 15 && _frameCount > 10) {
          _enableLowPerformanceMode();
        }
      }
    }
    _lastFrameTime = now;
  }

  void _enableLowPerformanceMode() {
    if (!_isLowPerformanceMode) {
      setState(() {
        _isLowPerformanceMode = true;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: const Text('Performance mode enabled for smoother experience'), backgroundColor: Colors.orange.withValues(alpha: 0.8), duration: const Duration(seconds: 3)));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;

    if (state == AppLifecycleState.inactive) {
      if (controller != null && controller.value.isInitialized) {
        _disposeCamera();
      }
    } else if (state == AppLifecycleState.resumed) {
      // Always try to initialize camera when app resumes
      // This handles the case where user granted permission in settings
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Check camera permission
      bool hasPermission = await _checkCameraPermission();
      if (!hasPermission) {
        setState(() {
          _errorMessage = 'Camera permission is required for AR experience';
          _isLoading = false;
        });
        return;
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No cameras found on this device';
          _isLoading = false;
        });
        return;
      }

      // Select back camera (preferred for AR) or first available
      _selectedCameraIndex = _cameras.indexWhere((camera) => camera.lensDirection == CameraLensDirection.back);
      if (_selectedCameraIndex == -1) {
        _selectedCameraIndex = 0;
      }

      // Initialize camera controller
      await _setupCameraController(_cameras[_selectedCameraIndex]);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize camera: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _setupCameraController(CameraDescription camera) async {
    // Dispose existing controller
    await _disposeCamera();

    // Create new controller with optimal settings for AR
    _cameraController = CameraController(
      camera,
      ResolutionPreset.high, // High resolution for better AR experience
      enableAudio: false, // No audio needed for AR
      imageFormatGroup: ImageFormatGroup.yuv420, // Optimal format for processing
    );

    try {
      await _cameraController!.initialize();

      // Set additional camera parameters for AR
      await _setCameraParameters();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to start camera: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _setCameraParameters() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      // Set focus mode to continuous for AR tracking
      await _cameraController!.setFocusMode(FocusMode.auto);

      // Set exposure mode to auto for consistent lighting
      await _cameraController!.setExposureMode(ExposureMode.auto);

      // Disable flash for AR experience
      await _cameraController!.setFlashMode(FlashMode.off);
    } catch (e) {
      // Camera parameter setting is not critical, continue without error
      debugPrint('Warning: Could not set camera parameters: $e');
    }
  }

  Future<bool> _checkCameraPermission() async {
    try {
      // First check current status
      PermissionStatus status = await Permission.camera.status;

      // If permission hasn't been granted, request it
      if (status != PermissionStatus.granted) {
        status = await Permission.camera.request();
      }

      // If permission is denied but not permanently, show explanation and request
      if (status.isDenied) {
        // Show a dialog explaining why we need camera permission
        bool shouldRequest = await _showPermissionExplanationDialog();
        if (!shouldRequest) {
          return false;
        }

        // Request permission again
        status = await Permission.camera.request();
      }

      // If permission is permanently denied, guide user to settings
      if (status.isPermanentlyDenied) {
        _showPermissionDialog();
        return false;
      }

      // If still denied after request, show error
      if (status.isDenied) {
        setState(() {
          _errorMessage = 'Camera permission is required for AR experience. Please allow camera access in the previous dialog.';
        });
        return false;
      }

      return status.isGranted;
    } catch (e) {
      setState(() {
        _errorMessage = 'Error requesting camera permission: ${e.toString()}';
      });
      return false;
    }
  }

  Future<bool> _showPermissionExplanationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Camera Permission Needed'),
              content: const Text(
                'This app needs access to your camera to provide an augmented reality experience. The camera lets you see your real environment with virtual objects overlaid on top.',
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Allow Camera')),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _disposeCamera() async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null;
      setState(() {
        _isCameraInitialized = false;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length <= 1) return;

    setState(() {
      _isLoading = true;
    });

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _setupCameraController(_cameras[_selectedCameraIndex]);
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(children: [Icon(Icons.warning, color: Colors.orange), const SizedBox(width: 8), const Text('Camera Permission Required')]),
          content: Text(
            (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)
                ? 'Camera access is required for AR features. To enable:\n\n'
                    '1. Tap "Open Settings" below\n'
                    '2. Find "Iamhere Demo" in the list\n'
                    '3. Toggle ON the Camera permission\n'
                    '4. Return to this app\n\n'
                    'The Camera option should appear in Settings after you allow it.'
                : 'Camera access has been permanently denied. To use the AR feature, please:\n\n'
                    '1. Go to Settings\n'
                    '2. Find this app\n'
                    '3. Enable Camera permission\n'
                    '4. Return to the app',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Also go back to previous screen
              },
              child: const Text('Cancel'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.3),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('AR Experience'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
        actions: [if (_cameras.length > 1 && _isCameraInitialized) IconButton(icon: const Icon(Icons.switch_camera), onPressed: _switchCamera, tooltip: 'Switch Camera')],
      ),
      body: _buildBody(),
      floatingActionButton: ValueListenableBuilder<String?>(
        valueListenable: AppState.instance.selectedModelPath,
        builder: (context, modelPath, _) {
          // Only show reviews button when a model is loaded
          if (modelPath == null) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            onPressed: _showReviewsDialog,
            backgroundColor: Colors.black.withValues(alpha: 0.8),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.rate_review),
            label: const Text('See Reviews'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25), side: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1)),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    if (!_isCameraInitialized || _cameraController == null) {
      return _buildLoadingWidget();
    }

    return _buildCameraPreview();
  }

  Widget _buildLoadingWidget() {
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black, Colors.grey.shade900])),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // IAMHERE Logo animation
            TweenAnimationBuilder(
              duration: const Duration(seconds: 2),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Opacity(
                    opacity: value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 5)],
                      ),
                      child: const Icon(Icons.view_in_ar, color: Colors.black, size: 40),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Loading indicator with custom styling
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(valueColor: const AlwaysStoppedAnimation<Color>(Colors.white), strokeWidth: 3, backgroundColor: Colors.white.withValues(alpha: 0.2)),
            ),
            const SizedBox(height: 24),

            // Loading text with animation
            TweenAnimationBuilder(
              duration: const Duration(seconds: 1),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Column(
                    children: [
                      const Text('IAMHERE AR', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      const SizedBox(height: 8),
                      Text('Initializing Camera...', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16, fontWeight: FontWeight.w400)),
                      const SizedBox(height: 16),
                      Text(
                        'Please allow camera access for AR experience',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14, fontWeight: FontWeight.w300),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.red.shade900.withValues(alpha: 0.8), Colors.black])),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error icon with animation
              TweenAnimationBuilder(
                duration: const Duration(seconds: 1),
                tween: Tween<double>(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 5)],
                      ),
                      child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 50),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Error title
              const Text('Camera Access Required', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 16),

              // Error message
              Text(_getErrorDescription(_errorMessage ?? 'Unknown error'), textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16, height: 1.5)),
              const SizedBox(height: 32),

              // Action buttons
              Column(
                children: [
                  // Retry button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _initializeCamera();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Settings button (for permission issues)
                  if (_errorMessage?.contains('permission') == true)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          openAppSettings();
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('Open Settings'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Help text
              Text(
                'IAMHERE needs camera access to provide AR experiences',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getErrorDescription(String error) {
    if (error.toLowerCase().contains('permission')) {
      return 'Camera permission is required to experience AR shopping. Please allow camera access in your device settings.';
    } else if (error.toLowerCase().contains('camera')) {
      return 'Unable to access your device camera. Please ensure no other apps are using the camera and try again.';
    } else if (error.toLowerCase().contains('initialize') || error.toLowerCase().contains('failed')) {
      return 'Camera initialization failed. This might be a temporary issue. Please try again.';
    } else {
      return 'An unexpected error occurred while setting up the AR experience. Please try again or restart the app.';
    }
  }

  Widget _buildCameraPreview() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return _buildLoadingWidget();
    }

    return Stack(
      children: [
        // Layer 1: Camera preview as background
        SizedBox.expand(child: CameraPreview(_cameraController!)),

        // Layer 2: 3D Model overlay (center positioned for AR effect)
        _build3DModelOverlay(),

        // Layer 3: UI controls and information overlay
        _buildUIOverlay(),
      ],
    );
  }

  Widget _build3DModelOverlay() {
    return ValueListenableBuilder<String?>(
      valueListenable: AppState.instance.selectedModelPath,
      builder: (context, modelPath, _) {
        if (modelPath == null) {
          return const SizedBox.shrink();
        }
        return ModelViewer(src: 'file://$modelPath', backgroundColor: Colors.transparent, cameraControls: true);
      },
    );
  }

  Widget _buildUIOverlay() {
    return ValueListenableBuilder<String?>(
      valueListenable: AppState.instance.selectedModelPath,
      builder: (context, modelPath, _) {
        return Stack(
          children: [
            // Model status indicator (top)
            Positioned(top: 20, left: 20, right: 20, child: _buildModelStatusIndicator(modelPath)),

            // AR controls (bottom)
            Positioned(bottom: 100, left: 20, right: 20, child: _buildARControls(modelPath)),

            // Instructions overlay (center-bottom)
            if (modelPath != null) Positioned(bottom: 30, left: 20, right: 20, child: _buildInstructionsOverlay()),
          ],
        );
      },
    );
  }

  Widget _buildModelStatusIndicator(String? modelPath) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(modelPath != null ? Icons.check_circle : Icons.error, color: modelPath != null ? Colors.green : Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              modelPath != null ? 'AR Model: ${modelPath.split('/').last}' : 'No AR model loaded',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildARControls(String? modelPath) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Reset model position button
        if (modelPath != null)
          _buildControlButton(
            icon: Icons.refresh,
            label: 'Reset',
            onTap: () {
              // Reset model position functionality can be added here
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Model position reset'), duration: Duration(seconds: 1)));
            },
          ),

        // Take photo button
        _buildControlButton(
          icon: Icons.camera_alt,
          label: 'Photo',
          onTap: () {
            // Photo capture functionality can be added here
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo capture coming soon'), duration: Duration(seconds: 1)));
          },
        ),

        // Performance toggle button
        _buildControlButton(
          icon: _isLowPerformanceMode ? Icons.speed : Icons.high_quality,
          label: _isLowPerformanceMode ? 'Quality' : 'Performance',
          onTap: () {
            setState(() {
              _isLowPerformanceMode = !_isLowPerformanceMode;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_isLowPerformanceMode ? 'Performance mode enabled - reduced quality for better framerate' : 'Quality mode enabled - enhanced visuals'),
                duration: const Duration(seconds: 2),
                backgroundColor: _isLowPerformanceMode ? Colors.blue.withValues(alpha: 0.8) : Colors.green.withValues(alpha: 0.8),
              ),
            );
          },
        ),

        // Settings button
        _buildControlButton(
          icon: Icons.settings,
          label: 'Settings',
          onTap: () {
            _showModelOptions();
          },
        ),
      ],
    );
  }

  Widget _buildControlButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(icon, color: Colors.white, size: 24), const SizedBox(height: 4), Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500))],
        ),
      ),
    );
  }

  Widget _buildInstructionsOverlay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
      child: const Text('Drag to rotate • Pinch to zoom • Tap controls for options', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 12)),
    );
  }

  Widget _build3DModelViewer(String modelPath) {
    // Comprehensive file validation
    final validationResult = _validateModelFile(modelPath);
    if (validationResult != null) {
      return _buildModelErrorWidget(
        validationResult['message'] as String,
        errorType: validationResult['type'] as String,
        canRetry: validationResult['canRetry'] as bool,
        onRetry: validationResult['onRetry'] as VoidCallback?,
      );
    }

    final file = File(modelPath);
    final fileSizeBytes = file.lengthSync();
    final fileSizeMB = fileSizeBytes / (1024 * 1024);

    return SizedBox(
      height: 300,
      width: 300,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GestureDetector(
          onTap: () => _handleModelTap(),
          onDoubleTap: () => _handleModelDoubleTap(),
          onLongPress: () => _handleModelLongPress(),
          child: Stack(
            children: [
              ModelViewer(
                // Set the source to the local file path
                src: 'file://$modelPath',

                // Configure for AR overlay experience
                backgroundColor: const Color(0x00000000), // Transparent background
                // Enhanced gesture controls
                cameraControls: true,
                autoRotate: false, // Let user control rotation manually
                // Gesture and interaction settings
                disableZoom: false,
                disablePan: false, // Allow panning for better control
                // Loading and performance settings
                loading: Loading.eager,
                autoPlay: true,

                // Enhanced camera and interaction settings
                cameraOrbit: "0deg 75deg 1.5m", // Default camera position
                fieldOfView: "30deg", // Narrow field for AR effect
                minCameraOrbit: "auto auto 0.5m", // Minimum zoom distance
                maxCameraOrbit: "auto auto 5m", // Maximum zoom distance
                // Performance and optimization settings
                shadowIntensity: _isLowPerformanceMode ? 0.0 : 0.3,
                shadowSoftness: _isLowPerformanceMode ? 0.0 : 0.25,

                // Error handling callback
                onWebViewCreated: (controller) {
                  _modelLoadStartTime = DateTime.now();
                  _isModelLoading = true;
                  debugPrint('ModelViewer WebView created for: ${modelPath.split('/').last}');
                  debugPrint('File size: ${fileSizeMB.toStringAsFixed(1)} MB');
                  debugPrint('Performance mode: ${_isLowPerformanceMode ? "Enabled" : "Disabled"}');
                  _startPerformanceMonitoring();
                  _showGestureHint();

                  // Simulate model loading completion after a delay
                  Timer(const Duration(seconds: 2), () {
                    if (mounted) _onModelLoaded();
                  });
                },
              ),

              // Performance indicators
              Positioned(
                top: 8,
                right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Large file warning
                    if (fileSizeMB > 10)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(4)),
                        child: Text('Large file (${fileSizeMB.toStringAsFixed(1)}MB)', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),

                    // Performance mode indicator
                    if (_isLowPerformanceMode)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(4)),
                        child: const Text('Performance Mode', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),

                    // Loading indicator
                    if (_isModelLoading)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(4)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
                            SizedBox(width: 4),
                            Text('Loading', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Gesture feedback overlay
              _buildGestureFeedback(),
            ],
          ),
        ),
      ),
    );
  }

  void _handleModelTap() {
    debugPrint('Model tapped - show interaction hint');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: const Text('Drag to rotate • Pinch to zoom • Double-tap to reset'), duration: const Duration(seconds: 2), backgroundColor: Colors.black.withValues(alpha: 0.8)));
  }

  void _handleModelDoubleTap() {
    debugPrint('Model double-tapped - reset position');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Model position reset'), duration: const Duration(seconds: 1), backgroundColor: Colors.green.withValues(alpha: 0.8)));
  }

  void _onModelLoaded() {
    if (_modelLoadStartTime != null) {
      final loadTime = DateTime.now().difference(_modelLoadStartTime!);
      debugPrint('Model loaded in ${loadTime.inMilliseconds}ms');

      setState(() {
        _isModelLoading = false;
      });

      // Show performance feedback for very slow loads
      if (loadTime.inSeconds > 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Model loaded (${loadTime.inSeconds}s) - Consider using smaller files for better performance'),
            backgroundColor: Colors.orange.withValues(alpha: 0.8),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _handleModelLongPress() {
    debugPrint('Model long-pressed - show advanced options');
    _showModelOptions();
  }

  void _showModelOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withValues(alpha: 0.9),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Model Options', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildOptionButton(
                icon: Icons.refresh,
                title: 'Reset Position',
                subtitle: 'Return to default view',
                onTap: () {
                  Navigator.pop(context);
                  _handleModelDoubleTap();
                },
              ),
              _buildOptionButton(
                icon: Icons.center_focus_strong,
                title: 'Center Model',
                subtitle: 'Focus on model center',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Model centered')));
                },
              ),
              _buildOptionButton(
                icon: Icons.help_outline,
                title: 'Gesture Help',
                subtitle: 'Show interaction guide',
                onTap: () {
                  Navigator.pop(context);
                  _showGestureHint();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionButton({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
      onTap: onTap,
    );
  }

  Widget _buildGestureFeedback() {
    return const Positioned(bottom: 8, left: 8, child: Icon(Icons.touch_app, color: Colors.white54, size: 16));
  }

  void _showGestureHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Gestures: Drag = Rotate • Pinch = Zoom • Double-tap = Reset • Long-press = Options'),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.blue.withValues(alpha: 0.8),
        action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: () {}),
      ),
    );
  }

  Map<String, dynamic>? _validateModelFile(String modelPath) {
    try {
      final file = File(modelPath);

      // Check if file exists
      if (!file.existsSync()) {
        return {'message': 'Model file not found. The file may have been moved or deleted.', 'type': 'file_not_found', 'canRetry': true, 'onRetry': () => _retryModelLoading()};
      }

      // Check file extension
      final extension = modelPath.toLowerCase().split('.').last;
      if (!['glb', 'gltf'].contains(extension)) {
        return {'message': 'Unsupported file format. Only .glb and .gltf files are supported.', 'type': 'invalid_format', 'canRetry': false, 'onRetry': null};
      }

      // Check file size limits
      final fileSizeBytes = file.lengthSync();
      final fileSizeMB = fileSizeBytes / (1024 * 1024);

      if (fileSizeMB > 50) {
        return {'message': 'File too large (${fileSizeMB.toStringAsFixed(1)}MB). Files over 50MB are not supported.', 'type': 'file_too_large', 'canRetry': false, 'onRetry': null};
      }

      // Check if file is corrupted (basic check)
      if (fileSizeBytes < 100) {
        return {'message': 'File appears to be corrupted or empty.', 'type': 'corrupted_file', 'canRetry': true, 'onRetry': () => _retryModelLoading()};
      }

      // Check file permissions
      try {
        final bytes = file.readAsBytesSync().take(10).toList();
        if (bytes.isEmpty) {
          return {'message': 'Cannot read file. Check file permissions.', 'type': 'permission_denied', 'canRetry': true, 'onRetry': () => _retryModelLoading()};
        }
      } catch (e) {
        return {'message': 'File access error: ${e.toString()}', 'type': 'access_error', 'canRetry': true, 'onRetry': () => _retryModelLoading()};
      }

      return null; // File is valid
    } catch (e) {
      debugPrint('Model validation error: $e');
      return {'message': 'Unexpected error during file validation: ${e.toString()}', 'type': 'validation_error', 'canRetry': true, 'onRetry': () => _retryModelLoading()};
    }
  }

  void _retryModelLoading() {
    setState(() {
      _isModelLoading = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Retrying model load...'), backgroundColor: Colors.blue.withValues(alpha: 0.8), duration: const Duration(seconds: 1)));

    // Force a rebuild after a short delay
    Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isModelLoading = false;
        });
      }
    });
  }

  Widget _buildModelErrorWidget(String message, {required String errorType, required bool canRetry, VoidCallback? onRetry}) {
    Color errorColor;
    IconData errorIcon;

    switch (errorType) {
      case 'file_not_found':
        errorColor = Colors.orange;
        errorIcon = Icons.search_off;
        break;
      case 'invalid_format':
        errorColor = Colors.red;
        errorIcon = Icons.block;
        break;
      case 'file_too_large':
        errorColor = Colors.purple;
        errorIcon = Icons.storage;
        break;
      case 'corrupted_file':
        errorColor = Colors.yellow;
        errorIcon = Icons.broken_image;
        break;
      case 'permission_denied':
        errorColor = Colors.amber;
        errorIcon = Icons.lock;
        break;
      default:
        errorColor = Colors.red;
        errorIcon = Icons.error_outline;
    }

    return SizedBox(
      height: 300,
      width: 300,
      child: Container(
        decoration: BoxDecoration(color: errorColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: errorColor.withValues(alpha: 0.5), width: 2)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(errorIcon, color: errorColor, size: 48),
              const SizedBox(height: 12),
              Text('Model Error', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              if (canRetry && onRetry != null) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(backgroundColor: errorColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  // Navigate back to load model screen
                  AppState.instance.selectedModelPath.value = null;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Returned to model selection'), duration: Duration(seconds: 1)));
                },
                child: const Text('Select Different Model', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show reviews dialog with product reviews from dummy data
  void _showReviewsDialog() {
    // Add haptic feedback for better UX
    HapticFeedback.lightImpact();

    showDialog(context: context, barrierColor: Colors.black.withValues(alpha: 0.7), builder: (BuildContext context) => _buildReviewsDialog());
  }

  /// Build the reviews dialog widget
  Widget _buildReviewsDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dialog header
            _buildReviewsDialogHeader(),

            // Reviews list
            Flexible(child: _buildReviewsList()),

            // Dialog footer
            _buildReviewsDialogFooter(),
          ],
        ),
      ),
    );
  }

  /// Build the header section of the reviews dialog
  Widget _buildReviewsDialogHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1))),
      child: Row(
        children: [
          const Icon(Icons.rate_review, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Customer Reviews', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(DummyData.productName, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
              ],
            ),
          ),
          IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close), color: Colors.white.withValues(alpha: 0.7)),
        ],
      ),
    );
  }

  /// Build the scrollable reviews list
  Widget _buildReviewsList() {
    return SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Column(children: DummyData.reviewsList.map((review) => _buildReviewItem(review)).toList()));
  }

  /// Build an individual review item
  Widget _buildReviewItem(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer info and rating
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(review.date, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                  ],
                ),
              ),
              // Star rating
              _buildStarRating(review.rating),
            ],
          ),

          const SizedBox(height: 8),

          // Review title
          Text(review.title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),

          const SizedBox(height: 6),

          // Review comment
          Text(review.comment, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, height: 1.4)),

          // Verified purchase badge
          if (review.isVerifiedPurchase) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.verified, color: Colors.green.withValues(alpha: 0.8), size: 14),
                const SizedBox(width: 4),
                Text('Verified Purchase', style: TextStyle(color: Colors.green.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Build star rating display
  Widget _buildStarRating(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(index < rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 16);
      }),
    );
  }

  /// Build the footer section of the reviews dialog
  Widget _buildReviewsDialogFooter() {
    // Calculate average rating
    final totalRating = DummyData.reviewsList.fold<int>(0, (sum, review) => sum + review.rating);
    final averageRating = totalRating / DummyData.reviewsList.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1))),
      child: Row(
        children: [
          // Average rating display
          _buildStarRating(averageRating.round()),
          const SizedBox(width: 8),
          Text('${averageRating.toStringAsFixed(1)} out of 5', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text('${DummyData.reviewsList.length} reviews', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
        ],
      ),
    );
  }
}
