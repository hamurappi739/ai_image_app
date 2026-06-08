import 'package:flutter/material.dart';

/// Description field for the Create tab — tuned for Cyrillic on Android IME.
///
/// [TextInputType.text] with [minLines] > 1 can configure Android as a
/// non-multiline text class input; many keyboards then accept only Latin.
/// [TextInputType.multiline] enables full Unicode (including Cyrillic).
class CreateDescriptionTextField extends StatelessWidget {
  const CreateDescriptionTextField({
    super.key,
    required this.controller,
    required this.hintText,
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      textCapitalization: TextCapitalization.sentences,
      enableSuggestions: true,
      autocorrect: true,
      smartDashesType: SmartDashesType.enabled,
      smartQuotesType: SmartQuotesType.enabled,
      enableIMEPersonalizedLearning: true,
      minLines: 3,
      maxLines: 6,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
      style: const TextStyle(fontSize: 16, height: 1.45),
    );
  }
}
