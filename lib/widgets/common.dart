import 'package:flutter/material.dart';

import '../config/theme.dart';

/// A compact labelled statistic tile.
class StatTile extends StatelessWidget {
  final String value;
  final String label;
  final String? emoji;
  final Color? color;
  const StatTile(
      {super.key,
      required this.value,
      required this.label,
      this.emoji,
      this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (emoji != null) Text(emoji!, style: const TextStyle(fontSize: 18)),
          if (emoji != null) const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color ?? Colors.white)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6))),
        ],
      ),
    );
  }
}

/// Pill-shaped status badge.
class StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const StatusPill(
      {super.key, required this.text, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
        ] else ...[
          Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
        ],
        Text(text,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

/// Section header with optional trailing action.
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHeader(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Empty-state placeholder.
class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Widget? action;
  const EmptyState(
      {super.key,
      required this.emoji,
      required this.title,
      required this.subtitle,
      this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.6))),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

/// Rounded emoji avatar chip.
class EmojiAvatar extends StatelessWidget {
  final String emoji;
  final double size;
  final Color? bg;
  const EmojiAvatar(this.emoji, {super.key, this.size = 44, this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg ?? AppTheme.primary.withOpacity(0.18),
        shape: BoxShape.circle,
      ),
      child: Text(emoji, style: TextStyle(fontSize: size * 0.5)),
    );
  }
}

/// A labelled icon pill used for quick-request buttons.
class BigActionButton extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const BigActionButton(
      {super.key,
      required this.emoji,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: color,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

/// Small info hint banner (e.g. maps-key / demo-mode notices).
class InfoBanner extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const InfoBanner(
      {super.key,
      required this.text,
      this.icon = Icons.info_outline,
      this.color = AppTheme.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: Colors.white.withOpacity(0.85)),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12.5, color: Colors.white.withOpacity(0.85)))),
      ]),
    );
  }
}
