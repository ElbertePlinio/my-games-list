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

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get goHome;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
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

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInButton;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @signUpLink.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpLink;

  /// No description provided for @signUpAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpAppBarTitle;

  /// No description provided for @signUpBodyTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
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

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
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

  /// No description provided for @signUpButton.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpButton;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @signInLink.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInLink;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @userInformationTitle.
  ///
  /// In en, this message translates to:
  /// **'User Information'**
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

  /// No description provided for @darkModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkModeTitle;

  /// No description provided for @darkModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Toggle between light and dark theme'**
  String get darkModeSubtitle;

  /// No description provided for @logoutButton.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutButton;

  /// No description provided for @searchGamesTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Games'**
  String get searchGamesTitle;

  /// No description provided for @searchGamesHint.
  ///
  /// In en, this message translates to:
  /// **'Search for games...'**
  String get searchGamesHint;

  /// No description provided for @searchGamesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search Games'**
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

  /// No description provided for @screenshots.
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

  /// No description provided for @similarGames.
  ///
  /// In en, this message translates to:
  /// **'Similar Games'**
  String get similarGames;

  /// No description provided for @whereToBuy.
  ///
  /// In en, this message translates to:
  /// **'Where to Buy'**
  String get whereToBuy;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read More'**
  String get readMore;

  /// No description provided for @readLess.
  ///
  /// In en, this message translates to:
  /// **'Read Less'**
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

  /// No description provided for @discoveryTrending.
  ///
  /// In en, this message translates to:
  /// **'Trending Now'**
  String get discoveryTrending;

  /// No description provided for @discoveryIndie.
  ///
  /// In en, this message translates to:
  /// **'Indie Gems'**
  String get discoveryIndie;

  /// No description provided for @discoveryUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Games'**
  String get discoveryUpcoming;

  /// No description provided for @discoveryNewReleases.
  ///
  /// In en, this message translates to:
  /// **'New Releases'**
  String get discoveryNewReleases;

  /// No description provided for @discoveryComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get discoveryComingSoon;

  /// No description provided for @recommendationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended for You'**
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

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'My Library'**
  String get libraryTitle;

  /// No description provided for @addGame.
  ///
  /// In en, this message translates to:
  /// **'Add Game'**
  String get addGame;

  /// No description provided for @addFirstGame.
  ///
  /// In en, this message translates to:
  /// **'Add Your First Game'**
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

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard!'**
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

  /// No description provided for @statusOnHold.
  ///
  /// In en, this message translates to:
  /// **'On Hold'**
  String get statusOnHold;

  /// No description provided for @mostAnticipated.
  ///
  /// In en, this message translates to:
  /// **'Most Anticipated'**
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

  /// No description provided for @removeFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Remove from Library'**
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

  /// No description provided for @libraryEntryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Library entry updated successfully.'**
  String get libraryEntryUpdated;

  /// No description provided for @gameAddedToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Game added to library successfully.'**
  String get gameAddedToLibrary;

  /// No description provided for @editEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit Entry'**
  String get editEntry;

  /// No description provided for @addToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Add to Library'**
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

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
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
