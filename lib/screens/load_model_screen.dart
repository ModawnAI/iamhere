import 'package:flutter/material.dart';
import 'package:iamhere_demo/state/app_state.dart';

/// Load Model screen showing preloaded 3D model status
class LoadModelScreen extends StatefulWidget {
  const LoadModelScreen({super.key});

  @override
  State<LoadModelScreen> createState() => _LoadModelScreenState();
}

class _LoadModelScreenState extends State<LoadModelScreen> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Icon section
              Flexible(
                flex: 2,
                child: Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(60),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.view_in_ar,
                      size: 60,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
              
              // Content section
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    const Text(
                      'Load 3D Model',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    Text(
                      'The Nike Dunk Low 3D model is preloaded and ready for your augmented reality experience',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Model Ready Status
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.green.shade300,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade600,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Nike Dunk Low Model Ready!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your 3D model is preloaded and ready for AR experience',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bottom section with navigation hint
              Flexible(
                flex: 1,
                child: Center(
                  child: Text(
                    'Go to the "Experience" tab to see the product details, then tap "View in Your Space" to start the AR experience!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
              
            ],
          ),
        ),
      ),
    );
  }
} 