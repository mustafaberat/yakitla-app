library;

import 'package:flutter/material.dart';

import '../config/strings.dart';
import '../config/theme.dart';
import '../services/fuel_controller.dart';

/// Centered location dialog (city → district).
Future<void> showLocationSheet({
  required BuildContext context,
  required FuelController fuel,
  required AppStrings s,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        child: _LocationDialogBody(fuel: fuel, s: s),
      ),
    ),
  );
}

class _LocationDialogBody extends StatefulWidget {
  const _LocationDialogBody({required this.fuel, required this.s});

  final FuelController fuel;
  final AppStrings s;

  @override
  State<_LocationDialogBody> createState() => _LocationDialogBodyState();
}

class _LocationDialogBodyState extends State<_LocationDialogBody> {
  int _step = 0;
  String _query = '';

  FuelController get fuel => widget.fuel;
  AppStrings get s => widget.s;

  String _fold(String value) => value.toLowerCase();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
          child: Row(
            children: [
              if (_step == 1)
                IconButton(
                  onPressed: () => setState(() {
                    _step = 0;
                    _query = '';
                  }),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              Expanded(
                child: Text(
                  _step == 0 ? s.selectCity : s.selectDistrict,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        if (_step == 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: FilledButton.tonalIcon(
              onPressed: fuel.locating
                  ? null
                  : () async {
                      await fuel.useMyLocation();
                      if (!mounted) return;
                      setState(() {
                        _step = 1;
                        _query = '';
                      });
                    },
              icon: fuel.locating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded),
              label: Text(s.useMyLocation),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _query = v.trim()),
            decoration: InputDecoration(
              hintText: _step == 0 ? s.selectCity : s.pickDistrict,
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: fuel,
            builder: (context, _) {
              if (_step == 0) {
                final q = _fold(_query);
                final cities = fuel.cities.where((c) {
                  if (q.isEmpty) return true;
                  return _fold(c.name).contains(q) || c.id.contains(q);
                }).toList();

                if (cities.isEmpty) {
                  return _EmptyCatalog(
                    loading: fuel.catalogLoading,
                    message: fuel.catalogError ?? s.errorGeneric,
                    loadingLabel: s.loading,
                    retryLabel: s.retry,
                    onRetry: () => fuel.ensureCities(force: true),
                  );
                }

                return ListView.builder(
                  itemCount: cities.length,
                  itemBuilder: (context, i) {
                    final city = cities[i];
                    final selected = city.id == fuel.cityId;
                    return ListTile(
                      title: Text(
                        city.name,
                        style: TextStyle(
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w500,
                        ),
                      ),
                      trailing: selected
                          ? const Icon(Icons.check_rounded,
                              color: YakitlaColors.accent)
                          : null,
                      onTap: () async {
                        await fuel.setCity(city.id);
                        if (!mounted) return;
                        setState(() {
                          _step = 1;
                          _query = '';
                        });
                      },
                    );
                  },
                );
              }

              final q = _fold(_query);
              final districts = fuel.districts.where((d) {
                if (q.isEmpty) return true;
                return _fold(d.name).contains(q);
              }).toList();

              if (districts.isEmpty) {
                return _EmptyCatalog(
                  loading: fuel.catalogLoading,
                  message: fuel.catalogError ?? s.emptyPickDistrict,
                  loadingLabel: s.loading,
                  retryLabel: s.retry,
                  onRetry: () =>
                      fuel.ensureDistricts(fuel.cityId, force: true),
                );
              }

              return ListView.builder(
                itemCount: districts.length,
                itemBuilder: (context, i) {
                  final d = districts[i];
                  final selected = d.id == fuel.districtId;
                  return ListTile(
                    title: Text(
                      d.name,
                      style: TextStyle(
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(Icons.check_rounded,
                            color: YakitlaColors.accent)
                        : null,
                    onTap: () async {
                      await fuel.setDistrict(d.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog({
    required this.loading,
    required this.message,
    required this.loadingLabel,
    required this.retryLabel,
    required this.onRetry,
  });

  final bool loading;
  final String message;
  final String loadingLabel;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              loading ? loadingLabel : message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: YakitlaColors.muted),
            ),
            if (!loading) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: Text(retryLabel)),
            ],
          ],
        ),
      ),
    );
  }
}
