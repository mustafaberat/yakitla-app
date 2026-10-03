library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../config/strings.dart';
import '../config/theme.dart';
import '../models/models.dart';
import '../services/fuel_controller.dart';
import '../utils/brand_icons.dart';
import '../utils/brand_stations.dart';
import '../utils/formatters.dart';
import '../widgets/calc_unit_field.dart';
import '../widgets/station_pick_card.dart';

class CalculateTab extends StatefulWidget {
  const CalculateTab({super.key});

  @override
  State<CalculateTab> createState() => _CalculateTabState();
}

class _CalculateTabState extends State<CalculateTab> {
  final _distance = TextEditingController();
  final _consumption = TextEditingController();
  final _price = TextEditingController();
  CalculateResult? _result;
  Station? _brand;
  String? _syncedBrand;
  String? _syncedFuelType;
  String? _distanceError;
  String? _consumptionError;
  String? _priceError;

  @override
  void dispose() {
    _distance.dispose();
    _consumption.dispose();
    _price.dispose();
    super.dispose();
  }

  void _syncPriceFromBrand(String fuelType) {
    final brand = _brand;
    if (brand == null) return;
    final p = brand.prices.forType(fuelType);
    if (p != null) {
      _price.text = p.toStringAsFixed(2);
      _syncedBrand = brand.brand;
      _syncedFuelType = fuelType;
    }
  }

  Future<void> _pickBrand(FuelController fuel, AppStrings s) async {
    final items = brandAverageStations(fuel.stations);
    if (items.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.noStationsForCalc)),
      );
      return;
    }

    final chosen = await showModalBottomSheet<Station>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final maxH = MediaQuery.sizeOf(ctx).height * 0.82;
        return Container(
          constraints: BoxConstraints(maxHeight: maxH),
          decoration: BoxDecoration(
            color: isDark ? YakitlaColors.asphalt : const Color(0xFFF7F6F4),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: YakitlaColors.muted.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.selectStation,
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final station = items[i];
                    return StationPickCard(
                      station: station,
                      selected: _brand?.brand == station.brand,
                      gasolineLabel: s.gasoline,
                      dieselLabel: s.diesel,
                      onTap: () => Navigator.pop(ctx, station),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (chosen == null || !mounted) return;
    setState(() {
      _brand = chosen;
      _result = null;
      _distanceError = null;
      _consumptionError = null;
      _priceError = null;
    });
    _syncPriceFromBrand(fuel.fuelType);
  }

  void _refreshBrandPrices(FuelController fuel) {
    if (_brand == null) return;
    final brands = brandAverageStations(fuel.stations);
    final match = brands.where((b) => b.brand == _brand!.brand);
    if (match.isNotEmpty) {
      _brand = match.first;
    } else {
      _brand = null;
      _syncedBrand = null;
      _price.clear();
    }
  }

  void _clearBrand() {
    setState(() {
      _brand = null;
      _syncedBrand = null;
      _syncedFuelType = null;
      _result = null;
      _price.clear();
    });
  }

  void _run(AppStrings s) {
    final dRaw = _distance.text.trim();
    final cRaw = _consumption.text.trim();
    final pRaw = _price.text.trim();

    String? dErr;
    String? cErr;
    String? pErr;

    if (dRaw.isEmpty) {
      dErr = s.fieldRequired;
    } else {
      final d = double.tryParse(dRaw.replaceAll(',', '.'));
      if (d == null || d <= 0) dErr = s.fieldInvalid;
    }

    if (cRaw.isEmpty) {
      cErr = s.fieldRequired;
    } else {
      final c = double.tryParse(cRaw.replaceAll(',', '.'));
      if (c == null || c <= 0) cErr = s.fieldInvalid;
    }

    if (pRaw.isEmpty) {
      pErr = s.fieldRequired;
    } else {
      final p = double.tryParse(pRaw.replaceAll(',', '.'));
      if (p == null || p <= 0) pErr = s.fieldInvalid;
    }

    if (dErr != null || cErr != null || pErr != null) {
      setState(() {
        _distanceError = dErr;
        _consumptionError = cErr;
        _priceError = pErr;
        _result = null;
      });
      return;
    }

    final d = double.parse(dRaw.replaceAll(',', '.'));
    final c = double.parse(cRaw.replaceAll(',', '.'));
    final p = double.parse(pRaw.replaceAll(',', '.'));

    setState(() {
      _distanceError = null;
      _consumptionError = null;
      _priceError = null;
      _result = calculateTrip(
        distanceKm: d,
        consumptionLPer100Km: c,
        pricePerLitre: p,
      );
    });
  }

  void _reset(FuelController fuel) {
    _distance.clear();
    _consumption.clear();
    _syncPriceFromBrand(fuel.fuelType);
    setState(() {
      _result = null;
      _distanceError = null;
      _consumptionError = null;
      _priceError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fuel = context.watch<FuelController>();
    final s = context.watch<AppStrings>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    _refreshBrandPrices(fuel);

    if (_brand != null &&
        (_syncedBrand != _brand!.brand ||
            _syncedFuelType != fuel.fuelType)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncPriceFromBrand(fuel.fuelType);
        setState(() {});
      });
    }

    final fill = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFF3F4F6);
    final selected = _brand != null;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            s.tabCalculate,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
          ),
          const SizedBox(height: 20),
          Material(
            color: fill,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: () => _pickBrand(fuel, s),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Row(
                  children: [
                    _BrandMark(brand: _brand?.brand),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selected ? _brand!.brand : s.selectStation,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                          ),
                          if (!selected) ...[
                            const SizedBox(height: 2),
                            Text(
                              s.selectStationHint,
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
                    const SizedBox(width: 8),
                    if (selected) ...[
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: YakitlaColors.accent.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: YakitlaColors.accentDark,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.white,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _clearBrand,
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: Icon(
                              Icons.close_rounded,
                              color: YakitlaColors.muted,
                              size: 20,
                              semanticLabel: s.clearSelection,
                            ),
                          ),
                        ),
                      ),
                    ] else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: YakitlaColors.accent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          s.pick,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final type in FuelTypes.all) ...[
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: type == FuelTypes.diesel ? 0 : 8,
                    ),
                    child: _FuelChip(
                      label: _fuelLabel(s, type),
                      selected: fuel.fuelType == type,
                      onTap: () {
                        fuel.setFuelType(type);
                        _syncPriceFromBrand(type);
                        setState(() {});
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          CalcUnitField(
            label: s.tripDistance,
            unit: s.unitKm,
            controller: _distance,
            errorText: _distanceError,
            onChanged: (_) {
              if (_distanceError != null) {
                setState(() => _distanceError = null);
              }
            },
          ),
          const SizedBox(height: 14),
          CalcUnitField(
            label: s.pricePerLitre,
            unit: s.unitTry,
            controller: _price,
            errorText: _priceError,
            onChanged: (_) {
              if (_priceError != null) {
                setState(() => _priceError = null);
              }
            },
          ),
          const SizedBox(height: 14),
          CalcUnitField(
            label: s.avgConsumption,
            unit: s.unitLPer100,
            controller: _consumption,
            errorText: _consumptionError,
            onChanged: (_) {
              if (_consumptionError != null) {
                setState(() => _consumptionError = null);
              }
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: () => _run(s),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    child: Text(s.calculate),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 52,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => _reset(fuel),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    side: BorderSide(
                      color: isDark ? Colors.white24 : YakitlaColors.line,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: isDark
                        ? YakitlaColors.asphaltElevated
                        : Colors.white,
                  ),
                  child: Icon(
                    Icons.refresh_rounded,
                    color: YakitlaColors.accent,
                    semanticLabel: s.reset,
                  ),
                ),
              ),
            ],
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            _ResultCard(result: _result!, s: s, isDark: isDark),
          ],
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

class _BrandMark extends StatelessWidget {
  const _BrandMark({this.brand});

  final String? brand;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasBrand = brand != null && brand!.trim().isNotEmpty;

    if (!hasBrand) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: YakitlaColors.accent.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.local_gas_station_rounded,
          color: YakitlaColors.accentDark,
          size: 22,
        ),
      );
    }

    final asset = brandAssetPath(brand!);
    final isSvg = asset.endsWith('.svg');
    final tint = isDark
        ? brandHeaderTint(brand!).withValues(alpha: 0.35)
        : brandHeaderTint(brand!);

    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : YakitlaColors.line,
        ),
      ),
      child: isSvg
          ? SvgPicture.asset(asset, fit: BoxFit.contain)
          : Image.asset(asset, fit: BoxFit.contain),
    );
  }
}

