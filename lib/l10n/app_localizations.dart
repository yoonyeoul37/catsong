import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

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
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In ko, this message translates to:
  /// **'뮤직웨이브'**
  String get appName;

  /// No description provided for @songs.
  ///
  /// In ko, this message translates to:
  /// **'곡'**
  String get songs;

  /// No description provided for @albums.
  ///
  /// In ko, this message translates to:
  /// **'앨범'**
  String get albums;

  /// No description provided for @artists.
  ///
  /// In ko, this message translates to:
  /// **'아티스트'**
  String get artists;

  /// No description provided for @playlists.
  ///
  /// In ko, this message translates to:
  /// **'재생목록'**
  String get playlists;

  /// No description provided for @folders.
  ///
  /// In ko, this message translates to:
  /// **'폴더'**
  String get folders;

  /// No description provided for @videos.
  ///
  /// In ko, this message translates to:
  /// **'동영상'**
  String get videos;

  /// No description provided for @settings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settings;

  /// No description provided for @search.
  ///
  /// In ko, this message translates to:
  /// **'검색'**
  String get search;

  /// No description provided for @favorites.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기'**
  String get favorites;

  /// No description provided for @recent.
  ///
  /// In ko, this message translates to:
  /// **'최근'**
  String get recent;

  /// No description provided for @all.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get all;

  /// No description provided for @play.
  ///
  /// In ko, this message translates to:
  /// **'재생'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In ko, this message translates to:
  /// **'일시정지'**
  String get pause;

  /// No description provided for @next.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In ko, this message translates to:
  /// **'이전'**
  String get previous;

  /// No description provided for @shuffle.
  ///
  /// In ko, this message translates to:
  /// **'셔플'**
  String get shuffle;

  /// No description provided for @repeat.
  ///
  /// In ko, this message translates to:
  /// **'반복'**
  String get repeat;

  /// No description provided for @nowPlaying.
  ///
  /// In ko, this message translates to:
  /// **'지금 재생 중'**
  String get nowPlaying;

  /// No description provided for @noSongs.
  ///
  /// In ko, this message translates to:
  /// **'MP3 파일이 없습니다'**
  String get noSongs;

  /// No description provided for @addMusic.
  ///
  /// In ko, this message translates to:
  /// **'기기에 음악 파일을 추가해 주세요'**
  String get addMusic;

  /// No description provided for @scanningMusic.
  ///
  /// In ko, this message translates to:
  /// **'음악을 스캔하는 중...'**
  String get scanningMusic;

  /// No description provided for @editSong.
  ///
  /// In ko, this message translates to:
  /// **'곡 정보 편집'**
  String get editSong;

  /// No description provided for @save.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get delete;

  /// No description provided for @title.
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get title;

  /// No description provided for @artist.
  ///
  /// In ko, this message translates to:
  /// **'아티스트'**
  String get artist;

  /// No description provided for @album.
  ///
  /// In ko, this message translates to:
  /// **'앨범'**
  String get album;

  /// No description provided for @addToPlaylist.
  ///
  /// In ko, this message translates to:
  /// **'재생목록에 추가'**
  String get addToPlaylist;

  /// No description provided for @addToFavorites.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기 추가'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기 제거'**
  String get removeFromFavorites;

  /// No description provided for @setRingtone.
  ///
  /// In ko, this message translates to:
  /// **'벨소리로 설정'**
  String get setRingtone;

  /// No description provided for @share.
  ///
  /// In ko, this message translates to:
  /// **'공유'**
  String get share;

  /// No description provided for @songInfo.
  ///
  /// In ko, this message translates to:
  /// **'곡 정보'**
  String get songInfo;

  /// No description provided for @equalizer.
  ///
  /// In ko, this message translates to:
  /// **'이퀄라이저'**
  String get equalizer;

  /// No description provided for @sleepTimer.
  ///
  /// In ko, this message translates to:
  /// **'수면 타이머'**
  String get sleepTimer;

  /// No description provided for @playbackSpeed.
  ///
  /// In ko, this message translates to:
  /// **'재생 속도'**
  String get playbackSpeed;

  /// No description provided for @repeatMode.
  ///
  /// In ko, this message translates to:
  /// **'반복 모드'**
  String get repeatMode;

  /// No description provided for @noRepeat.
  ///
  /// In ko, this message translates to:
  /// **'반복 없음'**
  String get noRepeat;

  /// No description provided for @repeatOne.
  ///
  /// In ko, this message translates to:
  /// **'현재 노래 반복'**
  String get repeatOne;

  /// No description provided for @repeatAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 반복'**
  String get repeatAll;

  /// No description provided for @themeColor.
  ///
  /// In ko, this message translates to:
  /// **'테마 색상'**
  String get themeColor;

  /// No description provided for @textSize.
  ///
  /// In ko, this message translates to:
  /// **'텍스트 크기'**
  String get textSize;

  /// No description provided for @fontChange.
  ///
  /// In ko, this message translates to:
  /// **'텍스트 변경'**
  String get fontChange;

  /// No description provided for @playerStyle.
  ///
  /// In ko, this message translates to:
  /// **'재생화면 스타일'**
  String get playerStyle;

  /// No description provided for @flashlight.
  ///
  /// In ko, this message translates to:
  /// **'손전등'**
  String get flashlight;

  /// No description provided for @sos.
  ///
  /// In ko, this message translates to:
  /// **'SOS 비상등'**
  String get sos;

  /// No description provided for @ringtone.
  ///
  /// In ko, this message translates to:
  /// **'벨소리 지정'**
  String get ringtone;

  /// No description provided for @widget.
  ///
  /// In ko, this message translates to:
  /// **'홈화면 위젯'**
  String get widget;

  /// No description provided for @version.
  ///
  /// In ko, this message translates to:
  /// **'버전 정보'**
  String get version;

  /// No description provided for @promoCode.
  ///
  /// In ko, this message translates to:
  /// **'프로모션 코드'**
  String get promoCode;

  /// No description provided for @privacyPolicy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보처리방침'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In ko, this message translates to:
  /// **'이용약관'**
  String get termsOfService;

  /// No description provided for @noRecentSongs.
  ///
  /// In ko, this message translates to:
  /// **'최근 재생한 곡이 없습니다'**
  String get noRecentSongs;

  /// No description provided for @playMusic.
  ///
  /// In ko, this message translates to:
  /// **'음악을 재생해보세요'**
  String get playMusic;

  /// No description provided for @clearAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 삭제'**
  String get clearAll;

  /// No description provided for @clearRecent.
  ///
  /// In ko, this message translates to:
  /// **'최근 재생 전체 삭제'**
  String get clearRecent;

  /// No description provided for @clearRecentConfirm.
  ///
  /// In ko, this message translates to:
  /// **'최근 재생 목록을 모두 삭제할까요?'**
  String get clearRecentConfirm;

  /// No description provided for @playAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 재생'**
  String get playAll;

  /// No description provided for @addedToFavorites.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기에 추가됐습니다'**
  String get addedToFavorites;

  /// No description provided for @removedFromFavorites.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기에서 제거됐습니다'**
  String get removedFromFavorites;

  /// No description provided for @songSaved.
  ///
  /// In ko, this message translates to:
  /// **'곡 정보가 저장되었습니다'**
  String get songSaved;

  /// No description provided for @swipeToChange.
  ///
  /// In ko, this message translates to:
  /// **'스와이프로 곡 변경'**
  String get swipeToChange;

  /// No description provided for @noAlbums.
  ///
  /// In ko, this message translates to:
  /// **'앨범이 없습니다'**
  String get noAlbums;

  /// No description provided for @noArtists.
  ///
  /// In ko, this message translates to:
  /// **'아티스트가 없습니다'**
  String get noArtists;

  /// No description provided for @searchAlbums.
  ///
  /// In ko, this message translates to:
  /// **'앨범 검색...'**
  String get searchAlbums;

  /// No description provided for @searchArtists.
  ///
  /// In ko, this message translates to:
  /// **'아티스트 검색...'**
  String get searchArtists;

  /// No description provided for @close.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get close;

  /// No description provided for @defaultValue.
  ///
  /// In ko, this message translates to:
  /// **'기본값'**
  String get defaultValue;

  /// No description provided for @preview.
  ///
  /// In ko, this message translates to:
  /// **'미리듣기'**
  String get preview;

  /// No description provided for @playing.
  ///
  /// In ko, this message translates to:
  /// **'재생 중...'**
  String get playing;

  /// No description provided for @ringtoneSet.
  ///
  /// In ko, this message translates to:
  /// **'벨소리가 설정됐습니다! 🎵'**
  String get ringtoneSet;

  /// No description provided for @ringtoneFailed.
  ///
  /// In ko, this message translates to:
  /// **'벨소리 설정에 실패했습니다'**
  String get ringtoneFailed;

  /// No description provided for @promoUnlocked.
  ///
  /// In ko, this message translates to:
  /// **'🎉 광고가 제거되었습니다!'**
  String get promoUnlocked;

  /// No description provided for @promoInvalid.
  ///
  /// In ko, this message translates to:
  /// **'올바르지 않은 코드입니다'**
  String get promoInvalid;

  /// No description provided for @promoEnter.
  ///
  /// In ko, this message translates to:
  /// **'프로모션 코드를 입력하세요'**
  String get promoEnter;

  /// No description provided for @confirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get confirm;

  /// No description provided for @permissionRequired.
  ///
  /// In ko, this message translates to:
  /// **'저장소 접근 권한 필요'**
  String get permissionRequired;

  /// No description provided for @permissionMessage.
  ///
  /// In ko, this message translates to:
  /// **'MP3 파일을 스캔하려면\n저장소 접근 권한이 필요합니다.'**
  String get permissionMessage;

  /// No description provided for @allowPermission.
  ///
  /// In ko, this message translates to:
  /// **'권한 허용'**
  String get allowPermission;

  /// No description provided for @retry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get retry;

  /// No description provided for @deleteSong.
  ///
  /// In ko, this message translates to:
  /// **'곡 삭제'**
  String get deleteSong;

  /// No description provided for @deleteSongConfirm.
  ///
  /// In ko, this message translates to:
  /// **'을(를) 삭제할까요?\n기기에서 영구 삭제됩니다.'**
  String get deleteSongConfirm;

  /// No description provided for @deleted.
  ///
  /// In ko, this message translates to:
  /// **'삭제됐습니다'**
  String get deleted;

  /// No description provided for @deleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제 실패'**
  String get deleteFailed;

  /// No description provided for @playNext.
  ///
  /// In ko, this message translates to:
  /// **'다음에 재생'**
  String get playNext;

  /// No description provided for @addedToQueue.
  ///
  /// In ko, this message translates to:
  /// **'다음에 재생됩니다'**
  String get addedToQueue;

  /// No description provided for @noPlaylists.
  ///
  /// In ko, this message translates to:
  /// **'재생목록이 없습니다.\n재생목록 탭에서 먼저 만들어주세요.'**
  String get noPlaylists;

  /// No description provided for @addedToPlaylist.
  ///
  /// In ko, this message translates to:
  /// **'에 추가됐습니다'**
  String get addedToPlaylist;

  /// No description provided for @searchHint.
  ///
  /// In ko, this message translates to:
  /// **'곡, 아티스트, 앨범 검색...'**
  String get searchHint;

  /// No description provided for @timerCancel.
  ///
  /// In ko, this message translates to:
  /// **'타이머 취소'**
  String get timerCancel;

  /// No description provided for @minutesAfterEnd.
  ///
  /// In ko, this message translates to:
  /// **'분 후 종료'**
  String get minutesAfterEnd;

  /// No description provided for @hoursAfterEnd.
  ///
  /// In ko, this message translates to:
  /// **'시간 후 종료'**
  String get hoursAfterEnd;

  /// No description provided for @set.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get set;

  /// No description provided for @small.
  ///
  /// In ko, this message translates to:
  /// **'작게'**
  String get small;

  /// No description provided for @large.
  ///
  /// In ko, this message translates to:
  /// **'크게'**
  String get large;

  /// No description provided for @apply.
  ///
  /// In ko, this message translates to:
  /// **'적용'**
  String get apply;

  /// No description provided for @songCount.
  ///
  /// In ko, this message translates to:
  /// **'곡'**
  String get songCount;

  /// No description provided for @on.
  ///
  /// In ko, this message translates to:
  /// **'켜짐'**
  String get on;

  /// No description provided for @off.
  ///
  /// In ko, this message translates to:
  /// **'꺼짐'**
  String get off;

  /// No description provided for @sosWorking.
  ///
  /// In ko, this message translates to:
  /// **'작동 중...'**
  String get sosWorking;

  /// No description provided for @flashlightError.
  ///
  /// In ko, this message translates to:
  /// **'손전등 오류'**
  String get flashlightError;

  /// No description provided for @minuteShort.
  ///
  /// In ko, this message translates to:
  /// **'분'**
  String get minuteShort;

  /// No description provided for @hourShort.
  ///
  /// In ko, this message translates to:
  /// **'시'**
  String get hourShort;

  /// No description provided for @privacyPolicyUrl.
  ///
  /// In ko, this message translates to:
  /// **'https://www.ssing.kr/privacy_policy.html'**
  String get privacyPolicyUrl;

  /// No description provided for @termsOfServiceUrl.
  ///
  /// In ko, this message translates to:
  /// **'https://www.ssing.kr/terms_of_service.html'**
  String get termsOfServiceUrl;

  /// No description provided for @preset.
  ///
  /// In ko, this message translates to:
  /// **'프리셋'**
  String get preset;

  /// No description provided for @bassBooster.
  ///
  /// In ko, this message translates to:
  /// **'베이스 부스터'**
  String get bassBooster;

  /// No description provided for @enhancesBass.
  ///
  /// In ko, this message translates to:
  /// **'저음을 강화해요'**
  String get enhancesBass;

  /// No description provided for @virtualizer.
  ///
  /// In ko, this message translates to:
  /// **'버추얼라이저'**
  String get virtualizer;

  /// No description provided for @surroundEffect.
  ///
  /// In ko, this message translates to:
  /// **'입체감 있는 소리를 만들어요'**
  String get surroundEffect;

  /// No description provided for @reset.
  ///
  /// In ko, this message translates to:
  /// **'초기화'**
  String get reset;

  /// No description provided for @reviewTitle.
  ///
  /// In ko, this message translates to:
  /// **'캣송이 마음에 드시나요?'**
  String get reviewTitle;

  /// No description provided for @reviewMessage.
  ///
  /// In ko, this message translates to:
  /// **'별점을 남겨주시면\n앱 개선에 큰 도움이 됩니다 😊'**
  String get reviewMessage;

  /// No description provided for @reviewButton.
  ///
  /// In ko, this message translates to:
  /// **'⭐ 평점 남기기'**
  String get reviewButton;

  /// No description provided for @reviewLater.
  ///
  /// In ko, this message translates to:
  /// **'나중에 할게요'**
  String get reviewLater;

  /// No description provided for @fontDefault.
  ///
  /// In ko, this message translates to:
  /// **'기본 폰트'**
  String get fontDefault;

  /// No description provided for @fontNotoSans.
  ///
  /// In ko, this message translates to:
  /// **'Noto Sans KR (깔끔)'**
  String get fontNotoSans;

  /// No description provided for @fontJua.
  ///
  /// In ko, this message translates to:
  /// **'Jua (귀여운)'**
  String get fontJua;

  /// No description provided for @fontGaegu.
  ///
  /// In ko, this message translates to:
  /// **'Gaegu (손글씨)'**
  String get fontGaegu;

  /// No description provided for @fontNanumGothic.
  ///
  /// In ko, this message translates to:
  /// **'Nanum Gothic (부드러운)'**
  String get fontNanumGothic;

  /// No description provided for @fontDoHyeon.
  ///
  /// In ko, this message translates to:
  /// **'Do Hyeon (모던)'**
  String get fontDoHyeon;

  /// No description provided for @fontCuteFont.
  ///
  /// In ko, this message translates to:
  /// **'Cute Font (귀여운)'**
  String get fontCuteFont;

  /// No description provided for @fontStylish.
  ///
  /// In ko, this message translates to:
  /// **'Stylish (세련된)'**
  String get fontStylish;

  /// No description provided for @fontSunflower.
  ///
  /// In ko, this message translates to:
  /// **'Sunflower (가벼운)'**
  String get fontSunflower;

  /// No description provided for @fontHiMelody.
  ///
  /// In ko, this message translates to:
  /// **'Hi Melody (감성적)'**
  String get fontHiMelody;

  /// No description provided for @fontPoorStory.
  ///
  /// In ko, this message translates to:
  /// **'Poor Story (손글씨)'**
  String get fontPoorStory;

  /// No description provided for @fontEastSeaDokdo.
  ///
  /// In ko, this message translates to:
  /// **'East Sea Dokdo (독특한)'**
  String get fontEastSeaDokdo;

  /// No description provided for @fontNanumBrush.
  ///
  /// In ko, this message translates to:
  /// **'Nanum Brush Script (붓글씨)'**
  String get fontNanumBrush;

  /// No description provided for @fontNanumMyeongjo.
  ///
  /// In ko, this message translates to:
  /// **'Nanum Myeongjo (명조체)'**
  String get fontNanumMyeongjo;

  /// No description provided for @fontBlackAndWhite.
  ///
  /// In ko, this message translates to:
  /// **'Black And White Picture (특이한)'**
  String get fontBlackAndWhite;

  /// No description provided for @fontGowunDodum.
  ///
  /// In ko, this message translates to:
  /// **'Gowun Dodum (도담도담)'**
  String get fontGowunDodum;

  /// No description provided for @fontGowunBatang.
  ///
  /// In ko, this message translates to:
  /// **'Gowun Batang (바탕체)'**
  String get fontGowunBatang;

  /// No description provided for @fontNanumPen.
  ///
  /// In ko, this message translates to:
  /// **'Nanum Pen Script (펜글씨)'**
  String get fontNanumPen;

  /// No description provided for @fontSingleDay.
  ///
  /// In ko, this message translates to:
  /// **'Single Day (귀여운)'**
  String get fontSingleDay;

  /// No description provided for @fontYeonSung.
  ///
  /// In ko, this message translates to:
  /// **'Yeon Sung (연성체)'**
  String get fontYeonSung;

  /// No description provided for @styleCD.
  ///
  /// In ko, this message translates to:
  /// **'CD 회전'**
  String get styleCD;

  /// No description provided for @styleCDDesc.
  ///
  /// In ko, this message translates to:
  /// **'클래식한 CD 회전 애니메이션'**
  String get styleCDDesc;

  /// No description provided for @styleCassette.
  ///
  /// In ko, this message translates to:
  /// **'카세트 테이프'**
  String get styleCassette;

  /// No description provided for @styleCassetteDesc.
  ///
  /// In ko, this message translates to:
  /// **'레트로 카세트 테이프'**
  String get styleCassetteDesc;

  /// No description provided for @styleCard.
  ///
  /// In ko, this message translates to:
  /// **'앨범아트 카드'**
  String get styleCard;

  /// No description provided for @styleCardDesc.
  ///
  /// In ko, this message translates to:
  /// **'심플한 앨범아트 카드형'**
  String get styleCardDesc;

  /// No description provided for @styleVisualizer.
  ///
  /// In ko, this message translates to:
  /// **'파형 비주얼라이저'**
  String get styleVisualizer;

  /// No description provided for @styleVisualizerDesc.
  ///
  /// In ko, this message translates to:
  /// **'음파 애니메이션'**
  String get styleVisualizerDesc;

  /// No description provided for @styleGradient.
  ///
  /// In ko, this message translates to:
  /// **'그라데이션'**
  String get styleGradient;

  /// No description provided for @styleGradientDesc.
  ///
  /// In ko, this message translates to:
  /// **'앨범아트 색상 그라데이션 배경'**
  String get styleGradientDesc;

  /// No description provided for @themeColorHint.
  ///
  /// In ko, this message translates to:
  /// **'설정에서 배경색을 바꿀 수 있어요'**
  String get themeColorHint;

  /// No description provided for @hourWord.
  ///
  /// In ko, this message translates to:
  /// **'시간'**
  String get hourWord;

  /// No description provided for @autoStopFormat.
  ///
  /// In ko, this message translates to:
  /// **'{time} 후 자동으로 꺼집니다'**
  String autoStopFormat(Object time);

  /// No description provided for @autoStopCountdownSuffix.
  ///
  /// In ko, this message translates to:
  /// **'후 자동 종료'**
  String get autoStopCountdownSuffix;

  /// No description provided for @secondShort.
  ///
  /// In ko, this message translates to:
  /// **'초'**
  String get secondShort;

  /// No description provided for @unknownArtist.
  ///
  /// In ko, this message translates to:
  /// **'알 수 없는 아티스트'**
  String get unknownArtist;

  /// No description provided for @unknownAlbum.
  ///
  /// In ko, this message translates to:
  /// **'알 수 없는 앨범'**
  String get unknownAlbum;

  /// No description provided for @noTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목 없음'**
  String get noTitle;

  /// No description provided for @selectedCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 선택됨'**
  String selectedCount(Object count);

  /// No description provided for @selectAll.
  ///
  /// In ko, this message translates to:
  /// **'전체선택'**
  String get selectAll;

  /// No description provided for @deleteSelected.
  ///
  /// In ko, this message translates to:
  /// **'선택 삭제'**
  String get deleteSelected;

  /// No description provided for @deleteSelectedConfirm.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 곡을 삭제할까요?\n기기에서 영구 삭제됩니다.'**
  String deleteSelectedConfirm(Object count);

  /// No description provided for @deletedCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 삭제됐습니다'**
  String deletedCount(Object count);

  /// No description provided for @noVideosFound.
  ///
  /// In ko, this message translates to:
  /// **'동영상이 없습니다'**
  String get noVideosFound;

  /// No description provided for @videoCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개'**
  String videoCount(Object count);

  /// No description provided for @rename.
  ///
  /// In ko, this message translates to:
  /// **'이름 변경'**
  String get rename;

  /// No description provided for @deleteVideoTitle.
  ///
  /// In ko, this message translates to:
  /// **'동영상 삭제'**
  String get deleteVideoTitle;

  /// No description provided for @deleteVideoConfirm.
  ///
  /// In ko, this message translates to:
  /// **'{name}을 삭제할까요?'**
  String deleteVideoConfirm(Object name);

  /// No description provided for @nameChanged.
  ///
  /// In ko, this message translates to:
  /// **'이름이 변경됐습니다'**
  String get nameChanged;

  /// No description provided for @renameFailed.
  ///
  /// In ko, this message translates to:
  /// **'이름 변경 실패: {error}'**
  String renameFailed(Object error);

  /// No description provided for @deleteFailedWithError.
  ///
  /// In ko, this message translates to:
  /// **'삭제 실패: {error}'**
  String deleteFailedWithError(Object error);

  /// No description provided for @videoPermissionRequired.
  ///
  /// In ko, this message translates to:
  /// **'동영상 접근 권한 필요'**
  String get videoPermissionRequired;

  /// No description provided for @videoPermissionMessage.
  ///
  /// In ko, this message translates to:
  /// **'동영상을 보려면\n접근 권한이 필요합니다.'**
  String get videoPermissionMessage;

  /// No description provided for @openSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정 열기'**
  String get openSettings;

  /// No description provided for @deleteSongConfirmFormat.
  ///
  /// In ko, this message translates to:
  /// **'{title}을(를) 삭제할까요?\n기기에서 영구 삭제됩니다.'**
  String deleteSongConfirmFormat(Object title);

  /// No description provided for @playTime.
  ///
  /// In ko, this message translates to:
  /// **'재생 시간'**
  String get playTime;

  /// No description provided for @path.
  ///
  /// In ko, this message translates to:
  /// **'경로'**
  String get path;

  /// No description provided for @newPlaylist.
  ///
  /// In ko, this message translates to:
  /// **'새 재생목록'**
  String get newPlaylist;

  /// No description provided for @playlistNameHint.
  ///
  /// In ko, this message translates to:
  /// **'재생목록 이름'**
  String get playlistNameHint;

  /// No description provided for @create.
  ///
  /// In ko, this message translates to:
  /// **'만들기'**
  String get create;

  /// No description provided for @playlistLabel.
  ///
  /// In ko, this message translates to:
  /// **'재생목록'**
  String get playlistLabel;

  /// No description provided for @renamePlaylistTitle.
  ///
  /// In ko, this message translates to:
  /// **'이름 변경'**
  String get renamePlaylistTitle;

  /// No description provided for @deletePlaylistTitle.
  ///
  /// In ko, this message translates to:
  /// **'재생목록 삭제'**
  String get deletePlaylistTitle;

  /// No description provided for @deletePlaylistConfirm.
  ///
  /// In ko, this message translates to:
  /// **'{name}을 삭제할까요?'**
  String deletePlaylistConfirm(Object name);

  /// No description provided for @change.
  ///
  /// In ko, this message translates to:
  /// **'변경'**
  String get change;

  /// No description provided for @songCountSuffix.
  ///
  /// In ko, this message translates to:
  /// **'곡'**
  String get songCountSuffix;

  /// No description provided for @lyrics.
  ///
  /// In ko, this message translates to:
  /// **'가사'**
  String get lyrics;

  /// No description provided for @lyricsLoading.
  ///
  /// In ko, this message translates to:
  /// **'가사를 불러오는 중...'**
  String get lyricsLoading;

  /// No description provided for @lyricsNotFound.
  ///
  /// In ko, this message translates to:
  /// **'가사를 찾을 수 없습니다'**
  String get lyricsNotFound;

  /// No description provided for @lyricsSearchPrompt.
  ///
  /// In ko, this message translates to:
  /// **'가사를 검색해보세요'**
  String get lyricsSearchPrompt;

  /// No description provided for @lyricsSearchButton.
  ///
  /// In ko, this message translates to:
  /// **'가사 검색'**
  String get lyricsSearchButton;

  /// No description provided for @lyricsErrorNotFound.
  ///
  /// In ko, this message translates to:
  /// **'가사를 찾을 수 없습니다'**
  String get lyricsErrorNotFound;

  /// No description provided for @lyricsErrorLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'가사 로딩 실패'**
  String get lyricsErrorLoadFailed;

  /// No description provided for @lyricsErrorNetwork.
  ///
  /// In ko, this message translates to:
  /// **'인터넷 연결을 확인해주세요'**
  String get lyricsErrorNetwork;

  /// No description provided for @justNow.
  ///
  /// In ko, this message translates to:
  /// **'방금 전'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분 전'**
  String minutesAgo(Object minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간 전'**
  String hoursAgo(Object hours);

  /// No description provided for @dateFormat.
  ///
  /// In ko, this message translates to:
  /// **'{year}년 {month}월 {day}일'**
  String dateFormat(Object day, Object month, Object year);

  /// No description provided for @deleteAllTooltip.
  ///
  /// In ko, this message translates to:
  /// **'전체 삭제'**
  String get deleteAllTooltip;

  /// No description provided for @radioTitle.
  ///
  /// In ko, this message translates to:
  /// **'라디오'**
  String get radioTitle;

  /// No description provided for @radioRecentListening.
  ///
  /// In ko, this message translates to:
  /// **'최근 청취'**
  String get radioRecentListening;

  /// No description provided for @radioSelectCountry.
  ///
  /// In ko, this message translates to:
  /// **'국가 선택'**
  String get radioSelectCountry;

  /// No description provided for @radioChannelCount.
  ///
  /// In ko, this message translates to:
  /// **'개 채널'**
  String get radioChannelCount;

  /// No description provided for @radioPopular200.
  ///
  /// In ko, this message translates to:
  /// **'인기 200개'**
  String get radioPopular200;

  /// No description provided for @radioSleep.
  ///
  /// In ko, this message translates to:
  /// **'수면'**
  String get radioSleep;

  /// No description provided for @radioSchedule.
  ///
  /// In ko, this message translates to:
  /// **'예약'**
  String get radioSchedule;

  /// No description provided for @sleepTimerDesc.
  ///
  /// In ko, this message translates to:
  /// **'선택한 시간 후 자동으로 꺼집니다'**
  String get sleepTimerDesc;

  /// No description provided for @sleepTimerActiveDesc.
  ///
  /// In ko, this message translates to:
  /// **'타이머가 작동 중입니다'**
  String get sleepTimerActiveDesc;

  /// No description provided for @remainingTime.
  ///
  /// In ko, this message translates to:
  /// **'남은 시간'**
  String get remainingTime;

  /// No description provided for @cancelTimerX.
  ///
  /// In ko, this message translates to:
  /// **'× 타이머 취소'**
  String get cancelTimerX;

  /// No description provided for @countryKR.
  ///
  /// In ko, this message translates to:
  /// **'한국'**
  String get countryKR;

  /// No description provided for @countryUS.
  ///
  /// In ko, this message translates to:
  /// **'미국'**
  String get countryUS;

  /// No description provided for @countryJP.
  ///
  /// In ko, this message translates to:
  /// **'일본'**
  String get countryJP;

  /// No description provided for @countryTW.
  ///
  /// In ko, this message translates to:
  /// **'대만'**
  String get countryTW;

  /// No description provided for @countryCN.
  ///
  /// In ko, this message translates to:
  /// **'중국'**
  String get countryCN;

  /// No description provided for @countryHK.
  ///
  /// In ko, this message translates to:
  /// **'홍콩'**
  String get countryHK;

  /// No description provided for @countryGB.
  ///
  /// In ko, this message translates to:
  /// **'영국'**
  String get countryGB;

  /// No description provided for @countryVN.
  ///
  /// In ko, this message translates to:
  /// **'베트남'**
  String get countryVN;

  /// No description provided for @categoryNational.
  ///
  /// In ko, this message translates to:
  /// **'전국'**
  String get categoryNational;

  /// No description provided for @categorySeoulGyeonggi.
  ///
  /// In ko, this message translates to:
  /// **'서울/경기'**
  String get categorySeoulGyeonggi;

  /// No description provided for @categoryRegionalMBC.
  ///
  /// In ko, this message translates to:
  /// **'지역 MBC'**
  String get categoryRegionalMBC;

  /// No description provided for @categoryRegionalPrivate.
  ///
  /// In ko, this message translates to:
  /// **'지역 민방'**
  String get categoryRegionalPrivate;

  /// No description provided for @categoryTraffic.
  ///
  /// In ko, this message translates to:
  /// **'교통방송'**
  String get categoryTraffic;

  /// No description provided for @categoryEtc.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get categoryEtc;
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
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
