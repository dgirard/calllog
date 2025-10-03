import 'package:flutter/material.dart';
import '../utils/birthday_utils.dart';

/// Widget affichant un badge pour les anniversaires proches
class BirthdayBadge extends StatelessWidget {
  final DateTime? birthday;

  const BirthdayBadge({
    super.key,
    required this.birthday,
  });

  @override
  Widget build(BuildContext context) {
    if (birthday == null) return const SizedBox.shrink();

    if (!isBirthdaySoon(birthday) && !isBirthdayToday(birthday)) {
      return const SizedBox.shrink();
    }

    final countdownText = getBirthdayCountdownText(birthday);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.pink.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎂', style: TextStyle(fontSize: 16)),
          if (countdownText.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              countdownText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.pink.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
