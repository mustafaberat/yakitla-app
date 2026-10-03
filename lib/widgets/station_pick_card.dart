library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../config/theme.dart';
import '../models/models.dart';
import '../utils/brand_icons.dart';
import '../utils/formatters.dart';

/// Compact station box matching Prices tab readability (logo + prices).
class StationPickCard extends StatelessWidget {
  const StationPickCard({
    required this.station,
    required this.selected,
    required this.onTap,
    required this.gasolineLabel,
    required this.dieselLabel,
    this.showChevron = false,
    super.key,
  });

  final Station station;
  final bool selected;
  final VoidCallback onTap;
  final String gasolineLabel;
  final String dieselLabel;
  final bool showChevron;

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
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
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
                    if (selected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: YakitlaColors.accent,
                        size: 22,
                      )
                    else if (showChevron)
                      Icon(
                        Icons.expand_more_rounded,
                        color: YakitlaColors.muted,
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: _PriceBox(
                        label: gasolineLabel,
                        value: station.prices.gasoline,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PriceBox(
                        label: dieselLabel,
                        value: station.prices.diesel,
                      ),
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

class _PriceBox extends StatelessWidget {
  const _PriceBox({required this.label, required this.value});

  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : YakitlaColors.line.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: YakitlaColors.muted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            formatPrice(value),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
          ),
        ],
      ),
    );
  }
}
