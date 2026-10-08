import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Picklog'**
  String get appTitle;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Picklog'**
  String get welcomeMessage;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorTitle;

  /// No description provided for @errorMessage.
  ///
  /// In en, this message translates to:
  /// **'Oops! Something went wrong.'**
  String get errorMessage;

  /// Shown in a banner when the device has no network connection
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get offlineBannerMessage;

  /// Accessibility label announced while a section is loading
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loadingLabel;

  /// Button that returns to the home tab
  ///
  /// In en, this message translates to:
  /// **'Go home'**
  String get goHome;

  /// Sign-in title
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailHint;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get emailInvalid;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// Email sign-in submit button
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInButton;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// Link from sign-in to sign-up
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUpLink;

  /// Sign-up headline
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get signUpBodyTitle;

  /// No description provided for @signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign up to get started'**
  String get signUpSubtitle;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a username'**
  String get usernameHint;

  /// No description provided for @usernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get usernameRequired;

  /// No description provided for @usernameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters'**
  String get usernameMinLength;

  /// No description provided for @usernameMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Username must be at most 20 characters'**
  String get usernameMaxLength;

  /// No description provided for @passwordCreateHint.
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get passwordCreateHint;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get confirmPasswordHint;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmPasswordRequired;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// Sign-up submit button
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUpButton;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// Link from sign-up to sign-in
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInLink;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings group label for the user's account
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get userInformationTitle;

  /// No description provided for @nameFormat.
  ///
  /// In en, this message translates to:
  /// **'Name: {name}'**
  String nameFormat(String name);

  /// No description provided for @emailFormat.
  ///
  /// In en, this message translates to:
  /// **'Email: {email}'**
  String emailFormat(String email);

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// No description provided for @logoutButton.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutButton;

  /// Search screen title
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchGamesTitle;

  /// No description provided for @searchGamesHint.
  ///
  /// In en, this message translates to:
  /// **'Search for games...'**
  String get searchGamesHint;

  /// Tooltip for the search action
  ///
  /// In en, this message translates to:
  /// **'Search games'**
  String get searchGamesTooltip;

  /// No description provided for @searchGamesInitialMessage.
  ///
  /// In en, this message translates to:
  /// **'Search for your favorite games'**
  String get searchGamesInitialMessage;

  /// No description provided for @searchGamesNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found for \"{query}\"'**
  String searchGamesNoResults(String query);

  /// No description provided for @searchGamesErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get searchGamesErrorMessage;

  /// No description provided for @searchGamesOffsetLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum search results reached. Please refine your search.'**
  String get searchGamesOffsetLimitReached;

  /// No description provided for @searchGamesLoadMoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load more results'**
  String get searchGamesLoadMoreFailed;

  /// No description provided for @searchFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters & sort'**
  String get searchFiltersTitle;

  /// No description provided for @searchFiltersTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filters and sort'**
  String get searchFiltersTooltip;

  /// No description provided for @searchFiltersApply.
  ///
  /// In en, this message translates to:
  /// **'Show results'**
  String get searchFiltersApply;

  /// No description provided for @searchFiltersClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get searchFiltersClearAll;

  /// No description provided for @searchFiltersReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get searchFiltersReset;

  /// No description provided for @searchFiltersLoadedScopeCaption.
  ///
  /// In en, this message translates to:
  /// **'Filters apply to loaded results'**
  String get searchFiltersLoadedScopeCaption;

  /// No description provided for @searchSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get searchSortLabel;

  /// No description provided for @searchSortRelevance.
  ///
  /// In en, this message translates to:
  /// **'Relevance'**
  String get searchSortRelevance;

  /// No description provided for @searchSortNameAsc.
  ///
  /// In en, this message translates to:
  /// **'Name (A–Z)'**
  String get searchSortNameAsc;

  /// No description provided for @searchSortYearDesc.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get searchSortYearDesc;

  /// No description provided for @searchSortYearAsc.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get searchSortYearAsc;

  /// No description provided for @searchFilterGenresLabel.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get searchFilterGenresLabel;

  /// No description provided for @searchFilterPlatformsLabel.
  ///
  /// In en, this message translates to:
  /// **'Platforms'**
  String get searchFilterPlatformsLabel;

  /// No description provided for @searchFilterYearLabel.
  ///
  /// In en, this message translates to:
  /// **'Release year'**
  String get searchFilterYearLabel;

  /// No description provided for @searchFilterNoFacets.
  ///
  /// In en, this message translates to:
  /// **'Filters appear once results load.'**
  String get searchFilterNoFacets;

  /// No description provided for @searchFilterChipYear.
  ///
  /// In en, this message translates to:
  /// **'Year: {year}'**
  String searchFilterChipYear(int year);

  /// No description provided for @searchFilterChipSort.
  ///
  /// In en, this message translates to:
  /// **'Sort: {sort}'**
  String searchFilterChipSort(String sort);

  /// No description provided for @searchNoResultsForFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches for these filters'**
  String get searchNoResultsForFiltersTitle;

  /// No description provided for @searchNoResultsForFiltersHint.
  ///
  /// In en, this message translates to:
  /// **'Try removing a filter to see more games.'**
  String get searchNoResultsForFiltersHint;

  /// No description provided for @searchClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get searchClearFilters;

  /// No description provided for @gameDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Game Details'**
  String get gameDetailsTitle;

  /// No description provided for @developer.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @genres.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get genres;

  /// No description provided for @platforms.
  ///
  /// In en, this message translates to:
  /// **'Platforms'**
  String get platforms;

  /// No description provided for @storyline.
  ///
  /// In en, this message translates to:
  /// **'Storyline'**
  String get storyline;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// Game details screenshots section title
  ///
  /// In en, this message translates to:
  /// **'Screenshots'**
  String get screenshots;

  /// No description provided for @videos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get videos;

  /// No description provided for @videoPlayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get videoPlayerTitle;

  /// Game details section of similar games
  ///
  /// In en, this message translates to:
  /// **'Similar games'**
  String get similarGames;

  /// Game details section of store links
  ///
  /// In en, this message translates to:
  /// **'Where to buy'**
  String get whereToBuy;

  /// Expands a long description
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// Collapses a long description
  ///
  /// In en, this message translates to:
  /// **'Read less'**
  String get readLess;

  /// No description provided for @noVideosAvailable.
  ///
  /// In en, this message translates to:
  /// **'No videos available'**
  String get noVideosAvailable;

  /// No description provided for @noScreenshotsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No screenshots available'**
  String get noScreenshotsAvailable;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadingData;

  /// Discovery list title for trending games
  ///
  /// In en, this message translates to:
  /// **'Trending now'**
  String get discoveryTrending;

  /// Discovery list title for indie games
  ///
  /// In en, this message translates to:
  /// **'Indie gems'**
  String get discoveryIndie;

  /// Discovery list title for upcoming games
  ///
  /// In en, this message translates to:
  /// **'Upcoming games'**
  String get discoveryUpcoming;

  /// Discovery list title for new releases
  ///
  /// In en, this message translates to:
  /// **'New releases'**
  String get discoveryNewReleases;

  /// Discovery list title for games coming soon
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get discoveryComingSoon;

  /// Title of the personalized recommendations section
  ///
  /// In en, this message translates to:
  /// **'Recommended for you'**
  String get recommendationsTitle;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get signInWithGoogle;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get orContinueWith;

  /// Toggle button label that expands the secondary email/password sign-in form
  ///
  /// In en, this message translates to:
  /// **'Sign in with email'**
  String get signInWithEmail;

  /// Badge marking Google as the preferred sign-in option
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// No description provided for @browseTitle.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browseTitle;

  /// No description provided for @browseGenresError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load genres. Please try again.'**
  String get browseGenresError;

  /// No description provided for @browseGenresEmpty.
  ///
  /// In en, this message translates to:
  /// **'No genres available right now.'**
  String get browseGenresEmpty;

  /// No description provided for @browseGenreGamesError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load games for this genre. Please try again.'**
  String get browseGenreGamesError;

  /// No description provided for @browseGenreEmpty.
  ///
  /// In en, this message translates to:
  /// **'No games found in this genre yet.'**
  String get browseGenreEmpty;

  /// No description provided for @browseRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get browseRetry;

  /// Section header above the genre grid on the Browse hub
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get browseGenresSection;

  /// Heading shown in an error/empty view when the device has no network connection
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get offlineTitle;

  /// Body shown in an error view when a load failed because the device is offline
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get offlineErrorMessage;

  /// Accessibility label for a game cover image
  ///
  /// In en, this message translates to:
  /// **'Cover of {name}'**
  String gameCoverLabel(String name);

  /// Tooltip and accessibility label for the button that clears the search field
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// Accessibility label for the button that clears a selected date
  ///
  /// In en, this message translates to:
  /// **'Clear date'**
  String get clearDate;

  /// Accessibility label for a game screenshot image
  ///
  /// In en, this message translates to:
  /// **'Screenshot of {name}'**
  String screenshotLabel(String name);

  /// Accessibility label/tooltip for a favorite toggle when the game is already favorited
  ///
  /// In en, this message translates to:
  /// **'Favorited'**
  String get favorited;

  /// Accessibility label for a library entry card combining the game name and its status
  ///
  /// In en, this message translates to:
  /// **'{name}, {status}'**
  String libraryEntryLabel(String name, String status);

  /// Accessibility label for a browseable genre card
  ///
  /// In en, this message translates to:
  /// **'{name} genre'**
  String genreCardLabel(String name);

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get navBrowse;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// Library screen title
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryTitle;

  /// Button that opens search to add a game
  ///
  /// In en, this message translates to:
  /// **'Add game'**
  String get addGame;

  /// Empty library call to action
  ///
  /// In en, this message translates to:
  /// **'Add your first game'**
  String get addFirstGame;

  /// No description provided for @failedToLoadLibrary.
  ///
  /// In en, this message translates to:
  /// **'Failed to load library'**
  String get failedToLoadLibrary;

  /// No description provided for @favoritesWithCount.
  ///
  /// In en, this message translates to:
  /// **'Favorites ({count})'**
  String favoritesWithCount(int count);

  /// No description provided for @emptyFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorite games yet.\nTap the heart icon to add favorites!'**
  String get emptyFavorites;

  /// No description provided for @emptyStatusGames.
  ///
  /// In en, this message translates to:
  /// **'No games with this status yet.\nAdd games with this status to see them here.'**
  String get emptyStatusGames;

  /// No description provided for @emptyLibrary.
  ///
  /// In en, this message translates to:
  /// **'Your library is empty.\nStart adding games to track your collection!'**
  String get emptyLibrary;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @noUserInfo.
  ///
  /// In en, this message translates to:
  /// **'No user information available'**
  String get noUserInfo;

  /// No description provided for @switchToList.
  ///
  /// In en, this message translates to:
  /// **'Switch to list'**
  String get switchToList;

  /// No description provided for @switchToGrid.
  ///
  /// In en, this message translates to:
  /// **'Switch to grid'**
  String get switchToGrid;

  /// No description provided for @failedToLoadGames.
  ///
  /// In en, this message translates to:
  /// **'Failed to load games'**
  String get failedToLoadGames;

  /// No description provided for @reachedEnd.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached the end'**
  String get reachedEnd;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @noGamesFound.
  ///
  /// In en, this message translates to:
  /// **'No games found'**
  String get noGamesFound;

  /// No description provided for @noGamesInCategory.
  ///
  /// In en, this message translates to:
  /// **'There are no games in this category yet.'**
  String get noGamesInCategory;

  /// Section header link that opens the full list
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// Snackbar after copying a share link
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get linkCopied;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavorites;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @addToLibraryShort.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addToLibraryShort;

  /// No description provided for @links.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get links;

  /// No description provided for @statusPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get statusPlanned;

  /// No description provided for @statusPlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get statusPlaying;

  /// No description provided for @statusFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get statusFinished;

  /// No description provided for @statusDropped.
  ///
  /// In en, this message translates to:
  /// **'Dropped'**
  String get statusDropped;

  /// Library status: on hold
  ///
  /// In en, this message translates to:
  /// **'On hold'**
  String get statusOnHold;

  /// Title of the most anticipated games carousel
  ///
  /// In en, this message translates to:
  /// **'Most anticipated'**
  String get mostAnticipated;

  /// No description provided for @noUpcomingGames.
  ///
  /// In en, this message translates to:
  /// **'No upcoming games found'**
  String get noUpcomingGames;

  /// No description provided for @shareGameMessage.
  ///
  /// In en, this message translates to:
  /// **'Check out {gameName} on Picklog!\n{url}'**
  String shareGameMessage(String gameName, String url);

  /// Button and dialog title to remove a game from the library
  ///
  /// In en, this message translates to:
  /// **'Remove from library'**
  String get removeFromLibrary;

  /// No description provided for @removeFromLibraryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove \"{gameName}\" from your library?'**
  String removeFromLibraryConfirm(String gameName);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Snackbar after updating a library entry
  ///
  /// In en, this message translates to:
  /// **'Entry updated'**
  String get libraryEntryUpdated;

  /// Snackbar after adding a game to the library
  ///
  /// In en, this message translates to:
  /// **'Added to your library'**
  String get gameAddedToLibrary;

  /// Button and sheet title for editing a library entry
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get editEntry;

  /// Button and sheet title for adding a game to the library
  ///
  /// In en, this message translates to:
  /// **'Add to library'**
  String get addToLibrary;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @platformLabel.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get platformLabel;

  /// No description provided for @selectPlatformHint.
  ///
  /// In en, this message translates to:
  /// **'Select platform (optional)'**
  String get selectPlatformHint;

  /// No description provided for @noneOption.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noneOption;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @favorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get favorite;

  /// No description provided for @playtime.
  ///
  /// In en, this message translates to:
  /// **'Playtime'**
  String get playtime;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get minutes;

  /// No description provided for @dates.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get dates;

  /// Library entry start date label
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDate;

  /// Library entry end date label
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get endDate;

  /// No description provided for @difficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get difficulty;

  /// No description provided for @difficultyHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Normal, Hard, Nightmare'**
  String get difficultyHint;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Add your notes...'**
  String get notesHint;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @onboardingTrackTitle.
  ///
  /// In en, this message translates to:
  /// **'Track every game you play'**
  String get onboardingTrackTitle;

  /// No description provided for @onboardingTrackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Build your personal library and keep your collection organized by status.'**
  String get onboardingTrackSubtitle;

  /// No description provided for @onboardingDiscoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover what to play next'**
  String get onboardingDiscoverTitle;

  /// No description provided for @onboardingDiscoverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse trending titles, hidden gems and upcoming releases tailored for you.'**
  String get onboardingDiscoverSubtitle;

  /// No description provided for @onboardingShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Make it yours'**
  String get onboardingShareTitle;

  /// No description provided for @onboardingShareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Mark favorites, rate your games and pick up right where you left off.'**
  String get onboardingShareSubtitle;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted;

  /// No description provided for @searchGamesInitialTitle.
  ///
  /// In en, this message translates to:
  /// **'Find your next favorite'**
  String get searchGamesInitialTitle;

  /// No description provided for @searchGamesInitialHint.
  ///
  /// In en, this message translates to:
  /// **'Search by title to add games to your library.'**
  String get searchGamesInitialHint;

  /// No description provided for @searchGamesNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches yet'**
  String get searchGamesNoResultsTitle;

  /// No description provided for @emptyLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your library is empty'**
  String get emptyLibraryTitle;

  /// No description provided for @emptyLibraryHint.
  ///
  /// In en, this message translates to:
  /// **'Start adding games to track your collection and never lose progress.'**
  String get emptyLibraryHint;

  /// No description provided for @privacyDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data'**
  String get privacyDataTitle;

  /// No description provided for @exportDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Export my data'**
  String get exportDataTitle;

  /// No description provided for @exportDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Download a copy of your account data as a JSON file.'**
  String get exportDataSubtitle;

  /// No description provided for @exportDataSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your data export is ready.'**
  String get exportDataSuccess;

  /// No description provided for @exportDataError.
  ///
  /// In en, this message translates to:
  /// **'Could not export your data. Please try again.'**
  String get exportDataError;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account and all your data.'**
  String get deleteAccountSubtitle;

  /// No description provided for @deleteAccountDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccountDialogTitle;

  /// No description provided for @deleteAccountDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account and all your data. This cannot be undone.'**
  String get deleteAccountDialogBody;

  /// Label for the type-to-confirm field in the delete-account dialog
  ///
  /// In en, this message translates to:
  /// **'Type {word} to confirm'**
  String deleteAccountConfirmLabel(String word);

  /// The exact word the user must type to confirm account deletion
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get deleteAccountConfirmWord;

  /// No description provided for @deleteAccountConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountConfirmButton;

  /// No description provided for @deleteAccountError.
  ///
  /// In en, this message translates to:
  /// **'Could not delete your account. Please try again.'**
  String get deleteAccountError;

  /// Title of the first-run / web consent banner
  ///
  /// In en, this message translates to:
  /// **'Your privacy choices'**
  String get consentBannerTitle;

  /// Body text of the first-run / web consent banner
  ///
  /// In en, this message translates to:
  /// **'Choose what data you allow. You can change these anytime in Settings.'**
  String get consentBannerBody;

  /// Consent banner button that grants every data-collection category
  ///
  /// In en, this message translates to:
  /// **'Accept all'**
  String get consentAcceptAll;

  /// Consent banner button that denies every data-collection category
  ///
  /// In en, this message translates to:
  /// **'Reject all'**
  String get consentRejectAll;

  /// Consent banner button that opens the per-category choices sheet
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get consentCustomize;

  /// Title of the per-category consent customization sheet
  ///
  /// In en, this message translates to:
  /// **'Choose what you allow'**
  String get consentCustomizeTitle;

  /// Button that saves the per-category consent choices
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get consentSave;

  /// Label for the usage analytics consent category
  ///
  /// In en, this message translates to:
  /// **'Usage analytics'**
  String get consentAnalyticsTitle;

  /// Description for the usage analytics consent category
  ///
  /// In en, this message translates to:
  /// **'Anonymous usage data to help improve the app.'**
  String get consentAnalyticsSubtitle;

  /// Label for the crash reporting consent category
  ///
  /// In en, this message translates to:
  /// **'Crash reports'**
  String get consentCrashTitle;

  /// Description for the crash reporting consent category
  ///
  /// In en, this message translates to:
  /// **'Send crash and error reports to help fix problems.'**
  String get consentCrashSubtitle;

  /// Label for the push notifications consent category
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get consentPushTitle;

  /// Description for the push notifications consent category
  ///
  /// In en, this message translates to:
  /// **'Receive notifications about your games and updates.'**
  String get consentPushSubtitle;

  /// Title of the Privacy Policy screen and its settings link
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyTitle;

  /// Title of the Terms of Service screen and its settings link
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsTitle;

  /// Header for the legal documents section in settings
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legalTitle;

  /// Banner shown on legal screens warning the content is placeholder text
  ///
  /// In en, this message translates to:
  /// **'DRAFT — placeholder text. Replace with the final legal text before release.'**
  String get legalDraftBanner;

  /// Error shown when a legal document asset fails to load
  ///
  /// In en, this message translates to:
  /// **'Could not load this document. Please try again later.'**
  String get legalLoadError;

  /// Leading text of the sign-up consent checkbox, before the Privacy Policy link
  ///
  /// In en, this message translates to:
  /// **'I accept the '**
  String get signUpAcceptPrefix;

  /// Tappable Privacy Policy link inside the sign-up consent checkbox label
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get signUpAcceptPrivacyLink;

  /// Conjunction between the Privacy Policy and Terms links in the consent checkbox label
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get signUpAcceptConjunction;

  /// Tappable Terms of Service link inside the sign-up consent checkbox label
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get signUpAcceptTermsLink;

  /// Message shown when sign-up is attempted without accepting the Privacy Policy and Terms
  ///
  /// In en, this message translates to:
  /// **'Please accept the Privacy Policy and Terms to continue.'**
  String get signUpAcceptRequired;

  /// Notice shown near the social sign-in buttons stating that continuing implies acceptance
  ///
  /// In en, this message translates to:
  /// **'By continuing you accept our Privacy Policy and Terms of Service.'**
  String get signInLegalNotice;

  /// Error message when the server cannot be reached
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach Picklog right now. Check your connection.'**
  String get errorNetwork;

  /// Error message when the requested item does not exist
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find that.'**
  String get errorNotFound;

  /// Error message when the session is missing or expired
  ///
  /// In en, this message translates to:
  /// **'Your session ended. Sign in again.'**
  String get errorUnauthorized;

  /// Error message when the server fails
  ///
  /// In en, this message translates to:
  /// **'The server had a problem. Try again in a moment.'**
  String get errorServer;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get errorUnknown;

  /// Short tagline under the app name on the splash screen
  ///
  /// In en, this message translates to:
  /// **'Your game library, logged'**
  String get splashTagline;

  /// Onboarding page eyebrow for the tracking page
  ///
  /// In en, this message translates to:
  /// **'01 · Track'**
  String get onboardingTrackEyebrow;

  /// Onboarding page eyebrow for the discovery page
  ///
  /// In en, this message translates to:
  /// **'02 · Discover'**
  String get onboardingDiscoverEyebrow;

  /// Onboarding page eyebrow for the personalization page
  ///
  /// In en, this message translates to:
  /// **'03 · Make it yours'**
  String get onboardingShareEyebrow;

  /// Spoken position of a page indicator
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String pageIndicatorLabel(int current, int total);

  /// Eyebrow above the sign-in headline
  ///
  /// In en, this message translates to:
  /// **'Picklog · Sign in'**
  String get signInEyebrow;

  /// Sign-in screen headline
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get signInHeadline;

  /// Eyebrow above the sign-up headline
  ///
  /// In en, this message translates to:
  /// **'Picklog · Create account'**
  String get signUpEyebrow;

  /// Accessibility label for a game card that shows a 0-100 score
  ///
  /// In en, this message translates to:
  /// **'{name}, rating {score}'**
  String gameWithScoreLabel(String name, int score);

  /// Subtitle under the Recommended for you section
  ///
  /// In en, this message translates to:
  /// **'Picked from the genres you play'**
  String get recommendationsSubtitle;

  /// Title shown for the curated collections section when it fails to load
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get collectionsSectionTitle;

  /// Eyebrow on a featured banner card
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featuredEyebrow;

  /// Inline error when the featured banners fail to load
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load featured picks.'**
  String get featuredError;

  /// Countdown to release with days, hours and minutes
  ///
  /// In en, this message translates to:
  /// **'{days}d {hours}h {minutes}m'**
  String countdownDaysHoursMinutes(int days, int hours, int minutes);

  /// Countdown to release with hours and minutes
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String countdownHoursMinutes(int hours, int minutes);

  /// Countdown to release with minutes only
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String countdownMinutes(int minutes);

  /// Countdown badge text once a game has released
  ///
  /// In en, this message translates to:
  /// **'Out now'**
  String get countdownReleased;

  /// Number of IGDB hype votes for an upcoming game
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hype} other{{count} hypes}}'**
  String anticipatedHypes(int count);

  /// Library row when no playtime is logged
  ///
  /// In en, this message translates to:
  /// **'No playtime'**
  String get playtimeNone;

  /// Playtime under one hour
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String playtimeMinutesShort(int minutes);

  /// Playtime in hours; hours is already formatted for the locale
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String playtimeHoursShort(String hours);

  /// Eyebrow above the home greeting
  ///
  /// In en, this message translates to:
  /// **'Picklog · Home'**
  String get homeEyebrow;

  /// Home greeting before noon
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}'**
  String homeGreetingMorning(String name);

  /// Home greeting in the afternoon
  ///
  /// In en, this message translates to:
  /// **'Good afternoon, {name}'**
  String homeGreetingAfternoon(String name);

  /// Home greeting in the evening
  ///
  /// In en, this message translates to:
  /// **'Good evening, {name}'**
  String homeGreetingEvening(String name);

  /// Home greeting when the user name is unknown
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get homeGreetingAnonymous;

  /// Line under the home greeting
  ///
  /// In en, this message translates to:
  /// **'What are you playing next?'**
  String get homeSubtitle;

  /// Eyebrow above the library title
  ///
  /// In en, this message translates to:
  /// **'Picklog · Library'**
  String get libraryEyebrow;

  /// Number of games in the library
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No games yet} =1{1 game} other{{count} games}}'**
  String libraryGameCount(int count);

  /// Snackbar when toggling a favorite fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update the favorite. Try again.'**
  String get libraryFavoriteFailed;

  /// Snackbar when removing a library entry fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t remove the game. It\'s back in your library.'**
  String get libraryDeleteFailed;

  /// Snackbar when refreshing the library fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t refresh your library.'**
  String get libraryRefreshFailed;

  /// Snackbar when adding or updating a library entry fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your changes. Try again.'**
  String get librarySaveFailed;

  /// Screenshot lightbox position counter
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String lightboxPosition(int current, int total);

  /// Tooltip for closing the screenshot viewer
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get lightboxClose;

  /// Tooltip for the previous screenshot button
  ///
  /// In en, this message translates to:
  /// **'Previous screenshot'**
  String get lightboxPrevious;

  /// Tooltip for the next screenshot button
  ///
  /// In en, this message translates to:
  /// **'Next screenshot'**
  String get lightboxNext;

  /// Title of the card on game details when the game is in the library
  ///
  /// In en, this message translates to:
  /// **'In your library'**
  String get inYourLibrary;

  /// Label for the user's own 0-100 score
  ///
  /// In en, this message translates to:
  /// **'Your score'**
  String get yourScore;

  /// Label for the IGDB 0-100 rating on game details
  ///
  /// In en, this message translates to:
  /// **'Critic and player score'**
  String get igdbScore;

  /// Label for a game's release date
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get releaseDate;

  /// Game details section title for the storyline and summary
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get detailsAbout;

  /// Inline error when fetching the next page of search results fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load more results.'**
  String get searchLoadMoreFailed;

  /// Eyebrow above the browse sections
  ///
  /// In en, this message translates to:
  /// **'Picklog · Browse'**
  String get browseEyebrow;

  /// Toggle that reveals playtime, dates, difficulty and notes in the add-to-library sheet
  ///
  /// In en, this message translates to:
  /// **'More details'**
  String get libraryDetailsSection;

  /// Hint under the More details toggle
  ///
  /// In en, this message translates to:
  /// **'Playtime, dates, difficulty and notes'**
  String get libraryDetailsHint;

  /// Shown when no 0-100 score is set
  ///
  /// In en, this message translates to:
  /// **'Not rated'**
  String get scoreNotSet;

  /// Settings label for the theme selector
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeTitle;

  /// Theme option that follows the device setting
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Eyebrow above the settings sections
  ///
  /// In en, this message translates to:
  /// **'Picklog · Settings'**
  String get settingsEyebrow;

  /// Eyebrow above the profile header
  ///
  /// In en, this message translates to:
  /// **'Picklog · Profile'**
  String get profileEyebrow;

  /// Body of the router error screen
  ///
  /// In en, this message translates to:
  /// **'This page doesn\'t exist or moved.'**
  String get routeNotFoundMessage;

  /// Eyebrow above the Play next screen and home card
  ///
  /// In en, this message translates to:
  /// **'AI · Play next'**
  String get aiEyebrowPlayNext;

  /// Eyebrow above the AI discover screen
  ///
  /// In en, this message translates to:
  /// **'AI · Discover'**
  String get aiEyebrowDiscover;

  /// App bar title of the AI play next screen
  ///
  /// In en, this message translates to:
  /// **'Play next'**
  String get aiPlayNextTitle;

  /// Headline of the play next screen and home card
  ///
  /// In en, this message translates to:
  /// **'What should I play tonight?'**
  String get aiPlayNextHeadline;

  /// Subtitle under the play next headline
  ///
  /// In en, this message translates to:
  /// **'Tell Picklog your mood and your time. It picks from your backlog.'**
  String get aiPlayNextSubtitle;

  /// Label above the mood chips
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get aiMoodLabel;

  /// Mood chip
  ///
  /// In en, this message translates to:
  /// **'Chill'**
  String get aiMoodChill;

  /// Mood chip
  ///
  /// In en, this message translates to:
  /// **'Intense'**
  String get aiMoodIntense;

  /// Mood chip
  ///
  /// In en, this message translates to:
  /// **'Story'**
  String get aiMoodStory;

  /// Mood chip
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get aiMoodSocial;

  /// Mood chip
  ///
  /// In en, this message translates to:
  /// **'Quick'**
  String get aiMoodQuick;

  /// Mood chip
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get aiMoodChallenge;

  /// Label above the time slider
  ///
  /// In en, this message translates to:
  /// **'Time available'**
  String get aiTimeLabel;

  /// A duration in minutes
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String aiDurationMinutes(int minutes);

  /// A duration in whole hours
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String aiDurationHours(int hours);

  /// A duration in hours and minutes
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String aiDurationHoursMinutes(int hours, int minutes);

  /// Last slider stop: four hours or more
  ///
  /// In en, this message translates to:
  /// **'4 h+'**
  String get aiDurationFourPlus;

  /// Label above the platform chips
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get aiPlatformLabel;

  /// Chip that clears the platform filter
  ///
  /// In en, this message translates to:
  /// **'Any platform'**
  String get aiPlatformAny;

  /// Label of the optional note field
  ///
  /// In en, this message translates to:
  /// **'Anything else? (optional)'**
  String get aiNoteLabel;

  /// Hint of the optional note field
  ///
  /// In en, this message translates to:
  /// **'For example: something I can pause often'**
  String get aiNoteHint;

  /// Button that asks the AI for picks
  ///
  /// In en, this message translates to:
  /// **'Suggest games'**
  String get aiGenerateButton;

  /// Button that asks the AI for new picks
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get aiRegenerateButton;

  /// Daily AI usage counter
  ///
  /// In en, this message translates to:
  /// **'{remaining} of {limit} left today'**
  String aiRemainingToday(int remaining, int limit);

  /// Daily AI usage counter without the limit
  ///
  /// In en, this message translates to:
  /// **'{remaining} left today'**
  String aiRemainingTodayShort(int remaining);

  /// Rotating status line while play next loads
  ///
  /// In en, this message translates to:
  /// **'Reading your backlog'**
  String get aiLoadingPlayNext1;

  /// Rotating status line while play next loads
  ///
  /// In en, this message translates to:
  /// **'Weighing your mood and time'**
  String get aiLoadingPlayNext2;

  /// Rotating status line while play next loads
  ///
  /// In en, this message translates to:
  /// **'Comparing genres and scores'**
  String get aiLoadingPlayNext3;

  /// Rotating status line while AI results load
  ///
  /// In en, this message translates to:
  /// **'Picking the best fits'**
  String get aiLoadingPlayNext4;

  /// Rotating status line while discover loads
  ///
  /// In en, this message translates to:
  /// **'Reading your taste'**
  String get aiLoadingDiscover1;

  /// Rotating status line while discover loads
  ///
  /// In en, this message translates to:
  /// **'Looking for new games'**
  String get aiLoadingDiscover2;

  /// Rotating status line while discover loads
  ///
  /// In en, this message translates to:
  /// **'Checking the catalogue'**
  String get aiLoadingDiscover3;

  /// Heading above AI results
  ///
  /// In en, this message translates to:
  /// **'Your picks'**
  String get aiResultsTitle;

  /// Eyebrow on the first play next pick
  ///
  /// In en, this message translates to:
  /// **'Top pick'**
  String get aiTopPick;

  /// Estimated session length of a pick
  ///
  /// In en, this message translates to:
  /// **'About {duration} per session'**
  String aiSessionLength(String duration);

  /// Sets a pick's library status to playing
  ///
  /// In en, this message translates to:
  /// **'Start playing'**
  String get aiStartPlaying;

  /// Shown after a pick is set to playing
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get aiNowPlaying;

  /// Opens the game details
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get aiOpenGame;

  /// Error after start playing fails
  ///
  /// In en, this message translates to:
  /// **'Could not update this game. Try again.'**
  String get aiStartPlayingError;

  /// Empty state title when there is nothing to pick from
  ///
  /// In en, this message translates to:
  /// **'Your backlog is empty'**
  String get aiEmptyBacklogTitle;

  /// Empty state message when there is nothing to pick from
  ///
  /// In en, this message translates to:
  /// **'Play next picks from games you plan to play, are playing, or put on hold. Add a few first.'**
  String get aiEmptyBacklogMessage;

  /// Button to the Explore screen
  ///
  /// In en, this message translates to:
  /// **'Explore games'**
  String get aiGoExplore;

  /// Button to the Search screen
  ///
  /// In en, this message translates to:
  /// **'Search games'**
  String get aiGoSearch;

  /// Error 503 error.ai.unavailable
  ///
  /// In en, this message translates to:
  /// **'AI suggestions are not available right now.'**
  String get aiErrorUnavailable;

  /// Error 403 error.ai.consent_required
  ///
  /// In en, this message translates to:
  /// **'Turn on AI suggestions to use this feature.'**
  String get aiErrorConsentRequired;

  /// Error 429 error.ai.quota_exceeded
  ///
  /// In en, this message translates to:
  /// **'You used all of today\'s AI suggestions. Come back tomorrow.'**
  String get aiErrorQuotaExceeded;

  /// Error 502 error.ai.upstream
  ///
  /// In en, this message translates to:
  /// **'The AI service did not answer. Try again in a moment.'**
  String get aiErrorUpstream;

  /// Title when AI is disabled on the server
  ///
  /// In en, this message translates to:
  /// **'AI suggestions are off'**
  String get aiUnavailableTitle;

  /// Title when the daily AI quota is used
  ///
  /// In en, this message translates to:
  /// **'Daily limit reached'**
  String get aiQuotaTitle;

  /// Title when the user has not opted in
  ///
  /// In en, this message translates to:
  /// **'AI suggestions need your OK'**
  String get aiConsentNeededTitle;

  /// Message when the user has not opted in
  ///
  /// In en, this message translates to:
  /// **'Picklog sends data to the AI service only after you agree.'**
  String get aiConsentNeededMessage;

  /// Button that reopens the AI consent dialog
  ///
  /// In en, this message translates to:
  /// **'Review and turn on'**
  String get aiReviewConsent;

  /// AI consent dialog title
  ///
  /// In en, this message translates to:
  /// **'Turn on AI suggestions?'**
  String get aiConsentTitle;

  /// AI consent dialog: what is sent
  ///
  /// In en, this message translates to:
  /// **'To make suggestions, Picklog sends OpenAI the names, statuses, scores, genres, and playtime of games in your library, plus the note you type.'**
  String get aiConsentBody;

  /// AI consent dialog: what is never sent
  ///
  /// In en, this message translates to:
  /// **'Picklog never sends your email or your name.'**
  String get aiConsentNever;

  /// AI consent dialog: how to revoke
  ///
  /// In en, this message translates to:
  /// **'You can turn this off at any time in Settings.'**
  String get aiConsentRevoke;

  /// AI consent dialog accept button
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get aiConsentAccept;

  /// AI consent dialog decline button
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get aiConsentDecline;

  /// Error when saving AI consent fails
  ///
  /// In en, this message translates to:
  /// **'Could not save your choice. Try again.'**
  String get aiConsentSaveError;

  /// Settings group label for AI
  ///
  /// In en, this message translates to:
  /// **'AI suggestions'**
  String get aiSettingsTitle;

  /// Settings switch for AI consent
  ///
  /// In en, this message translates to:
  /// **'Allow AI suggestions'**
  String get aiSettingsSwitch;

  /// Settings AI switch subtitle when on
  ///
  /// In en, this message translates to:
  /// **'Picklog can send game data from your library to OpenAI.'**
  String get aiSettingsSwitchOn;

  /// Settings AI switch subtitle when off
  ///
  /// In en, this message translates to:
  /// **'Nothing is sent to OpenAI.'**
  String get aiSettingsSwitchOff;

  /// Daily AI usage in settings
  ///
  /// In en, this message translates to:
  /// **'{used} of {limit} used today'**
  String aiSettingsUsage(int used, int limit);

  /// Settings note when AI is disabled
  ///
  /// In en, this message translates to:
  /// **'AI suggestions are not available on this server.'**
  String get aiSettingsUnavailable;

  /// Settings note when AI status fails to load
  ///
  /// In en, this message translates to:
  /// **'Could not load your AI settings.'**
  String get aiSettingsLoadError;

  /// Home AI card subtitle
  ///
  /// In en, this message translates to:
  /// **'Get picks from your backlog for your mood and your time.'**
  String get aiHomeCardSubtitle;

  /// Home AI card button
  ///
  /// In en, this message translates to:
  /// **'Pick for me'**
  String get aiHomeCardAction;

  /// Title of the AI discover screen and its home entry
  ///
  /// In en, this message translates to:
  /// **'Discover with AI'**
  String get aiDiscoverTitle;

  /// Home discover entry subtitle
  ///
  /// In en, this message translates to:
  /// **'Describe what you want and find new games.'**
  String get aiHomeDiscoverSubtitle;

  /// Subtitle of the AI discover screen
  ///
  /// In en, this message translates to:
  /// **'Describe what you feel like playing. Picklog suggests games you do not have yet.'**
  String get aiDiscoverSubtitle;

  /// Label of the discover prompt field
  ///
  /// In en, this message translates to:
  /// **'What are you in the mood for?'**
  String get aiDiscoverPromptLabel;

  /// Hint of the discover prompt field
  ///
  /// In en, this message translates to:
  /// **'For example: a relaxing farming game'**
  String get aiDiscoverPromptHint;

  /// Button that runs AI discover
  ///
  /// In en, this message translates to:
  /// **'Find games'**
  String get aiDiscoverSubmit;

  /// Discover prompt suggestion chip
  ///
  /// In en, this message translates to:
  /// **'Cozy games for the weekend'**
  String get aiDiscoverSuggestion1;

  /// Discover prompt suggestion chip
  ///
  /// In en, this message translates to:
  /// **'Like Hades but slower'**
  String get aiDiscoverSuggestion2;

  /// Discover prompt suggestion chip
  ///
  /// In en, this message translates to:
  /// **'Short story games under 10 hours'**
  String get aiDiscoverSuggestion3;

  /// Label above the discover suggestion chips
  ///
  /// In en, this message translates to:
  /// **'Try one'**
  String get aiDiscoverSuggestionsLabel;

  /// Discover empty state title
  ///
  /// In en, this message translates to:
  /// **'No new games found'**
  String get aiDiscoverEmptyTitle;

  /// Discover empty state message
  ///
  /// In en, this message translates to:
  /// **'Try a different prompt.'**
  String get aiDiscoverEmptyMessage;

  /// Spoken label for a rating badge
  ///
  /// In en, this message translates to:
  /// **'Rating {score}'**
  String aiRatingLabel(int score);

  /// Connected accounts screen title and settings label
  ///
  /// In en, this message translates to:
  /// **'Connected accounts'**
  String get accountsTitle;

  /// Eyebrow on the connected accounts screen
  ///
  /// In en, this message translates to:
  /// **'Picklog · Accounts'**
  String get accountsEyebrow;

  /// Intro text on the connected accounts screen
  ///
  /// In en, this message translates to:
  /// **'Link public gaming profiles to bring in achievements and playtime. Picklog uses public identifiers only and never asks for your passwords.'**
  String get accountsIntro;

  /// Settings subtitle listing the services
  ///
  /// In en, this message translates to:
  /// **'Steam, Xbox, RetroAchievements, PlayStation'**
  String get accountsSettingsSubtitle;

  /// Pill when a provider is not configured
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get accountsUnavailable;

  /// Message when a provider is not configured
  ///
  /// In en, this message translates to:
  /// **'This service is not set up yet.'**
  String get accountsUnavailableMessage;

  /// Pill for the experimental PlayStation provider
  ///
  /// In en, this message translates to:
  /// **'Experimental'**
  String get accountsExperimental;

  /// Status of a provider without a linked account
  ///
  /// In en, this message translates to:
  /// **'Not linked'**
  String get accountsNotLinked;

  /// Button that opens the link sheet
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get accountsLink;

  /// Link sheet title
  ///
  /// In en, this message translates to:
  /// **'Link {provider}'**
  String accountsLinkTitle(String provider);

  /// Steam identifier field label
  ///
  /// In en, this message translates to:
  /// **'Steam profile URL or ID'**
  String get accountsSteamFieldLabel;

  /// Steam identifier help text
  ///
  /// In en, this message translates to:
  /// **'Paste your profile link, your custom URL name, or your 17-digit SteamID.'**
  String get accountsSteamHelp;

  /// Steam privacy note
  ///
  /// In en, this message translates to:
  /// **'Game details must be public. In Steam, open your profile, choose Edit Profile, then Privacy Settings, and set Game details to Public.'**
  String get accountsSteamPublicNote;

  /// Xbox identifier field label
  ///
  /// In en, this message translates to:
  /// **'Xbox gamertag'**
  String get accountsXboxFieldLabel;

  /// Xbox identifier help text
  ///
  /// In en, this message translates to:
  /// **'Your gamertag as it shows on your Xbox profile.'**
  String get accountsXboxHelp;

  /// RetroAchievements identifier field label
  ///
  /// In en, this message translates to:
  /// **'RetroAchievements username'**
  String get accountsRaFieldLabel;

  /// RetroAchievements identifier help text
  ///
  /// In en, this message translates to:
  /// **'Your username on retroachievements.org.'**
  String get accountsRaHelp;

  /// PlayStation identifier field label
  ///
  /// In en, this message translates to:
  /// **'PSN online ID'**
  String get accountsPsnFieldLabel;

  /// PlayStation identifier help text
  ///
  /// In en, this message translates to:
  /// **'Your online ID. Your trophy list must be visible to anyone.'**
  String get accountsPsnHelp;

  /// PlayStation experimental note
  ///
  /// In en, this message translates to:
  /// **'PlayStation support is experimental. It reads public trophy lists only.'**
  String get accountsPsnExperimentalNote;

  /// Link sheet submit button
  ///
  /// In en, this message translates to:
  /// **'Link account'**
  String get accountsLinkSubmit;

  /// Snackbar after linking
  ///
  /// In en, this message translates to:
  /// **'{provider} linked. Tap Sync now to import your data.'**
  String accountsLinkedMessage(String provider);

  /// Last sync time of a linked account
  ///
  /// In en, this message translates to:
  /// **'Last synced {time}'**
  String accountsLastSynced(String time);

  /// Linked account that never synced
  ///
  /// In en, this message translates to:
  /// **'Not synced yet'**
  String get accountsNeverSynced;

  /// Sync status pill
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get accountsSyncing;

  /// Sync status pill
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get accountsSyncOk;

  /// Sync status pill
  ///
  /// In en, this message translates to:
  /// **'Last sync failed'**
  String get accountsSyncError;

  /// Button that starts a sync
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get accountsSyncNow;

  /// Switch to import games during sync
  ///
  /// In en, this message translates to:
  /// **'Also import games to my library'**
  String get accountsImportToggle;

  /// Help under the import switch
  ///
  /// In en, this message translates to:
  /// **'Adds games you own or played that are not in your library yet.'**
  String get accountsImportHelp;

  /// Snackbar after a sync starts
  ///
  /// In en, this message translates to:
  /// **'Syncing {provider}. This can take a few minutes.'**
  String accountsSyncStarted(String provider);

  /// Snackbar when a sync ends
  ///
  /// In en, this message translates to:
  /// **'{provider} sync finished'**
  String accountsSyncFinished(String provider);

  /// Button that unlinks an account
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get accountsUnlink;

  /// Unlink confirm dialog title
  ///
  /// In en, this message translates to:
  /// **'Unlink {provider}?'**
  String accountsUnlinkTitle(String provider);

  /// Unlink confirm dialog message
  ///
  /// In en, this message translates to:
  /// **'Picklog deletes the achievements and progress it imported from this account. Games already in your library stay.'**
  String get accountsUnlinkMessage;

  /// Snackbar after unlinking
  ///
  /// In en, this message translates to:
  /// **'{provider} unlinked'**
  String accountsUnlinkedMessage(String provider);

  /// Error 404 error.integration.account_not_found
  ///
  /// In en, this message translates to:
  /// **'We could not find that account. Check the spelling and try again.'**
  String get accountsErrorNotFound;

  /// Error 422 error.integration.private_profile
  ///
  /// In en, this message translates to:
  /// **'This profile is private. Make your game details public and try again.'**
  String get accountsErrorPrivate;

  /// Error 429 error.integration.sync_too_soon
  ///
  /// In en, this message translates to:
  /// **'This account synced recently. Try again in a few minutes.'**
  String get accountsErrorSyncTooSoon;

  /// Error 503 error.integration.unavailable
  ///
  /// In en, this message translates to:
  /// **'This service is not available right now.'**
  String get accountsErrorUnavailable;

  /// Error for an empty or invalid identifier
  ///
  /// In en, this message translates to:
  /// **'Enter a valid identifier.'**
  String get accountsErrorInvalid;

  /// Error 502 error.integration.upstream
  ///
  /// In en, this message translates to:
  /// **'The service did not answer. Try again later.'**
  String get accountsErrorUpstream;

  /// Error 404 error.integration.game_not_found
  ///
  /// In en, this message translates to:
  /// **'We could not find achievements for this game.'**
  String get accountsErrorGameNotFound;

  /// Relative time under one minute
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// Relative time in minutes
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String timeMinutesAgo(int minutes);

  /// Relative time in hours
  ///
  /// In en, this message translates to:
  /// **'{hours} h ago'**
  String timeHoursAgo(int hours);

  /// Achievements hub title and game details section title
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievementsTitle;

  /// Eyebrow on the achievements hub
  ///
  /// In en, this message translates to:
  /// **'Picklog · Achievements'**
  String get achievementsEyebrow;

  /// Label beside the completion ring
  ///
  /// In en, this message translates to:
  /// **'Overall completion'**
  String get achievementsCompletion;

  /// Unlocked count out of total
  ///
  /// In en, this message translates to:
  /// **'{unlocked} of {total} unlocked'**
  String achievementsUnlockedOf(int unlocked, int total);

  /// Number of games for a provider
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 game} other{{count} games}}'**
  String achievementsGamesCount(int count);

  /// Section title for recent unlocks
  ///
  /// In en, this message translates to:
  /// **'Recent unlocks'**
  String get achievementsRecentTitle;

  /// Section title for the games list
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get achievementsGamesTitle;

  /// Provider filter chip for all providers
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get achievementsFilterAll;

  /// Achievements empty state title
  ///
  /// In en, this message translates to:
  /// **'No achievements yet'**
  String get achievementsEmptyTitle;

  /// Achievements empty state message
  ///
  /// In en, this message translates to:
  /// **'Link Steam, Xbox, RetroAchievements, or PlayStation to see your achievements here.'**
  String get achievementsEmptyMessage;

  /// Achievements empty state button
  ///
  /// In en, this message translates to:
  /// **'Connect an account'**
  String get achievementsConnectAction;

  /// Share of players with an achievement
  ///
  /// In en, this message translates to:
  /// **'{percent}% of players'**
  String achievementsRarity(String percent);

  /// Pill for an achievement under 10% rarity
  ///
  /// In en, this message translates to:
  /// **'Rare'**
  String get achievementsRare;

  /// Unlock date of an achievement
  ///
  /// In en, this message translates to:
  /// **'Unlocked {date}'**
  String achievementsUnlockedOn(String date);

  /// Label for a locked achievement
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get achievementsLocked;

  /// Last played date of a game
  ///
  /// In en, this message translates to:
  /// **'Played {date}'**
  String achievementsLastPlayed(String date);

  /// Per-game screen with an empty list
  ///
  /// In en, this message translates to:
  /// **'This game has no achievements to show.'**
  String get achievementsGameEmpty;

  /// Headline of the AI discover screen
  ///
  /// In en, this message translates to:
  /// **'Find your next favorite game'**
  String get aiDiscoverHeadline;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