class _FuelChip extends StatelessWidget {
  const _FuelChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: selected
          ? YakitlaColors.accent.withValues(alpha: 0.12)
          : (isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFF3F4F6)),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? YakitlaColors.accent.withValues(alpha: 0.35)
                  : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.result,
    required this.s,
    required this.isDark,
  });

  final CalculateResult result;
  final AppStrings s;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? YakitlaColors.accent.withValues(alpha: 0.12)
        : const Color(0xFFEAF7EF);
    final iconBg = isDark
        ? YakitlaColors.accent.withValues(alpha: 0.2)
        : const Color(0xFFD7F0E0);

    Widget row({
      required IconData icon,
      required String label,
      required String value,
      bool last = false,
    }) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: YakitlaColors.accentDark, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: YakitlaColors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!last)
            Divider(
              height: 1,
              color: isDark
                  ? Colors.white12
                  : YakitlaColors.accent.withValues(alpha: 0.12),
            ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          row(
            icon: Icons.account_balance_wallet_outlined,
            label: s.estimatedCost,
            value: formatMoney(result.totalCost),
          ),
          row(
            icon: Icons.local_gas_station_outlined,
            label: s.totalFuel,
            value: '${result.fuelConsumedLitres.toStringAsFixed(1)} L',
          ),
          row(
            icon: Icons.route_outlined,
            label: s.costPerKm,
            value: formatMoney(result.costPerKm),
            last: true,
          ),
        ],
      ),
    );
  }
}
