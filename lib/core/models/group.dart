import 'enums.dart';

class Group {
  final String id;
  final String name;
  final String description;
  final String createdById;
  final List<String> memberIds;
  final DateTime createdAt;
  final String? emoji;
  final bool smartSplitEnabled;
  final SplitType defaultSplitType;

  const Group({
    required this.id,
    required this.name,
    required this.description,
    required this.createdById,
    required this.memberIds,
    required this.createdAt,
    this.emoji,
    this.smartSplitEnabled = false,
    this.defaultSplitType = SplitType.equal,
  });

  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? createdById,
    List<String>? memberIds,
    DateTime? createdAt,
    String? emoji,
    bool? smartSplitEnabled,
    SplitType? defaultSplitType,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdById: createdById ?? this.createdById,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
      emoji: emoji ?? this.emoji,
      smartSplitEnabled: smartSplitEnabled ?? this.smartSplitEnabled,
      defaultSplitType: defaultSplitType ?? this.defaultSplitType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Group && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
