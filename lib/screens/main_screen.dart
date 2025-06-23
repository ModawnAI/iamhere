import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:iamhere_demo/screens/home_screen.dart';
import 'package:iamhere_demo/screens/experience_screen.dart';
import 'package:iamhere_demo/screens/load_model_screen.dart';
import 'package:iamhere_demo/services/camera_permission_service.dart';

/// Main screen that contains the scaffold and bottom navigation
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Current selected index for bottom navigation
  int _currentIndex = 0;
  
  // Page controller for managing page transitions
  final PageController _pageController = PageController();
  
  // Navigation callback function
  void _onTabTapped(int index) async {
    // If user is trying to access Experience screen (index 1), check camera permission first
    if (index == 1) {
      await _ensureCameraPermissionSetup();
    }
    
    setState(() {
      _currentIndex = index;
    });
    
    // Navigate to the selected page
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  
  Future<void> _ensureCameraPermissionSetup() async {
    try {
      print('🎥 MainScreen: Ensuring camera permission before accessing Experience tab...');
      
      // Use the comprehensive permission service
      await CameraPermissionService.ensureCameraPermission(context);
      
      // Also force a request to be absolutely sure iOS knows about it
      await CameraPermissionService.forceRequestCameraPermission();
      
      print('🎥 MainScreen: Camera permission setup complete');
    } catch (e) {
      print('🎥 MainScreen: Error during camera permission setup: $e');
    }
  }
  
  // Screens for each tab - now using late initialization
  late final List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    // Initialize screens with the navigation callback
    _screens = [
      HomeScreen(onNavigateToTab: _onTabTapped),
      const ExperienceScreen(),
      const LoadModelScreen(),
    ];
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'IAMHERE',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Experience',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file),
            label: 'Load Model',
          ),
        ],
      ),
    );
  }
} 