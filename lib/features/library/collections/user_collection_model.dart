import 'package:equatable/equatable.dart';
import 'package:picklog/features/library/library_entry_model.dart';

/// A user-owned list of library entries (`/users/me/collections`).
///
/// Separate from the editorial game collections shown on Home and Browse.
class UserCollection extends Equatable {
  const UserCollection({
    required this.id,
    required this.name,
    required this.gameCount,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.coverUrls = const [],
  });

  factory UserCollection.fromJson(Map<String, dynamic> json) {
    return UserCollection(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      gameCount: json['game_count'] as int? ?? 0,
      coverUrls:
          (json['cover_urls'] as List<dynamic>?)
              ?.map((u) => u as String)
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Most collections a user can own.
  static const int maxPerUser = 50;

  /// Longest allowed name.
  static const int maxNameLength = 60;

  /// Longest allowed description.
  static const int maxDescriptionLength = 280;

  final String id;
  final String name;
  final String? description;
  final int gameCount;

  /// Up to four cover URLs for the mosaic.
  final List<String> coverUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserCollection copyWith({
    String? name,
    String? description,
    bool clearDescription = false,
    int? gameCount,
    List<String>? coverUrls,
    DateTime? updatedAt,
  }) {
    return UserCollection(
      id: id,
      name: name ?? this.name,
      description: clearDescription ? null : (description ?? this.description),
      gameCount: gameCount ?? this.gameCount,
      coverUrls: coverUrls ?? this.coverUrls,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    gameCount,
    coverUrls,
    createdAt,
    updatedAt,
  ];
}

/// A collection with its entries in position order.
class UserCollectionDetail extends Equatable {
  const UserCollectionDetail({required this.collection, required this.entries});

  factory UserCollectionDetail.fromJson(Map<String, dynamic> json) {
    return UserCollectionDetail(
      collection: UserCollection.fromJson(json),
      entries:
          (json['entries'] as List<dynamic>?)
              ?.map((e) => LibraryEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  final UserCollection collection;
  final List<LibraryEntry> entries;

  @override
  List<Object?> get props => [collection, entries];
}
