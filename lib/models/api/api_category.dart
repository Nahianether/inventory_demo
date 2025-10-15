/// API Category Model - matches backend schema
class ApiCategory {
  final String id;
  final String name;
  final String? description;
  final String? parentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ApiCategory({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ApiCategory.fromJson(Map<String, dynamic> json) {
    return ApiCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      parentId: json['parent_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (description != null) 'description': description,
    if (parentId != null) 'parent_id': parentId,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

/// Request model for creating a category
class CreateCategoryRequest {
  final String name;
  final String? description;
  final String? parentId;

  CreateCategoryRequest({
    required this.name,
    this.description,
    this.parentId,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    if (description != null) 'description': description,
    if (parentId != null) 'parent_id': parentId,
  };
}

/// Request model for updating a category
class UpdateCategoryRequest {
  final String? name;
  final String? description;
  final String? parentId;

  UpdateCategoryRequest({
    this.name,
    this.description,
    this.parentId,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (description != null) map['description'] = description;
    if (parentId != null) map['parent_id'] = parentId;
    return map;
  }
}
