library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/strings.dart';
import '../config/theme.dart';
import '../models/models.dart';
import '../services/fuel_controller.dart';
import '../utils/formatters.dart';
import '../widgets/location_sheet.dart';
import '../widgets/station_card.dart';

class PricesTab extends StatelessWidget {
  const PricesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final fuel = context.watch<FuelController>();
    final s = context.watch<AppStrings>();
    final locationLabel = fuel.districtName.isNotEmpty
        ? '${fuel.cityName} · ${fuel.districtName}'
        : fuel.cityName;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.brand,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.1,
                              height: 1.05,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${s.lastUpdate}: ${formatUpdatedAt(fuel.updatedAt, todayLabel: s.today)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: YakitlaColors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _LocationPill(
                  label: fuel.locating
                      ? s.locating
                      : (locationLabel.isEmpty ? s.useLocation : locationLabel),
                  loading: fuel.locating,
                  onTap: () => showLocationSheet(
                    context: context,
                    fuel: fuel,
                    s: s,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                for (final type in FuelTypes.all) ...[
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: type == FuelTypes.diesel ? 0 : 8,
                      ),
                      child: _FuelSortChip(
                        label: _fuelLabel(s, type),
                        selected: fuel.fuelType == type,
                        onTap: () => fuel.setFuelType(type),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(child: _StationsBody(fuel: fuel, s: s)),
        ],
      ),
    );
  }

  String _fuelLabel(AppStrings s, String type) {
    switch (type) {
      case FuelTypes.gasoline:
        return s.gasoline;
      case FuelTypes.diesel:
        return s.diesel;
      default:
        return s.gasoline;
    }
  }
}

class _LocationPill extends StatelessWidget {
  const _LocationPill({
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? Colors.white10 : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 180),
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isDark ? Colors.white12 : YakitlaColors.line,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(
                  Icons.location_on_rounded,
                  size: 18,
                  color: YakitlaColors.accent,
                ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FuelSortChip extends StatelessWidget {
  const _FuelSortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? YakitlaColors.accent.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? YakitlaColors.accent.withValues(alpha: 0.35)
                  : YakitlaColors.line,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: selected ? YakitlaColors.accentDark : YakitlaColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _StationsBody extends StatelessWidget {
  const _StationsBody({required this.fuel, required this.s});

  final FuelController fuel;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    if (fuel.state == LoadState.loading || fuel.state == LoadState.idle) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: 12),
            Text(s.loading, style: const TextStyle(color: YakitlaColors.muted)),
          ],
        ),
      );
    }
    if (fuel.state == LoadState.error) {
      return _Message(
        text: fuel.error ?? s.errorGeneric,
        actionLabel: s.retry,
        onAction: fuel.loadStations,
      );
    }
    if (fuel.districtId.isEmpty && fuel.stations.isEmpty) {
      return _Message(text: s.emptyPickDistrict);
    }
    final items = fuel.stations;
    if (items.isEmpty) {
      return _Message(
        text: s.emptyStations,
        actionLabel: s.retry,
        onAction: fuel.loadStations,
      );
    }

    return RefreshIndicator(
      color: YakitlaColors.accent,
      onRefresh: fuel.loadStations,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final station = items[i];
          final pinned = fuel.isPinned(station);
          return StationCard(
            station: station,
            selected: pinned,
            pinned: pinned,
            pinLabel: s.pin,
            goLabel: s.go,
            gasolineLabel: s.gasoline,
            dieselLabel: s.diesel,
            bestLabel: s.bestPrice,
            isBestGasoline: fuel.isBestPrice(station, FuelTypes.gasoline),
            isBestDiesel: fuel.isBestPrice(station, FuelTypes.diesel),
            onTap: () => fuel.selectStation(station),
            onPin: () => fuel.pinStation(station),
            onGo: () async {
              fuel.selectStation(station);
              final url = await fuel.api.resolveMapsUrl(station);
              await launchUrl(
                Uri.parse(url),
                mode: LaunchMode.externalApplication,
              );
            },
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.actionLabel, this.onAction});

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: YakitlaColors.muted, height: 1.4),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
