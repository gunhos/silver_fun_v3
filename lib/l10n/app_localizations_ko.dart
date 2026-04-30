// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Silvers Fun';

  @override
  String get loadingTitle => '불러오는 중';

  @override
  String stubComingSoon(String title) {
    return '$title — 준비 중이에요';
  }

  @override
  String get navDiscover => '둘러보기';

  @override
  String get navLikedYou => '좋아요';

  @override
  String get navChats => '대화';

  @override
  String get navYou => '내 정보';

  @override
  String get signInTagline => '인생의 다음 장을 함께할 친구를 만나 보세요.';

  @override
  String get signInButton => 'Google로 계속하기';

  @override
  String get signInButtonBusy => '로그인 중…';

  @override
  String get signInError => '로그인에 실패했어요. 다시 시도해 주세요.';

  @override
  String get signInTermsNote => '계속하시면 이용약관에 동의하시는 것입니다.';

  @override
  String get onbNameTitle => '성함이 어떻게 되세요?';

  @override
  String get onbNameSubtitle => '프로필에 표시되는 이름이에요.';

  @override
  String get onbFirstNameLabel => '이름';

  @override
  String get onbAgeLabel => '나이';

  @override
  String get onbAgeHelper => '65세 이상 어르신을 위한 앱이에요. 만 18세부터 가입하실 수 있습니다.';

  @override
  String get onbPhotoTitle => '사진을 올려 주세요';

  @override
  String get onbPhotoSubtitle => '본인이 잘 나온 최근 사진을 골라 주세요.';

  @override
  String get onbPhotoChoose => '사진첩에서 고르기';

  @override
  String get onbPhotoReplace => '사진 바꾸기';

  @override
  String get onbPhotoUploading => '올리는 중…';

  @override
  String get onbPhotoErrorOpen => '사진첩을 열 수 없어요.';

  @override
  String get onbPhotoErrorUpload => '사진을 올리지 못했어요. 다시 시도해 주세요.';

  @override
  String get onbBioTitle => '자기소개를 짧게 적어 주세요';

  @override
  String get onbBioSubtitle => '한두 문장이면 충분해요. 편하게 적어 주세요.';

  @override
  String get onbBioHint => '아침 커피와 주말 산책을 좋아해요…';

  @override
  String get onbInterestsTitle => '관심사를 골라 주세요';

  @override
  String get onbInterestsSubtitle => '좋아하시는 것 3가지에서 6가지를 골라 주세요.';

  @override
  String onbInterestsCounter(int count) {
    return '$count / 6개 선택됨';
  }

  @override
  String get onbPreviewTitle => '프로필 미리 보기';

  @override
  String get onbPreviewSubtitle => '다른 분들에게 이렇게 보여요.';

  @override
  String get onbPreviewPublishError => '프로필을 올리지 못했어요. 다시 시도해 주세요.';

  @override
  String get onbPreviewPublishing => '올리는 중…';

  @override
  String get onbPreviewPublish => '프로필 올리기';

  @override
  String get actionContinue => '계속하기';

  @override
  String get actionSave => '저장';

  @override
  String get actionSaving => '저장 중…';

  @override
  String get actionEdit => '수정';

  @override
  String get actionBack => '뒤로';

  @override
  String get feedEmptyTitle => '아직 둘러볼 분이 없어요.';

  @override
  String get feedEmptySubtitle => '곧 새로운 프로필이 올라올 거예요. 잠시 후 다시 와 주세요.';

  @override
  String get feedErrorPrefix => '둘러보기를 불러오지 못했어요.';

  @override
  String get profileViewNotFound => '프로필을 찾을 수 없어요.';

  @override
  String get profileViewLike => '좋아요';

  @override
  String get profileViewLiked => '좋아요 보냄';

  @override
  String get likedYouTitle => '나를 좋아한 분';

  @override
  String get likedYouEmptyTitle => '아직 아무도 없어요.';

  @override
  String get likedYouEmptySubtitle => '누군가 좋아요를 보내면 여기에 표시돼요.';

  @override
  String get likedYouErrorPrefix => '좋아요를 불러오지 못했어요.';

  @override
  String get chatsTitle => '대화';

  @override
  String get chatsErrorPrefix => '대화를 불러오지 못했어요.';

  @override
  String get chatsHintTitle => '새로 맺어진 친구에게 인사를 건네 보세요';

  @override
  String get chatsHintSubtitle => '위에 있는 친구를 눌러 대화를 시작해 보세요.';

  @override
  String get chatsEmptyTitle => '아직 친구가 없어요.';

  @override
  String get chatsEmptySubtitle => '서로 좋아요를 보낸 분과 여기에서 대화할 수 있어요.';

  @override
  String get chatsTimeNow => '방금';

  @override
  String chatsTimeMinutes(int n) {
    return '$n분 전';
  }

  @override
  String chatsTimeHours(int n) {
    return '$n시간 전';
  }

  @override
  String chatsTimeDays(int n) {
    return '$n일 전';
  }

  @override
  String get chatHeaderFallbackName => '친구';

  @override
  String get chatHeaderConnected => '친구';

  @override
  String get chatMessagesErrorPrefix => '메시지를 불러오지 못했어요.';

  @override
  String get chatComposerHint => '메시지 입력';

  @override
  String get chatMatchCardTitle => '이제 친구가 되었어요! 🎉';

  @override
  String get chatMatchCardHelloGeneric => '인사를 건네 대화를 시작해 보세요.';

  @override
  String chatMatchCardHelloNamed(String name) {
    return '$name님께 인사를 건네 대화를 시작해 보세요.';
  }

  @override
  String get chatSafetyReminder => '안전을 위해 개인정보, 비밀번호, 금전 거래는 절대 공유하지 마세요.';

  @override
  String get youTitle => '내 프로필';

  @override
  String get youSettingsTooltip => '설정';

  @override
  String get youErrorPrefix => '내 프로필을 불러오지 못했어요.';

  @override
  String get youStatusNotPublished => '아직 공개 전';

  @override
  String get youStatusPaused => '프로필 잠시 숨김';

  @override
  String get youStatusLive => '프로필 공개 중';

  @override
  String get youPreviewProfile => '프로필 미리 보기';

  @override
  String get youEditBio => '자기소개 수정';

  @override
  String get youEmptyMessage => '프로필이 아직 준비되지 않았어요.';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsSectionProfile => '프로필';

  @override
  String get settingsPauseProfile => '프로필 잠시 숨기기';

  @override
  String get settingsPauseSubtitlePaused => '둘러보기에서 보이지 않아요.';

  @override
  String get settingsPauseSubtitleLive => '둘러보기에 보여요.';

  @override
  String get settingsEditPhoto => '프로필 사진 바꾸기';

  @override
  String get settingsWhoCanSeeMe => '공개 범위';

  @override
  String get settingsWhoCanSeeMeValue => '전체 공개';

  @override
  String get settingsSectionNotifications => '알림';

  @override
  String get settingsNotifLikes => '새로운 좋아요';

  @override
  String get settingsNotifDigest => '주간 소식';

  @override
  String get settingsSectionAccount => '계정';

  @override
  String get settingsAccountGoogle => 'Google 계정 연결됨';

  @override
  String get settingsAccountPrivacy => '개인정보';

  @override
  String get settingsAccountHelp => '도움말';

  @override
  String get settingsSignOut => '로그아웃';

  @override
  String get editBioTitle => '자기소개 수정';

  @override
  String get toastProfilePaused => '프로필을 잠시 숨겼어요';

  @override
  String get toastProfileLive => '프로필을 공개했어요';

  @override
  String get toastLikedGeneric => '좋아요를 보냈어요';

  @override
  String toastLikedNamed(String name) {
    return '$name님께 좋아요를 보냈어요';
  }

  @override
  String get toastConnectedGeneric => '이제 친구가 되었어요! 🎉';

  @override
  String toastConnectedNamed(String name) {
    return '$name님과 친구가 되었어요! 🎉';
  }

  @override
  String profileNameAge(String name, int age) {
    return '$name, $age세';
  }

  @override
  String get interestGardening => '정원 가꾸기';

  @override
  String get interestWalking => '산책';

  @override
  String get interestCooking => '요리';

  @override
  String get interestBaking => '베이킹';

  @override
  String get interestCoffee => '커피';

  @override
  String get interestTravel => '여행';

  @override
  String get interestReading => '독서';

  @override
  String get interestPhotography => '사진 촬영';

  @override
  String get interestYoga => '요가';

  @override
  String get interestBirdWatching => '새 관찰';

  @override
  String get interestCrafts => '공예';

  @override
  String get interestKnitting => '뜨개질';

  @override
  String get interestBoardGames => '보드게임';

  @override
  String get interestCardsAndBridge => '카드 게임';

  @override
  String get interestMovies => '영화';

  @override
  String get interestTheatre => '연극';

  @override
  String get interestArt => '미술';

  @override
  String get interestLiveMusic => '라이브 음악';

  @override
  String get interestDancing => '춤';

  @override
  String get interestVolunteering => '자원봉사';

  @override
  String get interestGrandkids => '손주';

  @override
  String get interestDogs => '강아지';

  @override
  String get interestCats => '고양이';

  @override
  String get interestPlants => '식물';

  @override
  String get navMeetups => '모임';

  @override
  String get meetupsTitle => '모임';

  @override
  String get meetupsCreateButton => '모임 만들기';

  @override
  String get meetupsEmptyTitle => '예정된 모임이 없어요.';

  @override
  String get meetupsEmptySubtitle => '처음으로 모임을 만들어 보세요!';

  @override
  String get meetupsErrorPrefix => '모임을 불러오지 못했어요.';

  @override
  String get meetupCreateTitle => '새 모임';

  @override
  String get meetupFieldTitle => '제목';

  @override
  String get meetupFieldDescription => '내용';

  @override
  String get meetupFieldDateTime => '날짜와 시간';

  @override
  String get meetupFieldLocation => '장소';

  @override
  String get meetupFieldMaxAttendees => '최대 인원 (선택)';

  @override
  String get meetupCreateSave => '모임 만들기';

  @override
  String get meetupCreateError => '모임을 만들지 못했어요. 다시 시도해 주세요.';

  @override
  String get meetupValidationTitleRequired => '제목을 입력해 주세요.';

  @override
  String get meetupValidationDateRequired => '날짜와 시간을 선택해 주세요.';

  @override
  String get meetupValidationDateInPast => '미래의 날짜와 시간을 선택해 주세요.';

  @override
  String get meetupValidationLocationRequired => '장소를 입력해 주세요.';

  @override
  String get meetupValidationMaxAttendeesPositive => '1명 이상이어야 해요.';

  @override
  String get meetupDetailTitle => '모임';

  @override
  String meetupDetailHostedBy(String name) {
    return '$name님이 만든 모임';
  }

  @override
  String get meetupDetailHostedByYou => '내가 주최한 모임';

  @override
  String meetupDetailJoined(int count) {
    return '$count명 참여';
  }

  @override
  String meetupDetailJoinedWithCapacity(int count, int max) {
    return '$max명 중 $count명 참여';
  }

  @override
  String get meetupDetailJoinButton => '참여하기';

  @override
  String get meetupDetailLeaveButton => '참여 취소';

  @override
  String get meetupDetailCancelButton => '모임 취소';

  @override
  String get meetupDetailCanceledLabel => '취소됨';

  @override
  String get meetupDetailFullLabel => '정원 마감';

  @override
  String get meetupDetailNotFound => '모임을 찾을 수 없어요.';

  @override
  String get meetupListJoinedBadge => '참여 중';

  @override
  String get meetupListHostingBadge => '주최';

  @override
  String get toastMeetupCreated => '모임을 만들었어요';

  @override
  String get toastMeetupJoined => '모임에 참여했어요';

  @override
  String get toastMeetupLeft => '참여를 취소했어요';

  @override
  String get toastMeetupCanceled => '모임을 취소했어요';

  @override
  String get settingsSectionDisplay => '화면';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsLanguageSystem => '시스템 기본';

  @override
  String get settingsLanguageEnglish => '영어';

  @override
  String get settingsLanguageKorean => '한국어';

  @override
  String get settingsLanguageDialogTitle => '언어를 선택하세요';

  @override
  String get settingsLanguageDialogCancel => '취소';

  @override
  String get settingsEditInterests => '관심사 수정';

  @override
  String get editInterestsTitle => '관심사 수정';

  @override
  String get editInterestsSubtitle => '좋아하시는 것 3가지에서 6가지를 골라 주세요.';

  @override
  String get youEditInterests => '관심사 수정';

  @override
  String get toastLanguageSaved => '언어를 바꿨어요';

  @override
  String get toastInterestsUpdated => '관심사를 바꿨어요';
}
