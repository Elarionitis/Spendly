import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── SpendlyCard ─────────────────────────────────────────────────────────────

class SpendlyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? backgroundColor;
  final double borderRadius;

  const SpendlyCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.gradient,
    this.backgroundColor,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content = Padding(
      padding: padding ?? const EdgeInsets.all(20),
      child: child,
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: gradient,
        color: gradient == null
            ? (backgroundColor ??
                (isDark ? SpendlyColors.darkCard : Colors.white))
            : null,
        boxShadow: gradient != null
            ? [
                BoxShadow(
                  color: (gradient!.colors.first).withAlpha(60),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 30 : 8),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      ),
    );
  }
}

// ─── GradientButton ───────────────────────────────────────────────────────────

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Gradient gradient;
  final IconData? icon;
  final double height;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.gradient = SpendlyColors.primaryGradient,
    this.icon,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: onPressed != null ? gradient : null,
        color: onPressed == null ? SpendlyColors.neutral300 : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: gradient.colors.first.withAlpha(80),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── EmptyState ───────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: SpendlyColors.primary.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: SpendlyColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: SpendlyColors.neutral500,
                  ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── StatusBadge ─────────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color backgroundColor;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  factory StatusBadge.pending() => const StatusBadge(
        label: 'Pending',
        color: Color(0xFFF59E0B),
        backgroundColor: Color(0xFFFEF3C7),
      );

  factory StatusBadge.verified() => const StatusBadge(
        label: 'Verified',
        color: Color(0xFF10B981),
        backgroundColor: Color(0xFFD1FAE5),
      );

  factory StatusBadge.rejected() => const StatusBadge(
        label: 'Rejected',
        color: Color(0xFFEF4444),
        backgroundColor: Color(0xFFFEE2E2),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── UserAvatar ───────────────────────────────────────────────────────────────

class UserAvatar extends StatelessWidget {
  final String name;
  final String userId;
  final double size;
  final bool isVerified;
  final String? avatarUrl;

  const UserAvatar({
    super.key,
    required this.name,
    required this.userId,
    this.size = 36,
    this.isVerified = false,
    this.avatarUrl,
  });

  Color _colorFromId(String id) {
// ... same ...
  }

  String _initials(String name) {
// ... same ...
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: avatarUrl == null ? _colorFromId(userId) : Colors.transparent,
            shape: BoxShape.circle,
            image: avatarUrl != null
                ? DecorationImage(
                    image: NetworkImage(avatarUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: avatarUrl == null
              ? Center(
                  child: Text(
                    _initials(name),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : null,
        ),
        if (isVerified)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(1),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified,
                color: SpendlyColors.primary,
                size: size * 0.35,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── SectionHeader ────────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const Spacer(),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── SpendlyFilterChipRow ─────────────────────────────────────────────────────
/// A horizontally-scrolling row of [ChoiceChip]s with clear selected/unselected
/// states following the Spendly design system:
///   • Selected  → solid primary background, white text
///   • Unselected → neutral200 background, neutral700 text
///
/// Generic [T] can be any value type (int month, enum, String, etc.).
class SpendlyFilterChipRow<T> extends StatelessWidget {
  final List<T> items;
  final T? selected;
  final String Function(T) label;
  final void Function(T?) onSelect;
  final double height;
  final EdgeInsets itemPadding;

  const SpendlyFilterChipRow({
    super.key,
    required this.items,
    required this.selected,
    required this.label,
    required this.onSelect,
    this.height = 36,
    this.itemPadding = const EdgeInsets.symmetric(horizontal: 4),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final item = items[i];
          final isSelected = selected == item;
          return ChoiceChip(
            label: Text(
              label(item),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : SpendlyColors.neutral700,
              ),
            ),
            selected: isSelected,
            selectedColor: SpendlyColors.primary,
            backgroundColor: SpendlyColors.neutral200,
            showCheckmark: false,
            side: BorderSide.none,
            padding: itemPadding,
            onSelected: (_) => onSelect(isSelected ? null : item),
          );
        },
      ),
    );
  }
}

// ─── SpendlyCategoryChipGrid ──────────────────────────────────────────────────
/// A wrapping grid of category/option chips (for Add Expense screen).
/// Selected chip: solid primary bg + white text.
/// Unselected chip: surfaceContainerHighest bg + neutral700 text.
class SpendlyCategoryChipGrid<T> extends StatelessWidget {
  final List<T> items;
  final T? selected;
  final String Function(T) label;
  final void Function(T) onSelect;

  const SpendlyCategoryChipGrid({
    super.key,
    required this.items,
    required this.selected,
    required this.label,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = selected == item;
        return GestureDetector(
          onTap: () => onSelect(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? SpendlyColors.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: SpendlyColors.primary, width: 1.5)
                  : Border.all(color: Colors.transparent, width: 1.5),
            ),
            child: Text(
              label(item),
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
