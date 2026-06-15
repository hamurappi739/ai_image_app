import 'package:flutter/material.dart';

import 'good_result_guide_card.dart';

/// Tips card on the «Своя идея» screen — delegates to [GoodResultGuideCard].
class CreateResultTipsCard extends StatelessWidget {
  const CreateResultTipsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const GoodResultGuideCard();
  }
}
