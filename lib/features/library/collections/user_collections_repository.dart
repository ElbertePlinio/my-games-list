import 'package:picklog/core/data/services/http/i_http_client.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:picklog/features/library/collections/user_collection_model.dart';

/// CRUD for the caller's collections (`/users/me/collections`).
class UserCollectionsRepository {
  UserCollectionsRepository({required IHttpClient httpClient})
    : _httpClient = httpClient;

  final IHttpClient _httpClient;

  static const String _base = '/users/me/collections';

  /// Collections ordered by most recently updated.
  Future<List<UserCollection>> getCollections() async {
    final response = await _httpClient.get<Map<String, dynamic>>(_base);
    if (response.isError) {
      throw ApiException(
        response.error,
        fallbackMessage: 'Failed to fetch collections',
      );
    }
    final list = response.dataOrThrow['collections'] as List<dynamic>? ?? [];
    return list
        .map((c) => UserCollection.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  /// Creates a collection. 409 `error.collection.duplicate_name` when the name
  /// is taken.
  Future<UserCollection> createCollection({
    required String name,
    String? description,
  }) async {
    final response = await _httpClient.post<Map<String, dynamic>>(
      _base,
      data: {
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
      },
    );
    if (response.isError) {
      throw ApiException(
        response.error,
        fallbackMessage: 'Failed to create collection',
      );
    }
    return UserCollection.fromJson(response.dataOrThrow);
  }

  /// One collection with its entries.
  Future<UserCollectionDetail> getCollection(String id) async {
    final response = await _httpClient.get<Map<String, dynamic>>('$_base/$id');
    if (response.isError) {
      throw ApiException(
        response.error,
        fallbackMessage: 'Failed to fetch collection',
      );
    }
    return UserCollectionDetail.fromJson(response.dataOrThrow);
  }

  /// Renames or edits the description. An empty [description] clears it.
  Future<UserCollection> updateCollection(
    String id, {
    String? name,
    String? description,
  }) async {
    final response = await _httpClient.patch<Map<String, dynamic>>(
      '$_base/$id',
      data: {'name': ?name, 'description': ?description},
    );
    if (response.isError) {
      throw ApiException(
        response.error,
        fallbackMessage: 'Failed to update collection',
      );
    }
    return UserCollection.fromJson(response.dataOrThrow);
  }

  Future<void> deleteCollection(String id) async {
    final response = await _httpClient.delete<dynamic>('$_base/$id');
    if (response.isError) {
      throw ApiException(
        response.error,
        fallbackMessage: 'Failed to delete collection',
      );
    }
  }

  /// Adds a library entry. Adding twice is a no-op on the server.
  Future<UserCollection> addEntry(String id, String libraryEntryId) async {
    final response = await _httpClient.post<Map<String, dynamic>>(
      '$_base/$id/entries',
      data: {'library_entry_id': libraryEntryId},
    );
    if (response.isError) {
      throw ApiException(
        response.error,
        fallbackMessage: 'Failed to add to collection',
      );
    }
    return UserCollection.fromJson(response.dataOrThrow);
  }

  Future<void> removeEntry(String id, String libraryEntryId) async {
    final response = await _httpClient.delete<dynamic>(
      '$_base/$id/entries/$libraryEntryId',
    );
    if (response.isError) {
      throw ApiException(
        response.error,
        fallbackMessage: 'Failed to remove from collection',
      );
    }
  }
}
