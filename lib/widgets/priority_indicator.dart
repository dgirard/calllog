import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../utils/constants.dart';

/// Widget affichant un indicateur visuel de priorité
class PriorityIndicator extends StatelessWidget {
  final Priority priority;
  final double size;

  const PriorityIndicator({
    super.key,
    required this.priority,
    this.size = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    final color = priorityColors[priority] ?? Colors.grey;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
