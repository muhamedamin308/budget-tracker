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

  static String count(int n) => n == 1 ? '1 category' : '$n categories';

  static String headerTitle(bool isIncome) =>
      isIncome ? 'Income categories' : 'Expense categories';

  static String archiveBody(String name) =>
      '$name will be hidden from new transactions. '
      'Existing transactions keep this category.';

  static String emptyTitle(bool isIncome) =>
      isIncome ? 'No income categories yet' : 'No expense categories yet';
  static const emptyBody = 'Add one to organize your transactions.';
}

const int _maxNameLength = 40;

Color _accent(CategoryType type) => type == CategoryType.income
    ? AppTheme.incomeGreen
    : AppTheme.primaryEmerald;

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
    final banner = errorMessage;
    final visible = categories.where((c) => c.type == type).toList();
    final expenseCount = categories
        .where((c) => c.type == CategoryType.expense)
        .length;
    final incomeCount = categories
        .where((c) => c.type == CategoryType.income)
        .length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: _HeaderCard(
            type: type,
            count: type == CategoryType.income ? incomeCount : expenseCount,
            expenseCount: expenseCount,
            incomeCount: incomeCount,
            onTypeChanged: onTypeChanged,
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
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _CategoryTile(
                    category: visible[i],
                    onRename: () => onRename(visible[i]),
                    onArchive: () => onArchive(visible[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header: gradient summary + type toggle
// ---------------------------------------------------------------------------

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.type,
    required this.count,
    required this.expenseCount,
    required this.incomeCount,
    required this.onTypeChanged,
  });

  final CategoryType type;
  final int count;
  final int expenseCount;
  final int incomeCount;
  final ValueChanged<CategoryType> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = type == CategoryType.income;

    final gradient = isDark
        ? AppTheme.darkCardGradient
        : AppTheme.primaryGradient;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.45)
                : AppTheme.primaryEmerald.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -40,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.09),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _S.headerTitle(isIncome),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _S.count(count),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.8,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _TogglePill(
                        label: '${_S.expense} ($expenseCount)',
                        selected: type == CategoryType.expense,
                        onTap: () => onTypeChanged(CategoryType.expense),
                      ),
                      _TogglePill(
                        label: '${_S.income} ($incomeCount)',
                        selected: type == CategoryType.income,
                        onTap: () => onTypeChanged(CategoryType.income),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  const _TogglePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 11),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: selected
                    ? AppTheme.primaryEmerald
                    : Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// List items
// ---------------------------------------------------------------------------

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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = _accent(category.type);

    return Material(
      color: theme.cardColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.5),
        ),
      ),
      child: InkWell(
        onTap: onRename,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  CategoryIcons.getIcon(category.iconKey),
                  size: 22,
                  color: accent,
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
                    fontSize: 15.5,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: _S.actions,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty and error states
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isIncome, required this.onAdd});

  final bool isIncome;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = isIncome ? AppTheme.incomeGreen : AppTheme.primaryEmerald;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.category_outlined, size: 32, color: accent),
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

// ---------------------------------------------------------------------------
// Editor sheet
// ---------------------------------------------------------------------------

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
    final accent = _accent(_type);

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
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      CategoryIcons.getIcon(_iconKey),
                      size: 26,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _isEditing ? _S.renameCategory : _S.newCategory,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                maxLength: _maxNameLength,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: _S.nameLabel,
                  hintText: _S.nameHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                Row(
                  children: [
                    Expanded(
                      child: _TypeChoice(
                        label: _S.expense,
                        selected: _type == CategoryType.expense,
                        color: AppTheme.primaryEmerald,
                        onTap: () =>
                            setState(() => _type = CategoryType.expense),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TypeChoice(
                        label: _S.income,
                        selected: _type == CategoryType.income,
                        color: AppTheme.incomeGreen,
                        onTap: () =>
                            setState(() => _type = CategoryType.income),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
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
                      color: accent,
                      onTap: () => setState(() => _iconKey = key),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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

class _TypeChoice extends StatelessWidget {
  const _TypeChoice({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? color.withValues(alpha: 0.12) : theme.cardColor,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected
                ? color
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: selected ? color : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
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
    required this.color,
    required this.onTap,
  });

  final String iconKey;
  final bool selected;
  final Color color;
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
        color: selected ? color : scheme.surfaceContainerHighest,
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
