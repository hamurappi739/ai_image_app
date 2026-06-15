import 'package:flutter/material.dart';

/// Horizontal category filter used in template and photoshoot catalogs.
class CategoryFilterChips extends StatelessWidget {
  const CategoryFilterChips({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const _accentColor = Color(0xFF5B6CFF);

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            ChoiceChip(
              label: Text(labels[i]),
              selected: selectedIndex == i,
              onSelected: (_) => onSelected(i),
              selectedColor: const Color(0xFFEDE9FF),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight:
                    selectedIndex == i ? FontWeight.w600 : FontWeight.w500,
                color: selectedIndex == i ? _accentColor : const Color(0xFF1A1D26),
              ),
              side: BorderSide(
                color: selectedIndex == i
                    ? _accentColor.withValues(alpha: 0.45)
                    : const Color(0xFFE8EAEF),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }
}
