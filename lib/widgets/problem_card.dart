import 'package:flutter/material.dart';
import '../models/problem.dart';
import '../theme.dart';

class ProblemCard extends StatelessWidget {
  final Problem problem;
  final VoidCallback? onTap;
  final bool showStatus;
  final int? number;
  const ProblemCard(
      {super.key,
      required this.problem,
      this.onTap,
      this.showStatus = false,
      this.number});
  @override
  Widget build(BuildContext context) {
    final color = problem.difficulty == 'EASY'
        ? AppColors.green
        : problem.difficulty == 'HARD'
            ? AppColors.clay
            : const Color(0xFF99792F);
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
                side: const BorderSide(color: AppColors.line)),
            child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(13),
                child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(children: [
                      if (number != null) ...[
                        Text(number!.toString().padLeft(2, '0'),
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 12)),
                        const SizedBox(width: 20)
                      ],
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(problem.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 16)),
                            const SizedBox(height: 8),
                            Wrap(
                                spacing: 10,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(problem.difficultyLabel,
                                      style: TextStyle(
                                          color: color,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600)),
                                  Text(
                                      showStatus
                                          ? problem.statusLabel
                                          : 'Recall the approach',
                                      style: const TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 11)),
                                  if (showStatus)
                                    ...problem.tags.take(2).map((tag) => Text(
                                        tag,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.muted))),
                                ])
                          ])),
                      const SizedBox(width: 10),
                      const Icon(Icons.arrow_outward_rounded,
                          size: 18, color: AppColors.muted),
                    ])))));
  }
}
