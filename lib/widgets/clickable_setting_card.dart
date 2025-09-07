import 'package:flutter/material.dart';
import 'setting_card.dart';

Widget buildClickableSettingCard(
  BuildContext context, {
  required String label,
  required Widget icon,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    // MouseRegion to improve user experience on desktop
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: buildSettingCard(context, label: label, child: icon),
    ),
  );
}
