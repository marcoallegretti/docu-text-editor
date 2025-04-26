import 'package:flutter/material.dart';
import '../theme.dart';

class TextStyleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final VoidCallback onPressed;

  const TextStyleButton({
    Key? key,
    required this.icon,
    required this.tooltip,
    required this.isActive,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isActive ? AppTheme.primaryColor : AppTheme.textColor,
          ),
        ),
      ),
    );
  }
}

class FormatToolbarButton extends StatelessWidget {
  final Widget child;
  final String tooltip;
  final VoidCallback onPressed;

  const FormatToolbarButton({
    Key? key,
    required this.child,
    required this.tooltip,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
          ),
          child: child,
        ),
      ),
    );
  }
}

class ParagraphStyleButton extends StatelessWidget {
  final String text;
  final TextStyle style;
  final VoidCallback onPressed;

  const ParagraphStyleButton({
    Key? key,
    required this.text,
    required this.style,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Text(text, style: style),
      ),
    );
  }
}