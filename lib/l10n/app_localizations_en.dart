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
  String get goHome => 'Go to Home';

  @override
  String get signInTitle => 'Sign In';

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
  String get signInButton => 'Sign In';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get signUpLink => 'Sign Up';

  @override
  String get signUpAppBarTitle => 'Sign Up';

  @override
  String get signUpBodyTitle => 'Create Account';

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
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get confirmPasswordHint => 'Re-enter your password';

  @override
  String get confirmPasswordRequired => 'Please confirm your password';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get signUpButton => 'Sign Up';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get signInLink => 'Sign In';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get userInformationTitle => 'User Information';

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
  String get darkModeTitle => 'Dark Mode';

  @override
  String get darkModeSubtitle => 'Toggle between light and dark theme';

  @override
  String get logoutButton => 'Logout';

  @override
  String get searchGamesTitle => 'Search Games';

  @override
  String get searchGamesHint => 'Search for games...';

  @override
  String get searchGamesTooltip => 'Search Games';

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
  String get similarGames => 'Similar Games';

  @override
  String get whereToBuy => 'Where to Buy';

  @override
  String get readMore => 'Read More';

  @override
  String get readLess => 'Read Less';

  @override
  String get noVideosAvailable => 'No videos available';

  @override
  String get noScreenshotsAvailable => 'No screenshots available';

  @override
  String get errorLoadingData => 'Error loading data';

  @override
  String get discoveryTrending => 'Trending Now';

  @override
  String get discoveryIndie => 'Indie Gems';

  @override
  String get discoveryUpcoming => 'Upcoming Games';

  @override
  String get discoveryNewReleases => 'New Releases';

  @override
  String get discoveryComingSoon => 'Coming Soon';

  @override
  String get recommendationsTitle => 'Recommended for You';

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
  String get libraryTitle => 'My Library';

  @override
  String get addGame => 'Add Game';

  @override
  String get addFirstGame => 'Add Your First Game';

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
  String get seeAll => 'See All';

  @override
  String get linkCopied => 'Link copied to clipboard!';

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
  String get statusOnHold => 'On Hold';

  @override
  String get mostAnticipated => 'Most Anticipated';

  @override
  String get noUpcomingGames => 'No upcoming games found';

  @override
  String shareGameMessage(String gameName, String url) {
    return 'Check out $gameName on Picklog!\n$url';
  }

  @override
  String get removeFromLibrary => 'Remove from Library';

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
  String get libraryEntryUpdated => 'Library entry updated successfully.';

  @override
  String get gameAddedToLibrary => 'Game added to library successfully.';

  @override
  String get editEntry => 'Edit Entry';

  @override
  String get addToLibrary => 'Add to Library';

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
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

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
}
