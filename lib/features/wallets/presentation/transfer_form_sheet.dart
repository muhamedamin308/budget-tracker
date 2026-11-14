import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/utils/money_format.dart';
import '../../../core/widgets/amount_hero_field.dart';
import '../domain/wallet_entity.dart';
import 'wallet_cubit.dart';
import 'wallet_form_dialog.dart';

abstract final class _S {
  static const title = 'Transfer funds';
  static const from = 'From';
  static const to = 'To';
  static const swap = 'Swap wallets';
  static const noteLabel = 'Note (optional)';
  static const transfer = 'Transfer';
  static const needTwoWallets = 'Add another wallet to move money between wallets.';
  static const addWallet = 'Add wallet';
  static const amountInvalid = 'Enter an amount greater than zero';
  static const pickTwoWallets = 'Pick two different wallets.';
  static const genericError = 'Could not complete the transfer. Please try again.';

  static String willGoBelowZero(String name) => '$name will go below zero.';
}

Future<void> showTransferFormSheet(BuildContext context, {int? fromWalletId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => BlocProvider.value(
      value: context.read<WalletCubit>(),
      child: _TransferFormSheet(initialFromWalletId: fromWalletId),
    ),
  );
}

class _TransferFormSheet extends StatefulWidget {
  const _TransferFormSheet({this.initialFromWalletId});

  final int? initialFromWalletId;

  @override
  State<_TransferFormSheet> createState() => _TransferFormSheetState();
}

class _TransferFormSheetState extends State<_TransferFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  int? _fromWalletId;
  int? _toWalletId;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final state = context.read<WalletCubit>().state;
    final active = state.wallets.where((w) => !w.isArchived).toList();
    if (active.isEmpty) return;

    final preferred = widget.initialFromWalletId ?? state.selectedWalletId;
    final from = active.firstWhere((w) => w.id == preferred, orElse: () => active.first);
    _fromWalletId = from.id;
    _toWalletId = active.where((w) => w.id != from.id).firstOrNull?.id;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _swap() {
    setState(() {
      final from = _fromWalletId;
      _fromWalletId = _toWalletId;
      _toWalletId = from;
    });
  }

  String? _validateAmount(String? value) {
    final minor = parseMinor(value ?? '');
    return (minor == null || minor <= 0) ? _S.amountInvalid : null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final from = _fromWalletId;
    final to = _toWalletId;
    final amountMinor = parseMinor(_amountController.text);
    if (from == null || to == null || from == to) {
      setState(() => _error = _S.pickTwoWallets);
      return;
    }
    if (amountMinor == null || amountMinor <= 0) return;

    final cubit = context.read<WalletCubit>();
    final note = _noteController.text.trim();

    setState(() {
      _submitting = true;
      _error = null;
    });

    final success = await cubit.createTransfer(
      TransferDraft(
        fromWalletId: from,
        toWalletId: to,
        amountMinor: amountMinor,
        note: note.isEmpty ? null : note,
        createdAt: DateTime.now(),
      ),
    );

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _submitting = false;
      _error = cubit.state.errorMessage ?? _S.genericError;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<WalletCubit, WalletState>(
      builder: (context, state) {
        final active = state.wallets.where((w) => !w.isArchived).toList();
        final canTransfer = active.length >= 2;

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
                  Text(_S.title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  if (!canTransfer)
                    _NeedTwoWallets(
                      onAdd: () => showWalletFormDialog(context),
                    )
                  else ...[
                    AmountHeroField(
                      controller: _amountController,
                      autofocus: true,
                      validator: _validateAmount,
                    ),
                    const SizedBox(height: 16),
                    _SectionLabel(_S.from),
                    const SizedBox(height: 8),
                    _WalletChoices(
                      wallets: active,
                      selectedId: _fromWalletId,
                      disabledId: _toWalletId,
                      onSelected: (id) => setState(() => _fromWalletId = id),
                    ),
                    Center(
                      child: IconButton(
                        tooltip: _S.swap,
                        onPressed: _swap,
                        icon: const Icon(Icons.swap_vert_rounded),
                      ),
                    ),
                    _SectionLabel(_S.to),
                    const SizedBox(height: 8),
                    _WalletChoices(
                      wallets: active,
                      selectedId: _toWalletId,
                      disabledId: _fromWalletId,
                      onSelected: (id) => setState(() => _toWalletId = id),
                    ),
                    _BelowZeroHint(
                      amountController: _amountController,
                      wallet: active
                          .where((w) => w.id == _fromWalletId)
                          .firstOrNull,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _noteController,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: _S.noteLabel,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: _submitting
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Text(_S.transfer),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
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

class _WalletChoices extends StatelessWidget {
  const _WalletChoices({
    required this.wallets,
    required this.selectedId,
    required this.disabledId,
    required this.onSelected,
  });

  final List<WalletEntity> wallets;
  final int? selectedId;
  final int? disabledId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final wallet in wallets)
          _WalletOption(
            wallet: wallet,
            selected: wallet.id == selectedId,
            enabled: wallet.id != disabledId,
            onTap: () => onSelected(wallet.id),
          ),
      ],
    );
  }
}

class _WalletOption extends StatelessWidget {
  const _WalletOption({
    required this.wallet,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final WalletEntity wallet;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final balance = wallet.balanceMinor ?? 0;

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: '${wallet.name}, ${formatMinor(balance)}',
      onTap: enabled ? onTap : null,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Material(
          color: selected
              ? AppTheme.primaryEmerald.withValues(alpha: 0.12)
              : Colors.transparent,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              width: selected ? 1.5 : 1,
              color: selected
                  ? AppTheme.primaryEmerald
                  : scheme.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          child: InkWell(
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CategoryIcons.getIcon(wallet.iconKey),
                    size: 20,
                    color: selected
                        ? AppTheme.primaryEmerald
                        : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wallet.name,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        formatMinor(balance),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: balance < 0
                              ? AppTheme.expenseCoral
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BelowZeroHint extends StatelessWidget {
  const _BelowZeroHint({required this.amountController, required this.wallet});

  final TextEditingController amountController;
  final WalletEntity? wallet;

  @override
  Widget build(BuildContext context) {
    final source = wallet;
    if (source == null) return const SizedBox.shrink();

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: amountController,
      builder: (context, value, _) {
        final minor = parseMinor(value.text);
        final balance = source.balanceMinor ?? 0;
        if (minor == null || minor <= balance) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: AppTheme.expenseCoral,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _S.willGoBelowZero(source.name),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.expenseCoral,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NeedTwoWallets extends StatelessWidget {
  const _NeedTwoWallets({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          _S.needTwoWallets,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
          label: const Text(_S.addWallet),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}