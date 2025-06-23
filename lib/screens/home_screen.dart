import 'package:flutter/material.dart';
import 'package:iamhere_demo/services/camera_permission_service.dart';

/// Home screen with IAMHERE branding and call-to-action
class HomeScreen extends StatefulWidget {
  final Function(int) onNavigateToTab;
  
  const HomeScreen({
    super.key,
    required this.onNavigateToTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
    ));
    
    _animationController.forward();
    
    // AGGRESSIVE: Request camera permission as soon as home screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestCameraPermissionOnHomeLoad();
    });
  }
  
  /// Request camera permission when home screen loads to ensure iOS knows about it
  Future<void> _requestCameraPermissionOnHomeLoad() async {
    try {
      print('🎥 HomeScreen: Proactively requesting camera permission...');
      
      // Wait for the home screen to settle, then request permission
      await Future.delayed(const Duration(milliseconds: 2000));
      
      if (mounted) {
        // Force a camera permission request to ensure iOS is aware
        await CameraPermissionService.forceRequestCameraPermission();
        print('🎥 HomeScreen: Camera permission request completed');
      }
    } catch (e) {
      print('🎥 HomeScreen: Error requesting camera permission: $e');
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFF5F5F5),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Logo/Brand Name
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: Text(
                              'IAH',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'IAMHERE',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Tagline
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Text(
                    'Augmented Reality Shopping',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black54,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const Spacer(),
                // Call-to-action button
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to Experience tab (index 1)
                        widget.onNavigateToTab(1);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                        shadowColor: Colors.black26,
                      ),
                      child: const Text(
                        'Experience the Future of Shopping',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 