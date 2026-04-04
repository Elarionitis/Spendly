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

  factory Group.fromJson(Map<String, dynamic> json, {String? id}) {
    return Group(
      id: id ?? json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdById: json['createdById'] as String? ?? '',
      memberIds: List<String>.from(json['memberIds'] as List? ?? []),
      createdAt: json['createdAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
          : (json['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      emoji: json['emoji'] as String?,
      smartSplitEnabled: json['smartSplitEnabled'] as bool? ?? false,
      defaultSplitType: SplitType.values.firstWhere(
        (e) => e.name == (json['defaultSplitType'] as String?),
        orElse: () => SplitType.equal,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdById': createdById,
      'memberIds': memberIds,
      'createdAt': createdAt.millisecondsSinceEpoch,
      if (emoji != null) 'emoji': emoji,
      'smartSplitEnabled': smartSplitEnabled,
      'defaultSplitType': defaultSplitType.name,
    };
  }

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
