class UserBalance {
  const UserBalance({
    required this.freeGenerationsLimit,
    required this.freeGenerationsUsed,
    required this.freeGenerationsRemaining,
    required this.paidImageGenerations,
    required this.paidPhotoshoots,
    required this.totalAvailableImages,
    required this.photoshootImageCost,
    required this.availablePhotoshootsByImages,
    this.consumptionEnabled = false,
  });

  static const defaultPhotoshootImageCost = 3;

  final int freeGenerationsLimit;
  final int freeGenerationsUsed;
  final int freeGenerationsRemaining;
  final int paidImageGenerations;
  final int paidPhotoshoots;
  final int totalAvailableImages;
  final int photoshootImageCost;
  final int availablePhotoshootsByImages;
  final bool consumptionEnabled;

  factory UserBalance.fromJson(Map<String, dynamic> json) {
    final freeRemaining = json['free_generations_remaining'] as int? ?? 0;
    final paidImages = json['paid_image_generations'] as int? ?? 0;
    final totalFromApi = json['total_available_images'] as int?;
    final photoshootCost =
        json['photoshoot_image_cost'] as int? ?? defaultPhotoshootImageCost;
    final availablePhotoshoots =
        json['available_photoshoots_by_images'] as int?;

    return UserBalance(
      freeGenerationsLimit: json['free_generations_limit'] as int? ?? 0,
      freeGenerationsUsed: json['free_generations_used'] as int? ?? 0,
      freeGenerationsRemaining: freeRemaining,
      paidImageGenerations: paidImages,
      paidPhotoshoots: json['paid_photoshoots'] as int? ?? 0,
      totalAvailableImages: totalFromApi ?? (freeRemaining + paidImages),
      photoshootImageCost: photoshootCost,
      availablePhotoshootsByImages:
          availablePhotoshoots ?? ((totalFromApi ?? (freeRemaining + paidImages)) ~/ photoshootCost),
      consumptionEnabled: json['consumption_enabled'] as bool? ?? false,
    );
  }

  /// Списание выключено — генерации доступны без проверки остатка.
  bool get isImageGenerationAvailable =>
      !consumptionEnabled || totalAvailableImages >= 1;

  bool get isPhotoshootBalanceAvailable =>
      !consumptionEnabled || totalAvailableImages >= photoshootImageCost;

  bool get showImageDepletedWarning =>
      consumptionEnabled && totalAvailableImages < 1;

  bool get showPhotoshootDepletedWarning =>
      consumptionEnabled && totalAvailableImages < photoshootImageCost;
}
