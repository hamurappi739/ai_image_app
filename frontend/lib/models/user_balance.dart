class UserBalance {
  const UserBalance({
    required this.freeGenerationsLimit,
    required this.freeGenerationsUsed,
    required this.freeGenerationsRemaining,
    required this.paidImageGenerations,
    required this.paidPhotoshoots,
    this.consumptionEnabled = false,
  });

  final int freeGenerationsLimit;
  final int freeGenerationsUsed;
  final int freeGenerationsRemaining;
  final int paidImageGenerations;
  final int paidPhotoshoots;
  final bool consumptionEnabled;

  factory UserBalance.fromJson(Map<String, dynamic> json) {
    return UserBalance(
      freeGenerationsLimit: json['free_generations_limit'] as int? ?? 0,
      freeGenerationsUsed: json['free_generations_used'] as int? ?? 0,
      freeGenerationsRemaining: json['free_generations_remaining'] as int? ?? 0,
      paidImageGenerations: json['paid_image_generations'] as int? ?? 0,
      paidPhotoshoots: json['paid_photoshoots'] as int? ?? 0,
      consumptionEnabled: json['consumption_enabled'] as bool? ?? false,
    );
  }
}
