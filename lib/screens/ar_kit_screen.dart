import 'dart:async';

import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:flutter/material.dart';
import 'package:iamhere_demo/data/dummy_data.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class ARKitScreen extends StatefulWidget {
  const ARKitScreen({super.key});

  @override
  State<ARKitScreen> createState() => _ARKitScreenState();
}

class _ARKitScreenState extends State<ARKitScreen> with TickerProviderStateMixin {
  late ARKitController arkitController;
  ARKitNode? nikeNode;
  bool _didAddNode = false;
  Timer? _timer;
  bool _showHelperText = true;
  bool _showReviewWidget = false;

  late AnimationController _reviewAnimationController;
  late Animation<double> _reviewOpacity;
  late Animation<Offset> _reviewSlide;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _showHelperText = false;
        });
      }
    });

    // Initialize animations for review widget
    _reviewAnimationController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);

    _reviewOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _reviewAnimationController, curve: Curves.easeInOut));

    _reviewSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(CurvedAnimation(parent: _reviewAnimationController, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    arkitController.dispose();
    _timer?.cancel();
    _reviewAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR View'),
        actions: [
          // Debug button to force show UI
          IconButton(
            icon: Icon(_showReviewWidget ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              print('🔧 Debug: Force toggle UI - Current state: $_showReviewWidget');
              if (_showReviewWidget) {
                _reviewAnimationController.reverse().then((_) {
                  if (mounted) {
                    setState(() {
                      _showReviewWidget = false;
                    });
                  }
                });
              } else {
                setState(() {
                  _showReviewWidget = true;
                });
                _reviewAnimationController.forward();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (nikeNode != null) {
                arkitController.remove(nikeNode!.name);
              }
              nikeNode = null;
              _didAddNode = false;
              _showReviewWidget = false;
              _reviewAnimationController.reset();
              setState(() {});
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // AR Camera View
          ARKitSceneView(planeDetection: ARPlaneDetection.horizontal, onARKitViewCreated: onARKitViewCreated, autoenablesDefaultLighting: true),

          // Debug status indicator
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('3D Model: ${_didAddNode ? "✅" : "❌"}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  Text('UI State: ${_showReviewWidget ? "✅" : "❌"}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ),

          // Helper text
          if (_showHelperText && !_didAddNode)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
                child: const Text('Move your phone around to detect a horizontal surface.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),

          // Review Widget Overlay - positioned in center area above 3D object
          if (_showReviewWidget)
            Positioned(
              top: 150, // Fixed position for better visibility
              left: 20,
              right: 20,
              child: SlideTransition(position: _reviewSlide, child: FadeTransition(opacity: _reviewOpacity, child: _buildReviewWidget(DummyData.reviewsList.first))),
            ),

          // Tap instruction for review widget
          if (_didAddNode && !_showReviewWidget)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.8), borderRadius: BorderRadius.circular(16)),
                child: const Text('Tap anywhere to show product review', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 14)),
              ),
            ),
        ],
      ),
    );
  }

  void onARKitViewCreated(ARKitController arkitController) {
    this.arkitController = arkitController;
    this.arkitController.onAddNodeForAnchor = _handleAddAnchor;
    this.arkitController.onARTap = _handleARTap;
    print('🎥 ARKit controller created');
  }

  void _handleARTap(List<ARKitTestResult> results) {
    print('🖱️ AR Tap detected! Results count: ${results.length}');
    print('🖱️ Current state - didAddNode: $_didAddNode, showReviewWidget: $_showReviewWidget');

    // Show snackbar for tap confirmation
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Tap detected! Model: $_didAddNode, UI: $_showReviewWidget'), duration: const Duration(seconds: 2), backgroundColor: Colors.green));

    if (_didAddNode && !_showReviewWidget) {
      print('🖱️ Showing review widget');
      setState(() {
        _showReviewWidget = true;
      });
      _reviewAnimationController.forward();

      // Auto-hide after 5 seconds
      Timer(const Duration(seconds: 5), () {
        if (mounted && _showReviewWidget) {
          print('🖱️ Auto-hiding review widget');
          _reviewAnimationController.reverse().then((_) {
            if (mounted) {
              setState(() {
                _showReviewWidget = false;
              });
            }
          });
        }
      });
    }
  }

  void _handleAddAnchor(ARKitAnchor anchor) {
    print('⚓ Anchor added: ${anchor.runtimeType}');
    if (anchor is! ARKitPlaneAnchor) {
      return;
    }
    if (!_didAddNode) {
      print('⚓ Adding 3D model node');
      _addNode(anchor);
      _didAddNode = true;
      setState(() {});

      // Show confirmation snackbar
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('3D model placed! Now you can tap to show review.'), duration: Duration(seconds: 3), backgroundColor: Colors.blue));
    }
  }

  void _addNode(ARKitPlaneAnchor anchor) {
    final node = ARKitGltfNode(
      assetType: AssetType.flutterAsset,
      url: 'assets/nike_2.glb',
      position: vector.Vector3(0, 0, 0),
      scale: vector.Vector3.all(0.15), // Reduced from 0.3 to 0.15 (half size)
      name: 'nike_model',
    );
    arkitController.add(node, parentNodeName: anchor.nodeName);
    nikeNode = node;
  }

  Widget _buildReviewWidget(Review review) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white.withOpacity(0.95),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.rate_review, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                Expanded(child: Text(review.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87))),
                GestureDetector(
                  onTap: () {
                    _reviewAnimationController.reverse().then((_) {
                      if (mounted) {
                        setState(() {
                          _showReviewWidget = false;
                        });
                      }
                    });
                  },
                  child: const Icon(Icons.close, color: Colors.grey, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Row(children: List.generate(5, (i) => Icon(i < review.rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 20))),
                const SizedBox(width: 8),
                Text('${review.rating}/5', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 12),
            Text(review.comment, style: const TextStyle(fontSize: 15, color: Colors.black54, height: 1.4)),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(review.userName[0].toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                ),
                const SizedBox(width: 8),
                Text(review.userName, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontWeight: FontWeight.w500)),
                if (review.isVerifiedPurchase) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Text('Verified', style: TextStyle(fontSize: 10, color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
