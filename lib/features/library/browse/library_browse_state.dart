import 'package:equatable/equatable.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/features/library/library_query.dart';

enum LibraryBrowseStatus { initial, loading, loadingMore, success, failure }

/// How the library list renders.
enum LibraryViewMode {
  list,
  grid;

  static LibraryViewMode fromName(String? name) =>
      name == LibraryViewMode.grid.name ? grid : list;
}

class LibraryBrowseState extends Equatable {
  const LibraryBrowseState({
    this.status = LibraryBrowseStatus.initial,
    this.userId,
    this.filters = const LibraryFilters(),
    this.entries = const [],
    this.totalCount = 0,
    this.nextOffset = 0,
    this.hasMore = false,
    this.viewMode = LibraryViewMode.list,
    this.errorKind,
  });

  final LibraryBrowseStatus status;
  final String? userId;
  final LibraryFilters filters;

  /// Loaded matches, in server order.
  final List<LibraryEntry> entries;

  /// Matches before paging.
  final int totalCount;
  final int nextOffset;
  final bool hasMore;
  final LibraryViewMode viewMode;

  /// Why the last request failed. With entries on screen a page or refresh
  /// failed and the list stays.
  final AppErrorKind? errorKind;

  bool get isLoading => status == LibraryBrowseStatus.loading;
  bool get isLoadingMore => status == LibraryBrowseStatus.loadingMore;
  bool get hasEntries => entries.isNotEmpty;
  bool get canLoadMore => hasMore && !isLoading && !isLoadingMore;
  bool get loadMoreFailed =>
      errorKind != null && status == LibraryBrowseStatus.success;

  LibraryBrowseState copyWith({
    LibraryBrowseStatus? status,
    String? userId,
    LibraryFilters? filters,
    List<LibraryEntry>? entries,
    int? totalCount,
    int? nextOffset,
    bool? hasMore,
    LibraryViewMode? viewMode,
    AppErrorKind? errorKind,
  }) {
    return LibraryBrowseState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      filters: filters ?? this.filters,
      entries: entries ?? this.entries,
      totalCount: totalCount ?? this.totalCount,
      nextOffset: nextOffset ?? this.nextOffset,
      hasMore: hasMore ?? this.hasMore,
      viewMode: viewMode ?? this.viewMode,
      errorKind: errorKind,
    );
  }

  @override
  List<Object?> get props => [
    status,
    userId,
    filters,
    entries,
    totalCount,
    nextOffset,
    hasMore,
    viewMode,
    errorKind,
  ];
}
