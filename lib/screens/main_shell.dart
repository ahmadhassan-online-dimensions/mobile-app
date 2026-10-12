import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import 'account_screen.dart';
import 'bag_screen.dart';
import 'home_screen.dart';
import 'lens_guide_screen.dart';
import 'shop_screen.dart';

enum AppTab { home, shop, lenses, bag, account }

/// Lets any screen — including ones pushed above the shell — switch tabs.
class ShellScope {
  static final tab = ValueNotifier<AppTab>(AppTab.home);

  static void go(BuildContext context, AppTab t) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    tab.value = t;
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  AppTab get tab => ShellScope.tab.value;

  @override
  void initState() {
    super.initState();
    ShellScope.tab.value = AppTab.home;
    ShellScope.tab.addListener(_changed);
  }

  @override
  void dispose() {
    ShellScope.tab.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (tab == AppTab.bag) AppScope.read(context).refreshCart().catchError((_) {});
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: tab.index,
        children: const [HomeScreen(), ShopScreen(), LensGuideScreen(), BagScreen(), AccountScreen()],
      ),
      bottomNavigationBar: _NavBar(current: tab, onSelect: (t) => ShellScope.tab.value = t),
    );
  }
}

class _NavBar extends StatelessWidget {
  final AppTab current;
  final ValueChanged<AppTab> onSelect;

  const _NavBar({required this.current, required this.onSelect});

  static const items = [
    (AppTab.home, 'Home', Icons.home_outlined),
    (AppTab.shop, 'Shop', Icons.diamond_outlined),
    (AppTab.lenses, 'Lenses', Icons.visibility_outlined),
    (AppTab.bag, 'Bag', Icons.shopping_bag_outlined),
    (AppTab.account, 'Account', Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    final count = AppScope.of(context).bagCount;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              for (final (t, label, icon) in items)
                Expanded(
                  child: Semantics(
                    selected: t == current,
                    button: true,
                    label: t == AppTab.bag && count > 0 ? '$label, $count items' : label,
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: () => onSelect(t),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            top: 0,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: t == current ? 22 : 0,
                              height: 2,
                              color: AppColors.goldBright,
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Badge(
                                isLabelVisible: t == AppTab.bag && count > 0,
                                backgroundColor: AppColors.goldBright,
                                label: Text(
                                  '$count',
                                  style: AppText.sans(size: 10, weight: FontWeight.w700, color: AppColors.ink),
                                ),
                                child: Icon(icon, size: 23, color: t == current ? AppColors.ink : AppColors.muted),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                label,
                                style: AppText.sans(
                                  size: 11.5,
                                  weight: t == current ? FontWeight.w600 : FontWeight.w400,
                                  color: t == current ? AppColors.ink : AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
