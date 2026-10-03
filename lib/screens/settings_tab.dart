library;

import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';
import '../config/strings.dart';
import '../services/fuel_controller.dart';
import '../services/settings_store.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  String _version = '';
  bool _langOpen = false;
  bool _themeOpen = false;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (!mounted) return;
      setState(() => _version = '${info.version}+${info.buildNumber}');
    });
  }

  String _langLabel(AppLang lang) => switch (lang) {
        AppLang.tr => 'Türkçe',
        AppLang.en => 'English',
        AppLang.ar => 'العربية',
      };

  String _themeLabel(AppStrings s, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return s.themeLight;
      case ThemeMode.dark:
        return s.themeDark;
      case ThemeMode.system:
        return s.themeSystem;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsStore>();
    final fuel = context.watch<FuelController>();
    final s = context.watch<AppStrings>();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            s.tabSettings,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
          ),
          const SizedBox(height: 20),
          _ExpandableChoice(
            title: s.language,
            valueLabel: _langLabel(settings.lang),
            expanded: _langOpen,
            onToggle: () => setState(() {
              _langOpen = !_langOpen;
              if (_langOpen) _themeOpen = false;
            }),
            children: [
              for (final lang in AppLang.values)
                _ChoiceTile(
                  label: _langLabel(lang),
                  selected: settings.lang == lang,
                  onTap: () {
                    settings.setLang(lang);
                    setState(() => _langOpen = false);
                  },
                ),
            ],
          ),
          _ExpandableChoice(
            title: s.theme,
            valueLabel: _themeLabel(s, settings.themeMode),
            expanded: _themeOpen,
            onToggle: () => setState(() {
              _themeOpen = !_themeOpen;
              if (_themeOpen) _langOpen = false;
            }),
            children: [
              for (final mode in [
                ThemeMode.system,
                ThemeMode.light,
                ThemeMode.dark,
              ])
                _ChoiceTile(
                  label: _themeLabel(s, mode),
                  selected: settings.themeMode == mode,
                  onTap: () {
                    settings.setThemeMode(mode);
                    setState(() => _themeOpen = false);
                  },
                ),
            ],
          ),
          _Section(
            title: s.defaultLocation,
            child: Column(
              children: [
                InputDecorator(
                  decoration: InputDecoration(labelText: s.selectCity),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: fuel.cities.any((c) => c.id == fuel.cityId)
                          ? fuel.cityId
                          : null,
                      items: fuel.cities
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) fuel.setCity(v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                InputDecorator(
                  decoration: InputDecoration(labelText: s.selectDistrict),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: fuel.districtId.isNotEmpty &&
                              fuel.districts
                                  .any((d) => d.id == fuel.districtId)
                          ? fuel.districtId
                          : null,
                      hint: Text(s.pickDistrict),
                      items: fuel.districts
                          .map(
                            (d) => DropdownMenuItem(
                              value: d.id,
                              child: Text(d.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) fuel.setDistrict(v);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          _Section(
            title: s.about,
            child: Text(
              s.aboutBody,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
          ),
          _LinkTile(
            title: s.privacy,
            onTap: () => _open(ApiConfig.privacyUrl),
          ),
          _LinkTile(
            title: s.terms,
            onTap: () => _open(ApiConfig.termsUrl),
          ),
          const SizedBox(height: 8),
          Text(
            s.helpSupport,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          _LinkTile(
            title: s.contactUs,
            onTap: () => _open('mailto:${ApiConfig.supportEmail}'),
          ),
          _LinkTile(
            title: s.rateApp,
            onTap: () async {
              final review = InAppReview.instance;
              if (await review.isAvailable()) {
                await review.requestReview();
              }
            },
          ),
          const SizedBox(height: 28),
          Center(
            child: Text(
              '${s.version} $_version',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _ExpandableChoice extends StatelessWidget {
  const _ExpandableChoice({
    required this.title,
    required this.valueLabel,
    required this.expanded,
    required this.onToggle,
    required this.children,
  });

  final String title;
  final String valueLabel;
  final bool expanded;
  final VoidCallback onToggle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            valueLabel,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurface.withValues(alpha: 0.55),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: scheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  Divider(
                    height: 1,
                    color: scheme.outlineVariant.withValues(alpha: 0.45),
                  ),
                  ...children,
                ],
              ),
              crossFadeState: expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 180),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        dense: true,
        title: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        trailing: selected
            ? Icon(Icons.check_rounded, color: scheme.primary, size: 20)
            : null,
        onTap: onTap,
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
