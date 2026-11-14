import 'package:equatable/equatable.dart';

class WalletEntity extends Equatable {
  const WalletEntity({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.sortOrder,
    required this.isArchived,
    this.balanceMinor,
  });

  final int id;
  final String name;
  final String iconKey;
  final int sortOrder;
  final bool isArchived;
  final int? balanceMinor;

  @override
  List<Object?> get props => [
        id,
        name,
        iconKey,
        sortOrder,
        isArchived,
        balanceMinor,
      ];
}

class WalletDraft {
  const WalletDraft({
    required this.name,
    required this.iconKey,
    this.sortOrder = 0,
  });

  final String name;
  final String iconKey;
  final int sortOrder;
}

class TransferDraft {
  const TransferDraft({
    required this.fromWalletId,
    required this.toWalletId,
    required this.amountMinor,
    this.note,
    this.createdAt,
  });

  final int fromWalletId;
  final int toWalletId;
  final int amountMinor;
  final String? note;
  final DateTime? createdAt;
}
