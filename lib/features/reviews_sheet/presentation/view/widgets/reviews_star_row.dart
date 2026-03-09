import 'package:flutter/material.dart';

class StarRow extends StatelessWidget {
  final double rating;
  final double size;

  const StarRow({super.key, required this.rating, required this.size});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final v = i + 1.0;
        final icon = rating >= v
            ? Icons.star_rounded
            : rating >= v - 0.5
                ? Icons.star_half_rounded
                : Icons.star_border_rounded;
        return Icon(icon, color: const Color(0xFFF59E0B), size: size);
      }),
    );
  }
}