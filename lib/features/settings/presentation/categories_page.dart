// lib/features/categories/presentation/categories_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/category_icons.dart';
import '../../categories/domain/category_entity.dart';
import '../../categories/presentation/categories_bloc.dart';

abstract final class _S {
  static const title = 'Categories';
  static const add = 'Add category';
  static const expense = 'Expense';
  static const income = 'Income';
  static const retry = 'Retry';
  static const dismissError = 'Dismiss error';
  static const rename = 'Rename';
  static const archive = 'Archive';
  static const cancel = 'Cancel';
  static const actions = 'Category actions';
  static const archiveTitle = 'Archive category?';
  static const newCategory = 'New category';
  static const renameCategory = 'Edit category';
  static const nameLabel = 'Category name';
  static const nameHint = 'e.g. Groceries, Salary';
  static const nameRequired = 'Enter a category name.';
  static const nameTooLong = 'Use 40 characters or fewer.';
  static const typeLabel = 'Type';
  static const iconLabel = 'Icon';
  static const save = 'Save';
  static const create = 'Create';

  static String tabLabel(String label, int count) => '$label ($count)';

  static String archiveBody(String name) =>
      '$name will be hidden from new transactions. '
      'Existing transactions keep this category.';

  static String emptyTitle(bool isIncome) =>
      isIncome ? 'No income categories yet' : 'No expense categories yet';
  static const emptyBody = 'Add one to organize your transactions.';
}

const int _maxNameLength = 40;

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CategoriesBloc>()..add(const CategoriesStarted()),
      child: const _CategoriesView(),
    );
  }
}

class _CategoriesView extends StatefulWidget {
  const _CategoriesView();

  @override
  State<_CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<_CategoriesView> {
  CategoryType _type = CategoryType.expense;

  Future<_CategoryDraft?> _showEditor({CategoryEntity? category}) {
    return showModalBottomSheet<_CategoryDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) =>
          _CategoryEditorSheet(category: category, initialType: _type),
    );
  }

  Future<void> _add() async {
    final draft = await _showEditor();
    if (draft == null || !mounted) return;
    context.read<CategoriesBloc>().add(
      CategoryAdded(name: draft.name, type: draft.type, iconKey: draft.iconKey),
    );
  }

  Future<void> _rename(CategoryEntity category) async {
    final draft = await _showEditor(category: category);
    if (draft == null || !mounted) return;
    context.read<CategoriesBloc>().add(
      CategoryRenamed(
        id: category.id,
        name: draft.name,
        iconKey: draft.iconKey,
      ),
    );
  }

  Future<void> _archive(CategoryEntity category) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text(_S.archiveTitle),
            content: Text(_S.archiveBody(category.name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text(_S.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text(_S.archive),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    context.read<CategoriesBloc>().add(CategoryArchived(category.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(_S.title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_rounded),
        label: const Text(_S.add),
      ),
      body: BlocBuilder<CategoriesBloc, CategoriesState>(
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
            _LoadedView(
              categories: categories,
              errorMessage: errorMessage,
              type: _type,
              onTypeChanged: (type) => setState(() => _type = type),
              onAdd: _add,
              onRename: _rename,
              onArchive: _archive,
            ),
        },
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({
    required this.categories,
    required this.errorMessage,
    required this.type,
    required this.onTypeChanged,
    required this.onAdd,
    required this.onRename,
    required this.onArchive,
  });

  final List<CategoryEntity> categories;
  final String? errorMessage;
  final CategoryType type;
  final ValueChanged<CategoryType> onTypeChanged;
  final VoidCallback onAdd;
  final ValueChanged<CategoryEntity> onRename;
  final ValueChanged<CategoryEntity> onArchive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final outline = theme.colorScheme.outlineVariant;
    final banner = errorMessage;

    final expenseCount = categories
        .where((c) => c.type == CategoryType.expense)
        .length;
    final incomeCount = categories
        .where((c) => c.type == CategoryType.income)
        .length;
    final visible = categories.where((c) => c.type == type).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<CategoryType>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(minimumSize: const Size(0, 48)),
              segments: [
                ButtonSegment(
                  value: CategoryType.expense,
                  label: Text(_S.tabLabel(_S.expense, expenseCount)),
                ),
                ButtonSegment(
                  value: CategoryType.income,
                  label: Text(_S.tabLabel(_S.income, incomeCount)),
                ),
              ],
              selected: {type},
              onSelectionChanged: (selection) => onTypeChanged(selection.first),
            ),
          ),
        ),
        if (banner != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _ErrorBanner(
              message: banner,
              onDismiss: () => context.read<CategoriesBloc>().add(
                const CategoriesRetryRequested(),
              ),
            ),
          ),
        Expanded(
          child: visible.isEmpty
              ? _EmptyState(isIncome: type == CategoryType.income, onAdd: onAdd)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                  children: [
                    Material(
                      color: theme.cardColor,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: outline.withValues(alpha: isDark ? 0.3 : 0.5),
                        ),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < visible.length; i++) ...[
                            if (i > 0)
                              Divider(
                                height: 1,
                                indent: 70,
                                color: outline.withValues(alpha: 0.4),
                              ),
                            _CategoryTile(
                              category: visible[i],
                              onRename: () => onRename(visible[i]),
                              onArchive: () => onArchive(visible[i]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.onRename,
    required this.onArchive,
  });

  final CategoryEntity category;
  final VoidCallback onRename;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onRename,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryEmerald.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                CategoryIcons.getIcon(category.iconKey),
                size: 20,
                color: AppTheme.primaryEmerald,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: _S.actions,
              icon: Icon(
                Icons.more_vert_rounded,
                color: scheme.onSurfaceVariant,
              ),
              onSelected: (action) {
                if (action == 'rename') onRename();
                if (action == 'archive') onArchive();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'rename', child: Text(_S.rename)),
                PopupMenuItem(value: 'archive', child: Text(_S.archive)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isIncome, required this.onAdd});

  final bool isIncome;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.primaryEmerald.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.category_outlined,
                size: 30,
                color: AppTheme.primaryEmerald,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _S.emptyTitle(isIncome),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _S.emptyBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onAdd,
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
              icon: const Icon(Icons.add_rounded),
              label: const Text(_S.add),
            ),
          ],
        ),
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

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(_S.retry),
            ),
          ],
        ),
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
      padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: colors.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colors.onErrorContainer,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            tooltip: _S.dismissError,
            onPressed: onDismiss,
            iconSize: 18,
            icon: Icon(Icons.close_rounded, color: colors.onErrorContainer),
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

