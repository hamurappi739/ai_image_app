import 'package:ai_image_generator/models/payment_result.dart';
import 'package:ai_image_generator/models/user_balance.dart';
import 'package:ai_image_generator/services/api_service.dart';
import 'package:ai_image_generator/services/payment_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeApiService extends ApiService {
  _FakeApiService({
    required this.onMockPurchase,
    this.throwUnavailable = false,
  });

  final Future<MockPhotoPackResponse> Function(String packageId) onMockPurchase;
  final bool throwUnavailable;

  @override
  Future<MockPhotoPackResponse> mockPurchasePhotoPack({
    required String packageId,
  }) {
    if (throwUnavailable) {
      throw const MockPaymentUnavailableException();
    }
    return onMockPurchase(packageId);
  }
}

void main() {
  group('MockPhotoPackResponse', () {
    test('fromJson maps balance and photos_added', () {
      final response = MockPhotoPackResponse.fromJson({
        'status': 'credited',
        'package_id': 'package_499_20_images',
        'photos_added': 20,
        'balance': {
          'free_generations_limit': 3,
          'free_generations_used': 0,
          'free_generations_remaining': 3,
          'paid_image_generations': 20,
          'paid_photoshoots': 0,
          'total_available_images': 23,
          'available_photos': 23,
          'photoshoot_image_cost': 3,
          'available_photoshoots_by_images': 6,
          'consumption_enabled': true,
        },
      });

      expect(response.packageId, 'package_499_20_images');
      expect(response.photosAdded, 20);
      expect(response.balance?.totalAvailableImages, 23);
    });
  });

  group('PaymentService demo purchases', () {
    test('purchasePackage calls mock photo-pack endpoint and maps balance', () async {
      var calledPackageId = '';
      final service = PaymentService(
        apiService: _FakeApiService(
          onMockPurchase: (packageId) async {
            calledPackageId = packageId;
            return MockPhotoPackResponse(
              status: 'credited',
              packageId: 'package_499_20_images',
              photosAdded: 20,
              balance: const UserBalance(
                freeGenerationsLimit: 3,
                freeGenerationsUsed: 0,
                freeGenerationsRemaining: 3,
                paidImageGenerations: 20,
                paidPhotoshoots: 0,
                totalAvailableImages: 23,
                photoshootImageCost: 3,
                availablePhotoshootsByImages: 6,
                consumptionEnabled: true,
              ),
            );
          },
        ),
      );

      final result = await service.purchasePackage('package_499_20_images');

      expect(calledPackageId, 'package_499_20_images');
      expect(result.isVerified, isTrue);
      expect(result.addedImageGenerations, 20);
      expect(result.balance?.paidImageGenerations, 20);
    });

    test('purchasePackage maps unavailable mock payments to failure reason', () async {
      final service = PaymentService(
        apiService: _FakeApiService(
          throwUnavailable: true,
          onMockPurchase: (_) async => throw StateError('unreachable'),
        ),
      );

      final result = await service.purchasePackage('package_39_1_image');

      expect(result.isFailed, isTrue);
      expect(result.failureReason, PaymentFailureReason.unavailable);
    });
  });
}
