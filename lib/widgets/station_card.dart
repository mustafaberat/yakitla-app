library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../config/theme.dart';
import '../models/models.dart';
import '../utils/brand_icons.dart';
import '../utils/formatters.dart';

class StationCard extends StatelessWidget {
  const StationCard({
    required this.station,
    required this.selected,
    required this.onTap,
    required this.onPin,
    required this.onGo,
    required this.gasolineLabel,
    required this.dieselLabel,
    required this.bestLabel,
    required this.goLabel,
    required this.isBestGasoline,
    required this.isBestDiesel,
    this.pinned = false,
    this.pinLabel = 'Sabit',
    super.key,
  });

  final Station station;
  final bool selected;
  final bool pinned;
  final String pinLabel;
  final String goLabel;
  final VoidCallback onTap;
  final VoidCallback onPin;
  final VoidCallback onGo;
  final String gasolineLabel;
  final String dieselLabel;
  final String bestLabel;
  final bool isBestGasoline;
  final bool isBestDiesel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = isDark
        ? brandHeaderTint(station.brand).withValues(alpha: 0.22)
        : brandHeaderTint(station.brand);
    final asset = brandAssetPath(station.brand);
    final isSvg = asset.endsWith('.svg');
    final subtitle = stationSubtitle(station);

    return Material(
      color: isDark ? YakitlaColors.asphaltElevated : Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? YakitlaColors.accent.withValues(alpha: 0.55)
                  : (isDark ? Colors.white10 : YakitlaColors.line),
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                color: tint,
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: isDark ? 0.9 : 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: isSvg
                          ? SvgPicture.asset(asset, fit: BoxFit.contain)
                          : Image.asset(asset, fit: BoxFit.contain),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            station.brand,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          if (subtitle.isNotEmpty &&
                              subtitle.toLowerCase() !=
                                  station.brand.toLowerCase()) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: YakitlaColors.muted,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _HeaderAction(
                      icon: pinned
                          ? Icons.push_pin_rounded
                          : Icons.push_pin_outlined,
                      label: pinned ? pinLabel : null,
                      filled: pinned,
                      onTap: onPin,
                    ),
                    const SizedBox(width: 6),
                    _HeaderAction(
                      icon: Icons.directions_rounded,
                      label: goLabel,
                      filled: true,
                      emphasize: true,
                      onTap: onGo,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Column(
                  children: [
                    _FuelRow(
                      label: gasolineLabel,
                      value: station.prices.gasoline,
                      isBest: isBestGasoline,
                      bestLabel: bestLabel,
                    ),
                    const Divider(height: 18),
                    _FuelRow(
                      label: dieselLabel,
                      value: station.prices.diesel,
                      isBest: isBestDiesel,
                      bestLabel: bestLabel,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.onTap,
    this.label,
    this.filled = false,
    this.emphasize = false,
  });

  final IconData icon;
  final String? label;
  final bool filled;
  final bool emphasize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = emphasize
        ? YakitlaColors.accent
        : filled
            ? YakitlaColors.accent.withValues(alpha: 0.14)
            : Colors.transparent;
    final fg = emphasize
        ? Colors.white
        : filled
            ? YakitlaColors.accent
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: label == null ? 8 : 10,
            vertical: 7,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              if (label != null) ...[
                const SizedBox(width: 4),
                Text(
                  label!,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FuelRow extends StatelessWidget {
  const _FuelRow({
    required this.label,
    required this.value,
    required this.isBest,
    required this.bestLabel,
  });

  final String label;
  final double? value;
  final bool isBest;
  final String bestLabel;

  @override
  Widget build(BuildContext context) {
    final priceColor =
        isBest ? YakitlaColors.accentDark : Theme.of(context).colorScheme.onSurface;

    return Row(
      children: [
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.78),
                    ),
              ),
              if (isBest && value != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: YakitlaColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    bestLabel,
                    style: const TextStyle(
                      color: YakitlaColors.accentDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Text(
          formatPrice(value),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: priceColor,
                letterSpacing: -0.2,
              ),
        ),
      ],
    );
  }
}