class _CategoryEditorSheet extends StatefulWidget {
  const _CategoryEditorSheet({required this.initialType, this.category});

  final CategoryEntity? category;
  final CategoryType initialType;

  @override
  State<_CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<_CategoryEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController = TextEditingController(
    text: widget.category?.name,
  );
  late CategoryType _type = widget.category?.type ?? widget.initialType;
  late String _iconKey = CategoryIcons.selectableKeyFor(
    widget.category?.iconKey ?? 'category',
  );

  bool get _isEditing => widget.category != null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      _CategoryDraft(
        name: _nameController.text.trim(),
        type: _type,
        iconKey: _iconKey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? _S.renameCategory : _S.newCategory,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                maxLength: _maxNameLength,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: _S.nameLabel,
                  hintText: _S.nameHint,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final name = value?.trim() ?? '';
                  if (name.isEmpty) return _S.nameRequired;
                  if (name.length > _maxNameLength) return _S.nameTooLong;
                  return null;
                },
              ),
              if (!_isEditing) ...[
                const SizedBox(height: 8),
                _SectionLabel(_S.typeLabel),
                const SizedBox(height: 8),
                SegmentedButton<CategoryType>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: CategoryType.expense,
                      label: Text(_S.expense),
                    ),
                    ButtonSegment(
                      value: CategoryType.income,
                      label: Text(_S.income),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (selection) =>
                      setState(() => _type = selection.first),
                ),
              ],
              const SizedBox(height: 16),
              _SectionLabel(_S.iconLabel),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final key in CategoryIcons.availableIconKeys)
                    _IconOption(
                      iconKey: key,
                      selected: key == _iconKey,
                      onTap: () => setState(() => _iconKey = key),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: Text(_isEditing ? _S.save : _S.create),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _IconOption extends StatelessWidget {
  const _IconOption({
    required this.iconKey,
    required this.selected,
    required this.onTap,
  });

  final String iconKey;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: iconKey.replaceAll('_', ' '),
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: selected
            ? AppTheme.primaryEmerald
            : scheme.surfaceContainerHighest,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(
              CategoryIcons.getIcon(iconKey),
              color: selected ? Colors.white : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
