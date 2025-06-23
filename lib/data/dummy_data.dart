/// Dummy data for the IAMHERE demo application
class DummyData {
  // Product Information
  static const String productName = 'Nike Dunk Low "Grey Fog"';
  
  static const String productDescription = 
      'Clean, classic, and versatile. The Nike Dunk Low delivers timeless style '
      'with premium leather construction and iconic color blocking. Originally '
      'designed for the basketball court in 1985, the Dunk has since become a '
      'street style legend. This "Grey Fog" colorway offers a subtle, sophisticated '
      'look that pairs perfectly with any outfit.';
  
  static const String productPrice = '\$110';
  
  static const List<String> productFeatures = [
    'Premium leather upper',
    'Foam midsole for lightweight cushioning',
    'Rubber outsole with circular traction pattern',
    'Perforations on toe box for breathability',
    'Padded, low-cut collar',
  ];
  
  // Review Data
  static const List<Review> reviewsList = [
    Review(
      userName: 'Sarah K.',
      rating: 5,
      date: '2 days ago',
      title: 'Perfect everyday sneaker',
      comment: 'These are exactly what I was looking for! The quality is amazing '
          'and they go with everything. True to size and super comfortable.',
      isVerifiedPurchase: true,
    ),
    Review(
      userName: 'Mike Chen',
      rating: 4,
      date: '1 week ago',
      title: 'Great quality, runs slightly big',
      comment: 'Love the colorway and build quality. They run about half a size '
          'big, so consider sizing down. Otherwise perfect!',
      isVerifiedPurchase: true,
    ),
    Review(
      userName: 'Jordan T.',
      rating: 5,
      date: '2 weeks ago',
      title: 'Classic design, modern comfort',
      comment: 'Can\'t go wrong with Dunks. The grey fog colorway is super clean '
          'and versatile. Comfortable right out of the box.',
      isVerifiedPurchase: true,
    ),
  ];
  
  // Model file paths (example paths for testing)
  static const List<String> sampleModelPaths = [
    '/models/nike_dunk_low_grey.glb',
    '/models/sample_shoe.glb',
    '/models/test_model.glb',
  ];
  
  // Default 3D model URL (placeholder)
  static const String defaultModelUrl = 
      'https://modelviewer.dev/shared-assets/models/Astronaut.glb';
}

/// Review data model
class Review {
  final String userName;
  final int rating;
  final String date;
  final String title;
  final String comment;
  final bool isVerifiedPurchase;
  
  const Review({
    required this.userName,
    required this.rating,
    required this.date,
    required this.title,
    required this.comment,
    required this.isVerifiedPurchase,
  });
} 