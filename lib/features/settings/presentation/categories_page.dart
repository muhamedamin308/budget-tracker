import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../budget/presentation/monthly_limit_dialog.dart';
import '../../categories/domain/category_entity.dart';
import '../../categories/presentation/categories_bloc.dart';
import '../../recurring/presentation/recurring_rules_page.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Settings',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _addCategory(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Categories',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => showMonthlyLimitDialog(context),
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  label: const Text('Monthly limit'),
                ),
                TextButton.icon(
                  onPressed: () => showRecurringRules(context),
                  icon: const Icon(Icons.event_repeat_outlined),
                  label: const Text('Recurring rules'),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
      CategoryAdded(name: draft.name, type: draft.type),
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
                  padding: const EdgeInsets.only(bottom: 16),
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
      CategoryAdded(name: draft.name, type: draft.type),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 6),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryTile(
                category: category,
                accentColor: accentColor,
                onRename: () => _renameCategory(context, category),
                onArchive: () => _archiveCategory(context, category),
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
      CategoryRenamed(id: category.id, name: draft.name),
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(
        Icons.sell_outlined,
        color: Theme.of(context).colorScheme.secondary,
      ),
      title: Text(category.name),
      trailing: PopupMenuButton<String>(
        tooltip: 'Category actions',
        onSelected: (action) {
          if (action == 'rename') onRename();
          if (action == 'archive') onArchive();
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'rename', child: Text('Rename')),
          PopupMenuItem(value: 'archive', child: Text('Archive')),
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('No categories yet'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add category'),
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
          IconButton(
            tooltip: 'Dismiss error',
            onPressed: onDismiss,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _CategoryDraft {
  const _CategoryDraft({required this.name, required this.type});

  final String name;
  final CategoryType type;
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name);
    _type = widget.category?.type ?? CategoryType.expense;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? 'Add category' : 'Rename category'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              maxLength: 40,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) {
                final name = value?.trim() ?? '';
                if (name.isEmpty) return 'Enter a category name.';
                if (name.length > 40) return 'Use 40 characters or fewer.';
                return null;
              },
            ),
            if (widget.category == null)
              DropdownButtonFormField<CategoryType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(
                    value: CategoryType.income,
                    child: Text('Income'),
                  ),
                  DropdownMenuItem(
                    value: CategoryType.expense,
                    child: Text('Expense'),
                  ),
                ],
                onChanged: (type) {
                  if (type != null) setState(() => _type = type);
                },
              ),
          ],
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
              _CategoryDraft(name: _nameController.text.trim(), type: _type),
            );
          },
          child: Text(widget.category == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
