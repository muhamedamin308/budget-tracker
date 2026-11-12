import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/services/widget_sync_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/widgets/app_animations.dart';
import '../../../core/widgets/entrance_animation.dart';
import '../../budget/presentation/monthly_limit_dialog.dart';
import '../../categories/domain/category_entity.dart';
import '../../categories/presentation/categories_bloc.dart';
import '../../recurring/presentation/recurring_rules_page.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          EntranceAnimation(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Categories',
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Organize income & spending tags',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryEmerald.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: FilledButton.icon(
                    onPressed: () => _addCategory(context),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Add'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          EntranceAnimation(
            delay: const Duration(milliseconds: 70),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SettingsAction(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Monthly limit',
                      subtitle: 'Set budget cap',
                      onTap: () => showMonthlyLimitDialog(context),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE2E8F0),
                  ),
                  Expanded(
                    child: _SettingsAction(
                      icon: Icons.event_repeat_rounded,
                      label: 'Recurring',
                      subtitle: 'Automated rules',
                      onTap: () => showRecurringRules(context),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE2E8F0),
                  ),
                  Expanded(
                    child: _SettingsAction(
                      icon: Icons.widgets_rounded,
                      label: 'Widget',
                      subtitle: 'Home screen',
                      onTap: () => _showWidgetSettingsDialog(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: BlocBuilder<CategoriesBloc, CategoriesState>(
              builder: (context, state) => switch (state) {
                CategoriesInitial() || CategoriesLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                CategoriesError(:final message) => _ErrorView(
                  message: message,
                  onRetry: () => context.read<CategoriesBloc>().add(
                    const CategoriesRetryRequested(),
                  ),
                ),
                CategoriesLoaded(:final categories, :final errorMessage) =>
                  _CategoriesContent(
                    categories: categories,
                    errorMessage: errorMessage,
                  ),
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addCategory(BuildContext context) async {
    final draft = await showDialog<_CategoryDraft>(
      context: context,
      builder: (_) => const _CategoryEditorDialog(),
    );
    if (draft == null || !context.mounted) return;
    context.read<CategoriesBloc>().add(
      CategoryAdded(name: draft.name, type: draft.type, iconKey: draft.iconKey),
    );
  }

  Future<void> _showWidgetSettingsDialog(BuildContext context) async {
    final syncService = getIt<WidgetSyncService>();
    final isSupported = await syncService.isPinWidgetSupported();

    if (!context.mounted) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryEmerald.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.widgets_rounded,
                            color: AppTheme.primaryEmerald,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Home Screen Widget',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Android home screen companion',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'BUDGET TRACKER',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryEmerald,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '+ Expense',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        syncService.isBalanceHidden ? '••••••' : 'Live Balance',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Budget: Spent vs. Limit progress',
                        style: TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Hide balance on widget',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Displays •••••• instead of your balance for privacy.',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: syncService.isBalanceHidden,
                  activeTrackColor: AppTheme.primaryEmerald,
                  onChanged: (val) async {
                    await syncService.setBalanceHidden(val);
                    setSheetState(() {});
                  },
                ),
                const Divider(),
                const SizedBox(height: 10),
                if (isSupported)
                  FilledButton.icon(
                    onPressed: () async {
                      final success = await syncService.requestPinWidget();
                      if (context.mounted) {
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Widget pin prompt sent to home screen!'
                                  : 'Could not pin widget.',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.add_to_home_screen_rounded),
                    label: const Text('Add Widget to Home Screen'),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () async {
                      await syncService.syncNow();
                      if (context.mounted) {
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Widget refreshed!')),
                        );
                      }
                    },
                    icon: const Icon(Icons.sync_rounded),
                    label: const Text('Sync Widget Data Now'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SettingsAction extends StatelessWidget {
  const _SettingsAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        color: Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [
                          AppTheme.primaryEmerald.withValues(alpha: 0.14),
                          AppTheme.primaryEmerald.withValues(alpha: 0.05),
                        ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryEmerald.withValues(
                    alpha: isDark ? 0.3 : 0.18,
                  ),
                ),
              ),
              child: Icon(icon, color: AppTheme.primaryEmerald, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriesContent extends StatelessWidget {
  const _CategoriesContent({
    required this.categories,
    required this.errorMessage,
  });

  final List<CategoryEntity> categories;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final income = categories
        .where((category) => category.type == CategoryType.income)
        .toList();
    final expenses = categories
        .where((category) => category.type == CategoryType.expense)
        .toList();

    return Column(
      children: [
        if (errorMessage != null)
          _ErrorBanner(
            message: errorMessage!,
            onDismiss: () => context.read<CategoriesBloc>().add(
              const CategoriesRetryRequested(),
            ),
          ),
        Expanded(
          child: categories.isEmpty
              ? _EmptyCategories(onAdd: () => _addCategory(context))
              : ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    if (income.isNotEmpty)
                      _CategorySection(
                        title: 'Income',
                        categories: income,
                        accentColor: AppTheme.incomeGreen,
                      ),
                    if (expenses.isNotEmpty)
                      _CategorySection(
                        title: 'Expenses',
                        categories: expenses,
                        accentColor: AppTheme.expenseCoral,
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _addCategory(BuildContext context) async {
    final draft = await showDialog<_CategoryDraft>(
      context: context,
      builder: (_) => const _CategoryEditorDialog(),
    );
    if (draft == null || !context.mounted) return;
    context.read<CategoriesBloc>().add(
      CategoryAdded(name: draft.name, type: draft.type, iconKey: draft.iconKey),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.title,
    required this.categories,
    required this.accentColor,
  });

  final String title;
  final List<CategoryEntity> categories;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${categories.length}',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF1F5F9),
            ),
            itemBuilder: (context, index) {
              final category = categories[index];
              return EntranceAnimation(
                delay: Duration(milliseconds: index < 10 ? index * 30 : 300),
                duration: const Duration(milliseconds: 320),
                offset: const Offset(0, 0.03),
                child: _CategoryTile(
                  category: category,
                  accentColor: accentColor,
                  onRename: () => _renameCategory(context, category),
                  onArchive: () => _archiveCategory(context, category),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _renameCategory(
    BuildContext context,
    CategoryEntity category,
  ) async {
    final draft = await showDialog<_CategoryDraft>(
      context: context,
      builder: (_) => _CategoryEditorDialog(category: category),
    );
    if (draft == null || !context.mounted) return;
    context.read<CategoriesBloc>().add(
      CategoryRenamed(
        id: category.id,
        name: draft.name,
        iconKey: draft.iconKey,
      ),
    );
  }

  Future<void> _archiveCategory(
    BuildContext context,
    CategoryEntity category,
  ) async {
    final shouldArchive = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Archive category?'),
        content: Text(
          '${category.name} will be hidden from new transactions. '
          'Existing transactions will keep this category.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (shouldArchive != true || !context.mounted) return;
    context.read<CategoriesBloc>().add(CategoryArchived(category.id));
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.accentColor,
    required this.onRename,
    required this.onArchive,
  });

  final CategoryEntity category;
  final Color accentColor;
  final VoidCallback onRename;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: isDark ? 0.2 : 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: accentColor.withValues(alpha: isDark ? 0.35 : 0.2),
            width: 1,
          ),
        ),
        child: Icon(
          CategoryIcons.getIcon(category.iconKey),
          color: accentColor,
          size: 20,
        ),
      ),
      title: Text(
        category.name,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        category.type == CategoryType.income
            ? 'Income category'
            : 'Expense category',
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: PopupMenuButton<String>(
        tooltip: 'Category actions',
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: Icon(
          Icons.more_vert_rounded,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onSelected: (action) {
          if (action == 'rename') onRename();
          if (action == 'archive') onArchive();
        },
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: 'rename',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 18),
                SizedBox(width: 10),
                Text('Rename'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'archive',
            child: Row(
              children: [
                Icon(Icons.archive_outlined, size: 18),
                SizedBox(width: 10),
                Text('Archive'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCategories extends StatelessWidget {
  const _EmptyCategories({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: AppTheme.primaryEmerald.withValues(
                alpha: isDark ? 0.15 : 0.08,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.category_outlined,
              size: 56,
              color: AppTheme.primaryEmerald,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No categories yet',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create categories to organize your transactions.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add category'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colors.onErrorContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Dismiss error',
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _CategoryDraft {
  const _CategoryDraft({
    required this.name,
    required this.type,
    required this.iconKey,
  });

  final String name;
  final CategoryType type;
  final String iconKey;
}

class _CategoryEditorDialog extends StatefulWidget {
  const _CategoryEditorDialog({this.category});

  final CategoryEntity? category;

  @override
  State<_CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<_CategoryEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late CategoryType _type;
  late String _selectedIconKey;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name);
    _type = widget.category?.type ?? CategoryType.expense;
    _selectedIconKey = CategoryIcons.selectableKeyFor(
      widget.category?.iconKey ?? 'category',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.category_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            widget.category == null ? 'Add category' : 'Rename category',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  maxLength: 40,
                  decoration: const InputDecoration(
                    labelText: 'Category name',
                    hintText: 'e.g., Groceries, Salary, Freelance',
                  ),
                  validator: (value) {
                    final name = value?.trim() ?? '';
                    if (name.isEmpty) return 'Enter a category name.';
                    if (name.length > 40) return 'Use 40 characters or fewer.';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Choose Icon',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _selectedIconKey,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryEmerald,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF152033) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      childAspectRatio: 1,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: CategoryIcons.availableIconKeys.length,
                    itemBuilder: (context, index) {
                      final iconKey = CategoryIcons.availableIconKeys[index];
                      final isSelected = iconKey == _selectedIconKey;
                      return InkWell(
                        onTap: () => setState(() => _selectedIconKey = iconKey),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryEmerald.withValues(
                                    alpha: isDark ? 0.3 : 0.18,
                                  )
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryEmerald
                                  : isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : const Color(0xFFE2E8F0),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Icon(
                            CategoryIcons.getIcon(iconKey),
                            color: isSelected
                                ? AppTheme.primaryEmerald
                                : theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (widget.category == null) ...[
                  const SizedBox(height: 14),
                  DropdownButtonFormField<CategoryType>(
                    initialValue: _type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: const [
                      DropdownMenuItem(
                        value: CategoryType.income,
                        child: Row(
                          children: [
                            Icon(
                              Icons.arrow_downward_rounded,
                              size: 16,
                              color: AppTheme.incomeGreen,
                            ),
                            SizedBox(width: 8),
                            Text('Income'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: CategoryType.expense,
                        child: Row(
                          children: [
                            Icon(
                              Icons.arrow_upward_rounded,
                              size: 16,
                              color: AppTheme.expenseCoral,
                            ),
                            SizedBox(width: 8),
                            Text('Expense'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (type) {
                      if (type != null) setState(() => _type = type);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _CategoryDraft(
                name: _nameController.text.trim(),
                type: _type,
                iconKey: _selectedIconKey,
              ),
            );
          },
          child: Text(widget.category == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
