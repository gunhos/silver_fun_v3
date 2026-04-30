import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('ko'),
  ];

  /// Brand name. Always English.
  ///
  /// In en, this message translates to:
  /// **'Silvers Fun'**
  String get appTitle;

  /// No description provided for @loadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loadingTitle;

  /// No description provided for @stubComingSoon.
  ///
  /// In en, this message translates to:
  /// **'{title} — coming soon'**
  String stubComingSoon(String title);

  /// No description provided for @navDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get navDiscover;

  /// No description provided for @navLikedYou.
  ///
  /// In en, this message translates to:
  /// **'Liked you'**
  String get navLikedYou;

  /// No description provided for @navChats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get navChats;

  /// No description provided for @navYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get navYou;

  /// No description provided for @signInTagline.
  ///
  /// In en, this message translates to:
  /// **'Friendly company for the next chapter.'**
  String get signInTagline;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get signInButton;

  /// No description provided for @signInButtonBusy.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get signInButtonBusy;

  /// No description provided for @signInError.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Please try again.'**
  String get signInError;

  /// No description provided for @signInTermsNote.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to our Terms.'**
  String get signInTermsNote;

  /// No description provided for @onbNameTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your name?'**
  String get onbNameTitle;

  /// No description provided for @onbNameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This is what people will see on your profile.'**
  String get onbNameSubtitle;

  /// No description provided for @onbFirstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get onbFirstNameLabel;

  /// No description provided for @onbAgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get onbAgeLabel;

  /// No description provided for @onbAgeHelper.
  ///
  /// In en, this message translates to:
  /// **'Designed for adults 65+. You must be 18 or older to create an account.'**
  String get onbAgeHelper;

  /// No description provided for @onbPhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get onbPhotoTitle;

  /// No description provided for @onbPhotoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a clear, recent photo of you.'**
  String get onbPhotoSubtitle;

  /// No description provided for @onbPhotoChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get onbPhotoChoose;

  /// No description provided for @onbPhotoReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace photo'**
  String get onbPhotoReplace;

  /// No description provided for @onbPhotoUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get onbPhotoUploading;

  /// No description provided for @onbPhotoErrorOpen.
  ///
  /// In en, this message translates to:
  /// **'Could not open gallery.'**
  String get onbPhotoErrorOpen;

  /// No description provided for @onbPhotoErrorUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Please try again.'**
  String get onbPhotoErrorUpload;

  /// No description provided for @onbBioTitle.
  ///
  /// In en, this message translates to:
  /// **'Write a short bio'**
  String get onbBioTitle;

  /// No description provided for @onbBioSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A sentence or two about you. Keep it light.'**
  String get onbBioSubtitle;

  /// No description provided for @onbBioHint.
  ///
  /// In en, this message translates to:
  /// **'I love early morning coffee, hiking on weekends…'**
  String get onbBioHint;

  /// No description provided for @onbInterestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick your interests'**
  String get onbInterestsTitle;

  /// No description provided for @onbInterestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose 3 to 6 things you love.'**
  String get onbInterestsSubtitle;

  /// No description provided for @onbInterestsCounter.
  ///
  /// In en, this message translates to:
  /// **'{count} / 6 selected'**
  String onbInterestsCounter(int count);

  /// No description provided for @onbPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview your profile'**
  String get onbPreviewTitle;

  /// No description provided for @onbPreviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This is how others will see you.'**
  String get onbPreviewSubtitle;

  /// No description provided for @onbPreviewPublishError.
  ///
  /// In en, this message translates to:
  /// **'Publish failed. Please try again.'**
  String get onbPreviewPublishError;

  /// No description provided for @onbPreviewPublishing.
  ///
  /// In en, this message translates to:
  /// **'Publishing…'**
  String get onbPreviewPublishing;

  /// No description provided for @onbPreviewPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get onbPreviewPublish;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get actionSaving;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @feedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No one to discover yet.'**
  String get feedEmptyTitle;

  /// No description provided for @feedEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check back soon — new profiles are on the way.'**
  String get feedEmptySubtitle;

  /// No description provided for @feedErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Could not load feed.'**
  String get feedErrorPrefix;

  /// No description provided for @profileViewNotFound.
  ///
  /// In en, this message translates to:
  /// **'Profile not found.'**
  String get profileViewNotFound;

  /// No description provided for @profileViewLike.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get profileViewLike;

  /// No description provided for @profileViewLiked.
  ///
  /// In en, this message translates to:
  /// **'Liked'**
  String get profileViewLiked;

  /// No description provided for @likedYouTitle.
  ///
  /// In en, this message translates to:
  /// **'Liked you'**
  String get likedYouTitle;

  /// No description provided for @likedYouEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No one yet.'**
  String get likedYouEmptyTitle;

  /// No description provided for @likedYouEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'When someone likes you, they will show up here.'**
  String get likedYouEmptySubtitle;

  /// No description provided for @likedYouErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Could not load likes.'**
  String get likedYouErrorPrefix;

  /// No description provided for @chatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chatsTitle;

  /// No description provided for @chatsErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Could not load chats.'**
  String get chatsErrorPrefix;

  /// No description provided for @chatsHintTitle.
  ///
  /// In en, this message translates to:
  /// **'Say hello to a new connection'**
  String get chatsHintTitle;

  /// No description provided for @chatsHintSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap a friend above to start a conversation.'**
  String get chatsHintSubtitle;

  /// No description provided for @chatsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No connections yet.'**
  String get chatsEmptyTitle;

  /// No description provided for @chatsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'When you and someone like each other, you can chat here.'**
  String get chatsEmptySubtitle;

  /// No description provided for @chatsTimeNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get chatsTimeNow;

  /// No description provided for @chatsTimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n}m'**
  String chatsTimeMinutes(int n);

  /// No description provided for @chatsTimeHours.
  ///
  /// In en, this message translates to:
  /// **'{n}h'**
  String chatsTimeHours(int n);

  /// No description provided for @chatsTimeDays.
  ///
  /// In en, this message translates to:
  /// **'{n}d'**
  String chatsTimeDays(int n);

  /// No description provided for @chatHeaderFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get chatHeaderFallbackName;

  /// No description provided for @chatHeaderConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get chatHeaderConnected;

  /// No description provided for @chatMessagesErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Could not load messages.'**
  String get chatMessagesErrorPrefix;

  /// No description provided for @chatComposerHint.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get chatComposerHint;

  /// No description provided for @chatMatchCardTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re now connected! 🎉'**
  String get chatMatchCardTitle;

  /// No description provided for @chatMatchCardHelloGeneric.
  ///
  /// In en, this message translates to:
  /// **'Say hello to start chatting.'**
  String get chatMatchCardHelloGeneric;

  /// No description provided for @chatMatchCardHelloNamed.
  ///
  /// In en, this message translates to:
  /// **'Say hello to {name} to start chatting.'**
  String chatMatchCardHelloNamed(String name);

  /// No description provided for @chatSafetyReminder.
  ///
  /// In en, this message translates to:
  /// **'Stay safe — never share personal info, passwords, or money.'**
  String get chatSafetyReminder;

  /// No description provided for @youTitle.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youTitle;

  /// No description provided for @youSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get youSettingsTooltip;

  /// No description provided for @youErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Could not load your profile.'**
  String get youErrorPrefix;

  /// No description provided for @youStatusNotPublished.
  ///
  /// In en, this message translates to:
  /// **'Not published'**
  String get youStatusNotPublished;

  /// No description provided for @youStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Profile paused'**
  String get youStatusPaused;

  /// No description provided for @youStatusLive.
  ///
  /// In en, this message translates to:
  /// **'Profile live'**
  String get youStatusLive;

  /// No description provided for @youPreviewProfile.
  ///
  /// In en, this message translates to:
  /// **'Preview profile'**
  String get youPreviewProfile;

  /// No description provided for @youEditBio.
  ///
  /// In en, this message translates to:
  /// **'Edit bio'**
  String get youEditBio;

  /// No description provided for @youEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Your profile is not ready yet.'**
  String get youEmptyMessage;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsSectionProfile;

  /// No description provided for @settingsPauseProfile.
  ///
  /// In en, this message translates to:
  /// **'Pause profile'**
  String get settingsPauseProfile;

  /// No description provided for @settingsPauseSubtitlePaused.
  ///
  /// In en, this message translates to:
  /// **'Hidden from the discover feed.'**
  String get settingsPauseSubtitlePaused;

  /// No description provided for @settingsPauseSubtitleLive.
  ///
  /// In en, this message translates to:
  /// **'Visible in the discover feed.'**
  String get settingsPauseSubtitleLive;

  /// No description provided for @settingsEditPhoto.
  ///
  /// In en, this message translates to:
  /// **'Edit profile photo'**
  String get settingsEditPhoto;

  /// No description provided for @settingsWhoCanSeeMe.
  ///
  /// In en, this message translates to:
  /// **'Who can see me'**
  String get settingsWhoCanSeeMe;

  /// No description provided for @settingsWhoCanSeeMeValue.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get settingsWhoCanSeeMeValue;

  /// No description provided for @settingsSectionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsSectionNotifications;

  /// No description provided for @settingsNotifLikes.
  ///
  /// In en, this message translates to:
  /// **'New likes'**
  String get settingsNotifLikes;

  /// No description provided for @settingsNotifDigest.
  ///
  /// In en, this message translates to:
  /// **'Weekly digest'**
  String get settingsNotifDigest;

  /// No description provided for @settingsSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsSectionAccount;

  /// No description provided for @settingsAccountGoogle.
  ///
  /// In en, this message translates to:
  /// **'Connected with Google'**
  String get settingsAccountGoogle;

  /// No description provided for @settingsAccountPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsAccountPrivacy;

  /// No description provided for @settingsAccountHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get settingsAccountHelp;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsSignOut;

  /// No description provided for @editBioTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit bio'**
  String get editBioTitle;

  /// No description provided for @toastProfilePaused.
  ///
  /// In en, this message translates to:
  /// **'Profile paused'**
  String get toastProfilePaused;

  /// No description provided for @toastProfileLive.
  ///
  /// In en, this message translates to:
  /// **'Profile live'**
  String get toastProfileLive;

  /// No description provided for @toastLikedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Liked'**
  String get toastLikedGeneric;

  /// No description provided for @toastLikedNamed.
  ///
  /// In en, this message translates to:
  /// **'Liked {name}'**
  String toastLikedNamed(String name);

  /// No description provided for @toastConnectedGeneric.
  ///
  /// In en, this message translates to:
  /// **'You\'re now connected! 🎉'**
  String get toastConnectedGeneric;

  /// No description provided for @toastConnectedNamed.
  ///
  /// In en, this message translates to:
  /// **'You and {name} are now connected! 🎉'**
  String toastConnectedNamed(String name);

  /// No description provided for @profileNameAge.
  ///
  /// In en, this message translates to:
  /// **'{name}, {age}'**
  String profileNameAge(String name, int age);

  /// No description provided for @interestGardening.
  ///
  /// In en, this message translates to:
  /// **'Gardening'**
  String get interestGardening;

  /// No description provided for @interestWalking.
  ///
  /// In en, this message translates to:
  /// **'Walking'**
  String get interestWalking;

  /// No description provided for @interestCooking.
  ///
  /// In en, this message translates to:
  /// **'Cooking'**
  String get interestCooking;

  /// No description provided for @interestBaking.
  ///
  /// In en, this message translates to:
  /// **'Baking'**
  String get interestBaking;

  /// No description provided for @interestCoffee.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get interestCoffee;

  /// No description provided for @interestTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get interestTravel;

  /// No description provided for @interestReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get interestReading;

  /// No description provided for @interestPhotography.
  ///
  /// In en, this message translates to:
  /// **'Photography'**
  String get interestPhotography;

  /// No description provided for @interestYoga.
  ///
  /// In en, this message translates to:
  /// **'Yoga'**
  String get interestYoga;

  /// No description provided for @interestBirdWatching.
  ///
  /// In en, this message translates to:
  /// **'Bird watching'**
  String get interestBirdWatching;

  /// No description provided for @interestCrafts.
  ///
  /// In en, this message translates to:
  /// **'Crafts'**
  String get interestCrafts;

  /// No description provided for @interestKnitting.
  ///
  /// In en, this message translates to:
  /// **'Knitting'**
  String get interestKnitting;

  /// No description provided for @interestBoardGames.
  ///
  /// In en, this message translates to:
  /// **'Board games'**
  String get interestBoardGames;

  /// No description provided for @interestCardsAndBridge.
  ///
  /// In en, this message translates to:
  /// **'Cards & bridge'**
  String get interestCardsAndBridge;

  /// No description provided for @interestMovies.
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get interestMovies;

  /// No description provided for @interestTheatre.
  ///
  /// In en, this message translates to:
  /// **'Theatre'**
  String get interestTheatre;

  /// No description provided for @interestArt.
  ///
  /// In en, this message translates to:
  /// **'Art'**
  String get interestArt;

  /// No description provided for @interestLiveMusic.
  ///
  /// In en, this message translates to:
  /// **'Live music'**
  String get interestLiveMusic;

  /// No description provided for @interestDancing.
  ///
  /// In en, this message translates to:
  /// **'Dancing'**
  String get interestDancing;

  /// No description provided for @interestVolunteering.
  ///
  /// In en, this message translates to:
  /// **'Volunteering'**
  String get interestVolunteering;

  /// No description provided for @interestGrandkids.
  ///
  /// In en, this message translates to:
  /// **'Grandkids'**
  String get interestGrandkids;

  /// No description provided for @interestDogs.
  ///
  /// In en, this message translates to:
  /// **'Dogs'**
  String get interestDogs;

  /// No description provided for @interestCats.
  ///
  /// In en, this message translates to:
  /// **'Cats'**
  String get interestCats;

  /// No description provided for @interestPlants.
  ///
  /// In en, this message translates to:
  /// **'Plants'**
  String get interestPlants;

  /// No description provided for @navMeetups.
  ///
  /// In en, this message translates to:
  /// **'Meetups'**
  String get navMeetups;

  /// No description provided for @meetupsTitle.
  ///
  /// In en, this message translates to:
  /// **'Meetups'**
  String get meetupsTitle;

  /// No description provided for @meetupsCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create meetup'**
  String get meetupsCreateButton;

  /// No description provided for @meetupsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No upcoming meetups.'**
  String get meetupsEmptyTitle;

  /// No description provided for @meetupsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Be the first to plan one!'**
  String get meetupsEmptySubtitle;

  /// No description provided for @meetupsErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Could not load meetups.'**
  String get meetupsErrorPrefix;

  /// No description provided for @meetupCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New meetup'**
  String get meetupCreateTitle;

  /// No description provided for @meetupFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get meetupFieldTitle;

  /// No description provided for @meetupFieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get meetupFieldDescription;

  /// No description provided for @meetupFieldDateTime.
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get meetupFieldDateTime;

  /// No description provided for @meetupFieldLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get meetupFieldLocation;

  /// No description provided for @meetupFieldMaxAttendees.
  ///
  /// In en, this message translates to:
  /// **'Maximum attendees (optional)'**
  String get meetupFieldMaxAttendees;

  /// No description provided for @meetupCreateSave.
  ///
  /// In en, this message translates to:
  /// **'Create meetup'**
  String get meetupCreateSave;

  /// No description provided for @meetupCreateError.
  ///
  /// In en, this message translates to:
  /// **'Could not create meetup. Please try again.'**
  String get meetupCreateError;

  /// No description provided for @meetupValidationTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title.'**
  String get meetupValidationTitleRequired;

  /// No description provided for @meetupValidationDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Please pick a date and time.'**
  String get meetupValidationDateRequired;

  /// No description provided for @meetupValidationDateInPast.
  ///
  /// In en, this message translates to:
  /// **'Pick a future date and time.'**
  String get meetupValidationDateInPast;

  /// No description provided for @meetupValidationLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Please add a location.'**
  String get meetupValidationLocationRequired;

  /// No description provided for @meetupValidationMaxAttendeesPositive.
  ///
  /// In en, this message translates to:
  /// **'Must be 1 or more.'**
  String get meetupValidationMaxAttendeesPositive;

  /// No description provided for @meetupDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Meetup'**
  String get meetupDetailTitle;

  /// No description provided for @meetupDetailHostedBy.
  ///
  /// In en, this message translates to:
  /// **'Hosted by {name}'**
  String meetupDetailHostedBy(String name);

  /// No description provided for @meetupDetailHostedByYou.
  ///
  /// In en, this message translates to:
  /// **'You\'re hosting'**
  String get meetupDetailHostedByYou;

  /// No description provided for @meetupDetailJoined.
  ///
  /// In en, this message translates to:
  /// **'{count} joined'**
  String meetupDetailJoined(int count);

  /// No description provided for @meetupDetailJoinedWithCapacity.
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} joined'**
  String meetupDetailJoinedWithCapacity(int count, int max);

  /// No description provided for @meetupDetailJoinButton.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get meetupDetailJoinButton;

  /// No description provided for @meetupDetailLeaveButton.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get meetupDetailLeaveButton;

  /// No description provided for @meetupDetailCancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel meetup'**
  String get meetupDetailCancelButton;

  /// No description provided for @meetupDetailCanceledLabel.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get meetupDetailCanceledLabel;

  /// No description provided for @meetupDetailFullLabel.
  ///
  /// In en, this message translates to:
  /// **'Meetup full'**
  String get meetupDetailFullLabel;

  /// No description provided for @meetupDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Meetup not found.'**
  String get meetupDetailNotFound;

  /// No description provided for @meetupListJoinedBadge.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get meetupListJoinedBadge;

  /// No description provided for @meetupListHostingBadge.
  ///
  /// In en, this message translates to:
  /// **'Hosting'**
  String get meetupListHostingBadge;

  /// No description provided for @toastMeetupCreated.
  ///
  /// In en, this message translates to:
  /// **'Meetup created'**
  String get toastMeetupCreated;

  /// No description provided for @toastMeetupJoined.
  ///
  /// In en, this message translates to:
  /// **'You joined the meetup'**
  String get toastMeetupJoined;

  /// No description provided for @toastMeetupLeft.
  ///
  /// In en, this message translates to:
  /// **'You left the meetup'**
  String get toastMeetupLeft;

  /// No description provided for @toastMeetupCanceled.
  ///
  /// In en, this message translates to:
  /// **'Meetup canceled'**
  String get toastMeetupCanceled;

  /// No description provided for @settingsSectionDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get settingsSectionDisplay;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageKorean.
  ///
  /// In en, this message translates to:
  /// **'한국어'**
  String get settingsLanguageKorean;

  /// No description provided for @settingsLanguageDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get settingsLanguageDialogTitle;

  /// No description provided for @settingsLanguageDialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsLanguageDialogCancel;

  /// No description provided for @settingsEditInterests.
  ///
  /// In en, this message translates to:
  /// **'Edit interests'**
  String get settingsEditInterests;

  /// No description provided for @editInterestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit interests'**
  String get editInterestsTitle;

  /// No description provided for @editInterestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose 3 to 6 things you love.'**
  String get editInterestsSubtitle;

  /// No description provided for @youEditInterests.
  ///
  /// In en, this message translates to:
  /// **'Edit interests'**
  String get youEditInterests;

  /// No description provided for @toastLanguageSaved.
  ///
  /// In en, this message translates to:
  /// **'Language updated'**
  String get toastLanguageSaved;

  /// No description provided for @toastInterestsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Interests updated'**
  String get toastInterestsUpdated;
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
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
