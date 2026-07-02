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
  /// **'재생 중'**
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
  /// **'뮤직웨이브가 마음에 드시나요?'**
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

  /// No description provided for @countryPH.
  ///
  /// In ko, this message translates to:
  /// **'필리핀'**
  String get countryPH;

  /// No description provided for @countryDE.
  ///
  /// In ko, this message translates to:
  /// **'독일'**
  String get countryDE;

  /// No description provided for @countryFR.
  ///
  /// In ko, this message translates to:
  /// **'프랑스'**
  String get countryFR;

  /// No description provided for @countryTH.
  ///
  /// In ko, this message translates to:
  /// **'태국'**
  String get countryTH;

  /// No description provided for @countryID.
  ///
  /// In ko, this message translates to:
  /// **'인도네시아'**
  String get countryID;

  /// No description provided for @countryIN.
  ///
  /// In ko, this message translates to:
  /// **'인도'**
  String get countryIN;

  /// No description provided for @countryES.
  ///
  /// In ko, this message translates to:
  /// **'스페인'**
  String get countryES;

  /// No description provided for @countryIT.
  ///
  /// In ko, this message translates to:
  /// **'이탈리아'**
  String get countryIT;

  /// No description provided for @countryBR.
  ///
  /// In ko, this message translates to:
  /// **'브라질'**
  String get countryBR;

  /// No description provided for @countryCA.
  ///
  /// In ko, this message translates to:
  /// **'캐나다'**
  String get countryCA;

  /// No description provided for @countryAU.
  ///
  /// In ko, this message translates to:
  /// **'호주'**
  String get countryAU;

  /// No description provided for @countryMX.
  ///
  /// In ko, this message translates to:
  /// **'멕시코'**
  String get countryMX;

  /// No description provided for @countryTR.
  ///
  /// In ko, this message translates to:
  /// **'터키'**
  String get countryTR;

  /// No description provided for @countryNL.
  ///
  /// In ko, this message translates to:
  /// **'네덜란드'**
  String get countryNL;

  /// No description provided for @countrySE.
  ///
  /// In ko, this message translates to:
  /// **'스웨덴'**
  String get countrySE;

  /// No description provided for @countryPL.
  ///
  /// In ko, this message translates to:
  /// **'폴란드'**
  String get countryPL;

  /// No description provided for @countryAR.
  ///
  /// In ko, this message translates to:
  /// **'아르헨티나'**
  String get countryAR;

  /// No description provided for @countryCO.
  ///
  /// In ko, this message translates to:
  /// **'콜롬비아'**
  String get countryCO;

  /// No description provided for @countryNZ.
  ///
  /// In ko, this message translates to:
  /// **'뉴질랜드'**
  String get countryNZ;

  /// No description provided for @countryMY.
  ///
  /// In ko, this message translates to:
  /// **'말레이시아'**
  String get countryMY;

  /// No description provided for @countrySG.
  ///
  /// In ko, this message translates to:
  /// **'싱가포르'**
  String get countrySG;

  /// No description provided for @countryRU.
  ///
  /// In ko, this message translates to:
  /// **'러시아'**
  String get countryRU;

  /// No description provided for @countryZA.
  ///
  /// In ko, this message translates to:
  /// **'남아프리카'**
  String get countryZA;

  /// No description provided for @countryPK.
  ///
  /// In ko, this message translates to:
  /// **'파키스탄'**
  String get countryPK;

  /// No description provided for @countryBD.
  ///
  /// In ko, this message translates to:
  /// **'방글라데시'**
  String get countryBD;

  /// No description provided for @countryLK.
  ///
  /// In ko, this message translates to:
  /// **'스리랑카'**
  String get countryLK;

  /// No description provided for @countryNP.
  ///
  /// In ko, this message translates to:
  /// **'네팔'**
  String get countryNP;

  /// No description provided for @countryMM.
  ///
  /// In ko, this message translates to:
  /// **'미얀마'**
  String get countryMM;

  /// No description provided for @countryKH.
  ///
  /// In ko, this message translates to:
  /// **'캄보디아'**
  String get countryKH;

  /// No description provided for @countryAT.
  ///
  /// In ko, this message translates to:
  /// **'오스트리아'**
  String get countryAT;

  /// No description provided for @countryCH.
  ///
  /// In ko, this message translates to:
  /// **'스위스'**
  String get countryCH;

  /// No description provided for @countryBE.
  ///
  /// In ko, this message translates to:
  /// **'벨기에'**
  String get countryBE;

  /// No description provided for @countryPT.
  ///
  /// In ko, this message translates to:
  /// **'포르투갈'**
  String get countryPT;

  /// No description provided for @countryGR.
  ///
  /// In ko, this message translates to:
  /// **'그리스'**
  String get countryGR;

  /// No description provided for @countryIE.
  ///
  /// In ko, this message translates to:
  /// **'아일랜드'**
  String get countryIE;

  /// No description provided for @countryNO.
  ///
  /// In ko, this message translates to:
  /// **'노르웨이'**
  String get countryNO;

  /// No description provided for @countryDK.
  ///
  /// In ko, this message translates to:
  /// **'덴마크'**
  String get countryDK;

  /// No description provided for @countryFI.
  ///
  /// In ko, this message translates to:
  /// **'핀란드'**
  String get countryFI;

  /// No description provided for @countryCZ.
  ///
  /// In ko, this message translates to:
  /// **'체코'**
  String get countryCZ;

  /// No description provided for @countryRO.
  ///
  /// In ko, this message translates to:
  /// **'루마니아'**
  String get countryRO;

  /// No description provided for @countryUA.
  ///
  /// In ko, this message translates to:
  /// **'우크라이나'**
  String get countryUA;

  /// No description provided for @countryEG.
  ///
  /// In ko, this message translates to:
  /// **'이집트'**
  String get countryEG;

  /// No description provided for @countrySA.
  ///
  /// In ko, this message translates to:
  /// **'사우디아라비아'**
  String get countrySA;

  /// No description provided for @countryAE.
  ///
  /// In ko, this message translates to:
  /// **'UAE'**
  String get countryAE;

  /// No description provided for @countryNG.
  ///
  /// In ko, this message translates to:
  /// **'나이지리아'**
  String get countryNG;

  /// No description provided for @countryKE.
  ///
  /// In ko, this message translates to:
  /// **'케냐'**
  String get countryKE;

  /// No description provided for @countryCL.
  ///
  /// In ko, this message translates to:
  /// **'칠레'**
  String get countryCL;

  /// No description provided for @countryPE.
  ///
  /// In ko, this message translates to:
  /// **'페루'**
  String get countryPE;

  /// No description provided for @countryVE.
  ///
  /// In ko, this message translates to:
  /// **'베네수엘라'**
  String get countryVE;

  /// No description provided for @countryCU.
  ///
  /// In ko, this message translates to:
  /// **'쿠바'**
  String get countryCU;

  /// No description provided for @countryJM.
  ///
  /// In ko, this message translates to:
  /// **'자메이카'**
  String get countryJM;

  /// No description provided for @countryIQ.
  ///
  /// In ko, this message translates to:
  /// **'이라크'**
  String get countryIQ;

  /// No description provided for @countryIR.
  ///
  /// In ko, this message translates to:
  /// **'이란'**
  String get countryIR;

  /// No description provided for @countryIL.
  ///
  /// In ko, this message translates to:
  /// **'이스라엘'**
  String get countryIL;

  /// No description provided for @countryMN.
  ///
  /// In ko, this message translates to:
  /// **'몽골'**
  String get countryMN;

  /// No description provided for @countryUZ.
  ///
  /// In ko, this message translates to:
  /// **'우즈베키스탄'**
  String get countryUZ;

  /// No description provided for @countryKZ.
  ///
  /// In ko, this message translates to:
  /// **'카자흐스탄'**
  String get countryKZ;

  /// No description provided for @countryLA.
  ///
  /// In ko, this message translates to:
  /// **'라오스'**
  String get countryLA;

  /// No description provided for @countryHU.
  ///
  /// In ko, this message translates to:
  /// **'헝가리'**
  String get countryHU;

  /// No description provided for @countryHR.
  ///
  /// In ko, this message translates to:
  /// **'크로아티아'**
  String get countryHR;

  /// No description provided for @countryRS.
  ///
  /// In ko, this message translates to:
  /// **'세르비아'**
  String get countryRS;

  /// No description provided for @countryBG.
  ///
  /// In ko, this message translates to:
  /// **'불가리아'**
  String get countryBG;

  /// No description provided for @countrySK.
  ///
  /// In ko, this message translates to:
  /// **'슬로바키아'**
  String get countrySK;

  /// No description provided for @countryLT.
  ///
  /// In ko, this message translates to:
  /// **'리투아니아'**
  String get countryLT;

  /// No description provided for @countryLV.
  ///
  /// In ko, this message translates to:
  /// **'라트비아'**
  String get countryLV;

  /// No description provided for @countryEE.
  ///
  /// In ko, this message translates to:
  /// **'에스토니아'**
  String get countryEE;

  /// No description provided for @countryIS.
  ///
  /// In ko, this message translates to:
  /// **'아이슬란드'**
  String get countryIS;

  /// No description provided for @countryGH.
  ///
  /// In ko, this message translates to:
  /// **'가나'**
  String get countryGH;

  /// No description provided for @countryTZ.
  ///
  /// In ko, this message translates to:
  /// **'탄자니아'**
  String get countryTZ;

  /// No description provided for @countryMA.
  ///
  /// In ko, this message translates to:
  /// **'모로코'**
  String get countryMA;

  /// No description provided for @countryTN.
  ///
  /// In ko, this message translates to:
  /// **'튀니지'**
  String get countryTN;

  /// No description provided for @countryET.
  ///
  /// In ko, this message translates to:
  /// **'에티오피아'**
  String get countryET;

  /// No description provided for @countryUG.
  ///
  /// In ko, this message translates to:
  /// **'우간다'**
  String get countryUG;

  /// No description provided for @countryEC.
  ///
  /// In ko, this message translates to:
  /// **'에콰도르'**
  String get countryEC;

  /// No description provided for @countryBO.
  ///
  /// In ko, this message translates to:
  /// **'볼리비아'**
  String get countryBO;

  /// No description provided for @countryPY.
  ///
  /// In ko, this message translates to:
  /// **'파라과이'**
  String get countryPY;

  /// No description provided for @countryUY.
  ///
  /// In ko, this message translates to:
  /// **'우루과이'**
  String get countryUY;

  /// No description provided for @countryPA.
  ///
  /// In ko, this message translates to:
  /// **'파나마'**
  String get countryPA;

  /// No description provided for @countryCR.
  ///
  /// In ko, this message translates to:
  /// **'코스타리카'**
  String get countryCR;

  /// No description provided for @countryDO.
  ///
  /// In ko, this message translates to:
  /// **'도미니카공화국'**
  String get countryDO;

  /// No description provided for @countryTT.
  ///
  /// In ko, this message translates to:
  /// **'트리니다드토바고'**
  String get countryTT;

  /// No description provided for @countryHT.
  ///
  /// In ko, this message translates to:
  /// **'아이티'**
  String get countryHT;

  /// No description provided for @countryFJ.
  ///
  /// In ko, this message translates to:
  /// **'피지'**
  String get countryFJ;

  /// No description provided for @countryPG.
  ///
  /// In ko, this message translates to:
  /// **'파푸아뉴기니'**
  String get countryPG;

  /// No description provided for @countryJO.
  ///
  /// In ko, this message translates to:
  /// **'요르단'**
  String get countryJO;

  /// No description provided for @countryLB.
  ///
  /// In ko, this message translates to:
  /// **'레바논'**
  String get countryLB;

  /// No description provided for @countryGE.
  ///
  /// In ko, this message translates to:
  /// **'조지아'**
  String get countryGE;

  /// No description provided for @countryAM.
  ///
  /// In ko, this message translates to:
  /// **'아르메니아'**
  String get countryAM;

  /// No description provided for @countryAZ.
  ///
  /// In ko, this message translates to:
  /// **'아제르바이잔'**
  String get countryAZ;

  /// No description provided for @countrySI.
  ///
  /// In ko, this message translates to:
  /// **'슬로베니아'**
  String get countrySI;

  /// No description provided for @countryAL.
  ///
  /// In ko, this message translates to:
  /// **'알바니아'**
  String get countryAL;

  /// No description provided for @countryMK.
  ///
  /// In ko, this message translates to:
  /// **'북마케도니아'**
  String get countryMK;

  /// No description provided for @countryME.
  ///
  /// In ko, this message translates to:
  /// **'몬테네그로'**
  String get countryME;

  /// No description provided for @countryBA.
  ///
  /// In ko, this message translates to:
  /// **'보스니아'**
  String get countryBA;

  /// No description provided for @countryMT.
  ///
  /// In ko, this message translates to:
  /// **'몰타'**
  String get countryMT;

  /// No description provided for @countryLU.
  ///
  /// In ko, this message translates to:
  /// **'룩셈부르크'**
  String get countryLU;

  /// No description provided for @countryCY.
  ///
  /// In ko, this message translates to:
  /// **'키프로스'**
  String get countryCY;

  /// No description provided for @countryCM.
  ///
  /// In ko, this message translates to:
  /// **'카메룬'**
  String get countryCM;

  /// No description provided for @countrySN.
  ///
  /// In ko, this message translates to:
  /// **'세네갈'**
  String get countrySN;

  /// No description provided for @countryZW.
  ///
  /// In ko, this message translates to:
  /// **'짐바브웨'**
  String get countryZW;

  /// No description provided for @countryMZ.
  ///
  /// In ko, this message translates to:
  /// **'모잠비크'**
  String get countryMZ;

  /// No description provided for @countryMG.
  ///
  /// In ko, this message translates to:
  /// **'마다가스카르'**
  String get countryMG;

  /// No description provided for @countryGT.
  ///
  /// In ko, this message translates to:
  /// **'과테말라'**
  String get countryGT;

  /// No description provided for @countryHN.
  ///
  /// In ko, this message translates to:
  /// **'온두라스'**
  String get countryHN;

  /// No description provided for @countryNI.
  ///
  /// In ko, this message translates to:
  /// **'니카라과'**
  String get countryNI;

  /// No description provided for @countrySV.
  ///
  /// In ko, this message translates to:
  /// **'엘살바도르'**
  String get countrySV;

  /// No description provided for @countryPR.
  ///
  /// In ko, this message translates to:
  /// **'푸에르토리코'**
  String get countryPR;

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

  /// No description provided for @regionAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get regionAll;

  /// No description provided for @regionCapital.
  ///
  /// In ko, this message translates to:
  /// **'수도권'**
  String get regionCapital;

  /// No description provided for @regionBusanGyeongnam.
  ///
  /// In ko, this message translates to:
  /// **'부산/경남'**
  String get regionBusanGyeongnam;

  /// No description provided for @regionDaeguGyeongbuk.
  ///
  /// In ko, this message translates to:
  /// **'대구/경북'**
  String get regionDaeguGyeongbuk;

  /// No description provided for @regionGwangjuJeonnam.
  ///
  /// In ko, this message translates to:
  /// **'광주/전남'**
  String get regionGwangjuJeonnam;

  /// No description provided for @regionJeonbuk.
  ///
  /// In ko, this message translates to:
  /// **'전북'**
  String get regionJeonbuk;

  /// No description provided for @regionDaejeonChungnam.
  ///
  /// In ko, this message translates to:
  /// **'대전/충남'**
  String get regionDaejeonChungnam;

  /// No description provided for @regionChungbuk.
  ///
  /// In ko, this message translates to:
  /// **'충북'**
  String get regionChungbuk;

  /// No description provided for @regionGangwon.
  ///
  /// In ko, this message translates to:
  /// **'강원'**
  String get regionGangwon;

  /// No description provided for @regionJeju.
  ///
  /// In ko, this message translates to:
  /// **'제주'**
  String get regionJeju;

  /// No description provided for @radioNoFavorites.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기가 없습니다'**
  String get radioNoFavorites;

  /// No description provided for @radioNoFavoritesDesc.
  ///
  /// In ko, this message translates to:
  /// **'채널 목록에서 ♡를 눌러 추가해 보세요'**
  String get radioNoFavoritesDesc;

  /// No description provided for @radioRemovedFromFavorites.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기에서 제거했습니다'**
  String get radioRemovedFromFavorites;

  /// No description provided for @radioAddedToFavoritesToast.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기에 추가했습니다'**
  String get radioAddedToFavoritesToast;

  /// No description provided for @radioConnecting.
  ///
  /// In ko, this message translates to:
  /// **'접속 중...'**
  String get radioConnecting;

  /// No description provided for @radioPopularCount.
  ///
  /// In ko, this message translates to:
  /// **'인기 방송 {count}개'**
  String radioPopularCount(Object count);

  /// No description provided for @radioLoadingPopular.
  ///
  /// In ko, this message translates to:
  /// **'인기 방송을 불러오는 중...'**
  String get radioLoadingPopular;

  /// No description provided for @radioScheduleTitle.
  ///
  /// In ko, this message translates to:
  /// **'{station} 편성표'**
  String radioScheduleTitle(Object station);

  /// No description provided for @radioLoadingSchedule.
  ///
  /// In ko, this message translates to:
  /// **'편성표를 불러오는 중...'**
  String get radioLoadingSchedule;

  /// No description provided for @radioScheduleChannelSwitch.
  ///
  /// In ko, this message translates to:
  /// **'예약 채널 전환'**
  String get radioScheduleChannelSwitch;

  /// No description provided for @radioMaxSchedules.
  ///
  /// In ko, this message translates to:
  /// **'최대 5개 ({count}/5)'**
  String radioMaxSchedules(Object count);

  /// No description provided for @radioSelectTime.
  ///
  /// In ko, this message translates to:
  /// **'시간 선택'**
  String get radioSelectTime;

  /// No description provided for @radioSetSchedule.
  ///
  /// In ko, this message translates to:
  /// **'예약 설정'**
  String get radioSetSchedule;

  /// No description provided for @radioBroadcastSchedule.
  ///
  /// In ko, this message translates to:
  /// **'편성표'**
  String get radioBroadcastSchedule;

  /// No description provided for @radioPlayFirst.
  ///
  /// In ko, this message translates to:
  /// **'먼저 라디오를 재생해주세요'**
  String get radioPlayFirst;

  /// No description provided for @radioCancelAllSchedules.
  ///
  /// In ko, this message translates to:
  /// **'전체 예약 취소'**
  String get radioCancelAllSchedules;

  /// No description provided for @radioScheduleSetToast.
  ///
  /// In ko, this message translates to:
  /// **'예약이 설정되었습니다'**
  String get radioScheduleSetToast;

  /// No description provided for @radioScheduleCompleteToast.
  ///
  /// In ko, this message translates to:
  /// **'{title} {time} 예약 완료'**
  String radioScheduleCompleteToast(Object time, Object title);

  /// No description provided for @radioPlaybackFailed.
  ///
  /// In ko, this message translates to:
  /// **'재생에 실패했습니다.'**
  String get radioPlaybackFailed;

  /// No description provided for @radioRerun.
  ///
  /// In ko, this message translates to:
  /// **'재방송'**
  String get radioRerun;

  /// No description provided for @radioLive.
  ///
  /// In ko, this message translates to:
  /// **'● LIVE'**
  String get radioLive;

  /// No description provided for @radioStatusConnecting.
  ///
  /// In ko, this message translates to:
  /// **'접속 중...'**
  String get radioStatusConnecting;

  /// No description provided for @radioStatusFailed.
  ///
  /// In ko, this message translates to:
  /// **'연결 실패'**
  String get radioStatusFailed;

  /// No description provided for @radioStatusPaused.
  ///
  /// In ko, this message translates to:
  /// **'일시정지'**
  String get radioStatusPaused;

  /// No description provided for @radioAfterEnd.
  ///
  /// In ko, this message translates to:
  /// **'후 종료'**
  String get radioAfterEnd;

  /// No description provided for @radioNoStationsFound.
  ///
  /// In ko, this message translates to:
  /// **'방송을 찾을 수 없습니다'**
  String get radioNoStationsFound;

  /// No description provided for @sleepMin.
  ///
  /// In ko, this message translates to:
  /// **'분'**
  String get sleepMin;

  /// No description provided for @sleepHour.
  ///
  /// In ko, this message translates to:
  /// **'시간'**
  String get sleepHour;

  /// No description provided for @sleepMinuteUnit.
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분'**
  String sleepMinuteUnit(Object minutes);

  /// No description provided for @sleepHourUnit.
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간'**
  String sleepHourUnit(Object hours);

  /// No description provided for @sleepHourMinuteUnit.
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간 {minutes}분'**
  String sleepHourMinuteUnit(Object hours, Object minutes);

  /// No description provided for @sleepCountdownHMS.
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간 {minutes}분 {seconds}초'**
  String sleepCountdownHMS(Object hours, Object minutes, Object seconds);

  /// No description provided for @sleepCountdownMS.
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분 {seconds}초'**
  String sleepCountdownMS(Object minutes, Object seconds);

  /// No description provided for @sleepCountdownS.
  ///
  /// In ko, this message translates to:
  /// **'{seconds}초'**
  String sleepCountdownS(Object seconds);

  /// No description provided for @sleepAutoStopToast.
  ///
  /// In ko, this message translates to:
  /// **'{time} 후 자동으로 꺼집니다'**
  String sleepAutoStopToast(Object time);

  /// No description provided for @radioKoreaTitle.
  ///
  /// In ko, this message translates to:
  /// **'\"세상의 소리를 담다\"'**
  String get radioKoreaTitle;

  /// No description provided for @radioOnAirTitle.
  ///
  /// In ko, this message translates to:
  /// **'ON AIR'**
  String get radioOnAirTitle;

  /// No description provided for @radioKoreaSlogan.
  ///
  /// In ko, this message translates to:
  /// **'세상의 소리를 담다'**
  String get radioKoreaSlogan;

  /// No description provided for @radioSloganUS.
  ///
  /// In ko, this message translates to:
  /// **'자유의 목소리를 듣다'**
  String get radioSloganUS;

  /// No description provided for @radioSloganJP.
  ///
  /// In ko, this message translates to:
  /// **'일상 속 작은 위로'**
  String get radioSloganJP;

  /// No description provided for @radioSloganTW.
  ///
  /// In ko, this message translates to:
  /// **'섬을 흐르는 노래'**
  String get radioSloganTW;

  /// No description provided for @radioSloganCN.
  ///
  /// In ko, this message translates to:
  /// **'광활한 대륙의 소리'**
  String get radioSloganCN;

  /// No description provided for @radioSloganHK.
  ///
  /// In ko, this message translates to:
  /// **'도시의 리듬을 타다'**
  String get radioSloganHK;

  /// No description provided for @radioSloganGB.
  ///
  /// In ko, this message translates to:
  /// **'전통과 현재가 만나는 곳'**
  String get radioSloganGB;

  /// No description provided for @radioSloganVN.
  ///
  /// In ko, this message translates to:
  /// **'메콩강의 선율'**
  String get radioSloganVN;

  /// No description provided for @radioSloganPH.
  ///
  /// In ko, this message translates to:
  /// **'섬들의 울림'**
  String get radioSloganPH;

  /// No description provided for @radioSloganDE.
  ///
  /// In ko, this message translates to:
  /// **'유럽 심장부의 소리'**
  String get radioSloganDE;

  /// No description provided for @radioSloganFR.
  ///
  /// In ko, this message translates to:
  /// **'삶의 멜로디'**
  String get radioSloganFR;

  /// No description provided for @radioSloganTH.
  ///
  /// In ko, this message translates to:
  /// **'시암의 소리'**
  String get radioSloganTH;

  /// No description provided for @radioSloganID.
  ///
  /// In ko, this message translates to:
  /// **'군도의 리듬'**
  String get radioSloganID;

  /// No description provided for @radioSloganIN.
  ///
  /// In ko, this message translates to:
  /// **'인도의 선율'**
  String get radioSloganIN;

  /// No description provided for @radioSloganES.
  ///
  /// In ko, this message translates to:
  /// **'영혼의 리듬'**
  String get radioSloganES;

  /// No description provided for @radioSloganIT.
  ///
  /// In ko, this message translates to:
  /// **'삶의 음악'**
  String get radioSloganIT;

  /// No description provided for @radioSloganBR.
  ///
  /// In ko, this message translates to:
  /// **'브라질의 소리'**
  String get radioSloganBR;

  /// No description provided for @radioSloganCA.
  ///
  /// In ko, this message translates to:
  /// **'북쪽을 가로지르는 목소리'**
  String get radioSloganCA;

  /// No description provided for @radioSloganAU.
  ///
  /// In ko, this message translates to:
  /// **'남반구의 소리'**
  String get radioSloganAU;

  /// No description provided for @radioSloganMX.
  ///
  /// In ko, this message translates to:
  /// **'멕시코의 리듬'**
  String get radioSloganMX;

  /// No description provided for @radioSloganTR.
  ///
  /// In ko, this message translates to:
  /// **'아나톨리아의 소리'**
  String get radioSloganTR;

  /// No description provided for @radioSloganNL.
  ///
  /// In ko, this message translates to:
  /// **'저지대의 울림'**
  String get radioSloganNL;

  /// No description provided for @radioSloganSE.
  ///
  /// In ko, this message translates to:
  /// **'북유럽의 소리'**
  String get radioSloganSE;

  /// No description provided for @radioSloganPL.
  ///
  /// In ko, this message translates to:
  /// **'비스와강의 선율'**
  String get radioSloganPL;

  /// No description provided for @radioSloganAR.
  ///
  /// In ko, this message translates to:
  /// **'영혼의 탱고'**
  String get radioSloganAR;

  /// No description provided for @radioSloganCO.
  ///
  /// In ko, this message translates to:
  /// **'콜롬비아의 리듬'**
  String get radioSloganCO;

  /// No description provided for @radioSloganNZ.
  ///
  /// In ko, this message translates to:
  /// **'아오테아로아의 메아리'**
  String get radioSloganNZ;

  /// No description provided for @radioSloganMY.
  ///
  /// In ko, this message translates to:
  /// **'말레이시아의 리듬'**
  String get radioSloganMY;

  /// No description provided for @radioSloganSG.
  ///
  /// In ko, this message translates to:
  /// **'사자의 도시 바이브'**
  String get radioSloganSG;

  /// No description provided for @radioSloganRU.
  ///
  /// In ko, this message translates to:
  /// **'러시아의 소리'**
  String get radioSloganRU;

  /// No description provided for @radioSloganZA.
  ///
  /// In ko, this message translates to:
  /// **'무지개 나라의 소리'**
  String get radioSloganZA;

  /// No description provided for @radioSloganPK.
  ///
  /// In ko, this message translates to:
  /// **'파키스탄의 선율'**
  String get radioSloganPK;

  /// No description provided for @radioSloganBD.
  ///
  /// In ko, this message translates to:
  /// **'벵골의 소리'**
  String get radioSloganBD;

  /// No description provided for @radioSloganLK.
  ///
  /// In ko, this message translates to:
  /// **'스리랑카의 소리'**
  String get radioSloganLK;

  /// No description provided for @radioSloganNP.
  ///
  /// In ko, this message translates to:
  /// **'히말라야의 선율'**
  String get radioSloganNP;

  /// No description provided for @radioSloganMM.
  ///
  /// In ko, this message translates to:
  /// **'미얀마의 소리'**
  String get radioSloganMM;

  /// No description provided for @radioSloganKH.
  ///
  /// In ko, this message translates to:
  /// **'앙코르의 소리'**
  String get radioSloganKH;

  /// No description provided for @radioSloganAT.
  ///
  /// In ko, this message translates to:
  /// **'알프스의 울림'**
  String get radioSloganAT;

  /// No description provided for @radioSloganCH.
  ///
  /// In ko, this message translates to:
  /// **'스위스의 목소리'**
  String get radioSloganCH;

  /// No description provided for @radioSloganBE.
  ///
  /// In ko, this message translates to:
  /// **'벨기에의 울림'**
  String get radioSloganBE;

  /// No description provided for @radioSloganPT.
  ///
  /// In ko, this message translates to:
  /// **'포르투갈의 소리'**
  String get radioSloganPT;

  /// No description provided for @radioSloganGR.
  ///
  /// In ko, this message translates to:
  /// **'그리스의 소리'**
  String get radioSloganGR;

  /// No description provided for @radioSloganIE.
  ///
  /// In ko, this message translates to:
  /// **'에메랄드 섬의 소리'**
  String get radioSloganIE;

  /// No description provided for @radioSloganNO.
  ///
  /// In ko, this message translates to:
  /// **'피오르의 소리'**
  String get radioSloganNO;

  /// No description provided for @radioSloganDK.
  ///
  /// In ko, this message translates to:
  /// **'덴마크의 소리'**
  String get radioSloganDK;

  /// No description provided for @radioSloganFI.
  ///
  /// In ko, this message translates to:
  /// **'핀란드의 소리'**
  String get radioSloganFI;

  /// No description provided for @radioSloganCZ.
  ///
  /// In ko, this message translates to:
  /// **'체코의 소리'**
  String get radioSloganCZ;

  /// No description provided for @radioSloganRO.
  ///
  /// In ko, this message translates to:
  /// **'루마니아의 소리'**
  String get radioSloganRO;

  /// No description provided for @radioSloganUA.
  ///
  /// In ko, this message translates to:
  /// **'우크라이나의 소리'**
  String get radioSloganUA;

  /// No description provided for @radioSloganEG.
  ///
  /// In ko, this message translates to:
  /// **'나일강의 소리'**
  String get radioSloganEG;

  /// No description provided for @radioSloganSA.
  ///
  /// In ko, this message translates to:
  /// **'아라비아의 소리'**
  String get radioSloganSA;

  /// No description provided for @radioSloganAE.
  ///
  /// In ko, this message translates to:
  /// **'걸프의 소리'**
  String get radioSloganAE;

  /// No description provided for @radioSloganNG.
  ///
  /// In ko, this message translates to:
  /// **'나이지리아의 소리'**
  String get radioSloganNG;

  /// No description provided for @radioSloganKE.
  ///
  /// In ko, this message translates to:
  /// **'케냐의 소리'**
  String get radioSloganKE;

  /// No description provided for @radioSloganCL.
  ///
  /// In ko, this message translates to:
  /// **'칠레의 소리'**
  String get radioSloganCL;

  /// No description provided for @radioSloganPE.
  ///
  /// In ko, this message translates to:
  /// **'페루의 소리'**
  String get radioSloganPE;

  /// No description provided for @radioSloganVE.
  ///
  /// In ko, this message translates to:
  /// **'베네수엘라의 리듬'**
  String get radioSloganVE;

  /// No description provided for @radioSloganCU.
  ///
  /// In ko, this message translates to:
  /// **'쿠바의 리듬'**
  String get radioSloganCU;

  /// No description provided for @radioSloganJM.
  ///
  /// In ko, this message translates to:
  /// **'자메이카의 리듬'**
  String get radioSloganJM;

  /// No description provided for @radioSloganIQ.
  ///
  /// In ko, this message translates to:
  /// **'메소포타미아의 소리'**
  String get radioSloganIQ;

  /// No description provided for @radioSloganIR.
  ///
  /// In ko, this message translates to:
  /// **'이란의 선율'**
  String get radioSloganIR;

  /// No description provided for @radioSloganIL.
  ///
  /// In ko, this message translates to:
  /// **'이스라엘의 소리'**
  String get radioSloganIL;

  /// No description provided for @radioSloganMN.
  ///
  /// In ko, this message translates to:
  /// **'몽골 초원의 선율'**
  String get radioSloganMN;

  /// No description provided for @radioSloganUZ.
  ///
  /// In ko, this message translates to:
  /// **'우즈베키스탄의 소리'**
  String get radioSloganUZ;

  /// No description provided for @radioSloganKZ.
  ///
  /// In ko, this message translates to:
  /// **'카자흐스탄의 소리'**
  String get radioSloganKZ;

  /// No description provided for @radioSloganLA.
  ///
  /// In ko, this message translates to:
  /// **'라오스의 소리'**
  String get radioSloganLA;

  /// No description provided for @radioSloganHU.
  ///
  /// In ko, this message translates to:
  /// **'도나우의 소리'**
  String get radioSloganHU;

  /// No description provided for @radioSloganHR.
  ///
  /// In ko, this message translates to:
  /// **'아드리아해의 소리'**
  String get radioSloganHR;

  /// No description provided for @radioSloganRS.
  ///
  /// In ko, this message translates to:
  /// **'세르비아의 소리'**
  String get radioSloganRS;

  /// No description provided for @radioSloganBG.
  ///
  /// In ko, this message translates to:
  /// **'불가리아의 소리'**
  String get radioSloganBG;

  /// No description provided for @radioSloganSK.
  ///
  /// In ko, this message translates to:
  /// **'슬로바키아의 소리'**
  String get radioSloganSK;

  /// No description provided for @radioSloganLT.
  ///
  /// In ko, this message translates to:
  /// **'리투아니아의 소리'**
  String get radioSloganLT;

  /// No description provided for @radioSloganLV.
  ///
  /// In ko, this message translates to:
  /// **'라트비아의 소리'**
  String get radioSloganLV;

  /// No description provided for @radioSloganEE.
  ///
  /// In ko, this message translates to:
  /// **'에스토니아의 소리'**
  String get radioSloganEE;

  /// No description provided for @radioSloganIS.
  ///
  /// In ko, this message translates to:
  /// **'아이슬란드의 소리'**
  String get radioSloganIS;

  /// No description provided for @radioSloganGH.
  ///
  /// In ko, this message translates to:
  /// **'가나의 소리'**
  String get radioSloganGH;

  /// No description provided for @radioSloganTZ.
  ///
  /// In ko, this message translates to:
  /// **'탄자니아의 소리'**
  String get radioSloganTZ;

  /// No description provided for @radioSloganMA.
  ///
  /// In ko, this message translates to:
  /// **'모로코의 소리'**
  String get radioSloganMA;

  /// No description provided for @radioSloganTN.
  ///
  /// In ko, this message translates to:
  /// **'튀니지의 소리'**
  String get radioSloganTN;

  /// No description provided for @radioSloganET.
  ///
  /// In ko, this message translates to:
  /// **'에티오피아의 소리'**
  String get radioSloganET;

  /// No description provided for @radioSloganUG.
  ///
  /// In ko, this message translates to:
  /// **'우간다의 소리'**
  String get radioSloganUG;

  /// No description provided for @radioSloganEC.
  ///
  /// In ko, this message translates to:
  /// **'에콰도르의 소리'**
  String get radioSloganEC;

  /// No description provided for @radioSloganBO.
  ///
  /// In ko, this message translates to:
  /// **'볼리비아의 소리'**
  String get radioSloganBO;

  /// No description provided for @radioSloganPY.
  ///
  /// In ko, this message translates to:
  /// **'파라과이의 소리'**
  String get radioSloganPY;

  /// No description provided for @radioSloganUY.
  ///
  /// In ko, this message translates to:
  /// **'우루과이의 소리'**
  String get radioSloganUY;

  /// No description provided for @radioSloganPA.
  ///
  /// In ko, this message translates to:
  /// **'파나마의 소리'**
  String get radioSloganPA;

  /// No description provided for @radioSloganCR.
  ///
  /// In ko, this message translates to:
  /// **'코스타리카의 소리'**
  String get radioSloganCR;

  /// No description provided for @radioSloganDO.
  ///
  /// In ko, this message translates to:
  /// **'도미니카의 리듬'**
  String get radioSloganDO;

  /// No description provided for @radioSloganTT.
  ///
  /// In ko, this message translates to:
  /// **'트리니다드의 소리'**
  String get radioSloganTT;

  /// No description provided for @radioSloganHT.
  ///
  /// In ko, this message translates to:
  /// **'아이티의 소리'**
  String get radioSloganHT;

  /// No description provided for @selectSong.
  ///
  /// In ko, this message translates to:
  /// **'곡 선택'**
  String get selectSong;

  /// No description provided for @selectRange.
  ///
  /// In ko, this message translates to:
  /// **'구간 선택'**
  String get selectRange;

  /// No description provided for @start.
  ///
  /// In ko, this message translates to:
  /// **'시작'**
  String get start;

  /// No description provided for @end.
  ///
  /// In ko, this message translates to:
  /// **'끝'**
  String get end;

  /// No description provided for @rangeFormat.
  ///
  /// In ko, this message translates to:
  /// **'구간: {start} ~ {end} ({seconds}초)'**
  String rangeFormat(Object end, Object seconds, Object start);

  /// No description provided for @deselectAll.
  ///
  /// In ko, this message translates to:
  /// **'선택 해제'**
  String get deselectAll;

  /// No description provided for @exit.
  ///
  /// In ko, this message translates to:
  /// **'종료'**
  String get exit;

  /// No description provided for @timerLabel.
  ///
  /// In ko, this message translates to:
  /// **'타이머'**
  String get timerLabel;

  /// No description provided for @playbackSpeedLabel.
  ///
  /// In ko, this message translates to:
  /// **'재생속도'**
  String get playbackSpeedLabel;
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
