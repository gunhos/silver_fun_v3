// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Silvers Fun';

  @override
  String get loadingTitle => 'Loading';

  @override
  String stubComingSoon(String title) {
    return '$title — coming soon';
  }

  @override
  String get navDiscover => 'Discover';

  @override
  String get navLikedYou => 'Liked you';

  @override
  String get navChats => 'Chats';

  @override
  String get navYou => 'You';

  @override
  String get signInTagline => 'Friendly company for the next chapter.';

  @override
  String get signInButton => 'Continue with Google';

  @override
  String get signInButtonBusy => 'Signing in…';

  @override
  String get signInError => 'Sign-in failed. Please try again.';

  @override
  String get signInTermsNote => 'By continuing you agree to our Terms.';

  @override
  String get onbNameTitle => 'What\'s your name?';

  @override
  String get onbNameSubtitle => 'This is what people will see on your profile.';

  @override
  String get onbFirstNameLabel => 'First name';

  @override
  String get onbAgeLabel => 'Age';

  @override
  String get onbAgeHelper =>
      'Designed for adults 65+. You must be 18 or older to create an account.';

  @override
  String get onbPhotoTitle => 'Add a photo';

  @override
  String get onbPhotoSubtitle => 'Pick a clear, recent photo of you.';

  @override
  String get onbPhotoChoose => 'Choose from gallery';

  @override
  String get onbPhotoReplace => 'Replace photo';

  @override
  String get onbPhotoUploading => 'Uploading…';

  @override
  String get onbPhotoErrorOpen => 'Could not open gallery.';

  @override
  String get onbPhotoErrorUpload => 'Upload failed. Please try again.';

  @override
  String get onbBioTitle => 'Write a short bio';

  @override
  String get onbBioSubtitle => 'A sentence or two about you. Keep it light.';

  @override
  String get onbBioHint => 'I love early morning coffee, hiking on weekends…';

  @override
  String get onbInterestsTitle => 'Pick your interests';

  @override
  String get onbInterestsSubtitle => 'Choose 3 to 6 things you love.';

  @override
  String onbInterestsCounter(int count) {
    return '$count / 6 selected';
  }

  @override
  String get onbPreviewTitle => 'Preview your profile';

  @override
  String get onbPreviewSubtitle => 'This is how others will see you.';

  @override
  String get onbPreviewPublishError => 'Publish failed. Please try again.';

  @override
  String get onbPreviewPublishing => 'Publishing…';

  @override
  String get onbPreviewPublish => 'Publish';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionSave => 'Save';

  @override
  String get actionSaving => 'Saving…';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionBack => 'Back';

  @override
  String get feedEmptyTitle => 'No one to discover yet.';

  @override
  String get feedEmptySubtitle =>
      'Check back soon — new profiles are on the way.';

  @override
  String get feedErrorPrefix => 'Could not load feed.';

  @override
  String get profileViewNotFound => 'Profile not found.';

  @override
  String get profileViewLike => 'Like';

  @override
  String get profileViewLiked => 'Liked';

  @override
  String get likedYouTitle => 'Liked you';

  @override
  String get likedYouEmptyTitle => 'No one yet.';

  @override
  String get likedYouEmptySubtitle =>
      'When someone likes you, they will show up here.';

  @override
  String get likedYouErrorPrefix => 'Could not load likes.';

  @override
  String get chatsTitle => 'Chats';

  @override
  String get chatsErrorPrefix => 'Could not load chats.';

  @override
  String get chatsHintTitle => 'Say hello to a new connection';

  @override
  String get chatsHintSubtitle => 'Tap a friend above to start a conversation.';

  @override
  String get chatsEmptyTitle => 'No connections yet.';

  @override
  String get chatsEmptySubtitle =>
      'When you and someone like each other, you can chat here.';

  @override
  String get chatsTimeNow => 'now';

  @override
  String chatsTimeMinutes(int n) {
    return '${n}m';
  }

  @override
  String chatsTimeHours(int n) {
    return '${n}h';
  }

  @override
  String chatsTimeDays(int n) {
    return '${n}d';
  }

  @override
  String get chatHeaderFallbackName => 'Friend';

  @override
  String get chatHeaderConnected => 'Connected';

  @override
  String get chatMessagesErrorPrefix => 'Could not load messages.';

  @override
  String get chatComposerHint => 'Message';

  @override
  String get chatMatchCardTitle => 'You\'re now connected! 🎉';

  @override
  String get chatMatchCardHelloGeneric => 'Say hello to start chatting.';

  @override
  String chatMatchCardHelloNamed(String name) {
    return 'Say hello to $name to start chatting.';
  }

  @override
  String get chatSafetyReminder =>
      'Stay safe — never share personal info, passwords, or money.';

  @override
  String get youTitle => 'You';

  @override
  String get youSettingsTooltip => 'Settings';

  @override
  String get youErrorPrefix => 'Could not load your profile.';

  @override
  String get youStatusNotPublished => 'Not published';

  @override
  String get youStatusPaused => 'Profile paused';

  @override
  String get youStatusLive => 'Profile live';

  @override
  String get youPreviewProfile => 'Preview profile';

  @override
  String get youEditBio => 'Edit bio';

  @override
  String get youEmptyMessage => 'Your profile is not ready yet.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionProfile => 'Profile';

  @override
  String get settingsPauseProfile => 'Pause profile';

  @override
  String get settingsPauseSubtitlePaused => 'Hidden from the discover feed.';

  @override
  String get settingsPauseSubtitleLive => 'Visible in the discover feed.';

  @override
  String get settingsEditPhoto => 'Edit profile photo';

  @override
  String get settingsWhoCanSeeMe => 'Who can see me';

  @override
  String get settingsWhoCanSeeMeValue => 'Everyone';

  @override
  String get settingsSectionNotifications => 'Notifications';

  @override
  String get settingsNotifLikes => 'New likes';

  @override
  String get settingsNotifDigest => 'Weekly digest';

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String get settingsAccountGoogle => 'Connected with Google';

  @override
  String get settingsAccountPrivacy => 'Privacy';

  @override
  String get settingsAccountHelp => 'Help';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get editBioTitle => 'Edit bio';

  @override
  String get toastProfilePaused => 'Profile paused';

  @override
  String get toastProfileLive => 'Profile live';

  @override
  String get toastLikedGeneric => 'Liked';

  @override
  String toastLikedNamed(String name) {
    return 'Liked $name';
  }

  @override
  String get toastConnectedGeneric => 'You\'re now connected! 🎉';

  @override
  String toastConnectedNamed(String name) {
    return 'You and $name are now connected! 🎉';
  }

  @override
  String profileNameAge(String name, int age) {
    return '$name, $age';
  }

  @override
  String get interestGardening => 'Gardening';

  @override
  String get interestWalking => 'Walking';

  @override
  String get interestCooking => 'Cooking';

  @override
  String get interestBaking => 'Baking';

  @override
  String get interestCoffee => 'Coffee';

  @override
  String get interestTravel => 'Travel';

  @override
  String get interestReading => 'Reading';

  @override
  String get interestPhotography => 'Photography';

  @override
  String get interestYoga => 'Yoga';

  @override
  String get interestBirdWatching => 'Bird watching';

  @override
  String get interestCrafts => 'Crafts';

  @override
  String get interestKnitting => 'Knitting';

  @override
  String get interestBoardGames => 'Board games';

  @override
  String get interestCardsAndBridge => 'Cards & bridge';

  @override
  String get interestMovies => 'Movies';

  @override
  String get interestTheatre => 'Theatre';

  @override
  String get interestArt => 'Art';

  @override
  String get interestLiveMusic => 'Live music';

  @override
  String get interestDancing => 'Dancing';

  @override
  String get interestVolunteering => 'Volunteering';

  @override
  String get interestGrandkids => 'Grandkids';

  @override
  String get interestDogs => 'Dogs';

  @override
  String get interestCats => 'Cats';

  @override
  String get interestPlants => 'Plants';

  @override
  String get navMeetups => 'Meetups';

  @override
  String get meetupsTitle => 'Meetups';

  @override
  String get meetupsCreateButton => 'Create meetup';

  @override
  String get meetupsEmptyTitle => 'No upcoming meetups.';

  @override
  String get meetupsEmptySubtitle => 'Be the first to plan one!';

  @override
  String get meetupsErrorPrefix => 'Could not load meetups.';

  @override
  String get meetupCreateTitle => 'New meetup';

  @override
  String get meetupFieldTitle => 'Title';

  @override
  String get meetupFieldDescription => 'Description';

  @override
  String get meetupFieldDateTime => 'Date and time';

  @override
  String get meetupFieldLocation => 'Location';

  @override
  String get meetupFieldMaxAttendees => 'Maximum attendees (optional)';

  @override
  String get meetupCreateSave => 'Create meetup';

  @override
  String get meetupCreateError => 'Could not create meetup. Please try again.';

  @override
  String get meetupValidationTitleRequired => 'Please enter a title.';

  @override
  String get meetupValidationDateRequired => 'Please pick a date and time.';

  @override
  String get meetupValidationDateInPast => 'Pick a future date and time.';

  @override
  String get meetupValidationLocationRequired => 'Please add a location.';

  @override
  String get meetupValidationMaxAttendeesPositive => 'Must be 1 or more.';

  @override
  String get meetupDetailTitle => 'Meetup';

  @override
  String meetupDetailHostedBy(String name) {
    return 'Hosted by $name';
  }

  @override
  String get meetupDetailHostedByYou => 'You\'re hosting';

  @override
  String meetupDetailJoined(int count) {
    return '$count joined';
  }

  @override
  String meetupDetailJoinedWithCapacity(int count, int max) {
    return '$count of $max joined';
  }

  @override
  String get meetupDetailJoinButton => 'Join';

  @override
  String get meetupDetailLeaveButton => 'Leave';

  @override
  String get meetupDetailCancelButton => 'Cancel meetup';

  @override
  String get meetupDetailCanceledLabel => 'Canceled';

  @override
  String get meetupDetailFullLabel => 'Meetup full';

  @override
  String get meetupDetailNotFound => 'Meetup not found.';

  @override
  String get meetupListJoinedBadge => 'Joined';

  @override
  String get meetupListHostingBadge => 'Hosting';

  @override
  String get toastMeetupCreated => 'Meetup created';

  @override
  String get toastMeetupJoined => 'You joined the meetup';

  @override
  String get toastMeetupLeft => 'You left the meetup';

  @override
  String get toastMeetupCanceled => 'Meetup canceled';

  @override
  String get settingsSectionDisplay => 'Display';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageKorean => '한국어';

  @override
  String get settingsLanguageDialogTitle => 'Choose language';

  @override
  String get settingsLanguageDialogCancel => 'Cancel';

  @override
  String get settingsEditInterests => 'Edit interests';

  @override
  String get editInterestsTitle => 'Edit interests';

  @override
  String get editInterestsSubtitle => 'Choose 3 to 6 things you love.';

  @override
  String get youEditInterests => 'Edit interests';

  @override
  String get toastLanguageSaved => 'Language updated';

  @override
  String get toastInterestsUpdated => 'Interests updated';
}
