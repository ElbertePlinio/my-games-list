// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Picklog';

  @override
  String get welcomeMessage => 'Welcome to Picklog';

  @override
  String get errorTitle => 'Error';

  @override
  String get errorMessage => 'Oops! Something went wrong.';

  @override
  String get offlineBannerMessage => 'You\'re offline';

  @override
  String get loadingLabel => 'Loading';

  @override
  String get goHome => 'Go home';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInSubtitle => 'Sign in to continue';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'Enter your email';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emailInvalid => 'Enter a valid email address';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get signInButton => 'Sign in';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get signUpLink => 'Sign up';

  @override
  String get signUpBodyTitle => 'Create your account';

  @override
  String get signUpSubtitle => 'Sign up to get started';

  @override
  String get usernameLabel => 'Username';

  @override
  String get usernameHint => 'Choose a username';

  @override
  String get usernameRequired => 'Username is required';

  @override
  String get usernameMinLength => 'Username must be at least 3 characters';

  @override
  String get usernameMaxLength => 'Username must be at most 20 characters';

  @override
  String get passwordCreateHint => 'Create a password';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get confirmPasswordHint => 'Re-enter your password';

  @override
  String get confirmPasswordRequired => 'Please confirm your password';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get signUpButton => 'Create account';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get signInLink => 'Sign in';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get userInformationTitle => 'Account';

  @override
  String nameFormat(String name) {
    return 'Name: $name';
  }

  @override
  String emailFormat(String email) {
    return 'Email: $email';
  }

  @override
  String get unknown => 'Unknown';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get logoutButton => 'Logout';

  @override
  String get searchGamesTitle => 'Search';

  @override
  String get searchGamesHint => 'Search for games...';

  @override
  String get searchGamesTooltip => 'Search games';

  @override
  String get searchGamesInitialMessage => 'Search for your favorite games';

  @override
  String searchGamesNoResults(String query) {
    return 'No results found for \"$query\"';
  }

  @override
  String get searchGamesErrorMessage => 'An error occurred';

  @override
  String get searchGamesOffsetLimitReached =>
      'Maximum search results reached. Please refine your search.';

  @override
  String get searchGamesLoadMoreFailed => 'Failed to load more results';

  @override
  String get searchFiltersTitle => 'Filters & sort';

  @override
  String get searchFiltersTooltip => 'Filters and sort';

  @override
  String get searchFiltersApply => 'Show results';

  @override
  String get searchFiltersClearAll => 'Clear all';

  @override
  String get searchFiltersReset => 'Reset';

  @override
  String get searchFiltersLoadedScopeCaption =>
      'Filters apply to loaded results';

  @override
  String get searchSortLabel => 'Sort by';

  @override
  String get searchSortRelevance => 'Relevance';

  @override
  String get searchSortNameAsc => 'Name (A–Z)';

  @override
  String get searchSortYearDesc => 'Newest first';

  @override
  String get searchSortYearAsc => 'Oldest first';

  @override
  String get searchFilterGenresLabel => 'Genres';

  @override
  String get searchFilterPlatformsLabel => 'Platforms';

  @override
  String get searchFilterYearLabel => 'Release year';

  @override
  String get searchFilterNoFacets => 'Filters appear once results load.';

  @override
  String searchFilterChipYear(int year) {
    return 'Year: $year';
  }

  @override
  String searchFilterChipSort(String sort) {
    return 'Sort: $sort';
  }

  @override
  String get searchNoResultsForFiltersTitle => 'No matches for these filters';

  @override
  String get searchNoResultsForFiltersHint =>
      'Try removing a filter to see more games.';

  @override
  String get searchClearFilters => 'Clear filters';

  @override
  String get gameDetailsTitle => 'Game Details';

  @override
  String get developer => 'Developer';

  @override
  String get rating => 'Rating';

  @override
  String get genres => 'Genres';

  @override
  String get platforms => 'Platforms';

  @override
  String get storyline => 'Storyline';

  @override
  String get summary => 'Summary';

  @override
  String get screenshots => 'Screenshots';

  @override
  String get videos => 'Videos';

  @override
  String get videoPlayerTitle => 'Video';

  @override
  String get similarGames => 'Similar games';

  @override
  String get whereToBuy => 'Where to buy';

  @override
  String get readMore => 'Read more';

  @override
  String get readLess => 'Read less';

  @override
  String get noVideosAvailable => 'No videos available';

  @override
  String get noScreenshotsAvailable => 'No screenshots available';

  @override
  String get errorLoadingData => 'Error loading data';

  @override
  String get discoveryTrending => 'Trending now';

  @override
  String get discoveryIndie => 'Indie gems';

  @override
  String get discoveryUpcoming => 'Upcoming games';

  @override
  String get discoveryNewReleases => 'New releases';

  @override
  String get discoveryComingSoon => 'Coming soon';

  @override
  String get recommendationsTitle => 'Recommended for you';

  @override
  String get signInWithGoogle => 'Continue with Google';

  @override
  String get orContinueWith => 'or continue with';

  @override
  String get signInWithEmail => 'Sign in with email';

  @override
  String get recommended => 'Recommended';

  @override
  String get browseTitle => 'Browse';

  @override
  String get browseGenresError => 'Couldn\'t load genres. Please try again.';

  @override
  String get browseGenresEmpty => 'No genres available right now.';

  @override
  String get browseGenreGamesError =>
      'Couldn\'t load games for this genre. Please try again.';

  @override
  String get browseGenreEmpty => 'No games found in this genre yet.';

  @override
  String get browseRetry => 'Try again';

  @override
  String get browseGenresSection => 'Genres';

  @override
  String get offlineTitle => 'You\'re offline';

  @override
  String get offlineErrorMessage => 'Check your connection and try again.';

  @override
  String gameCoverLabel(String name) {
    return 'Cover of $name';
  }

  @override
  String get clearSearch => 'Clear search';

  @override
  String get clearDate => 'Clear date';

  @override
  String screenshotLabel(String name) {
    return 'Screenshot of $name';
  }

  @override
  String get favorited => 'Favorited';

  @override
  String libraryEntryLabel(String name, String status) {
    return '$name, $status';
  }

  @override
  String genreCardLabel(String name) {
    return '$name genre';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navBrowse => 'Browse';

  @override
  String get navLibrary => 'Library';

  @override
  String get navProfile => 'Profile';

  @override
  String get libraryTitle => 'Library';

  @override
  String get addGame => 'Add game';

  @override
  String get addFirstGame => 'Add your first game';

  @override
  String get failedToLoadLibrary => 'Failed to load library';

  @override
  String favoritesWithCount(int count) {
    return 'Favorites ($count)';
  }

  @override
  String get emptyFavorites =>
      'No favorite games yet.\nTap the heart icon to add favorites!';

  @override
  String get emptyStatusGames =>
      'No games with this status yet.\nAdd games with this status to see them here.';

  @override
  String get emptyLibrary =>
      'Your library is empty.\nStart adding games to track your collection!';

  @override
  String get profileTitle => 'Profile';

  @override
  String get noUserInfo => 'No user information available';

  @override
  String get switchToList => 'Switch to list';

  @override
  String get switchToGrid => 'Switch to grid';

  @override
  String get failedToLoadGames => 'Failed to load games';

  @override
  String get reachedEnd => 'You\'ve reached the end';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get noGamesFound => 'No games found';

  @override
  String get noGamesInCategory => 'There are no games in this category yet.';

  @override
  String get seeAll => 'See all';

  @override
  String get linkCopied => 'Link copied';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get share => 'Share';

  @override
  String get addToLibraryShort => 'Add';

  @override
  String get links => 'Links';

  @override
  String get statusPlanned => 'Planned';

  @override
  String get statusPlaying => 'Playing';

  @override
  String get statusFinished => 'Finished';

  @override
  String get statusDropped => 'Dropped';

  @override
  String get statusOnHold => 'On hold';

  @override
  String get mostAnticipated => 'Most anticipated';

  @override
  String get noUpcomingGames => 'No upcoming games found';

  @override
  String shareGameMessage(String gameName, String url) {
    return 'Check out $gameName on Picklog!\n$url';
  }

  @override
  String get removeFromLibrary => 'Remove from library';

  @override
  String removeFromLibraryConfirm(String gameName) {
    return 'Are you sure you want to remove \"$gameName\" from your library?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get remove => 'Remove';

  @override
  String get save => 'Save';

  @override
  String get libraryEntryUpdated => 'Entry updated';

  @override
  String get gameAddedToLibrary => 'Added to your library';

  @override
  String get editEntry => 'Edit entry';

  @override
  String get addToLibrary => 'Add to library';

  @override
  String get statusLabel => 'Status';

  @override
  String get platformLabel => 'Platform';

  @override
  String get selectPlatformHint => 'Select platform (optional)';

  @override
  String get noneOption => 'None';

  @override
  String get score => 'Score';

  @override
  String get favorite => 'Favorite';

  @override
  String get playtime => 'Playtime';

  @override
  String get hours => 'Hours';

  @override
  String get minutes => 'Minutes';

  @override
  String get dates => 'Dates';

  @override
  String get startDate => 'Start date';

  @override
  String get endDate => 'End date';

  @override
  String get difficulty => 'Difficulty';

  @override
  String get difficultyHint => 'e.g., Normal, Hard, Nightmare';

  @override
  String get notes => 'Notes';

  @override
  String get notesHint => 'Add your notes...';

  @override
  String get notSet => 'Not set';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get onboardingTrackTitle => 'Track every game you play';

  @override
  String get onboardingTrackSubtitle =>
      'Build your personal library and keep your collection organized by status.';

  @override
  String get onboardingDiscoverTitle => 'Discover what to play next';

  @override
  String get onboardingDiscoverSubtitle =>
      'Browse trending titles, hidden gems and upcoming releases tailored for you.';

  @override
  String get onboardingShareTitle => 'Make it yours';

  @override
  String get onboardingShareSubtitle =>
      'Mark favorites, rate your games and pick up right where you left off.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String get searchGamesInitialTitle => 'Find your next favorite';

  @override
  String get searchGamesInitialHint =>
      'Search by title to add games to your library.';

  @override
  String get searchGamesNoResultsTitle => 'No matches yet';

  @override
  String get emptyLibraryTitle => 'Your library is empty';

  @override
  String get emptyLibraryHint =>
      'Start adding games to track your collection and never lose progress.';

  @override
  String get privacyDataTitle => 'Privacy & data';

  @override
  String get exportDataTitle => 'Export my data';

  @override
  String get exportDataSubtitle =>
      'Download a copy of your account data as a JSON file.';

  @override
  String get exportDataSuccess => 'Your data export is ready.';

  @override
  String get exportDataError => 'Could not export your data. Please try again.';

  @override
  String get deleteAccountTitle => 'Delete my account';

  @override
  String get deleteAccountSubtitle =>
      'Permanently delete your account and all your data.';

  @override
  String get deleteAccountDialogTitle => 'Delete account?';

  @override
  String get deleteAccountDialogBody =>
      'This permanently deletes your account and all your data. This cannot be undone.';

  @override
  String deleteAccountConfirmLabel(String word) {
    return 'Type $word to confirm';
  }

  @override
  String get deleteAccountConfirmWord => 'DELETE';

  @override
  String get deleteAccountConfirmButton => 'Delete account';

  @override
  String get deleteAccountError =>
      'Could not delete your account. Please try again.';

  @override
  String get consentBannerTitle => 'Your privacy choices';

  @override
  String get consentBannerBody =>
      'Choose what data you allow. You can change these anytime in Settings.';

  @override
  String get consentAcceptAll => 'Accept all';

  @override
  String get consentRejectAll => 'Reject all';

  @override
  String get consentCustomize => 'Customize';

  @override
  String get consentCustomizeTitle => 'Choose what you allow';

  @override
  String get consentSave => 'Save';

  @override
  String get consentAnalyticsTitle => 'Usage analytics';

  @override
  String get consentAnalyticsSubtitle =>
      'Anonymous usage data to help improve the app.';

  @override
  String get consentCrashTitle => 'Crash reports';

  @override
  String get consentCrashSubtitle =>
      'Send crash and error reports to help fix problems.';

  @override
  String get consentPushTitle => 'Push notifications';

  @override
  String get consentPushSubtitle =>
      'Receive notifications about your games and updates.';

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get termsTitle => 'Terms of Service';

  @override
  String get legalTitle => 'Legal';

  @override
  String get legalDraftBanner =>
      'DRAFT — placeholder text. Replace with the final legal text before release.';

  @override
  String get legalLoadError =>
      'Could not load this document. Please try again later.';

  @override
  String get signUpAcceptPrefix => 'I accept the ';

  @override
  String get signUpAcceptPrivacyLink => 'Privacy Policy';

  @override
  String get signUpAcceptConjunction => ' and ';

  @override
  String get signUpAcceptTermsLink => 'Terms of Service';

  @override
  String get signUpAcceptRequired =>
      'Please accept the Privacy Policy and Terms to continue.';

  @override
  String get signInLegalNotice =>
      'By continuing you accept our Privacy Policy and Terms of Service.';

  @override
  String get errorNetwork =>
      'Can\'t reach Picklog right now. Check your connection.';

  @override
  String get errorNotFound => 'We couldn\'t find that.';

  @override
  String get errorUnauthorized => 'Your session ended. Sign in again.';

  @override
  String get errorServer => 'The server had a problem. Try again in a moment.';

  @override
  String get errorUnknown => 'Something went wrong. Try again.';

  @override
  String get splashTagline => 'Your game library, logged';

  @override
  String get onboardingTrackEyebrow => '01 · Track';

  @override
  String get onboardingDiscoverEyebrow => '02 · Discover';

  @override
  String get onboardingShareEyebrow => '03 · Make it yours';

  @override
  String pageIndicatorLabel(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get signInEyebrow => 'Picklog · Sign in';

  @override
  String get signInHeadline => 'Welcome back';

  @override
  String get signUpEyebrow => 'Picklog · Create account';

  @override
  String gameWithScoreLabel(String name, int score) {
    return '$name, rating $score';
  }

  @override
  String get recommendationsSubtitle => 'Picked from the genres you play';

  @override
  String get collectionsSectionTitle => 'Collections';

  @override
  String get featuredEyebrow => 'Featured';

  @override
  String get featuredError => 'Couldn\'t load featured picks.';

  @override
  String countdownDaysHoursMinutes(int days, int hours, int minutes) {
    return '${days}d ${hours}h ${minutes}m';
  }

  @override
  String countdownHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String countdownMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String get countdownReleased => 'Out now';

  @override
  String anticipatedHypes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hypes',
      one: '1 hype',
    );
    return '$_temp0';
  }

  @override
  String get playtimeNone => 'No playtime';

  @override
  String playtimeMinutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String playtimeHoursShort(String hours) {
    return '$hours h';
  }

  @override
  String get homeEyebrow => 'Picklog · Home';

  @override
  String homeGreetingMorning(String name) {
    return 'Good morning, $name';
  }

  @override
  String homeGreetingAfternoon(String name) {
    return 'Good afternoon, $name';
  }

  @override
  String homeGreetingEvening(String name) {
    return 'Good evening, $name';
  }

  @override
  String get homeGreetingAnonymous => 'Welcome back';

  @override
  String get homeSubtitle => 'What are you playing next?';

  @override
  String get libraryEyebrow => 'Picklog · Library';

  @override
  String libraryGameCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count games',
      one: '1 game',
      zero: 'No games yet',
    );
    return '$_temp0';
  }

  @override
  String get libraryFavoriteFailed =>
      'Couldn\'t update the favorite. Try again.';

  @override
  String get libraryDeleteFailed =>
      'Couldn\'t remove the game. It\'s back in your library.';

  @override
  String get libraryRefreshFailed => 'Couldn\'t refresh your library.';

  @override
  String get librarySaveFailed => 'Couldn\'t save your changes. Try again.';

  @override
  String lightboxPosition(int current, int total) {
    return '$current / $total';
  }

  @override
  String get lightboxClose => 'Close';

  @override
  String get lightboxPrevious => 'Previous screenshot';

  @override
  String get lightboxNext => 'Next screenshot';

  @override
  String get inYourLibrary => 'In your library';

  @override
  String get yourScore => 'Your score';

  @override
  String get igdbScore => 'Critic and player score';

  @override
  String get releaseDate => 'Release';

  @override
  String get detailsAbout => 'About';

  @override
  String get searchLoadMoreFailed => 'Couldn\'t load more results.';

  @override
  String get browseEyebrow => 'Picklog · Browse';

  @override
  String get libraryDetailsSection => 'More details';

  @override
  String get libraryDetailsHint => 'Playtime, dates, difficulty and notes';

  @override
  String get scoreNotSet => 'Not rated';

  @override
  String get themeTitle => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsEyebrow => 'Picklog · Settings';

  @override
  String get profileEyebrow => 'Picklog · Profile';

  @override
  String get routeNotFoundMessage => 'This page doesn\'t exist or moved.';

  @override
  String get librarySortUpdated => 'Recently updated';

  @override
  String get librarySortAdded => 'Recently added';

  @override
  String get librarySortName => 'Name (A-Z)';

  @override
  String get librarySortScore => 'Your score';

  @override
  String get librarySortPlaytime => 'Most played';

  @override
  String get librarySortRelease => 'Release date';

  @override
  String get librarySortRating => 'Community rating';

  @override
  String get collectionErrorDuplicateName =>
      'You already have a collection with this name.';

  @override
  String get collectionErrorLimit =>
      'You can have up to 50 collections. Delete one to create another.';

  @override
  String get collectionErrorEntriesLimit =>
      'This collection is full (500 games).';

  @override
  String get collectionErrorNameInvalid =>
      'Use 1 to 60 characters for the name.';

  @override
  String get collectionErrorDescriptionTooLong =>
      'Keep the description under 280 characters.';

  @override
  String get collectionErrorNotFound => 'This collection no longer exists.';

  @override
  String recommendationReasonSimilar(String name) {
    return 'Because you liked $name';
  }

  @override
  String get recommendationReasonSimilarGeneric => 'Similar to games you like';

  @override
  String recommendationReasonGenre(String genre) {
    return 'More $genre';
  }

  @override
  String get recommendationReasonGenreGeneric => 'Matches your favorite genres';

  @override
  String get recommendationReasonPopular => 'Popular now';

  @override
  String get exploreSortPopular => 'Popular';

  @override
  String get exploreSortRating => 'Top rated';

  @override
  String get exploreSortNewest => 'Newest';

  @override
  String get exploreSortOldest => 'Oldest';

  @override
  String get exploreSortName => 'A-Z';

  @override
  String get filterOptionsFailed => 'Could not load the options.';

  @override
  String get filterReleaseYears => 'Release years';

  @override
  String filterYearRangeValue(int from, int to) {
    return '$from-$to';
  }

  @override
  String get filterMinRating => 'Minimum rating';

  @override
  String get filterAnyRating => 'Any';

  @override
  String filterRatingValue(int rating) {
    return 'Rating $rating+';
  }

  @override
  String get filterGenreFallback => 'Genre';

  @override
  String get filterPlatformFallback => 'Platform';

  @override
  String filterRemoveChip(String label) {
    return 'Remove $label';
  }

  @override
  String get exploreTitle => 'Explore';

  @override
  String get searchExploreCatalog => 'Explore the catalog';

  @override
  String get searchSortLoadedScopeCaption =>
      'Sorting reorders the results loaded so far.';

  @override
  String get exploreFiltersButton => 'Filters';

  @override
  String get exploreFiltersTitle => 'Filters';

  @override
  String get exploreEmptyTitle => 'No games match';

  @override
  String get exploreEmptyHint => 'Try fewer filters or a wider year range.';

  @override
  String exploreResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count games shown',
      one: '1 game shown',
    );
    return '$_temp0';
  }

  @override
  String get exploreEndOfResults => 'You reached the end.';

  @override
  String get undo => 'Undo';

  @override
  String libraryChangeStatusTitle(String name) {
    return 'Change status of $name';
  }

  @override
  String get collectionEditTitle => 'Edit collection';

  @override
  String get collectionNewTitle => 'New collection';

  @override
  String get collectionNameLabel => 'Name';

  @override
  String get collectionDescriptionLabel => 'Description (optional)';

  @override
  String get collectionCreateAction => 'Create';

  @override
  String get collectionDeleteTitle => 'Delete collection?';

  @override
  String collectionDeleteConfirm(String name) {
    return '\"$name\" will be deleted. The games stay in your library.';
  }

  @override
  String get collectionDeleteAction => 'Delete';

  @override
  String get collectionPickerTitle => 'Add to collections';

  @override
  String get collectionPickerEmpty =>
      'No collections yet. Create one to group games your way.';

  @override
  String collectionGameCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count games',
      one: '1 game',
      zero: 'No games',
    );
    return '$_temp0';
  }

  @override
  String get collectionsEmptyTitle => 'No collections yet';

  @override
  String get collectionsEmptyHint =>
      'Group games into lists like Couch co-op or Comfort games.';

  @override
  String get collectionDeleted => 'Collection deleted';

  @override
  String collectionCardLabel(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count games',
      one: '1 game',
    );
    return '$name, $_temp0';
  }

  @override
  String get collectionActions => 'Collection actions';

  @override
  String get statsTotal => 'Total';

  @override
  String get statsHours => 'Hours';

  @override
  String libraryStatsSemantics(
    int total,
    int playing,
    int finished,
    String hours,
  ) {
    return '$total games, $playing playing, $finished finished, $hours hours';
  }

  @override
  String get libraryFiltersTitle => 'Filter library';

  @override
  String get libraryFavoritesFilter => 'Favorites';

  @override
  String get libraryFilterMinScore => 'Minimum score';

  @override
  String get libraryFilterCollection => 'Collection';

  @override
  String libraryScoreChip(int score) {
    return 'Score $score+';
  }

  @override
  String libraryUnfavorited(String name) {
    return '$name removed from favorites';
  }

  @override
  String libraryFavorited(String name) {
    return '$name added to favorites';
  }

  @override
  String libraryStatusChanged(String name, String status) {
    return '$name is now $status';
  }

  @override
  String get libraryEntryActions => 'More actions';

  @override
  String get libraryChangeStatus => 'Change status';

  @override
  String get rouletteTitle => 'Pick for me';

  @override
  String get librarySegmentGames => 'Games';

  @override
  String get librarySegmentCollections => 'Collections';

  @override
  String get librarySearchHint => 'Search titles';

  @override
  String get librarySortTooltip => 'Sort';

  @override
  String get libraryViewList => 'Show as list';

  @override
  String get libraryViewGrid => 'Show as grid';

  @override
  String libraryMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches',
      one: '1 match',
      zero: 'No matches',
    );
    return '$_temp0';
  }

  @override
  String get libraryNoMatchesTitle => 'No games match';

  @override
  String get libraryNoMatchesHint => 'Try another search or clear the filters.';

  @override
  String get rouletteEyebrow => 'Backlog roulette';

  @override
  String rouletteCandidates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count games in the draw',
      one: '1 game in the draw',
      zero: 'No games to pick from',
    );
    return '$_temp0';
  }

  @override
  String get rouletteAnyPlatform => 'Any platform';

  @override
  String get rouletteAnyLength => 'Any time played';

  @override
  String rouletteMaxHours(int hours) {
    return 'Up to $hours h played';
  }

  @override
  String get rouletteNoMatch => 'No backlog game matches these filters.';

  @override
  String get rouletteHint =>
      'Spin to let Picklog choose your next game from the backlog.';

  @override
  String get rouletteStartPlaying => 'Start playing';

  @override
  String get rouletteSpinAgain => 'Spin again';

  @override
  String get rouletteSpin => 'Spin';

  @override
  String rouletteStarted(String name) {
    return 'Have fun with $name!';
  }

  @override
  String get rouletteEmptyTitle => 'Your backlog is empty';

  @override
  String get rouletteEmptyHint =>
      'Add games as Planned or On hold and Picklog will pick one for you.';

  @override
  String get collectionEyebrow => 'Collection';

  @override
  String get collectionEmptyTitle => 'No games here yet';

  @override
  String get collectionEmptyHint =>
      'Add games from a game\'s library sheet or the library menu.';

  @override
  String collectionEntryRemoved(String name) {
    return '$name removed from the collection';
  }

  @override
  String get collectionRemoveEntry => 'Remove from collection';

  @override
  String get profileTopGenres => 'Top genres';

  @override
  String get profileTopPlatforms => 'Top platforms';

  @override
  String get profileStatsFailed => 'Could not load your stats.';

  @override
  String get profileSettingsHint => 'Account, theme, privacy and language';

  @override
  String get profileMemberLine => 'Picklog member';

  @override
  String profileMemberLineCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Picklog member · $count games logged',
      one: 'Picklog member · 1 game logged',
      zero: 'Picklog member · No games logged yet',
    );
    return '$_temp0';
  }

  @override
  String get profileStatGames => 'Games';

  @override
  String get profileStatAverage => 'Avg score';

  @override
  String get profileStatBacklog => 'Backlog';

  @override
  String get profileStatusDistribution => 'By status';

  @override
  String profileYearInReviewLabel(int year) {
    return 'Open your $year in review';
  }

  @override
  String get yearInReviewEyebrow => 'Year in review';

  @override
  String get profileYearInReviewHint => 'Your year in games, card by card.';

  @override
  String get profileAchievements => 'Achievements';

  @override
  String profileAchievementsValue(int unlocked, int total) {
    return '$unlocked of $total unlocked';
  }

  @override
  String profileBacklogValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count games in backlog',
      one: '1 game in backlog',
      zero: 'Backlog is empty',
    );
    return '$_temp0';
  }

  @override
  String get profileFavorites => 'Favorites';

  @override
  String get profileFavoritesEmpty => 'Tap the heart on a game to see it here.';

  @override
  String yearShareText(int year) {
    return 'My $year in games on Picklog';
  }

  @override
  String get yearShareFailed => 'Could not share the image.';

  @override
  String yearInReviewTitle(int year) {
    return '$year in review';
  }

  @override
  String get yearPickerTooltip => 'Choose year';

  @override
  String get yearShareTooltip => 'Share';

  @override
  String get yearIntroTitle => 'Your year in games';

  @override
  String get yearIntroEmpty =>
      'Nothing logged this year yet. Add games to fill your story.';

  @override
  String get yearIntroHint =>
      'Scroll through what you added, finished and loved.';

  @override
  String get yearGamesAdded => 'Games added';

  @override
  String get yearGamesFinished => 'Games finished';

  @override
  String get yearHoursPlayed => 'Hours played';

  @override
  String get yearByMonth => 'Month by month';

  @override
  String yearByMonthSemantics(int added, int finished) {
    return 'Chart by month: $added added and $finished finished in total';
  }

  @override
  String get yearLegendAdded => 'Added';

  @override
  String get yearLegendFinished => 'Finished';

  @override
  String get yearTopRated => 'Top rated';

  @override
  String get yearTopGenres => 'Top genres';

  @override
  String yearGenreChip(String name, int count) {
    return '$name · $count';
  }

  @override
  String get yearFirstFinished => 'First game finished';

  @override
  String get yearShareEyebrow => 'Share your year';

  @override
  String get yearShareAction => 'Share image';

  @override
  String get yearShareAdded => 'Added';

  @override
  String get yearShareFinished => 'Finished';

  @override
  String get yearShareHours => 'Hours';

  @override
  String yearShareTopRated(String name) {
    return 'Top rated: $name';
  }

  @override
  String yearShareTopGenre(String genre) {
    return 'Top genre: $genre';
  }

  @override
  String get browseExploreTitle => 'Explore the catalog';

  @override
  String get browseExploreHint => 'Filter by genre, platform, year and rating.';

  @override
  String get aiEyebrowPlayNext => 'AI · Play next';

  @override
  String get aiEyebrowDiscover => 'AI · Discover';

  @override
  String get aiPlayNextTitle => 'Play next';

  @override
  String get aiPlayNextHeadline => 'What should I play tonight?';

  @override
  String get aiPlayNextSubtitle =>
      'Tell Picklog your mood and your time. It picks from your backlog.';

  @override
  String get aiMoodLabel => 'Mood';

  @override
  String get aiMoodChill => 'Chill';

  @override
  String get aiMoodIntense => 'Intense';

  @override
  String get aiMoodStory => 'Story';

  @override
  String get aiMoodSocial => 'Social';

  @override
  String get aiMoodQuick => 'Quick';

  @override
  String get aiMoodChallenge => 'Challenge';

  @override
  String get aiTimeLabel => 'Time available';

  @override
  String aiDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String aiDurationHours(int hours) {
    return '$hours h';
  }

  @override
  String aiDurationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get aiDurationFourPlus => '4 h+';

  @override
  String get aiPlatformLabel => 'Platform';

  @override
  String get aiPlatformAny => 'Any platform';

  @override
  String get aiNoteLabel => 'Anything else? (optional)';

  @override
  String get aiNoteHint => 'For example: something I can pause often';

  @override
  String get aiGenerateButton => 'Suggest games';

  @override
  String get aiRegenerateButton => 'Regenerate';

  @override
  String aiRemainingToday(int remaining, int limit) {
    return '$remaining of $limit left today';
  }

  @override
  String aiRemainingTodayShort(int remaining) {
    return '$remaining left today';
  }

  @override
  String get aiLoadingPlayNext1 => 'Reading your backlog';

  @override
  String get aiLoadingPlayNext2 => 'Weighing your mood and time';

  @override
  String get aiLoadingPlayNext3 => 'Comparing genres and scores';

  @override
  String get aiLoadingPlayNext4 => 'Picking the best fits';

  @override
  String get aiLoadingDiscover1 => 'Reading your taste';

  @override
  String get aiLoadingDiscover2 => 'Looking for new games';

  @override
  String get aiLoadingDiscover3 => 'Checking the catalogue';

  @override
  String get aiResultsTitle => 'Your picks';

  @override
  String get aiTopPick => 'Top pick';

  @override
  String aiSessionLength(String duration) {
    return 'About $duration per session';
  }

  @override
  String get aiStartPlaying => 'Start playing';

  @override
  String get aiNowPlaying => 'Now playing';

  @override
  String get aiOpenGame => 'Open';

  @override
  String get aiStartPlayingError => 'Could not update this game. Try again.';

  @override
  String get aiEmptyBacklogTitle => 'Your backlog is empty';

  @override
  String get aiEmptyBacklogMessage =>
      'Play next picks from games you plan to play, are playing, or put on hold. Add a few first.';

  @override
  String get aiGoExplore => 'Explore games';

  @override
  String get aiGoSearch => 'Search games';

  @override
  String get aiErrorUnavailable =>
      'AI suggestions are not available right now.';

  @override
  String get aiErrorConsentRequired =>
      'Turn on AI suggestions to use this feature.';

  @override
  String get aiErrorQuotaExceeded =>
      'You used all of today\'s AI suggestions. Come back tomorrow.';

  @override
  String get aiErrorUpstream =>
      'The AI service did not answer. Try again in a moment.';

  @override
  String get aiUnavailableTitle => 'AI suggestions are off';

  @override
  String get aiQuotaTitle => 'Daily limit reached';

  @override
  String get aiConsentNeededTitle => 'AI suggestions need your OK';

  @override
  String get aiConsentNeededMessage =>
      'Picklog sends data to the AI service only after you agree.';

  @override
  String get aiReviewConsent => 'Review and turn on';

  @override
  String get aiConsentTitle => 'Turn on AI suggestions?';

  @override
  String get aiConsentBody =>
      'To make suggestions, Picklog sends OpenAI the names, statuses, scores, genres, and playtime of games in your library, plus the note you type.';

  @override
  String get aiConsentNever => 'Picklog never sends your email or your name.';

  @override
  String get aiConsentRevoke =>
      'You can turn this off at any time in Settings.';

  @override
  String get aiConsentAccept => 'Turn on';

  @override
  String get aiConsentDecline => 'Not now';

  @override
  String get aiConsentSaveError => 'Could not save your choice. Try again.';

  @override
  String get aiSettingsTitle => 'AI suggestions';

  @override
  String get aiSettingsSwitch => 'Allow AI suggestions';

  @override
  String get aiSettingsSwitchOn =>
      'Picklog can send game data from your library to OpenAI.';

  @override
  String get aiSettingsSwitchOff => 'Nothing is sent to OpenAI.';

  @override
  String aiSettingsUsage(int used, int limit) {
    return '$used of $limit used today';
  }

  @override
  String get aiSettingsUnavailable =>
      'AI suggestions are not available on this server.';

  @override
  String get aiSettingsLoadError => 'Could not load your AI settings.';

  @override
  String get aiHomeCardSubtitle =>
      'Get picks from your backlog for your mood and your time.';

  @override
  String get aiHomeCardAction => 'Pick for me';

  @override
  String get aiDiscoverTitle => 'Discover with AI';

  @override
  String get aiHomeDiscoverSubtitle =>
      'Describe what you want and find new games.';

  @override
  String get aiDiscoverSubtitle =>
      'Describe what you feel like playing. Picklog suggests games you do not have yet.';

  @override
  String get aiDiscoverPromptLabel => 'What are you in the mood for?';

  @override
  String get aiDiscoverPromptHint => 'For example: a relaxing farming game';

  @override
  String get aiDiscoverSubmit => 'Find games';

  @override
  String get aiDiscoverSuggestion1 => 'Cozy games for the weekend';

  @override
  String get aiDiscoverSuggestion2 => 'Like Hades but slower';

  @override
  String get aiDiscoverSuggestion3 => 'Short story games under 10 hours';

  @override
  String get aiDiscoverSuggestionsLabel => 'Try one';

  @override
  String get aiDiscoverEmptyTitle => 'No new games found';

  @override
  String get aiDiscoverEmptyMessage => 'Try a different prompt.';

  @override
  String aiRatingLabel(int score) {
    return 'Rating $score';
  }

  @override
  String get accountsTitle => 'Connected accounts';

  @override
  String get accountsEyebrow => 'Picklog · Accounts';

  @override
  String get accountsIntro =>
      'Link public gaming profiles to bring in achievements and playtime. Picklog uses public identifiers only and never asks for your passwords.';

  @override
  String get accountsSettingsSubtitle =>
      'Steam, Xbox, RetroAchievements, PlayStation';

  @override
  String get accountsUnavailable => 'Unavailable';

  @override
  String get accountsUnavailableMessage => 'This service is not set up yet.';

  @override
  String get accountsExperimental => 'Experimental';

  @override
  String get accountsNotLinked => 'Not linked';

  @override
  String get accountsLink => 'Link';

  @override
  String accountsLinkTitle(String provider) {
    return 'Link $provider';
  }

  @override
  String get accountsSteamFieldLabel => 'Steam profile URL or ID';

  @override
  String get accountsSteamHelp =>
      'Paste your profile link, your custom URL name, or your 17-digit SteamID.';

  @override
  String get accountsSteamPublicNote =>
      'Game details must be public. In Steam, open your profile, choose Edit Profile, then Privacy Settings, and set Game details to Public.';

  @override
  String get accountsXboxFieldLabel => 'Xbox gamertag';

  @override
  String get accountsXboxHelp =>
      'Your gamertag as it shows on your Xbox profile.';

  @override
  String get accountsRaFieldLabel => 'RetroAchievements username';

  @override
  String get accountsRaHelp => 'Your username on retroachievements.org.';

  @override
  String get accountsPsnFieldLabel => 'PSN online ID';

  @override
  String get accountsPsnHelp =>
      'Your online ID. Your trophy list must be visible to anyone.';

  @override
  String get accountsPsnExperimentalNote =>
      'PlayStation support is experimental. It reads public trophy lists only.';

  @override
  String get accountsLinkSubmit => 'Link account';

  @override
  String accountsLinkedMessage(String provider) {
    return '$provider linked. Tap Sync now to import your data.';
  }

  @override
  String accountsLastSynced(String time) {
    return 'Last synced $time';
  }

  @override
  String get accountsNeverSynced => 'Not synced yet';

  @override
  String get accountsSyncing => 'Syncing';

  @override
  String get accountsSyncOk => 'Up to date';

  @override
  String get accountsSyncError => 'Last sync failed';

  @override
  String get accountsSyncNow => 'Sync now';

  @override
  String get accountsImportToggle => 'Also import games to my library';

  @override
  String get accountsImportHelp =>
      'Adds games you own or played that are not in your library yet.';

  @override
  String accountsSyncStarted(String provider) {
    return 'Syncing $provider. This can take a few minutes.';
  }

  @override
  String accountsSyncFinished(String provider) {
    return '$provider sync finished';
  }

  @override
  String get accountsUnlink => 'Unlink';

  @override
  String accountsUnlinkTitle(String provider) {
    return 'Unlink $provider?';
  }

  @override
  String get accountsUnlinkMessage =>
      'Picklog deletes the achievements and progress it imported from this account. Games already in your library stay.';

  @override
  String accountsUnlinkedMessage(String provider) {
    return '$provider unlinked';
  }

  @override
  String get accountsErrorNotFound =>
      'We could not find that account. Check the spelling and try again.';

  @override
  String get accountsErrorPrivate =>
      'This profile is private. Make your game details public and try again.';

  @override
  String get accountsErrorSyncTooSoon =>
      'This account synced recently. Try again in a few minutes.';

  @override
  String get accountsErrorUnavailable =>
      'This service is not available right now.';

  @override
  String get accountsErrorInvalid => 'Enter a valid identifier.';

  @override
  String get accountsErrorUpstream =>
      'The service did not answer. Try again later.';

  @override
  String get accountsErrorGameNotFound =>
      'We could not find achievements for this game.';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes min ago';
  }

  @override
  String timeHoursAgo(int hours) {
    return '$hours h ago';
  }

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String get achievementsEyebrow => 'Picklog · Achievements';

  @override
  String get achievementsCompletion => 'Overall completion';

  @override
  String achievementsUnlockedOf(int unlocked, int total) {
    return '$unlocked of $total unlocked';
  }

  @override
  String achievementsGamesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count games',
      one: '1 game',
    );
    return '$_temp0';
  }

  @override
  String get achievementsRecentTitle => 'Recent unlocks';

  @override
  String get achievementsGamesTitle => 'Games';

  @override
  String get achievementsFilterAll => 'All';

  @override
  String get achievementsEmptyTitle => 'No achievements yet';

  @override
  String get achievementsEmptyMessage =>
      'Link Steam, Xbox, RetroAchievements, or PlayStation to see your achievements here.';

  @override
  String get achievementsConnectAction => 'Connect an account';

  @override
  String achievementsRarity(String percent) {
    return '$percent% of players';
  }

  @override
  String get achievementsRare => 'Rare';

  @override
  String achievementsUnlockedOn(String date) {
    return 'Unlocked $date';
  }

  @override
  String get achievementsLocked => 'Locked';

  @override
  String achievementsLastPlayed(String date) {
    return 'Played $date';
  }

  @override
  String get achievementsGameEmpty => 'This game has no achievements to show.';

  @override
  String get aiDiscoverHeadline => 'Find your next favorite game';
}
