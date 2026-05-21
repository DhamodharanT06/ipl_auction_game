import 'package:flutter/material.dart';

class PodiumCard extends StatelessWidget {
  const PodiumCard({
    super.key,
    required this.name,
    required this.points,
    required this.rank,
  });

  final String name;
  final double points;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final height = rank == 1 ? 150.0 : rank == 2 ? 125.0 : 110.0;
    final color = rank == 1
        ? const Color(0xFFFDE047)
        : rank == 2
            ? const Color(0xFFD1D5DB)
            : const Color(0xFFFB923C);

    return Expanded(
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.60)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('#$rank', style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(name, textAlign: TextAlign.center, maxLines: 1),
            const SizedBox(height: 4),
            Text(points.toStringAsFixed(1)),
          ],
        ),
      ),
    );
  }
}
