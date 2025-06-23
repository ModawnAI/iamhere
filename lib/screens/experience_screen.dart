import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iamhere_demo/data/dummy_data.dart';
import 'package:iamhere_demo/state/app_state.dart';
import 'package:iamhere_demo/screens/pseudo_ar_screen.dart';
import 'package:iamhere_demo/services/camera_permission_service.dart';

/// Experience screen displaying product information
class ExperienceScreen extends StatelessWidget {
  const ExperienceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image Section
            Container(
              height: 400,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey.shade200,
                    Colors.grey.shade100,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Product Image
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      child: Image.asset(
                        'lib/data/nike.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to placeholder if image fails to load
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 120,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Product Image',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Price tag overlay
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        DummyData.productPrice,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Product Information Section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name and Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          DummyData.productName,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _buildRatingDisplay(),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Product Description
                  Text(
                    DummyData.productDescription,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Product Features
                  const Text(
                    'Features',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...DummyData.productFeatures.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 20,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 24),
                  
                  // AR Button
                  Center(
                    child: ValueListenableBuilder<String?>(
                      valueListenable: AppState.instance.selectedModelPath,
                      builder: (context, modelPath, _) {
                        return ElevatedButton(
                          onPressed: () async {
                            print('🎥 AR Button pressed! Model path: $modelPath');
                            
                            if (modelPath == null) {
                              // Haptic feedback for error
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please load a 3D model first'),
                                  backgroundColor: Colors.orange,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }

                            // AGGRESSIVE camera permission check before navigating
                            print('🎥 Ensuring camera permission before AR navigation...');
                            final hasPermission = await CameraPermissionService.ensureCameraPermission(context);
                            
                            if (hasPermission) {
                              // Haptic feedback for success
                              HapticFeedback.mediumImpact();
                              print('🎥 Camera permission granted! Navigating to AR screen...');
                              
                              // Navigate to PseudoArScreen
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const PseudoArScreen(),
                                ),
                              );
                            } else {
                              print('🎥 Camera permission denied, cannot proceed to AR');
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Camera access is required for AR features'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.view_in_ar, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'View in Your Space',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRatingDisplay() {
    // Calculate average rating
    double averageRating = DummyData.reviewsList
        .map((r) => r.rating.toDouble())
        .reduce((a, b) => a + b) / DummyData.reviewsList.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < averageRating.round()
                  ? Icons.star
                  : Icons.star_border,
              color: Colors.amber,
              size: 20,
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          '${averageRating.toStringAsFixed(1)} (${DummyData.reviewsList.length} reviews)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
} 