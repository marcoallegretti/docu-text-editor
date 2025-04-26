import 'package:flutter/material.dart';

class PaginationIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const PaginationIndicator({
    Key? key,
    required this.currentPage,
    required this.totalPages,
    this.onPrev,
    this.onNext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: (onPrev != null && currentPage > 1) ? onPrev : null,
        ),
        Text(
          'Page $currentPage of $totalPages',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: (onNext != null && currentPage < totalPages) ? onNext : null,
        ),
      ],
    );
  }
}
