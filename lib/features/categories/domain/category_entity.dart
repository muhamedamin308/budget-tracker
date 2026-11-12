import 'package:equatable/equatable.dart';

enum CategoryType { income, expense }

class CategoryEntity extends Equatable {
  const CategoryEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.iconKey,
    required this.isDefault,
    required this.isArchived,
  });

  final int id;
  final String name;
  final CategoryType type;
  final String iconKey;
  final bool isDefault;
  final bool isArchived;

  @override
  List<Object?> get props => [id, name, type, iconKey, isDefault, isArchived];
}
