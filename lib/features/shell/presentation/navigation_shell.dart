import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../budget/presentation/budget_bloc.dart';
import 'month_cubit.dart';

class NavigationShell extends StatefulWidget {
  const NavigationShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell>
    with TickerProviderStateMixin {
  late final List<AnimationController> _scaleControllers;
  late final List<Animation<double>> _scaleAnimations;

  static const _destinations = [
    _NavDestination(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _NavDestination(
      label: 'Stats',
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights_rounded,
    ),
    _NavDestination(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _scaleControllers = List.generate(
      _destinations.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 150),
        value: i == widget.navigationShell.currentIndex ? 1.0 : 0.0,
      ),
    );

    _scaleAnimations = _scaleControllers.map((controller) {
      return Tween<double>(
        begin: 1.0,
        end: 1.18,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
    }).toList();
  }

  @override
  void dispose() {
    for (final controller in _scaleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (index == widget.navigationShell.currentIndex) return;

    HapticFeedback.selectionClick();

    // Reverse the previously selected tab's animation
    _scaleControllers[widget.navigationShell.currentIndex].reverse();
    // Forward the new tab's animation
    _scaleControllers[index].forward();

    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MonthCubit, DateTime>(
      listener: (context, month) =>
          context.read<BudgetBloc>().add(BudgetMonthChanged(month)),
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: _onTabSelected,
          destinations: List.generate(_destinations.length, (i) {
            final dest = _destinations[i];
            final isSelected = i == widget.navigationShell.currentIndex;
            return NavigationDestination(
              label: dest.label,
              icon: ScaleTransition(
                scale: _scaleAnimations[i],
                child: Icon(isSelected ? dest.selectedIcon : dest.icon),
              ),
              selectedIcon: ScaleTransition(
                scale: _scaleAnimations[i],
                child: Icon(dest.selectedIcon),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavDestination {
  const _NavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
