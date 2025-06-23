import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere_demo/data/dummy_data.dart';

void main() {
  group('DummyData Product Information Tests', () {
    test('should have correct product name', () {
      expect(DummyData.productName, equals('Nike Dunk Low "Grey Fog"'));
    });
    
    test('should have non-empty product description', () {
      expect(DummyData.productDescription, isNotEmpty);
      expect(DummyData.productDescription.contains('Nike Dunk Low'), isTrue);
    });
    
    test('should have valid product price', () {
      expect(DummyData.productPrice, equals('\$110'));
    });
    
    test('should have product features list', () {
      expect(DummyData.productFeatures, isNotEmpty);
      expect(DummyData.productFeatures.length, equals(5));
      expect(DummyData.productFeatures.first, equals('Premium leather upper'));
    });
  });
  
  group('DummyData Reviews Tests', () {
    test('should have exactly 3 reviews', () {
      expect(DummyData.reviewsList.length, equals(3));
    });
    
    test('should have valid review data for all reviews', () {
      for (final review in DummyData.reviewsList) {
        expect(review.userName, isNotEmpty);
        expect(review.rating, greaterThanOrEqualTo(1));
        expect(review.rating, lessThanOrEqualTo(5));
        expect(review.date, isNotEmpty);
        expect(review.title, isNotEmpty);
        expect(review.comment, isNotEmpty);
        expect(review.isVerifiedPurchase, isNotNull);
      }
    });
    
    test('should have correct first review data', () {
      final firstReview = DummyData.reviewsList.first;
      
      expect(firstReview.userName, equals('Sarah K.'));
      expect(firstReview.rating, equals(5));
      expect(firstReview.date, equals('2 days ago'));
      expect(firstReview.title, equals('Perfect everyday sneaker'));
      expect(firstReview.isVerifiedPurchase, isTrue);
    });
    
    test('should have mixed ratings in reviews', () {
      final ratings = DummyData.reviewsList.map((r) => r.rating).toList();
      expect(ratings, contains(5)); // Has 5-star reviews
      expect(ratings, contains(4)); // Has 4-star reviews
    });
  });
  
  group('DummyData Model Paths Tests', () {
    test('should have sample model paths', () {
      expect(DummyData.sampleModelPaths, isNotEmpty);
      expect(DummyData.sampleModelPaths.length, equals(3));
    });
    
    test('should have .glb file extensions for all sample paths', () {
      for (final path in DummyData.sampleModelPaths) {
        expect(path.endsWith('.glb'), isTrue);
      }
    });
    
    test('should have valid default model URL', () {
      expect(DummyData.defaultModelUrl, isNotEmpty);
      expect(DummyData.defaultModelUrl, startsWith('https://'));
      expect(DummyData.defaultModelUrl, endsWith('.glb'));
    });
  });
  
  group('Review Model Tests', () {
    test('should create Review instance with all required fields', () {
      const review = Review(
        userName: 'Test User',
        rating: 5,
        date: 'Today',
        title: 'Test Review',
        comment: 'This is a test comment',
        isVerifiedPurchase: true,
      );
      
      expect(review.userName, equals('Test User'));
      expect(review.rating, equals(5));
      expect(review.date, equals('Today'));
      expect(review.title, equals('Test Review'));
      expect(review.comment, equals('This is a test comment'));
      expect(review.isVerifiedPurchase, isTrue);
    });
  });
} 