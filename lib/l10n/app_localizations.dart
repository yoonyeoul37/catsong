import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_th.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_vi.dart';
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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('pl'),
    Locale('pt'),
    Locale('ru'),
    Locale('th'),
    Locale('tr'),
    Locale('vi'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// No description provided for @appName.
  ///
  /// In ko, this message translates to:
  /// **'파란소리'**
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

  /// No description provided for @textSize.
  ///
  /// In ko, this message translates to:
  /// **'글자 크기'**
  String get textSize;

  /// No description provided for @fontChange.
  ///
  /// In ko, this message translates to:
  /// **'글꼴 변경'**
  String get fontChange;

  /// No description provided for @playerStyle.
  ///
  /// In ko, this message translates to:
  /// **'재생 화면 스타일'**
  String get playerStyle;

  /// No description provided for @flashlight.
  ///
  /// In ko, this message translates to:
  /// **'손전등'**
  String get flashlight;

  /// No description provided for @sos.
  ///
  /// In ko, this message translates to:
  /// **'SOS 긴급 신호'**
  String get sos;

  /// No description provided for @ringtone.
  ///
  /// In ko, this message translates to:
  /// **'벨소리 설정'**
  String get ringtone;

  /// No description provided for @widget.
  ///
  /// In ko, this message translates to:
  /// **'홈 화면 위젯'**
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

  /// No description provided for @ringtoneFailed.
  ///
  /// In ko, this message translates to:
  /// **'벨소리 설정에 실패했습니다'**
  String get ringtoneFailed;

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
  /// **'파란소리가 마음에 드시나요?'**
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

  /// No description provided for @styleCard.
  ///
  /// In ko, this message translates to:
  /// **'앨범아트 카드'**
  String get styleCard;

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

  /// No description provided for @noVideosFound.
  ///
  /// In ko, this message translates to:
  /// **'동영상이 없습니다'**
  String get noVideosFound;

  /// No description provided for @rename.
  ///
  /// In ko, this message translates to:
  /// **'이름 변경'**
  String get rename;

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

  /// No description provided for @lyricsErrorNotFound.
  ///
  /// In ko, this message translates to:
  /// **'가사를 찾을 수 없습니다'**
  String get lyricsErrorNotFound;

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

  /// No description provided for @updateReadyTitle.
  ///
  /// In ko, this message translates to:
  /// **'업데이트 준비 완료'**
  String get updateReadyTitle;

  /// No description provided for @updateReadyMessage.
  ///
  /// In ko, this message translates to:
  /// **'새로운 기능이 다운로드됐어요.\n지금 재시작을 권장합니다.'**
  String get updateReadyMessage;

  /// No description provided for @updateReadyButton.
  ///
  /// In ko, this message translates to:
  /// **'지금 재시작'**
  String get updateReadyButton;

  /// No description provided for @updateReadyLater.
  ///
  /// In ko, this message translates to:
  /// **'나중에'**
  String get updateReadyLater;

  /// No description provided for @radioNextProgram.
  ///
  /// In ko, this message translates to:
  /// **'다음 방송'**
  String get radioNextProgram;

  /// No description provided for @radioExitConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'라디오를 종료하시겠어요?'**
  String get radioExitConfirmTitle;

  /// No description provided for @radioExitConfirmMessage.
  ///
  /// In ko, this message translates to:
  /// **'다음에 또 좋은 소리로 만나요.'**
  String get radioExitConfirmMessage;

  /// No description provided for @radioExitKeepListening.
  ///
  /// In ko, this message translates to:
  /// **'계속 듣기'**
  String get radioExitKeepListening;

  /// No description provided for @radioExitConfirmButton.
  ///
  /// In ko, this message translates to:
  /// **'종료'**
  String get radioExitConfirmButton;

  /// No description provided for @darkMode.
  ///
  /// In ko, this message translates to:
  /// **'다크 모드'**
  String get darkMode;

  /// No description provided for @darkModeOn.
  ///
  /// In ko, this message translates to:
  /// **'켜짐'**
  String get darkModeOn;

  /// No description provided for @darkModeOff.
  ///
  /// In ko, this message translates to:
  /// **'꺼짐'**
  String get darkModeOff;

  /// No description provided for @rateApp.
  ///
  /// In ko, this message translates to:
  /// **'앱 평가하기'**
  String get rateApp;

  /// No description provided for @musicExitConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'음악을 종료하시겠어요?'**
  String get musicExitConfirmTitle;

  /// No description provided for @musicExitConfirmMessage.
  ///
  /// In ko, this message translates to:
  /// **'다음에 또 좋은 소리로 만나요.'**
  String get musicExitConfirmMessage;

  /// No description provided for @homeNewSongs.
  ///
  /// In ko, this message translates to:
  /// **'새로 들어온 곡'**
  String get homeNewSongs;

  /// No description provided for @homeTipWidgetTitle.
  ///
  /// In ko, this message translates to:
  /// **'바탕화면 위젯을 놓아 보세요'**
  String get homeTipWidgetTitle;

  /// No description provided for @homeTipWidgetSub.
  ///
  /// In ko, this message translates to:
  /// **'바탕화면을 꾹 → 위젯 → 파란소리'**
  String get homeTipWidgetSub;

  /// No description provided for @homeTipAlarmTitle.
  ///
  /// In ko, this message translates to:
  /// **'아침 알람으로 깨워 드려요'**
  String get homeTipAlarmTitle;

  /// No description provided for @homeTipAlarmSub.
  ///
  /// In ko, this message translates to:
  /// **'음악·라디오·자연 소리로 일어나요'**
  String get homeTipAlarmSub;

  /// No description provided for @homeTipScheduleTitle.
  ///
  /// In ko, this message translates to:
  /// **'원하는 시간에 라디오 켜기'**
  String get homeTipScheduleTitle;

  /// No description provided for @homeTipScheduleSub.
  ///
  /// In ko, this message translates to:
  /// **'라디오 재생 화면 아래 [예약]'**
  String get homeTipScheduleSub;

  /// No description provided for @homeTipCastTitle.
  ///
  /// In ko, this message translates to:
  /// **'TV·스피커로 소리 보내기'**
  String get homeTipCastTitle;

  /// No description provided for @homeTipCastSub.
  ///
  /// In ko, this message translates to:
  /// **'같은 Wi-Fi라면 재생 화면 ⋮ 메뉴에서'**
  String get homeTipCastSub;

  /// No description provided for @homeTipSleepTitle.
  ///
  /// In ko, this message translates to:
  /// **'잠들 땐 수면 타이머'**
  String get homeTipSleepTitle;

  /// No description provided for @homeTipSleepSub.
  ///
  /// In ko, this message translates to:
  /// **'재생 화면 아래 [수면]을 눌러요'**
  String get homeTipSleepSub;

  /// No description provided for @homeTodayTip.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 팁'**
  String get homeTodayTip;

  /// No description provided for @accentColor.
  ///
  /// In ko, this message translates to:
  /// **'강조 색상'**
  String get accentColor;

  /// No description provided for @homeColorTitle.
  ///
  /// In ko, this message translates to:
  /// **'나만의 색으로 꾸며보세요'**
  String get homeColorTitle;

  /// No description provided for @homeColorSub.
  ///
  /// In ko, this message translates to:
  /// **'숲 · 노을 · 벚꽃 등 10가지 색'**
  String get homeColorSub;

  /// No description provided for @homeColorAction.
  ///
  /// In ko, this message translates to:
  /// **'꾸미기'**
  String get homeColorAction;

  /// No description provided for @homeColorQuestion.
  ///
  /// In ko, this message translates to:
  /// **'오늘 기분에 어울리는 색은?'**
  String get homeColorQuestion;

  /// No description provided for @homeColorHint.
  ///
  /// In ko, this message translates to:
  /// **'설정 → 꾸미기 → 강조 색상에서\n다시 변경할 수 있습니다.'**
  String get homeColorHint;

  /// No description provided for @done.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get done;

  /// No description provided for @homeStartTitle.
  ///
  /// In ko, this message translates to:
  /// **'앱 시작 화면으로 설정할까요?'**
  String get homeStartTitle;

  /// No description provided for @homeStartMessage.
  ///
  /// In ko, this message translates to:
  /// **'파란소리를 실행할 때 이 화면을 가장 먼저 보여드려요.'**
  String get homeStartMessage;

  /// No description provided for @homeStartConfirm.
  ///
  /// In ko, this message translates to:
  /// **'설정하기'**
  String get homeStartConfirm;

  /// No description provided for @deleteSongsTitle.
  ///
  /// In ko, this message translates to:
  /// **'{count}곡을 삭제할까요?'**
  String deleteSongsTitle(int count);

  /// No description provided for @deleteSongsMessage.
  ///
  /// In ko, this message translates to:
  /// **'선택한 곡이 폰에서 지워져요'**
  String get deleteSongsMessage;

  /// No description provided for @deletedSongsToast.
  ///
  /// In ko, this message translates to:
  /// **'{count}곡을 삭제했어요'**
  String deletedSongsToast(int count);

  /// No description provided for @couldNotDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제하지 못했어요'**
  String get couldNotDelete;

  /// No description provided for @menuShareTitle.
  ///
  /// In ko, this message translates to:
  /// **'친구에게 공유하기'**
  String get menuShareTitle;

  /// No description provided for @menuShareSub.
  ///
  /// In ko, this message translates to:
  /// **'파란소리를 친구에게\n소개해보세요.'**
  String get menuShareSub;

  /// No description provided for @shareAppMessage.
  ///
  /// In ko, this message translates to:
  /// **'파란소리 앱으로 음악 들어요! 🎧'**
  String get shareAppMessage;

  /// No description provided for @menuRateTitle.
  ///
  /// In ko, this message translates to:
  /// **'앱 평가하기'**
  String get menuRateTitle;

  /// No description provided for @menuRateSub.
  ///
  /// In ko, this message translates to:
  /// **'좋은 평가가\n큰 힘이 됩니다.'**
  String get menuRateSub;

  /// No description provided for @menuSettingsSub.
  ///
  /// In ko, this message translates to:
  /// **'앱 환경을\n설정할 수 있어요.'**
  String get menuSettingsSub;

  /// No description provided for @menuRadioTitle.
  ///
  /// In ko, this message translates to:
  /// **'방송국 바로가기'**
  String get menuRadioTitle;

  /// No description provided for @menuRadioSub.
  ///
  /// In ko, this message translates to:
  /// **'다양한 라디오 방송을\n바로 들어보세요.'**
  String get menuRadioSub;

  /// No description provided for @recentSearches.
  ///
  /// In ko, this message translates to:
  /// **'최근 검색'**
  String get recentSearches;

  /// No description provided for @clearAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 지우기'**
  String get clearAll;

  /// No description provided for @catMusic.
  ///
  /// In ko, this message translates to:
  /// **'음악'**
  String get catMusic;

  /// No description provided for @catMusicSub.
  ///
  /// In ko, this message translates to:
  /// **'내 음악 · MP3 플레이어'**
  String get catMusicSub;

  /// No description provided for @catRadio.
  ///
  /// In ko, this message translates to:
  /// **'라디오'**
  String get catRadio;

  /// No description provided for @catRadioSub.
  ///
  /// In ko, this message translates to:
  /// **'국내외 라디오 · 즐겨찾기'**
  String get catRadioSub;

  /// No description provided for @catNature.
  ///
  /// In ko, this message translates to:
  /// **'자연'**
  String get catNature;

  /// No description provided for @catNatureSub.
  ///
  /// In ko, this message translates to:
  /// **'비 · 바람 · 숲 · 파도'**
  String get catNatureSub;

  /// No description provided for @catRest.
  ///
  /// In ko, this message translates to:
  /// **'휴식 · 집중'**
  String get catRest;

  /// No description provided for @catRestSub.
  ///
  /// In ko, this message translates to:
  /// **'백색소음 · 집중 소리 (준비중)'**
  String get catRestSub;

  /// No description provided for @homeSoundsHeader.
  ///
  /// In ko, this message translates to:
  /// **'이런 소리는 어때요?'**
  String get homeSoundsHeader;

  /// No description provided for @homeRestHeader.
  ///
  /// In ko, this message translates to:
  /// **'잠시 쉬어가요'**
  String get homeRestHeader;

  /// No description provided for @homeRecentHeader.
  ///
  /// In ko, this message translates to:
  /// **'최근에 들었어요'**
  String get homeRecentHeader;

  /// No description provided for @homeRecentEmpty.
  ///
  /// In ko, this message translates to:
  /// **'최근 들은 곡이 없어요'**
  String get homeRecentEmpty;

  /// No description provided for @homeRecentEmptySub.
  ///
  /// In ko, this message translates to:
  /// **'30초 이상 들은 곡·라디오·자연이 여기에 모여요'**
  String get homeRecentEmptySub;

  /// No description provided for @cleanLabel.
  ///
  /// In ko, this message translates to:
  /// **'곡 정리'**
  String get cleanLabel;

  /// No description provided for @cleanTitle.
  ///
  /// In ko, this message translates to:
  /// **'곡 제목 {count}개를 깔끔하게'**
  String cleanTitle(int count);

  /// No description provided for @later.
  ///
  /// In ko, this message translates to:
  /// **'나중에'**
  String get later;

  /// No description provided for @cleanAction.
  ///
  /// In ko, this message translates to:
  /// **'정리하기'**
  String get cleanAction;

  /// No description provided for @dailyOftenMorning.
  ///
  /// In ko, this message translates to:
  /// **'아침에 자주 듣던 곡'**
  String get dailyOftenMorning;

  /// No description provided for @dailyOftenDay.
  ///
  /// In ko, this message translates to:
  /// **'낮에 자주 듣던 곡'**
  String get dailyOftenDay;

  /// No description provided for @dailyOftenEvening.
  ///
  /// In ko, this message translates to:
  /// **'저녁에 자주 듣던 곡'**
  String get dailyOftenEvening;

  /// No description provided for @dailyOftenNight.
  ///
  /// In ko, this message translates to:
  /// **'밤에 자주 듣던 곡'**
  String get dailyOftenNight;

  /// No description provided for @dailyLongTime.
  ///
  /// In ko, this message translates to:
  /// **'오랜만에 듣는 곡'**
  String get dailyLongTime;

  /// No description provided for @dailySongOfDay.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 곡'**
  String get dailySongOfDay;

  /// No description provided for @dailyHowAboutThis.
  ///
  /// In ko, this message translates to:
  /// **'오늘은 이 곡 어때요'**
  String get dailyHowAboutThis;

  /// No description provided for @listen.
  ///
  /// In ko, this message translates to:
  /// **'듣기'**
  String get listen;

  /// No description provided for @dailyListenAgain.
  ///
  /// In ko, this message translates to:
  /// **'다시 듣기'**
  String get dailyListenAgain;

  /// No description provided for @dailyNotPlayedTitle.
  ///
  /// In ko, this message translates to:
  /// **'한 달 동안 안 들은 곡 {count}개'**
  String dailyNotPlayedTitle(int count);

  /// No description provided for @dailyNotPlayedSub.
  ///
  /// In ko, this message translates to:
  /// **'오랜만에 다시 들어볼까요'**
  String get dailyNotPlayedSub;

  /// No description provided for @dailyShufflePlay.
  ///
  /// In ko, this message translates to:
  /// **'틀기'**
  String get dailyShufflePlay;

  /// No description provided for @dailyMyStats.
  ///
  /// In ko, this message translates to:
  /// **'내 기록'**
  String get dailyMyStats;

  /// No description provided for @dailyWeekCount.
  ///
  /// In ko, this message translates to:
  /// **'최근 7일 동안 {count}번 들었어요'**
  String dailyWeekCount(int count);

  /// No description provided for @dailyMostPlayed.
  ///
  /// In ko, this message translates to:
  /// **'가장 많이 들은 곡'**
  String get dailyMostPlayed;

  /// No description provided for @dailyMorningTitle.
  ///
  /// In ko, this message translates to:
  /// **'상쾌한 아침이에요'**
  String get dailyMorningTitle;

  /// No description provided for @dailyMorningLine.
  ///
  /// In ko, this message translates to:
  /// **'새소리로 하루를 시작해요'**
  String get dailyMorningLine;

  /// No description provided for @dailyDayTitle.
  ///
  /// In ko, this message translates to:
  /// **'잠깐 쉬어가요'**
  String get dailyDayTitle;

  /// No description provided for @dailyDayLine.
  ///
  /// In ko, this message translates to:
  /// **'시냇물 소리 들으며 한숨 돌려요'**
  String get dailyDayLine;

  /// No description provided for @dailyEveningTitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘도 수고했어요'**
  String get dailyEveningTitle;

  /// No description provided for @dailyEveningLine.
  ///
  /// In ko, this message translates to:
  /// **'파도소리 틀어놓고 쉬어요'**
  String get dailyEveningLine;

  /// No description provided for @dailyNightTitle.
  ///
  /// In ko, this message translates to:
  /// **'늦은 밤엔 잔잔하게'**
  String get dailyNightTitle;

  /// No description provided for @dailyNightLine.
  ///
  /// In ko, this message translates to:
  /// **'빗소리 틀어놓고 쉬어요'**
  String get dailyNightLine;

  /// No description provided for @dailyRightNow.
  ///
  /// In ko, this message translates to:
  /// **'지금 이 시간'**
  String get dailyRightNow;

  /// No description provided for @dailyTipBatteryTitle.
  ///
  /// In ko, this message translates to:
  /// **'화면 꺼도 계속 들어요'**
  String get dailyTipBatteryTitle;

  /// No description provided for @dailyTipBatterySub.
  ///
  /// In ko, this message translates to:
  /// **'배터리를 \'제한 없음\'으로 바꿔 주세요'**
  String get dailyTipBatterySub;

  /// No description provided for @dailyTipRingtoneTitle.
  ///
  /// In ko, this message translates to:
  /// **'노래로 벨소리 만들기'**
  String get dailyTipRingtoneTitle;

  /// No description provided for @dailyTipRingtoneSub.
  ///
  /// In ko, this message translates to:
  /// **'곡 ⋮ 메뉴에서 바로 만들어요'**
  String get dailyTipRingtoneSub;

  /// No description provided for @dailyTipVideoTitle.
  ///
  /// In ko, this message translates to:
  /// **'동영상 노래만 저장'**
  String get dailyTipVideoTitle;

  /// No description provided for @dailyTipVideoSub.
  ///
  /// In ko, this message translates to:
  /// **'동영상 ⋮ 메뉴에서 \'음악으로 저장\''**
  String get dailyTipVideoSub;

  /// No description provided for @dailyTipMixTitle.
  ///
  /// In ko, this message translates to:
  /// **'음악에 빗소리 더하기'**
  String get dailyTipMixTitle;

  /// No description provided for @dailyTipMixSub.
  ///
  /// In ko, this message translates to:
  /// **'재생 화면 ⋮ 메뉴 → 자연 소리 믹스'**
  String get dailyTipMixSub;

  /// No description provided for @dailyTipLyricsTitle.
  ///
  /// In ko, this message translates to:
  /// **'가사 한 줄 공유'**
  String get dailyTipLyricsTitle;

  /// No description provided for @dailyTipLyricsSub.
  ///
  /// In ko, this message translates to:
  /// **'가사를 꾹 누르면 카드로 보내요'**
  String get dailyTipLyricsSub;

  /// No description provided for @dailyOffTitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 카드를 끌까요?'**
  String get dailyOffTitle;

  /// No description provided for @dailyOffMessage.
  ///
  /// In ko, this message translates to:
  /// **'설정 → 홈 추천 카드에서 언제든 다시 켤 수 있어요'**
  String get dailyOffMessage;

  /// No description provided for @turnOff.
  ///
  /// In ko, this message translates to:
  /// **'끄기'**
  String get turnOff;

  /// No description provided for @dailyOffKeep.
  ///
  /// In ko, this message translates to:
  /// **'계속 볼래요'**
  String get dailyOffKeep;

  /// No description provided for @callRecordingsChip.
  ///
  /// In ko, this message translates to:
  /// **'통화녹음 ›'**
  String get callRecordingsChip;

  /// No description provided for @sortedByArtist.
  ///
  /// In ko, this message translates to:
  /// **'가수 이름순으로 정렬했어요'**
  String get sortedByArtist;

  /// No description provided for @sortedByTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목순으로 정렬했어요'**
  String get sortedByTitle;

  /// No description provided for @sortArtist.
  ///
  /// In ko, this message translates to:
  /// **'가수'**
  String get sortArtist;

  /// No description provided for @sortTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get sortTitle;

  /// No description provided for @today.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In ko, this message translates to:
  /// **'어제'**
  String get yesterday;

  /// No description provided for @within3Days.
  ///
  /// In ko, this message translates to:
  /// **'3일 안'**
  String get within3Days;

  /// No description provided for @withinWeek.
  ///
  /// In ko, this message translates to:
  /// **'일주일 안'**
  String get withinWeek;

  /// No description provided for @colorParansori.
  ///
  /// In ko, this message translates to:
  /// **'파란소리'**
  String get colorParansori;

  /// No description provided for @colorForest.
  ///
  /// In ko, this message translates to:
  /// **'숲'**
  String get colorForest;

  /// No description provided for @colorSunset.
  ///
  /// In ko, this message translates to:
  /// **'노을'**
  String get colorSunset;

  /// No description provided for @colorLavender.
  ///
  /// In ko, this message translates to:
  /// **'라벤더'**
  String get colorLavender;

  /// No description provided for @colorInk.
  ///
  /// In ko, this message translates to:
  /// **'먹색'**
  String get colorInk;

  /// No description provided for @colorBlossom.
  ///
  /// In ko, this message translates to:
  /// **'벚꽃'**
  String get colorBlossom;

  /// No description provided for @colorOcean.
  ///
  /// In ko, this message translates to:
  /// **'바다'**
  String get colorOcean;

  /// No description provided for @colorSunlight.
  ///
  /// In ko, this message translates to:
  /// **'햇살'**
  String get colorSunlight;

  /// No description provided for @colorWine.
  ///
  /// In ko, this message translates to:
  /// **'와인'**
  String get colorWine;

  /// No description provided for @colorNightSky.
  ///
  /// In ko, this message translates to:
  /// **'밤하늘'**
  String get colorNightSky;

  /// No description provided for @songsCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}곡'**
  String songsCount(int count);

  /// No description provided for @undoHint.
  ///
  /// In ko, this message translates to:
  /// **'마음에 안 들면 원래대로 돌릴 수 있어요'**
  String get undoHint;

  /// No description provided for @undo.
  ///
  /// In ko, this message translates to:
  /// **'원래대로'**
  String get undo;

  /// No description provided for @ok.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get ok;

  /// No description provided for @fbEdited.
  ///
  /// In ko, this message translates to:
  /// **'수정했어요'**
  String get fbEdited;

  /// No description provided for @fbDeleted.
  ///
  /// In ko, this message translates to:
  /// **'삭제했어요'**
  String get fbDeleted;

  /// No description provided for @fbSaved.
  ///
  /// In ko, this message translates to:
  /// **'저장했어요'**
  String get fbSaved;

  /// No description provided for @fbAdded.
  ///
  /// In ko, this message translates to:
  /// **'추가했어요'**
  String get fbAdded;

  /// No description provided for @fbCanceled.
  ///
  /// In ko, this message translates to:
  /// **'취소했어요'**
  String get fbCanceled;

  /// No description provided for @exitConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'종료하시겠어요?'**
  String get exitConfirmTitle;

  /// No description provided for @playCountHint.
  ///
  /// In ko, this message translates to:
  /// **'30초 이상 들은 횟수예요'**
  String get playCountHint;

  /// No description provided for @editInfo.
  ///
  /// In ko, this message translates to:
  /// **'정보 수정'**
  String get editInfo;

  /// No description provided for @addedCheck.
  ///
  /// In ko, this message translates to:
  /// **'추가됨 ✓'**
  String get addedCheck;

  /// No description provided for @trimAudio.
  ///
  /// In ko, this message translates to:
  /// **'오디오 자르기'**
  String get trimAudio;

  /// No description provided for @fileInfo.
  ///
  /// In ko, this message translates to:
  /// **'파일 정보'**
  String get fileInfo;

  /// No description provided for @deleteSongTitle.
  ///
  /// In ko, this message translates to:
  /// **'이 곡을 삭제할까요?'**
  String get deleteSongTitle;

  /// No description provided for @deleteSongMessage.
  ///
  /// In ko, this message translates to:
  /// **'\'{title}\'이(가) 폰에서 지워져요'**
  String deleteSongMessage(String title);

  /// No description provided for @moreShareSub.
  ///
  /// In ko, this message translates to:
  /// **'파란소리를 소개해보세요.'**
  String get moreShareSub;

  /// No description provided for @moreCleanTitle.
  ///
  /// In ko, this message translates to:
  /// **'음악 정보 일괄 정리'**
  String get moreCleanTitle;

  /// No description provided for @moreCleanSub.
  ///
  /// In ko, this message translates to:
  /// **'지저분한 제목·가수를 깔끔하게 정리해요.'**
  String get moreCleanSub;

  /// No description provided for @moreArtTitle.
  ///
  /// In ko, this message translates to:
  /// **'앨범 사진 자동 찾기'**
  String get moreArtTitle;

  /// No description provided for @moreArtSub.
  ///
  /// In ko, this message translates to:
  /// **'앨범 사진 없는 곡에 사진을 넣어요.'**
  String get moreArtSub;

  /// No description provided for @moreAlarmTitle.
  ///
  /// In ko, this message translates to:
  /// **'아침 알람'**
  String get moreAlarmTitle;

  /// No description provided for @moreAlarmSub.
  ///
  /// In ko, this message translates to:
  /// **'좋아하는 노래·라디오·자연으로 깨워 드려요'**
  String get moreAlarmSub;

  /// No description provided for @moreRateSub.
  ///
  /// In ko, this message translates to:
  /// **'좋은 평가가 큰 힘이 됩니다.'**
  String get moreRateSub;

  /// No description provided for @moreSettingsSub.
  ///
  /// In ko, this message translates to:
  /// **'앱 환경을 설정해요.'**
  String get moreSettingsSub;

  /// No description provided for @moreHelpTitle.
  ///
  /// In ko, this message translates to:
  /// **'설정 도움말'**
  String get moreHelpTitle;

  /// No description provided for @moreHelpSub.
  ///
  /// In ko, this message translates to:
  /// **'권한·배터리·알림 설정 방법을 알려드려요.'**
  String get moreHelpSub;

  /// No description provided for @moreHomepageTitle.
  ///
  /// In ko, this message translates to:
  /// **'방송국 홈페이지'**
  String get moreHomepageTitle;

  /// No description provided for @moreHomepageSub.
  ///
  /// In ko, this message translates to:
  /// **'공식 홈페이지로 이동해요.'**
  String get moreHomepageSub;

  /// No description provided for @brandLine1.
  ///
  /// In ko, this message translates to:
  /// **'오늘도 파란소리와 함께'**
  String get brandLine1;

  /// No description provided for @brandLine2.
  ///
  /// In ko, this message translates to:
  /// **'당신의 하루에 편안한 소리를 더합니다.'**
  String get brandLine2;

  /// No description provided for @addToPlaylist.
  ///
  /// In ko, this message translates to:
  /// **'재생목록에 추가'**
  String get addToPlaylist;

  /// No description provided for @newPlaylistCreate.
  ///
  /// In ko, this message translates to:
  /// **'새 재생목록 만들기'**
  String get newPlaylistCreate;

  /// No description provided for @newPlaylist.
  ///
  /// In ko, this message translates to:
  /// **'새 재생목록'**
  String get newPlaylist;

  /// No description provided for @playlistHintExample.
  ///
  /// In ko, this message translates to:
  /// **'예) 드라이브할 때'**
  String get playlistHintExample;

  /// No description provided for @createAndAdd.
  ///
  /// In ko, this message translates to:
  /// **'만들고 추가'**
  String get createAndAdd;

  /// No description provided for @addedToPlaylist.
  ///
  /// In ko, this message translates to:
  /// **'재생목록에 추가했어요'**
  String get addedToPlaylist;

  /// No description provided for @playlistCreated.
  ///
  /// In ko, this message translates to:
  /// **'재생목록을 만들었어요'**
  String get playlistCreated;

  /// No description provided for @renamePlaylist.
  ///
  /// In ko, this message translates to:
  /// **'재생목록 이름 바꾸기'**
  String get renamePlaylist;

  /// No description provided for @renameAction.
  ///
  /// In ko, this message translates to:
  /// **'바꾸기'**
  String get renameAction;

  /// No description provided for @renamed.
  ///
  /// In ko, this message translates to:
  /// **'이름을 바꿨어요'**
  String get renamed;

  /// No description provided for @deletePlaylistTitle.
  ///
  /// In ko, this message translates to:
  /// **'재생목록을 삭제할까요?'**
  String get deletePlaylistTitle;

  /// No description provided for @deletePlaylistMessage.
  ///
  /// In ko, this message translates to:
  /// **'\'{name}\' 재생목록이 지워져요 (노래 파일은 그대로예요)'**
  String deletePlaylistMessage(String name);

  /// No description provided for @clearAction.
  ///
  /// In ko, this message translates to:
  /// **'지우기'**
  String get clearAction;

  /// No description provided for @historyCleared.
  ///
  /// In ko, this message translates to:
  /// **'기록을 지웠어요'**
  String get historyCleared;

  /// No description provided for @castPlayingOn.
  ///
  /// In ko, this message translates to:
  /// **'{device}에서 재생'**
  String castPlayingOn(String device);

  /// No description provided for @storagePermissionNeeded.
  ///
  /// In ko, this message translates to:
  /// **'저장소 접근 권한이 필요합니다.\n설정에서 권한을 허용해 주세요.'**
  String get storagePermissionNeeded;

  /// No description provided for @musicLoadError.
  ///
  /// In ko, this message translates to:
  /// **'음악을 불러오는 중 오류가 발생했습니다'**
  String get musicLoadError;

  /// No description provided for @musicScanError.
  ///
  /// In ko, this message translates to:
  /// **'음악 스캔 오류'**
  String get musicScanError;

  /// No description provided for @sleepAskDuration.
  ///
  /// In ko, this message translates to:
  /// **'몇 시간 몇 분 후 정지할까요?'**
  String get sleepAskDuration;

  /// No description provided for @sleepFadeHint.
  ///
  /// In ko, this message translates to:
  /// **'끝나기 1분 전부터 천천히 작아져요'**
  String get sleepFadeHint;

  /// No description provided for @paranPhoto.
  ///
  /// In ko, this message translates to:
  /// **'파란포토'**
  String get paranPhoto;

  /// No description provided for @paranPhotoSwitched.
  ///
  /// In ko, this message translates to:
  /// **'파란포토로 바꿨어요'**
  String get paranPhotoSwitched;

  /// No description provided for @backToAlbum.
  ///
  /// In ko, this message translates to:
  /// **'앨범으로 되돌리기'**
  String get backToAlbum;

  /// No description provided for @backToCd.
  ///
  /// In ko, this message translates to:
  /// **'시디롬으로 되돌리기'**
  String get backToCd;

  /// No description provided for @paranSuggestTitle.
  ///
  /// In ko, this message translates to:
  /// **'파란포토로 들어볼까요?'**
  String get paranSuggestTitle;

  /// No description provided for @paranSuggestSub.
  ///
  /// In ko, this message translates to:
  /// **'예쁜 사진 위로 음악이 흘러요'**
  String get paranSuggestSub;

  /// No description provided for @noThanks.
  ///
  /// In ko, this message translates to:
  /// **'괜찮아요'**
  String get noThanks;

  /// No description provided for @takeALook.
  ///
  /// In ko, this message translates to:
  /// **'구경하기'**
  String get takeALook;

  /// No description provided for @photoHearts.
  ///
  /// In ko, this message translates to:
  /// **'하트'**
  String get photoHearts;

  /// No description provided for @myPhotos.
  ///
  /// In ko, this message translates to:
  /// **'내 사진'**
  String get myPhotos;

  /// No description provided for @pickedPhotos.
  ///
  /// In ko, this message translates to:
  /// **'고른 사진'**
  String get pickedPhotos;

  /// No description provided for @paranPhotoSub.
  ///
  /// In ko, this message translates to:
  /// **'나만의 재생 화면 꾸미기'**
  String get paranPhotoSub;

  /// No description provided for @addPhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진 추가'**
  String get addPhoto;

  /// No description provided for @portraitBest.
  ///
  /// In ko, this message translates to:
  /// **'세로형 사진을 추천해요'**
  String get portraitBest;

  /// No description provided for @photoRandom.
  ///
  /// In ko, this message translates to:
  /// **'랜덤'**
  String get photoRandom;

  /// No description provided for @photoFixed.
  ///
  /// In ko, this message translates to:
  /// **'고정'**
  String get photoFixed;

  /// No description provided for @photoRandomSub.
  ///
  /// In ko, this message translates to:
  /// **'곡이 바뀌면 배경도 바뀝니다.'**
  String get photoRandomSub;

  /// No description provided for @photoFixedSub.
  ///
  /// In ko, this message translates to:
  /// **'배경 사진이 고정됩니다.'**
  String get photoFixedSub;

  /// No description provided for @manage.
  ///
  /// In ko, this message translates to:
  /// **'관리'**
  String get manage;

  /// No description provided for @comingSoon.
  ///
  /// In ko, this message translates to:
  /// **'준비 중이에요'**
  String get comingSoon;

  /// No description provided for @toneColor.
  ///
  /// In ko, this message translates to:
  /// **'컬러'**
  String get toneColor;

  /// No description provided for @toneBw.
  ///
  /// In ko, this message translates to:
  /// **'흑백'**
  String get toneBw;

  /// No description provided for @toneSepia.
  ///
  /// In ko, this message translates to:
  /// **'세피아'**
  String get toneSepia;

  /// No description provided for @toneFilm.
  ///
  /// In ko, this message translates to:
  /// **'필름'**
  String get toneFilm;

  /// No description provided for @landscapeHint.
  ///
  /// In ko, this message translates to:
  /// **'가로 사진은 가운데 부분만 보여요. 세로로 찍은 사진이 가장 잘 어울려요'**
  String get landscapeHint;

  /// No description provided for @photo.
  ///
  /// In ko, this message translates to:
  /// **'사진'**
  String get photo;

  /// No description provided for @castPlayingNow.
  ///
  /// In ko, this message translates to:
  /// **'{device}에서 재생 중'**
  String castPlayingNow(String device);

  /// No description provided for @listenOnTv.
  ///
  /// In ko, this message translates to:
  /// **'TV로 듣기'**
  String get listenOnTv;

  /// No description provided for @shufflePlay.
  ///
  /// In ko, this message translates to:
  /// **'랜덤 재생'**
  String get shufflePlay;

  /// No description provided for @repeatPlay.
  ///
  /// In ko, this message translates to:
  /// **'반복 재생'**
  String get repeatPlay;

  /// No description provided for @playerScreen.
  ///
  /// In ko, this message translates to:
  /// **'재생 화면'**
  String get playerScreen;

  /// No description provided for @viewLyrics.
  ///
  /// In ko, this message translates to:
  /// **'가사 보기'**
  String get viewLyrics;

  /// No description provided for @natureMix.
  ///
  /// In ko, this message translates to:
  /// **'자연 소리 믹스'**
  String get natureMix;

  /// No description provided for @repeatOffChip.
  ///
  /// In ko, this message translates to:
  /// **'끔'**
  String get repeatOffChip;

  /// No description provided for @repeatOneChip.
  ///
  /// In ko, this message translates to:
  /// **'한 곡'**
  String get repeatOneChip;

  /// No description provided for @sleepStopInMin.
  ///
  /// In ko, this message translates to:
  /// **'{m}분 후 중지'**
  String sleepStopInMin(int m);

  /// No description provided for @sleepStopInHour.
  ///
  /// In ko, this message translates to:
  /// **'{h}시간 후 중지'**
  String sleepStopInHour(int h);

  /// No description provided for @sleepStopInHourMin.
  ///
  /// In ko, this message translates to:
  /// **'{h}시간 {m}분 후 중지'**
  String sleepStopInHourMin(int h, int m);

  /// No description provided for @albumArt.
  ///
  /// In ko, this message translates to:
  /// **'앨범 사진'**
  String get albumArt;

  /// No description provided for @connected.
  ///
  /// In ko, this message translates to:
  /// **'연결됨'**
  String get connected;

  /// No description provided for @recommended.
  ///
  /// In ko, this message translates to:
  /// **'추천'**
  String get recommended;

  /// No description provided for @printBasic.
  ///
  /// In ko, this message translates to:
  /// **'기본'**
  String get printBasic;

  /// No description provided for @printPolaroid.
  ///
  /// In ko, this message translates to:
  /// **'폴라로이드'**
  String get printPolaroid;

  /// No description provided for @printTape.
  ///
  /// In ko, this message translates to:
  /// **'테이프'**
  String get printTape;

  /// No description provided for @printStacked.
  ///
  /// In ko, this message translates to:
  /// **'겹친 사진'**
  String get printStacked;

  /// No description provided for @printRounded.
  ///
  /// In ko, this message translates to:
  /// **'둥근 테두리'**
  String get printRounded;

  /// No description provided for @lyricsCardHint.
  ///
  /// In ko, this message translates to:
  /// **'가사를 꾹 누르면 카드로 만들어 공유할 수 있어요'**
  String get lyricsCardHint;

  /// No description provided for @lyricsNeededForCard.
  ///
  /// In ko, this message translates to:
  /// **'가사가 있어야 카드를 만들 수 있어요'**
  String get lyricsNeededForCard;

  /// No description provided for @lyricsTextSize.
  ///
  /// In ko, this message translates to:
  /// **'가사 글자 크기'**
  String get lyricsTextSize;

  /// No description provided for @sizeMedium.
  ///
  /// In ko, this message translates to:
  /// **'보통'**
  String get sizeMedium;

  /// No description provided for @textSample.
  ///
  /// In ko, this message translates to:
  /// **'가'**
  String get textSample;

  /// No description provided for @lyricsSyncTitle.
  ///
  /// In ko, this message translates to:
  /// **'가사 박자 맞추기'**
  String get lyricsSyncTitle;

  /// No description provided for @secondsValue.
  ///
  /// In ko, this message translates to:
  /// **'{value}초'**
  String secondsValue(String value);

  /// No description provided for @nowLabel.
  ///
  /// In ko, this message translates to:
  /// **'지금'**
  String get nowLabel;

  /// No description provided for @notAdjusted.
  ///
  /// In ko, this message translates to:
  /// **'맞춘 적 없음'**
  String get notAdjusted;

  /// No description provided for @lyricsEarlier.
  ///
  /// In ko, this message translates to:
  /// **'가사를 빨리 (+0.5초)'**
  String get lyricsEarlier;

  /// No description provided for @lyricsLater.
  ///
  /// In ko, this message translates to:
  /// **'가사를 늦게 (−0.5초)'**
  String get lyricsLater;

  /// No description provided for @revert.
  ///
  /// In ko, this message translates to:
  /// **'원래대로'**
  String get revert;

  /// No description provided for @lyricsEdit.
  ///
  /// In ko, this message translates to:
  /// **'가사 직접 고치기'**
  String get lyricsEdit;

  /// No description provided for @lyricsAdd.
  ///
  /// In ko, this message translates to:
  /// **'가사 직접 넣기'**
  String get lyricsAdd;

  /// No description provided for @lyricsPasteHint.
  ///
  /// In ko, this message translates to:
  /// **'가사를 붙여넣어 주세요\n[00:12.34] 처럼 시간이 있으면 노래에 맞춰 나와요'**
  String get lyricsPasteHint;

  /// No description provided for @paste.
  ///
  /// In ko, this message translates to:
  /// **'붙여넣기'**
  String get paste;

  /// No description provided for @clearText.
  ///
  /// In ko, this message translates to:
  /// **'비우기'**
  String get clearText;

  /// No description provided for @lyricsSaved.
  ///
  /// In ko, this message translates to:
  /// **'이 노래 가사로 저장했어요'**
  String get lyricsSaved;

  /// No description provided for @lyricsDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'직접 넣은 가사를 지울까요?'**
  String get lyricsDeleteTitle;

  /// No description provided for @lyricsDeleteMessage.
  ///
  /// In ko, this message translates to:
  /// **'지우면 인터넷에서 다시 찾아요'**
  String get lyricsDeleteMessage;

  /// No description provided for @lyricsBg.
  ///
  /// In ko, this message translates to:
  /// **'가사 배경'**
  String get lyricsBg;

  /// No description provided for @lyricsBgSub.
  ///
  /// In ko, this message translates to:
  /// **'나만의 가사 화면 꾸미기'**
  String get lyricsBgSub;

  /// No description provided for @noPhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진 없이'**
  String get noPhoto;

  /// No description provided for @paransoriPhotos.
  ///
  /// In ko, this message translates to:
  /// **'파란소리 사진'**
  String get paransoriPhotos;

  /// No description provided for @lyricsSyncShort.
  ///
  /// In ko, this message translates to:
  /// **'박자 맞추기'**
  String get lyricsSyncShort;

  /// No description provided for @lyricsRefetch.
  ///
  /// In ko, this message translates to:
  /// **'가사 다시 찾기'**
  String get lyricsRefetch;

  /// No description provided for @lyricsDeleteMine.
  ///
  /// In ko, this message translates to:
  /// **'직접 넣은 가사 지우기'**
  String get lyricsDeleteMine;

  /// No description provided for @linesSelected.
  ///
  /// In ko, this message translates to:
  /// **'{count}줄 골랐어요'**
  String linesSelected(int count);

  /// No description provided for @linesSelectHint.
  ///
  /// In ko, this message translates to:
  /// **'다른 줄을 누르면 거기까지 · 최대 5줄'**
  String get linesSelectHint;

  /// No description provided for @makeCard.
  ///
  /// In ko, this message translates to:
  /// **'카드 만들기'**
  String get makeCard;

  /// No description provided for @checkInternet.
  ///
  /// In ko, this message translates to:
  /// **'인터넷 연결을 확인해 주세요'**
  String get checkInternet;

  /// No description provided for @lyricsNotFoundYet.
  ///
  /// In ko, this message translates to:
  /// **'이 노래 가사를 아직 못 찾았어요'**
  String get lyricsNotFoundYet;

  /// No description provided for @retryWhenOnline.
  ///
  /// In ko, this message translates to:
  /// **'연결되면 다시 찾아볼 수 있어요'**
  String get retryWhenOnline;

  /// No description provided for @lyricsNotFoundSub.
  ///
  /// In ko, this message translates to:
  /// **'다시 찾거나, 가사를 직접 넣을 수 있어요'**
  String get lyricsNotFoundSub;

  /// No description provided for @searchAgain.
  ///
  /// In ko, this message translates to:
  /// **'다시 찾기'**
  String get searchAgain;

  /// No description provided for @addManually.
  ///
  /// In ko, this message translates to:
  /// **'직접 넣기'**
  String get addManually;

  /// No description provided for @editText.
  ///
  /// In ko, this message translates to:
  /// **'글자 고치기'**
  String get editText;

  /// No description provided for @enterNewLine.
  ///
  /// In ko, this message translates to:
  /// **'엔터로 줄을 바꿀 수 있어요'**
  String get enterNewLine;

  /// No description provided for @fontClean.
  ///
  /// In ko, this message translates to:
  /// **'깔끔'**
  String get fontClean;

  /// No description provided for @fontLetter.
  ///
  /// In ko, this message translates to:
  /// **'편지'**
  String get fontLetter;

  /// No description provided for @fontHand.
  ///
  /// In ko, this message translates to:
  /// **'손글씨'**
  String get fontHand;

  /// No description provided for @fontCute.
  ///
  /// In ko, this message translates to:
  /// **'귀여움'**
  String get fontCute;

  /// No description provided for @ratioStory.
  ///
  /// In ko, this message translates to:
  /// **'스토리 9:16'**
  String get ratioStory;

  /// No description provided for @ratioFeed.
  ///
  /// In ko, this message translates to:
  /// **'피드 1:1'**
  String get ratioFeed;

  /// No description provided for @cardMakeFailed.
  ///
  /// In ko, this message translates to:
  /// **'카드를 만들지 못했어요. 다시 해주세요.'**
  String get cardMakeFailed;

  /// No description provided for @photoLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'사진을 불러오지 못했어요'**
  String get photoLoadFailed;

  /// No description provided for @lyricsCard.
  ///
  /// In ko, this message translates to:
  /// **'가사 카드'**
  String get lyricsCard;

  /// No description provided for @lyricsCardSelectHint.
  ///
  /// In ko, this message translates to:
  /// **'가사를 길게 눌러 여러 줄을 선택하세요'**
  String get lyricsCardSelectHint;

  /// No description provided for @tabBackdrop.
  ///
  /// In ko, this message translates to:
  /// **'배경'**
  String get tabBackdrop;

  /// No description provided for @tabFont.
  ///
  /// In ko, this message translates to:
  /// **'글꼴'**
  String get tabFont;

  /// No description provided for @tabRatio.
  ///
  /// In ko, this message translates to:
  /// **'비율'**
  String get tabRatio;

  /// No description provided for @tabTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get tabTitle;

  /// No description provided for @tabText.
  ///
  /// In ko, this message translates to:
  /// **'글자'**
  String get tabText;

  /// No description provided for @fontSample.
  ///
  /// In ko, this message translates to:
  /// **'가나다'**
  String get fontSample;

  /// No description provided for @alignCenter.
  ///
  /// In ko, this message translates to:
  /// **'가운데'**
  String get alignCenter;

  /// No description provided for @alignLeft.
  ///
  /// In ko, this message translates to:
  /// **'왼쪽'**
  String get alignLeft;

  /// No description provided for @posTop.
  ///
  /// In ko, this message translates to:
  /// **'위'**
  String get posTop;

  /// No description provided for @posBottom.
  ///
  /// In ko, this message translates to:
  /// **'아래'**
  String get posBottom;

  /// No description provided for @posHide.
  ///
  /// In ko, this message translates to:
  /// **'숨기기'**
  String get posHide;

  /// No description provided for @colorChip.
  ///
  /// In ko, this message translates to:
  /// **'색'**
  String get colorChip;

  /// No description provided for @makingCard.
  ///
  /// In ko, this message translates to:
  /// **'카드 만드는 중…'**
  String get makingCard;

  /// No description provided for @shareAction.
  ///
  /// In ko, this message translates to:
  /// **'공유하기'**
  String get shareAction;

  /// No description provided for @songNotFoundOnline.
  ///
  /// In ko, this message translates to:
  /// **'인터넷에서 이 곡을 찾지 못했어요'**
  String get songNotFoundOnline;

  /// No description provided for @isThisTheSong.
  ///
  /// In ko, this message translates to:
  /// **'이 곡이 맞나요?'**
  String get isThisTheSong;

  /// No description provided for @pickSongHint.
  ///
  /// In ko, this message translates to:
  /// **'찾는 곡을 선택하면 제목·가수·앨범·앨범 사진이 채워져요'**
  String get pickSongHint;

  /// No description provided for @noMatchingSong.
  ///
  /// In ko, this message translates to:
  /// **'찾는 곡이 없어요'**
  String get noMatchingSong;

  /// No description provided for @searching.
  ///
  /// In ko, this message translates to:
  /// **'찾는 중…'**
  String get searching;

  /// No description provided for @findInfoOnline.
  ///
  /// In ko, this message translates to:
  /// **'인터넷에서 정확한 정보 찾기'**
  String get findInfoOnline;

  /// No description provided for @autoCleaned.
  ///
  /// In ko, this message translates to:
  /// **'제목·가수를 자동으로 정리했어요'**
  String get autoCleaned;

  /// No description provided for @originalInfo.
  ///
  /// In ko, this message translates to:
  /// **'원래 제목·가수예요'**
  String get originalInfo;

  /// No description provided for @cleanAgain.
  ///
  /// In ko, this message translates to:
  /// **'다시 정리'**
  String get cleanAgain;

  /// No description provided for @searchResultApplied.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과를 넣었어요'**
  String get searchResultApplied;

  /// No description provided for @revertChange.
  ///
  /// In ko, this message translates to:
  /// **'되돌리기'**
  String get revertChange;

  /// No description provided for @songInfoSection.
  ///
  /// In ko, this message translates to:
  /// **'곡 정보'**
  String get songInfoSection;

  /// No description provided for @fieldArtist.
  ///
  /// In ko, this message translates to:
  /// **'아티스트'**
  String get fieldArtist;

  /// No description provided for @fieldAlbum.
  ///
  /// In ko, this message translates to:
  /// **'앨범'**
  String get fieldAlbum;

  /// No description provided for @songsReverted.
  ///
  /// In ko, this message translates to:
  /// **'{count}곡을 되돌렸어요'**
  String songsReverted(int count);

  /// No description provided for @songsCleaned.
  ///
  /// In ko, this message translates to:
  /// **'{count}곡을 정리했어요'**
  String songsCleaned(int count);

  /// No description provided for @lastCleaned.
  ///
  /// In ko, this message translates to:
  /// **'마지막에 정리한 {count}곡'**
  String lastCleaned(int count);

  /// No description provided for @readingSongInfo.
  ///
  /// In ko, this message translates to:
  /// **'곡 정보를 읽는 중이에요'**
  String get readingSongInfo;

  /// No description provided for @pleaseWait.
  ///
  /// In ko, this message translates to:
  /// **'잠시만 기다려 주세요'**
  String get pleaseWait;

  /// No description provided for @deselectAllShort.
  ///
  /// In ko, this message translates to:
  /// **'전체 해제'**
  String get deselectAllShort;

  /// No description provided for @selectAllShort.
  ///
  /// In ko, this message translates to:
  /// **'전체 선택'**
  String get selectAllShort;

  /// No description provided for @nothingToClean.
  ///
  /// In ko, this message translates to:
  /// **'정리할 곡이 없어요'**
  String get nothingToClean;

  /// No description provided for @allTidy.
  ///
  /// In ko, this message translates to:
  /// **'모든 곡의 제목·가수가 깔끔해요'**
  String get allTidy;

  /// No description provided for @cleanableCount.
  ///
  /// In ko, this message translates to:
  /// **'정리할 수 있는 곡 {count}개 · 체크한 곡만 바꿔요'**
  String cleanableCount(int count);

  /// No description provided for @cleaningProgress.
  ///
  /// In ko, this message translates to:
  /// **'정리하는 중… {done} / {total}'**
  String cleaningProgress(int done, int total);

  /// No description provided for @cleanSongsButton.
  ///
  /// In ko, this message translates to:
  /// **'{count}곡 정리하기'**
  String cleanSongsButton(int count);

  /// No description provided for @pickRightArt.
  ///
  /// In ko, this message translates to:
  /// **'맞는 앨범 사진을 골라주세요'**
  String get pickRightArt;

  /// No description provided for @artAdded.
  ///
  /// In ko, this message translates to:
  /// **'{count}곡에 사진을 넣었어요'**
  String artAdded(int count);

  /// No description provided for @noSongsWithoutArt.
  ///
  /// In ko, this message translates to:
  /// **'앨범 사진이 없는 곡이 없어요'**
  String get noSongsWithoutArt;

  /// No description provided for @allHaveArt.
  ///
  /// In ko, this message translates to:
  /// **'모든 곡에 앨범 사진이 있어요'**
  String get allHaveArt;

  /// No description provided for @searchingOnline.
  ///
  /// In ko, this message translates to:
  /// **'인터넷에서 찾는 중… {done} / {total}'**
  String searchingOnline(int done, int total);

  /// No description provided for @artSummary.
  ///
  /// In ko, this message translates to:
  /// **'앨범 사진 없는 곡 {missing}개 · 찾은 곡 {found}개'**
  String artSummary(int missing, int found);

  /// No description provided for @notFoundOnline.
  ///
  /// In ko, this message translates to:
  /// **'인터넷에서 못 찾았어요'**
  String get notFoundOnline;

  /// No description provided for @otherCandidates.
  ///
  /// In ko, this message translates to:
  /// **'다른 후보'**
  String get otherCandidates;

  /// No description provided for @addingProgress.
  ///
  /// In ko, this message translates to:
  /// **'넣는 중… {done} / {total}'**
  String addingProgress(int done, int total);

  /// No description provided for @addArtButton.
  ///
  /// In ko, this message translates to:
  /// **'{count}곡에 앨범 사진 넣기'**
  String addArtButton(int count);

  /// No description provided for @trimTitle.
  ///
  /// In ko, this message translates to:
  /// **'자르기'**
  String get trimTitle;

  /// No description provided for @previewListen.
  ///
  /// In ko, this message translates to:
  /// **'미리 듣기'**
  String get previewListen;

  /// No description provided for @trimAndSave.
  ///
  /// In ko, this message translates to:
  /// **'잘라서 저장'**
  String get trimAndSave;

  /// No description provided for @setAsRingtone.
  ///
  /// In ko, this message translates to:
  /// **'벨소리로 지정'**
  String get setAsRingtone;

  /// No description provided for @onlyMp3M4a.
  ///
  /// In ko, this message translates to:
  /// **'mp3, m4a 파일만 자를 수 있어요'**
  String get onlyMp3M4a;

  /// No description provided for @trimmed.
  ///
  /// In ko, this message translates to:
  /// **'잘랐어요'**
  String get trimmed;

  /// No description provided for @trimFailed.
  ///
  /// In ko, this message translates to:
  /// **'자르기에 실패했어요'**
  String get trimFailed;

  /// No description provided for @ringtoneSet.
  ///
  /// In ko, this message translates to:
  /// **'벨소리로 지정했어요'**
  String get ringtoneSet;

  /// No description provided for @allowModifySettings.
  ///
  /// In ko, this message translates to:
  /// **'\"시스템 설정 변경\"을 허용으로 켜고 돌아와서 다시 눌러주세요'**
  String get allowModifySettings;

  /// No description provided for @ringtoneFailedMsg.
  ///
  /// In ko, this message translates to:
  /// **'벨소리를 지정하지 못했어요'**
  String get ringtoneFailedMsg;

  /// No description provided for @saveCurrentEq.
  ///
  /// In ko, this message translates to:
  /// **'지금 설정 저장'**
  String get saveCurrentEq;

  /// No description provided for @eqNeedsPlay.
  ///
  /// In ko, this message translates to:
  /// **'노래를 한 번 재생하면 이퀄라이저를 쓸 수 있어요'**
  String get eqNeedsPlay;

  /// No description provided for @myPresets.
  ///
  /// In ko, this message translates to:
  /// **'내 설정'**
  String get myPresets;

  /// No description provided for @longPressToDelete.
  ///
  /// In ko, this message translates to:
  /// **'길게 누르면 지울 수 있어요'**
  String get longPressToDelete;

  /// No description provided for @manualAdjust.
  ///
  /// In ko, this message translates to:
  /// **'직접 맞추기'**
  String get manualAdjust;

  /// No description provided for @effects.
  ///
  /// In ko, this message translates to:
  /// **'효과'**
  String get effects;

  /// No description provided for @myPresetName.
  ///
  /// In ko, this message translates to:
  /// **'내 설정 {n}'**
  String myPresetName(int n);

  /// No description provided for @presetHintExample.
  ///
  /// In ko, this message translates to:
  /// **'예) 출근길, 잠잘 때'**
  String get presetHintExample;

  /// No description provided for @deletePresetTitle.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\"을 지울까요?'**
  String deletePresetTitle(String name);

  /// No description provided for @artistFormed.
  ///
  /// In ko, this message translates to:
  /// **'{year}년 결성'**
  String artistFormed(String year);

  /// No description provided for @artistFirstAlbum.
  ///
  /// In ko, this message translates to:
  /// **'첫 앨범 {year}년'**
  String artistFirstAlbum(String year);

  /// No description provided for @albumCountChip.
  ///
  /// In ko, this message translates to:
  /// **'앨범 {count}장'**
  String albumCountChip(int count);

  /// No description provided for @releaseDate.
  ///
  /// In ko, this message translates to:
  /// **'발매일'**
  String get releaseDate;

  /// No description provided for @genre.
  ///
  /// In ko, this message translates to:
  /// **'장르'**
  String get genre;

  /// No description provided for @trackNumber.
  ///
  /// In ko, this message translates to:
  /// **'{n}번째 곡'**
  String trackNumber(String n);

  /// No description provided for @nowListening.
  ///
  /// In ko, this message translates to:
  /// **'지금 듣는 곡'**
  String get nowListening;

  /// No description provided for @findingArtistInfo.
  ///
  /// In ko, this message translates to:
  /// **'{artist} 정보를 찾는 중…'**
  String findingArtistInfo(String artist);

  /// No description provided for @songInfoNotFound.
  ///
  /// In ko, this message translates to:
  /// **'이 곡의 정보를 찾지 못했어요'**
  String get songInfoNotFound;

  /// No description provided for @addArtistToSearch.
  ///
  /// In ko, this message translates to:
  /// **'곡 정보 수정에서 가수 이름을 넣으면 찾을 수 있어요'**
  String get addArtistToSearch;

  /// No description provided for @accurateNamesHelp.
  ///
  /// In ko, this message translates to:
  /// **'가수 이름이나 제목이 정확하면 더 잘 찾아요'**
  String get accurateNamesHelp;

  /// No description provided for @showLess.
  ///
  /// In ko, this message translates to:
  /// **'접기'**
  String get showLess;

  /// No description provided for @showMore.
  ///
  /// In ko, this message translates to:
  /// **'더 보기'**
  String get showMore;

  /// No description provided for @autoTranslated.
  ///
  /// In ko, this message translates to:
  /// **'자동 번역'**
  String get autoTranslated;

  /// No description provided for @findingCredits.
  ///
  /// In ko, this message translates to:
  /// **'작사·작곡 찾는 중…'**
  String get findingCredits;

  /// No description provided for @artistAlbums.
  ///
  /// In ko, this message translates to:
  /// **'이 가수의 앨범'**
  String get artistAlbums;

  /// No description provided for @mayHaveErrors.
  ///
  /// In ko, this message translates to:
  /// **'(일부 오류가 있을 수 있어요)'**
  String get mayHaveErrors;

  /// No description provided for @sourcesLabel.
  ///
  /// In ko, this message translates to:
  /// **'정보'**
  String get sourcesLabel;

  /// No description provided for @hiddenIfNotFound.
  ///
  /// In ko, this message translates to:
  /// **'찾지 못한 항목은 보이지 않아요'**
  String get hiddenIfNotFound;

  /// No description provided for @moreOnWikipedia.
  ///
  /// In ko, this message translates to:
  /// **'Wikipedia에서 더 보기 ›'**
  String get moreOnWikipedia;

  /// No description provided for @roleLyrics.
  ///
  /// In ko, this message translates to:
  /// **'작사'**
  String get roleLyrics;

  /// No description provided for @roleComposer.
  ///
  /// In ko, this message translates to:
  /// **'작곡'**
  String get roleComposer;

  /// No description provided for @roleWriter.
  ///
  /// In ko, this message translates to:
  /// **'작사·작곡'**
  String get roleWriter;

  /// No description provided for @roleArranger.
  ///
  /// In ko, this message translates to:
  /// **'편곡'**
  String get roleArranger;

  /// No description provided for @roleProducer.
  ///
  /// In ko, this message translates to:
  /// **'프로듀서'**
  String get roleProducer;

  /// No description provided for @kindSingle.
  ///
  /// In ko, this message translates to:
  /// **'싱글'**
  String get kindSingle;

  /// No description provided for @kindCompilation.
  ///
  /// In ko, this message translates to:
  /// **'모음집'**
  String get kindCompilation;

  /// No description provided for @kindLive.
  ///
  /// In ko, this message translates to:
  /// **'라이브'**
  String get kindLive;

  /// No description provided for @artistSolo.
  ///
  /// In ko, this message translates to:
  /// **'솔로'**
  String get artistSolo;

  /// No description provided for @artistGroup.
  ///
  /// In ko, this message translates to:
  /// **'그룹'**
  String get artistGroup;

  /// No description provided for @recRecovered.
  ///
  /// In ko, this message translates to:
  /// **'중간에 끊긴 녹음 {count}개를 되살렸어요'**
  String recRecovered(int count);

  /// No description provided for @selectedCount2.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 선택'**
  String selectedCount2(int count);

  /// No description provided for @deselect.
  ///
  /// In ko, this message translates to:
  /// **'선택 해제'**
  String get deselect;

  /// No description provided for @recordings.
  ///
  /// In ko, this message translates to:
  /// **'녹음'**
  String get recordings;

  /// No description provided for @sortLabel.
  ///
  /// In ko, this message translates to:
  /// **'정렬'**
  String get sortLabel;

  /// No description provided for @sortNewest.
  ///
  /// In ko, this message translates to:
  /// **'최신순'**
  String get sortNewest;

  /// No description provided for @sortOldest.
  ///
  /// In ko, this message translates to:
  /// **'오래된순'**
  String get sortOldest;

  /// No description provided for @sortLongest.
  ///
  /// In ko, this message translates to:
  /// **'긴 통화순'**
  String get sortLongest;

  /// No description provided for @recSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'이름, 번호, 제목으로 찾기'**
  String get recSearchHint;

  /// No description provided for @callRecTab.
  ///
  /// In ko, this message translates to:
  /// **'통화 녹음 ({count})'**
  String callRecTab(int count);

  /// No description provided for @voiceRecTab.
  ///
  /// In ko, this message translates to:
  /// **'음성 녹음 ({count})'**
  String voiceRecTab(int count);

  /// No description provided for @noVoiceRec.
  ///
  /// In ko, this message translates to:
  /// **'음성 녹음이 없어요'**
  String get noVoiceRec;

  /// No description provided for @noCallRec.
  ///
  /// In ko, this message translates to:
  /// **'통화 녹음이 없어요'**
  String get noCallRec;

  /// No description provided for @voiceEmptyHint1.
  ///
  /// In ko, this message translates to:
  /// **'오른쪽 아래 '**
  String get voiceEmptyHint1;

  /// No description provided for @voiceEmptyHint2.
  ///
  /// In ko, this message translates to:
  /// **' 버튼으로\n바로 녹음할 수 있어요'**
  String get voiceEmptyHint2;

  /// No description provided for @callEmptyHint.
  ///
  /// In ko, this message translates to:
  /// **'전화 앱 설정에서 통화 녹음을 켜면\n녹음된 통화가 여기에 모여요'**
  String get callEmptyHint;

  /// No description provided for @recManage.
  ///
  /// In ko, this message translates to:
  /// **'녹음 관리'**
  String get recManage;

  /// No description provided for @selectMultiple.
  ///
  /// In ko, this message translates to:
  /// **'여러 개 선택하기'**
  String get selectMultiple;

  /// No description provided for @deleteAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 삭제'**
  String get deleteAll;

  /// No description provided for @unlock.
  ///
  /// In ko, this message translates to:
  /// **'잠금 풀기'**
  String get unlock;

  /// No description provided for @lock.
  ///
  /// In ko, this message translates to:
  /// **'잠금'**
  String get lock;

  /// No description provided for @recSaved.
  ///
  /// In ko, this message translates to:
  /// **'녹음을 저장했어요'**
  String get recSaved;

  /// No description provided for @renameTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목 바꾸기'**
  String get renameTitle;

  /// No description provided for @lockNoDelete.
  ///
  /// In ko, this message translates to:
  /// **'잠금 (삭제 안 되게)'**
  String get lockNoDelete;

  /// No description provided for @unlocked.
  ///
  /// In ko, this message translates to:
  /// **'잠금을 풀었어요'**
  String get unlocked;

  /// No description provided for @locked.
  ///
  /// In ko, this message translates to:
  /// **'잠갔어요'**
  String get locked;

  /// No description provided for @lockedCantDelete.
  ///
  /// In ko, this message translates to:
  /// **'잠긴 녹음은 삭제할 수 없어요'**
  String get lockedCantDelete;

  /// No description provided for @recRenameHint.
  ///
  /// In ko, this message translates to:
  /// **'예) 엄마랑 통화'**
  String get recRenameHint;

  /// No description provided for @deleteRecsTitle.
  ///
  /// In ko, this message translates to:
  /// **'녹음 {count}개를 삭제할까요?'**
  String deleteRecsTitle(int count);

  /// No description provided for @deleteRecTitle.
  ///
  /// In ko, this message translates to:
  /// **'이 녹음을 삭제할까요?'**
  String get deleteRecTitle;

  /// No description provided for @trashInfo.
  ///
  /// In ko, this message translates to:
  /// **'휴지통으로 옮겨져요. 30일 뒤에 완전히 지워져요.'**
  String get trashInfo;

  /// No description provided for @lockedKept.
  ///
  /// In ko, this message translates to:
  /// **'잠긴 녹음 {count}개는 남겨둬요.'**
  String lockedKept(int count);

  /// No description provided for @toTrash.
  ///
  /// In ko, this message translates to:
  /// **'휴지통으로'**
  String get toTrash;

  /// No description provided for @deleteForever.
  ///
  /// In ko, this message translates to:
  /// **'영구 삭제'**
  String get deleteForever;

  /// No description provided for @deleteForeverTitle.
  ///
  /// In ko, this message translates to:
  /// **'영구 삭제할까요?'**
  String get deleteForeverTitle;

  /// No description provided for @deleteForeverMsg.
  ///
  /// In ko, this message translates to:
  /// **'녹음 {count}개를 영구 삭제하면 되살릴 수 없어요.'**
  String deleteForeverMsg(int count);

  /// No description provided for @deletedForever.
  ///
  /// In ko, this message translates to:
  /// **'영구 삭제했어요'**
  String get deletedForever;

  /// No description provided for @recDefaultName.
  ///
  /// In ko, this message translates to:
  /// **'녹음'**
  String get recDefaultName;

  /// No description provided for @unknownShort.
  ///
  /// In ko, this message translates to:
  /// **'알 수 없음'**
  String get unknownShort;

  /// No description provided for @voiceRec.
  ///
  /// In ko, this message translates to:
  /// **'음성 녹음'**
  String get voiceRec;

  /// No description provided for @callRec.
  ///
  /// In ko, this message translates to:
  /// **'통화 녹음'**
  String get callRec;

  /// No description provided for @weekdaysShort.
  ///
  /// In ko, this message translates to:
  /// **'월,화,수,목,금,토,일'**
  String get weekdaysShort;

  /// No description provided for @am.
  ///
  /// In ko, this message translates to:
  /// **'오전'**
  String get am;

  /// No description provided for @pm.
  ///
  /// In ko, this message translates to:
  /// **'오후'**
  String get pm;

  /// No description provided for @recDate.
  ///
  /// In ko, this message translates to:
  /// **'{month}월 {day}일 ({weekday}) {ampm} {time}'**
  String recDate(
    String month,
    String day,
    String weekday,
    String ampm,
    String time,
  );

  /// No description provided for @recDateYear.
  ///
  /// In ko, this message translates to:
  /// **'{year}년 {month}월 {day}일 ({weekday}) {ampm} {time}'**
  String recDateYear(
    String year,
    String month,
    String day,
    String weekday,
    String ampm,
    String time,
  );

  /// No description provided for @durHM.
  ///
  /// In ko, this message translates to:
  /// **'{h}시간 {m}분'**
  String durHM(int h, int m);

  /// No description provided for @durMS.
  ///
  /// In ko, this message translates to:
  /// **'{m}분 {s}초'**
  String durMS(int m, int s);

  /// No description provided for @durS.
  ///
  /// In ko, this message translates to:
  /// **'{s}초'**
  String durS(int s);

  /// No description provided for @durM.
  ///
  /// In ko, this message translates to:
  /// **'{m}분'**
  String durM(int m);

  /// No description provided for @durH.
  ///
  /// In ko, this message translates to:
  /// **'{h}시간'**
  String durH(int h);

  /// No description provided for @micPermissionNeeded.
  ///
  /// In ko, this message translates to:
  /// **'녹음하려면 마이크 권한이 필요해요'**
  String get micPermissionNeeded;

  /// No description provided for @recNotifyHint.
  ///
  /// In ko, this message translates to:
  /// **'알림을 허용하면 알림창에서 녹음 중인 걸 볼 수 있어요'**
  String get recNotifyHint;

  /// No description provided for @discardRecTitle.
  ///
  /// In ko, this message translates to:
  /// **'녹음을 지울까요?'**
  String get discardRecTitle;

  /// No description provided for @discardRecMsg.
  ///
  /// In ko, this message translates to:
  /// **'지금까지 녹음한 내용이 저장되지 않아요.'**
  String get discardRecMsg;

  /// No description provided for @keepRecording.
  ///
  /// In ko, this message translates to:
  /// **'계속 녹음'**
  String get keepRecording;

  /// No description provided for @newRecording.
  ///
  /// In ko, this message translates to:
  /// **'새 녹음'**
  String get newRecording;

  /// No description provided for @noTimer.
  ///
  /// In ko, this message translates to:
  /// **'타이머 없음'**
  String get noTimer;

  /// No description provided for @autoSaveAfter.
  ///
  /// In ko, this message translates to:
  /// **'{time} 녹음하면 자동 저장'**
  String autoSaveAfter(String time);

  /// No description provided for @autoSaveIn.
  ///
  /// In ko, this message translates to:
  /// **'{time} 후 자동 저장'**
  String autoSaveIn(String time);

  /// No description provided for @alreadyLonger.
  ///
  /// In ko, this message translates to:
  /// **'이미 그보다 오래 녹음했어요'**
  String get alreadyLonger;

  /// No description provided for @autoSaveWhen.
  ///
  /// In ko, this message translates to:
  /// **'이만큼 녹음되면 자동으로 저장'**
  String get autoSaveWhen;

  /// No description provided for @timerOff.
  ///
  /// In ko, this message translates to:
  /// **'타이머 끄기'**
  String get timerOff;

  /// No description provided for @recReady.
  ///
  /// In ko, this message translates to:
  /// **'준비됐어요'**
  String get recReady;

  /// No description provided for @recRecording.
  ///
  /// In ko, this message translates to:
  /// **'녹음 중'**
  String get recRecording;

  /// No description provided for @recPausedCall.
  ///
  /// In ko, this message translates to:
  /// **'통화 중 · 끝나면 이어서 녹음'**
  String get recPausedCall;

  /// No description provided for @recPaused.
  ///
  /// In ko, this message translates to:
  /// **'일시정지'**
  String get recPaused;

  /// No description provided for @saving.
  ///
  /// In ko, this message translates to:
  /// **'저장 중…'**
  String get saving;

  /// No description provided for @longVideoTitle.
  ///
  /// In ko, this message translates to:
  /// **'긴 동영상이에요'**
  String get longVideoTitle;

  /// No description provided for @longVideoMsg.
  ///
  /// In ko, this message translates to:
  /// **'10분이 넘는 영상은 카카오톡으로 안 보내질 수 있어요.\n구글 드라이브나 메일로 보내면 잘 가요.'**
  String get longVideoMsg;

  /// No description provided for @send.
  ///
  /// In ko, this message translates to:
  /// **'보내기'**
  String get send;

  /// No description provided for @deleteVideosTitle.
  ///
  /// In ko, this message translates to:
  /// **'동영상 {count}개를 삭제할까요?'**
  String deleteVideosTitle(int count);

  /// No description provided for @deleteVideoTitle.
  ///
  /// In ko, this message translates to:
  /// **'이 동영상을 삭제할까요?'**
  String get deleteVideoTitle;

  /// No description provided for @deleteVideosForeverMsg.
  ///
  /// In ko, this message translates to:
  /// **'동영상 {count}개를 영구 삭제하면 되살릴 수 없어요.'**
  String deleteVideosForeverMsg(int count);

  /// No description provided for @deleteVideoForeverMsg.
  ///
  /// In ko, this message translates to:
  /// **'이 동영상을 영구 삭제하면 되살릴 수 없어요.'**
  String get deleteVideoForeverMsg;

  /// No description provided for @sortByName.
  ///
  /// In ko, this message translates to:
  /// **'이름순'**
  String get sortByName;

  /// No description provided for @sortLongVideo.
  ///
  /// In ko, this message translates to:
  /// **'긴 영상순'**
  String get sortLongVideo;

  /// No description provided for @sortShortVideo.
  ///
  /// In ko, this message translates to:
  /// **'짧은 영상순'**
  String get sortShortVideo;

  /// No description provided for @dateUnknown.
  ///
  /// In ko, this message translates to:
  /// **'날짜 모름'**
  String get dateUnknown;

  /// No description provided for @monthNames.
  ///
  /// In ko, this message translates to:
  /// **'1월,2월,3월,4월,5월,6월,7월,8월,9월,10월,11월,12월'**
  String get monthNames;

  /// No description provided for @yearMonth.
  ///
  /// In ko, this message translates to:
  /// **'{year}년 {month}'**
  String yearMonth(String year, String month);

  /// No description provided for @timeAmPm.
  ///
  /// In ko, this message translates to:
  /// **'{ampm} {time}'**
  String timeAmPm(String ampm, String time);

  /// No description provided for @dateYMDW.
  ///
  /// In ko, this message translates to:
  /// **'{year}년 {month}월 {day}일 ({weekday})'**
  String dateYMDW(String year, String month, String day, String weekday);

  /// No description provided for @dateMDW.
  ///
  /// In ko, this message translates to:
  /// **'{month}월 {day}일 ({weekday})'**
  String dateMDW(String month, String day, String weekday);

  /// No description provided for @dateDW.
  ///
  /// In ko, this message translates to:
  /// **'{day}일 ({weekday})'**
  String dateDW(String day, String weekday);

  /// No description provided for @dateYMDdotW.
  ///
  /// In ko, this message translates to:
  /// **'{year}.{month}.{day} ({weekday})'**
  String dateYMDdotW(String year, String month, String day, String weekday);

  /// No description provided for @videoManage.
  ///
  /// In ko, this message translates to:
  /// **'동영상 관리'**
  String get videoManage;

  /// No description provided for @videoPermTitle.
  ///
  /// In ko, this message translates to:
  /// **'폰에 있는 동영상을 불러올게요'**
  String get videoPermTitle;

  /// No description provided for @videoPermSub.
  ///
  /// In ko, this message translates to:
  /// **'동영상 접근을 한 번만 허용해 주세요'**
  String get videoPermSub;

  /// No description provided for @videoPermStep1.
  ///
  /// In ko, this message translates to:
  /// **'아래 설정에서 허용하기 누르기'**
  String get videoPermStep1;

  /// No description provided for @videoPermStep1Note.
  ///
  /// In ko, this message translates to:
  /// **'파란소리 앱 설정이 바로 열려요'**
  String get videoPermStep1Note;

  /// No description provided for @videoPermStep2.
  ///
  /// In ko, this message translates to:
  /// **'권한 → 사진 및 동영상 누르기'**
  String get videoPermStep2;

  /// No description provided for @videoPermStep3.
  ///
  /// In ko, this message translates to:
  /// **'허용 고르고 돌아오기'**
  String get videoPermStep3;

  /// No description provided for @videoPermStep3Note.
  ///
  /// In ko, this message translates to:
  /// **'돌아오면 바로 목록이 나와요'**
  String get videoPermStep3Note;

  /// No description provided for @videoPermManual.
  ///
  /// In ko, this message translates to:
  /// **'직접 찾아갈 때: 설정 → 애플리케이션(앱) → 파란소리 → 권한 → 사진 및 동영상'**
  String get videoPermManual;

  /// No description provided for @allowInSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정에서 허용하기'**
  String get allowInSettings;

  /// No description provided for @otherSetupHelp.
  ///
  /// In ko, this message translates to:
  /// **'다른 설정 도움말 보기'**
  String get otherSetupHelp;

  /// No description provided for @trimAndSend.
  ///
  /// In ko, this message translates to:
  /// **'잘라서 보내기'**
  String get trimAndSend;

  /// No description provided for @saveAsMusic.
  ///
  /// In ko, this message translates to:
  /// **'음악으로 저장'**
  String get saveAsMusic;

  /// No description provided for @renameFailed.
  ///
  /// In ko, this message translates to:
  /// **'이름을 바꾸지 못했어요'**
  String get renameFailed;

  /// No description provided for @castFailedRetry.
  ///
  /// In ko, this message translates to:
  /// **'TV로 보내지 못했어요. 다시 시도해 주세요.'**
  String get castFailedRetry;

  /// No description provided for @watchOnTv.
  ///
  /// In ko, this message translates to:
  /// **'TV로 보기'**
  String get watchOnTv;

  /// No description provided for @watchingOn.
  ///
  /// In ko, this message translates to:
  /// **'{device}에서 보는 중'**
  String watchingOn(String device);

  /// No description provided for @continueOnPhone.
  ///
  /// In ko, this message translates to:
  /// **'폰에서 이어 보기'**
  String get continueOnPhone;

  /// No description provided for @speedNormal.
  ///
  /// In ko, this message translates to:
  /// **'보통'**
  String get speedNormal;

  /// No description provided for @setAFirst.
  ///
  /// In ko, this message translates to:
  /// **'A를 먼저 정해 주세요'**
  String get setAFirst;

  /// No description provided for @pressAfterA.
  ///
  /// In ko, this message translates to:
  /// **'A보다 뒤에서 눌러 주세요'**
  String get pressAfterA;

  /// No description provided for @setAHint.
  ///
  /// In ko, this message translates to:
  /// **'A를 정해 주세요'**
  String get setAHint;

  /// No description provided for @setBHint.
  ///
  /// In ko, this message translates to:
  /// **'B를 정하면 반복돼요'**
  String get setBHint;

  /// No description provided for @looping.
  ///
  /// In ko, this message translates to:
  /// **'반복 중'**
  String get looping;

  /// No description provided for @abRepeat.
  ///
  /// In ko, this message translates to:
  /// **'구간 반복'**
  String get abRepeat;

  /// No description provided for @setA.
  ///
  /// In ko, this message translates to:
  /// **'A 지정'**
  String get setA;

  /// No description provided for @setB.
  ///
  /// In ko, this message translates to:
  /// **'B 지정'**
  String get setB;

  /// No description provided for @loopEnd.
  ///
  /// In ko, this message translates to:
  /// **'반복 끝'**
  String get loopEnd;

  /// No description provided for @audioOnly.
  ///
  /// In ko, this message translates to:
  /// **'소리만 듣기'**
  String get audioOnly;

  /// No description provided for @playbackSpeedWith.
  ///
  /// In ko, this message translates to:
  /// **'재생 속도 ({speed})'**
  String playbackSpeedWith(String speed);

  /// No description provided for @audioOnlyOn.
  ///
  /// In ko, this message translates to:
  /// **'화면을 꺼도 소리가 계속 나와요'**
  String get audioOnlyOn;

  /// No description provided for @audioOnlyOff.
  ///
  /// In ko, this message translates to:
  /// **'앱을 나가면 멈춰요'**
  String get audioOnlyOff;

  /// No description provided for @videoScanError.
  ///
  /// In ko, this message translates to:
  /// **'비디오 스캔 오류'**
  String get videoScanError;

  /// No description provided for @saveMusicFailed.
  ///
  /// In ko, this message translates to:
  /// **'음악으로 저장하지 못했어요'**
  String get saveMusicFailed;

  /// No description provided for @savedAsMusic.
  ///
  /// In ko, this message translates to:
  /// **'음악으로 저장했어요'**
  String get savedAsMusic;

  /// No description provided for @saveMusicSub.
  ///
  /// In ko, this message translates to:
  /// **'영상의 소리만 뽑아서 음악 목록에 넣어요'**
  String get saveMusicSub;

  /// No description provided for @saveWhole.
  ///
  /// In ko, this message translates to:
  /// **'전체 저장'**
  String get saveWhole;

  /// No description provided for @savePart.
  ///
  /// In ko, this message translates to:
  /// **'구간 골라서 저장'**
  String get savePart;

  /// No description provided for @trimFailed2.
  ///
  /// In ko, this message translates to:
  /// **'자르지 못했어요'**
  String get trimFailed2;

  /// No description provided for @trimSaved.
  ///
  /// In ko, this message translates to:
  /// **'잘라서 저장했어요'**
  String get trimSaved;

  /// No description provided for @stop.
  ///
  /// In ko, this message translates to:
  /// **'멈추기'**
  String get stop;

  /// No description provided for @previewWatch.
  ///
  /// In ko, this message translates to:
  /// **'미리 보기'**
  String get previewWatch;

  /// No description provided for @saveOnly.
  ///
  /// In ko, this message translates to:
  /// **'저장만'**
  String get saveOnly;

  /// No description provided for @saveMusicNote.
  ///
  /// In ko, this message translates to:
  /// **'고른 구간의 소리만 음악 목록에 저장해요 (Music/Paransori · M4A)'**
  String get saveMusicNote;

  /// No description provided for @trimVideoNote.
  ///
  /// In ko, this message translates to:
  /// **'원본은 그대로 두고 잘라낸 영상을 새로 저장해요 (Movies/Paransori)\n다시 압축하지 않아 화질 그대로예요. 시작이 1초쯤 앞당겨질 수 있어요'**
  String get trimVideoNote;

  /// No description provided for @castNeedsPlaying.
  ///
  /// In ko, this message translates to:
  /// **'방송이 나오고 있을 때 TV로 보낼 수 있어요'**
  String get castNeedsPlaying;

  /// No description provided for @radioShareText.
  ///
  /// In ko, this message translates to:
  /// **'지금 {name} 듣고 있어요! 파란소리에서 같이 들어요 🎧'**
  String radioShareText(String name);

  /// No description provided for @radioShareSub.
  ///
  /// In ko, this message translates to:
  /// **'지금 듣는 방송을 소개해보세요.'**
  String get radioShareSub;

  /// No description provided for @savedSongAdded.
  ///
  /// In ko, this message translates to:
  /// **'저장한 곡에 넣었어요'**
  String get savedSongAdded;

  /// No description provided for @savedSongRemoved.
  ///
  /// In ko, this message translates to:
  /// **'저장한 곡에서 뺐어요'**
  String get savedSongRemoved;

  /// No description provided for @smsJoin.
  ///
  /// In ko, this message translates to:
  /// **'문자 참여 #{number}'**
  String smsJoin(String number);

  /// No description provided for @tvPaused.
  ///
  /// In ko, this message translates to:
  /// **'TV에서 일시정지'**
  String get tvPaused;

  /// No description provided for @similarStation.
  ///
  /// In ko, this message translates to:
  /// **'비슷한 방송 듣기 · {name}'**
  String similarStation(String name);

  /// No description provided for @minutesLeft.
  ///
  /// In ko, this message translates to:
  /// **'{m}분 남음'**
  String minutesLeft(int m);

  /// No description provided for @countItems.
  ///
  /// In ko, this message translates to:
  /// **'{count}개'**
  String countItems(int count);

  /// No description provided for @listeningNow.
  ///
  /// In ko, this message translates to:
  /// **'듣는 중'**
  String get listeningNow;

  /// No description provided for @tapToListen.
  ///
  /// In ko, this message translates to:
  /// **'눌러서 바로 듣기'**
  String get tapToListen;

  /// No description provided for @removedFromFav.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기에서 뺐어요'**
  String get removedFromFav;

  /// No description provided for @swipeToRemoveFav.
  ///
  /// In ko, this message translates to:
  /// **'왼쪽으로 밀면 즐겨찾기에서 빼요'**
  String get swipeToRemoveFav;

  /// No description provided for @partDawn.
  ///
  /// In ko, this message translates to:
  /// **'새벽'**
  String get partDawn;

  /// No description provided for @partMorning.
  ///
  /// In ko, this message translates to:
  /// **'아침'**
  String get partMorning;

  /// No description provided for @partAfternoon.
  ///
  /// In ko, this message translates to:
  /// **'오후'**
  String get partAfternoon;

  /// No description provided for @partEvening.
  ///
  /// In ko, this message translates to:
  /// **'저녁 · 밤'**
  String get partEvening;

  /// No description provided for @scheduledToast.
  ///
  /// In ko, this message translates to:
  /// **'예약했어요'**
  String get scheduledToast;

  /// No description provided for @scheduleFull.
  ///
  /// In ko, this message translates to:
  /// **'예약을 더 넣을 수 없어요. 예약 창에서 지난 예약을 지워주세요'**
  String get scheduleFull;

  /// No description provided for @nextShort.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get nextShort;

  /// No description provided for @todayFull.
  ///
  /// In ko, this message translates to:
  /// **'오늘 · {month}월 {day}일 {weekday}요일'**
  String todayFull(String month, String day, String weekday);

  /// No description provided for @onAirNow.
  ///
  /// In ko, this message translates to:
  /// **'지금 방송 중'**
  String get onAirNow;

  /// No description provided for @searchCountry.
  ///
  /// In ko, this message translates to:
  /// **'국가 검색'**
  String get searchCountry;

  /// No description provided for @noCountryFound.
  ///
  /// In ko, this message translates to:
  /// **'찾는 나라가 없어요'**
  String get noCountryFound;

  /// No description provided for @currentCountry.
  ///
  /// In ko, this message translates to:
  /// **'현재 국가'**
  String get currentCountry;

  /// No description provided for @continentAsia.
  ///
  /// In ko, this message translates to:
  /// **'아시아'**
  String get continentAsia;

  /// No description provided for @continentEurope.
  ///
  /// In ko, this message translates to:
  /// **'유럽'**
  String get continentEurope;

  /// No description provided for @continentNorthAmerica.
  ///
  /// In ko, this message translates to:
  /// **'북아메리카'**
  String get continentNorthAmerica;

  /// No description provided for @continentSouthAmerica.
  ///
  /// In ko, this message translates to:
  /// **'남아메리카'**
  String get continentSouthAmerica;

  /// No description provided for @continentMiddleEast.
  ///
  /// In ko, this message translates to:
  /// **'중동'**
  String get continentMiddleEast;

  /// No description provided for @continentAfrica.
  ///
  /// In ko, this message translates to:
  /// **'아프리카'**
  String get continentAfrica;

  /// No description provided for @continentOceania.
  ///
  /// In ko, this message translates to:
  /// **'오세아니아'**
  String get continentOceania;

  /// No description provided for @radioConnecting.
  ///
  /// In ko, this message translates to:
  /// **'접속 중...'**
  String get radioConnecting;

  /// No description provided for @radioNotPlaying.
  ///
  /// In ko, this message translates to:
  /// **'나오지 않아요'**
  String get radioNotPlaying;

  /// No description provided for @pausedShort.
  ///
  /// In ko, this message translates to:
  /// **'일시정지'**
  String get pausedShort;

  /// No description provided for @similarStationShort.
  ///
  /// In ko, this message translates to:
  /// **'비슷한 방송 듣기 ›'**
  String get similarStationShort;

  /// No description provided for @inMinutes.
  ///
  /// In ko, this message translates to:
  /// **'{m}분 뒤'**
  String inMinutes(int m);

  /// No description provided for @inHours.
  ///
  /// In ko, this message translates to:
  /// **'{h}시간 뒤'**
  String inHours(int h);

  /// No description provided for @inHoursMinutes.
  ///
  /// In ko, this message translates to:
  /// **'{h}시간 {m}분 뒤'**
  String inHoursMinutes(int h, int m);

  /// No description provided for @scheduleTitle.
  ///
  /// In ko, this message translates to:
  /// **'예약'**
  String get scheduleTitle;

  /// No description provided for @scheduleSub.
  ///
  /// In ko, this message translates to:
  /// **'정한 시간이 되면 그 방송으로 바꿔줘요'**
  String get scheduleSub;

  /// No description provided for @mySchedules.
  ///
  /// In ko, this message translates to:
  /// **'내 예약'**
  String get mySchedules;

  /// No description provided for @cancelAllSchedulesTitle.
  ///
  /// In ko, this message translates to:
  /// **'예약을 전부 취소할까요?'**
  String get cancelAllSchedulesTitle;

  /// No description provided for @cancelAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 취소'**
  String get cancelAll;

  /// No description provided for @schedulesCanceled.
  ///
  /// In ko, this message translates to:
  /// **'예약을 취소했어요'**
  String get schedulesCanceled;

  /// No description provided for @switchedCheck.
  ///
  /// In ko, this message translates to:
  /// **'바꿨어요 ✓'**
  String get switchedCheck;

  /// No description provided for @newSchedule.
  ///
  /// In ko, this message translates to:
  /// **'새 예약'**
  String get newSchedule;

  /// No description provided for @whatTime.
  ///
  /// In ko, this message translates to:
  /// **'몇 시에?'**
  String get whatTime;

  /// No description provided for @pickTime.
  ///
  /// In ko, this message translates to:
  /// **'시간 고르기'**
  String get pickTime;

  /// No description provided for @quick30min.
  ///
  /// In ko, this message translates to:
  /// **'30분 뒤'**
  String get quick30min;

  /// No description provided for @quick1hour.
  ///
  /// In ko, this message translates to:
  /// **'1시간 뒤'**
  String get quick1hour;

  /// No description provided for @quick7am.
  ///
  /// In ko, this message translates to:
  /// **'아침 7시'**
  String get quick7am;

  /// No description provided for @whichStation.
  ///
  /// In ko, this message translates to:
  /// **'어떤 방송?'**
  String get whichStation;

  /// No description provided for @pickFromSchedule.
  ///
  /// In ko, this message translates to:
  /// **'편성표에서 프로그램으로 고르기'**
  String get pickFromSchedule;

  /// No description provided for @scheduleAction.
  ///
  /// In ko, this message translates to:
  /// **'예약하기'**
  String get scheduleAction;

  /// No description provided for @scheduleLimit.
  ///
  /// In ko, this message translates to:
  /// **'예약은 5개까지예요. 지난 예약을 지우면 새로 넣을 수 있어요'**
  String get scheduleLimit;

  /// No description provided for @diceProgramLabel.
  ///
  /// In ko, this message translates to:
  /// **'지금 하는 프로그램'**
  String get diceProgramLabel;

  /// No description provided for @diceNoProgram.
  ///
  /// In ko, this message translates to:
  /// **'편성 정보가 없어요'**
  String get diceNoProgram;

  /// No description provided for @diceWhich.
  ///
  /// In ko, this message translates to:
  /// **'어느 방송이 나올까요?'**
  String get diceWhich;

  /// No description provided for @diceGot.
  ///
  /// In ko, this message translates to:
  /// **'{n}이(가) 나왔어요!'**
  String diceGot(int n);

  /// No description provided for @nowPlayingBadge.
  ///
  /// In ko, this message translates to:
  /// **'재생 중'**
  String get nowPlayingBadge;

  /// No description provided for @rollAgain.
  ///
  /// In ko, this message translates to:
  /// **'다시 던지기'**
  String get rollAgain;

  /// No description provided for @diceTitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘은 어떤 라디오를\n들어볼까요?'**
  String get diceTitle;

  /// No description provided for @diceSub.
  ///
  /// In ko, this message translates to:
  /// **'주사위를 던져\n새로운 방송을 만나보세요.'**
  String get diceSub;

  /// No description provided for @rollDice.
  ///
  /// In ko, this message translates to:
  /// **'주사위 던지기'**
  String get rollDice;

  /// No description provided for @savedSongs.
  ///
  /// In ko, this message translates to:
  /// **'저장한 곡'**
  String get savedSongs;

  /// No description provided for @savedDate.
  ///
  /// In ko, this message translates to:
  /// **'{month}월 {day}일 {ampm} {time}'**
  String savedDate(String month, String day, String ampm, String time);

  /// No description provided for @youtubeOpenFailed.
  ///
  /// In ko, this message translates to:
  /// **'유튜브를 열지 못했어요'**
  String get youtubeOpenFailed;

  /// No description provided for @savedSongDeleted.
  ///
  /// In ko, this message translates to:
  /// **'저장한 곡에서 지웠어요'**
  String get savedSongDeleted;

  /// No description provided for @searchYoutube.
  ///
  /// In ko, this message translates to:
  /// **'유튜브에서 찾기'**
  String get searchYoutube;

  /// No description provided for @copySongName.
  ///
  /// In ko, this message translates to:
  /// **'곡 이름 복사'**
  String get copySongName;

  /// No description provided for @songNameCopied.
  ///
  /// In ko, this message translates to:
  /// **'곡 이름을 복사했어요'**
  String get songNameCopied;

  /// No description provided for @savedSongsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'방송에서 나온 곡 옆 ♡를 누르면\n여기에 모여요'**
  String get savedSongsEmpty;

  /// No description provided for @searchingTv.
  ///
  /// In ko, this message translates to:
  /// **'같은 와이파이의 TV를 찾고 있어요'**
  String get searchingTv;

  /// No description provided for @tvNotFound.
  ///
  /// In ko, this message translates to:
  /// **'TV를 못 찾았어요'**
  String get tvNotFound;

  /// No description provided for @tvCheckWifi.
  ///
  /// In ko, this message translates to:
  /// **'TV가 켜져 있고 같은 와이파이인지 확인해 주세요'**
  String get tvCheckWifi;

  /// No description provided for @sameWifiOnly.
  ///
  /// In ko, this message translates to:
  /// **'같은 와이파이의 TV만 보여요'**
  String get sameWifiOnly;

  /// No description provided for @tvPlayingShort.
  ///
  /// In ko, this message translates to:
  /// **'TV에서 재생 중'**
  String get tvPlayingShort;

  /// No description provided for @disconnect.
  ///
  /// In ko, this message translates to:
  /// **'연결 끊기'**
  String get disconnect;

  /// No description provided for @popMost.
  ///
  /// In ko, this message translates to:
  /// **'많이 듣는'**
  String get popMost;

  /// No description provided for @popTrend.
  ///
  /// In ko, this message translates to:
  /// **'요즘 뜨는'**
  String get popTrend;

  /// No description provided for @recentListened.
  ///
  /// In ko, this message translates to:
  /// **'최근청취'**
  String get recentListened;

  /// No description provided for @myRadio.
  ///
  /// In ko, this message translates to:
  /// **'내 라디오'**
  String get myRadio;

  /// No description provided for @popularTab.
  ///
  /// In ko, this message translates to:
  /// **'인기'**
  String get popularTab;

  /// No description provided for @genreTab.
  ///
  /// In ko, this message translates to:
  /// **'장르'**
  String get genreTab;

  /// No description provided for @regionTab.
  ///
  /// In ko, this message translates to:
  /// **'지역'**
  String get regionTab;

  /// No description provided for @languageTab.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get languageTab;

  /// No description provided for @genreNews.
  ///
  /// In ko, this message translates to:
  /// **'뉴스'**
  String get genreNews;

  /// No description provided for @genreTalk.
  ///
  /// In ko, this message translates to:
  /// **'토크'**
  String get genreTalk;

  /// No description provided for @genreSports.
  ///
  /// In ko, this message translates to:
  /// **'스포츠'**
  String get genreSports;

  /// No description provided for @genrePop.
  ///
  /// In ko, this message translates to:
  /// **'팝'**
  String get genrePop;

  /// No description provided for @genreHits.
  ///
  /// In ko, this message translates to:
  /// **'인기곡'**
  String get genreHits;

  /// No description provided for @genreRock.
  ///
  /// In ko, this message translates to:
  /// **'록'**
  String get genreRock;

  /// No description provided for @genreJazz.
  ///
  /// In ko, this message translates to:
  /// **'재즈'**
  String get genreJazz;

  /// No description provided for @genreClassical.
  ///
  /// In ko, this message translates to:
  /// **'클래식'**
  String get genreClassical;

  /// No description provided for @genreDance.
  ///
  /// In ko, this message translates to:
  /// **'댄스·일렉'**
  String get genreDance;

  /// No description provided for @genreHiphop.
  ///
  /// In ko, this message translates to:
  /// **'힙합'**
  String get genreHiphop;

  /// No description provided for @genreRnb.
  ///
  /// In ko, this message translates to:
  /// **'R&B·소울'**
  String get genreRnb;

  /// No description provided for @genreLatin.
  ///
  /// In ko, this message translates to:
  /// **'라틴'**
  String get genreLatin;

  /// No description provided for @genreCountry.
  ///
  /// In ko, this message translates to:
  /// **'컨트리'**
  String get genreCountry;

  /// No description provided for @genreOldies.
  ///
  /// In ko, this message translates to:
  /// **'올디스'**
  String get genreOldies;

  /// No description provided for @genreLounge.
  ///
  /// In ko, this message translates to:
  /// **'라운지'**
  String get genreLounge;

  /// No description provided for @genreFolk.
  ///
  /// In ko, this message translates to:
  /// **'포크'**
  String get genreFolk;

  /// No description provided for @genreBlues.
  ///
  /// In ko, this message translates to:
  /// **'블루스'**
  String get genreBlues;

  /// No description provided for @genreReggae.
  ///
  /// In ko, this message translates to:
  /// **'레게'**
  String get genreReggae;

  /// No description provided for @genreMetal.
  ///
  /// In ko, this message translates to:
  /// **'메탈'**
  String get genreMetal;

  /// No description provided for @genreReligious.
  ///
  /// In ko, this message translates to:
  /// **'종교'**
  String get genreReligious;

  /// No description provided for @genreKids.
  ///
  /// In ko, this message translates to:
  /// **'어린이'**
  String get genreKids;

  /// No description provided for @genreBollywood.
  ///
  /// In ko, this message translates to:
  /// **'볼리우드'**
  String get genreBollywood;

  /// No description provided for @genreSertanejo.
  ///
  /// In ko, this message translates to:
  /// **'세르타네주'**
  String get genreSertanejo;

  /// No description provided for @noRegionStations.
  ///
  /// In ko, this message translates to:
  /// **'지역 정보가 있는 방송국이 없어요'**
  String get noRegionStations;

  /// No description provided for @favAddHint.
  ///
  /// In ko, this message translates to:
  /// **'하트를 눌러 즐겨찾기에 추가해보세요'**
  String get favAddHint;

  /// No description provided for @noRecentStations.
  ///
  /// In ko, this message translates to:
  /// **'최근 들은 방송이 없어요'**
  String get noRecentStations;

  /// No description provided for @loadingMoreStations.
  ///
  /// In ko, this message translates to:
  /// **'방송을 더 불러오는 중'**
  String get loadingMoreStations;

  /// No description provided for @nowPlayingSong.
  ///
  /// In ko, this message translates to:
  /// **'지금 나오는 곡'**
  String get nowPlayingSong;

  /// No description provided for @noSongInfoYet.
  ///
  /// In ko, this message translates to:
  /// **'곡 정보가 아직 없어요'**
  String get noSongInfoYet;

  /// No description provided for @trendingSort.
  ///
  /// In ko, this message translates to:
  /// **'요즘 듣는 사람이 늘어난 순'**
  String get trendingSort;

  /// No description provided for @heroDicePick.
  ///
  /// In ko, this message translates to:
  /// **'주사위가 고른 방송'**
  String get heroDicePick;

  /// No description provided for @heroRecent.
  ///
  /// In ko, this message translates to:
  /// **'최근 들은 방송'**
  String get heroRecent;

  /// No description provided for @slotMorning.
  ///
  /// In ko, this message translates to:
  /// **'아침'**
  String get slotMorning;

  /// No description provided for @slotDay.
  ///
  /// In ko, this message translates to:
  /// **'낮'**
  String get slotDay;

  /// No description provided for @slotEvening.
  ///
  /// In ko, this message translates to:
  /// **'저녁'**
  String get slotEvening;

  /// No description provided for @slotNight.
  ///
  /// In ko, this message translates to:
  /// **'밤'**
  String get slotNight;

  /// No description provided for @heroTopN.
  ///
  /// In ko, this message translates to:
  /// **'인기 {n}위'**
  String heroTopN(int n);

  /// No description provided for @heroNowIn.
  ///
  /// In ko, this message translates to:
  /// **'지금 {country} {slot} · {why}'**
  String heroNowIn(String country, String slot, String why);

  /// No description provided for @stationsPopular.
  ///
  /// In ko, this message translates to:
  /// **'방송 {n}개 · 인기순'**
  String stationsPopular(String n);

  /// No description provided for @countStr.
  ///
  /// In ko, this message translates to:
  /// **'{n}개'**
  String countStr(String n);

  /// No description provided for @channelsCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 채널'**
  String channelsCount(int count);

  /// No description provided for @localTime.
  ///
  /// In ko, this message translates to:
  /// **'현지 {time}'**
  String localTime(String time);

  /// No description provided for @niceNow.
  ///
  /// In ko, this message translates to:
  /// **'지금 듣기 좋은'**
  String get niceNow;

  /// No description provided for @tryRolling.
  ///
  /// In ko, this message translates to:
  /// **'던져보세요!'**
  String get tryRolling;

  /// No description provided for @byBroadcaster.
  ///
  /// In ko, this message translates to:
  /// **'방송사별'**
  String get byBroadcaster;

  /// No description provided for @byRegion.
  ///
  /// In ko, this message translates to:
  /// **'지역별'**
  String get byRegion;

  /// No description provided for @selectCountryShort.
  ///
  /// In ko, this message translates to:
  /// **'국가선택'**
  String get selectCountryShort;

  /// No description provided for @stationLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'방송을 불러올 수 없습니다.\n다른 채널을 선택해 주세요.'**
  String get stationLoadFailed;

  /// No description provided for @soundPlayFailed.
  ///
  /// In ko, this message translates to:
  /// **'소리를 재생하지 못했어요'**
  String get soundPlayFailed;

  /// No description provided for @natureTitle1.
  ///
  /// In ko, this message translates to:
  /// **'자연'**
  String get natureTitle1;

  /// No description provided for @natureTitle2.
  ///
  /// In ko, this message translates to:
  /// **' 휴식'**
  String get natureTitle2;

  /// No description provided for @natureSub.
  ///
  /// In ko, this message translates to:
  /// **'마음이 편안해지는 소리를 들어보세요'**
  String get natureSub;

  /// No description provided for @versionsCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}가지 버전'**
  String versionsCount(int count);

  /// No description provided for @pickVersion.
  ///
  /// In ko, this message translates to:
  /// **'{name} 버전 고르기'**
  String pickVersion(String name);

  /// No description provided for @natureShareText.
  ///
  /// In ko, this message translates to:
  /// **'파란소리 자연소리로 편안한 시간 보내요 🌊'**
  String get natureShareText;

  /// No description provided for @mixShort.
  ///
  /// In ko, this message translates to:
  /// **'믹스'**
  String get mixShort;

  /// No description provided for @pickSongs.
  ///
  /// In ko, this message translates to:
  /// **'노래 선택'**
  String get pickSongs;

  /// No description provided for @searchTitleArtist.
  ///
  /// In ko, this message translates to:
  /// **'제목, 아티스트로 검색'**
  String get searchTitleArtist;

  /// No description provided for @noMyMusic.
  ///
  /// In ko, this message translates to:
  /// **'내 음악이 없어요'**
  String get noMyMusic;

  /// No description provided for @noSearchResults.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없어요'**
  String get noSearchResults;

  /// No description provided for @mixTitle1.
  ///
  /// In ko, this message translates to:
  /// **'나만의'**
  String get mixTitle1;

  /// No description provided for @mixTitle2.
  ///
  /// In ko, this message translates to:
  /// **' 소리'**
  String get mixTitle2;

  /// No description provided for @mixSub.
  ///
  /// In ko, this message translates to:
  /// **'나만의 힐링 사운드를 만들어보세요.'**
  String get mixSub;

  /// No description provided for @musicLabel.
  ///
  /// In ko, this message translates to:
  /// **'음악'**
  String get musicLabel;

  /// No description provided for @addShort.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get addShort;

  /// No description provided for @musicVolume.
  ///
  /// In ko, this message translates to:
  /// **'음악 음량'**
  String get musicVolume;

  /// No description provided for @noSongsPicked.
  ///
  /// In ko, this message translates to:
  /// **'선택된 노래가 없어요'**
  String get noSongsPicked;

  /// No description provided for @nowPlayingMix.
  ///
  /// In ko, this message translates to:
  /// **'현재 재생 중'**
  String get nowPlayingMix;

  /// No description provided for @autoStopIn.
  ///
  /// In ko, this message translates to:
  /// **'{time} 후 자동 정지'**
  String autoStopIn(String time);

  /// No description provided for @setSleepTimer.
  ///
  /// In ko, this message translates to:
  /// **'수면 타이머 설정'**
  String get setSleepTimer;

  /// No description provided for @stopMix.
  ///
  /// In ko, this message translates to:
  /// **'믹스 정지하기'**
  String get stopMix;

  /// No description provided for @playMix.
  ///
  /// In ko, this message translates to:
  /// **'믹스 재생하기'**
  String get playMix;

  /// No description provided for @myMixDefault.
  ///
  /// In ko, this message translates to:
  /// **'나만의 소리 믹스'**
  String get myMixDefault;

  /// No description provided for @paransoriMix.
  ///
  /// In ko, this message translates to:
  /// **'파란소리 믹스'**
  String get paransoriMix;

  /// No description provided for @paransoriRadio.
  ///
  /// In ko, this message translates to:
  /// **'파란소리 라디오'**
  String get paransoriRadio;

  /// No description provided for @naturePlaying.
  ///
  /// In ko, this message translates to:
  /// **'{name} 재생 중'**
  String naturePlaying(String name);

  /// No description provided for @naturePaused.
  ///
  /// In ko, this message translates to:
  /// **'{name} 일시정지'**
  String naturePaused(String name);

  /// No description provided for @natureSounds.
  ///
  /// In ko, this message translates to:
  /// **'자연소리'**
  String get natureSounds;

  /// No description provided for @mixPlaying.
  ///
  /// In ko, this message translates to:
  /// **'믹스 재생 중'**
  String get mixPlaying;

  /// No description provided for @andNMore.
  ///
  /// In ko, this message translates to:
  /// **'{name} 외 {count}개'**
  String andNMore(String name, int count);

  /// No description provided for @withNature.
  ///
  /// In ko, this message translates to:
  /// **'{name}와 함께'**
  String withNature(String name);

  /// No description provided for @turnAllOff.
  ///
  /// In ko, this message translates to:
  /// **'모두 끄기'**
  String get turnAllOff;

  /// No description provided for @overlayOnHint.
  ///
  /// In ko, this message translates to:
  /// **'음악 위에 자연소리를 살짝 깔아 같이 들어요'**
  String get overlayOnHint;

  /// No description provided for @overlayIdleHint.
  ///
  /// In ko, this message translates to:
  /// **'음악이 재생될 때 같이 나와요'**
  String get overlayIdleHint;

  /// No description provided for @lastMix.
  ///
  /// In ko, this message translates to:
  /// **'지난번 섞기'**
  String get lastMix;

  /// No description provided for @turnBackOn.
  ///
  /// In ko, this message translates to:
  /// **'다시 켜기'**
  String get turnBackOn;

  /// No description provided for @pickType.
  ///
  /// In ko, this message translates to:
  /// **'종류 고르기'**
  String get pickType;

  /// No description provided for @favoritesTitle.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기'**
  String get favoritesTitle;

  /// No description provided for @tabWithCount.
  ///
  /// In ko, this message translates to:
  /// **'{name}({count})'**
  String tabWithCount(String name, int count);

  /// No description provided for @noFavRadio.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾는 라디오가 없어요'**
  String get noFavRadio;

  /// No description provided for @noFavNature.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾는 자연소리가 없어요'**
  String get noFavNature;

  /// No description provided for @restFocusSoon.
  ///
  /// In ko, this message translates to:
  /// **'휴식 · 집중 기능은 준비중이에요'**
  String get restFocusSoon;

  /// No description provided for @restLabel.
  ///
  /// In ko, this message translates to:
  /// **'휴식'**
  String get restLabel;

  /// No description provided for @focusLabel.
  ///
  /// In ko, this message translates to:
  /// **'집중'**
  String get focusLabel;

  /// No description provided for @focusTitlePart.
  ///
  /// In ko, this message translates to:
  /// **' · 집중'**
  String get focusTitlePart;

  /// No description provided for @whiteNoise.
  ///
  /// In ko, this message translates to:
  /// **'백색소음'**
  String get whiteNoise;

  /// No description provided for @restFocusSub.
  ///
  /// In ko, this message translates to:
  /// **'편안한 소리로 쉬고, 마음을 모아 집중해 보세요'**
  String get restFocusSub;

  /// No description provided for @comingSoonTitle.
  ///
  /// In ko, this message translates to:
  /// **'준비중입니다'**
  String get comingSoonTitle;

  /// No description provided for @comingSoonCategory.
  ///
  /// In ko, this message translates to:
  /// **'{name} 콘텐츠를 곧 만나보실 수 있어요'**
  String comingSoonCategory(String name);

  /// No description provided for @widgetIdle.
  ///
  /// In ko, this message translates to:
  /// **'음악 · 라디오 · 자연을 들어보세요'**
  String get widgetIdle;

  /// No description provided for @zoomDefault.
  ///
  /// In ko, this message translates to:
  /// **'기본'**
  String get zoomDefault;

  /// No description provided for @zoomLarge.
  ///
  /// In ko, this message translates to:
  /// **'크게'**
  String get zoomLarge;

  /// No description provided for @zoomXLarge.
  ///
  /// In ko, this message translates to:
  /// **'아주 크게'**
  String get zoomXLarge;

  /// No description provided for @secDecorate.
  ///
  /// In ko, this message translates to:
  /// **'꾸미기'**
  String get secDecorate;

  /// No description provided for @descPlayerStyle.
  ///
  /// In ko, this message translates to:
  /// **'원하는 재생 화면을 선택하세요'**
  String get descPlayerStyle;

  /// No description provided for @descFont.
  ///
  /// In ko, this message translates to:
  /// **'원하는 글꼴을 선택하세요'**
  String get descFont;

  /// No description provided for @descTextSize.
  ///
  /// In ko, this message translates to:
  /// **'글자 크기를 조절하세요'**
  String get descTextSize;

  /// No description provided for @cardsReopened.
  ///
  /// In ko, this message translates to:
  /// **'카드를 다시 켰어요'**
  String get cardsReopened;

  /// No description provided for @allClosedToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘은 모두 닫았어요 · '**
  String get allClosedToday;

  /// No description provided for @showAgain.
  ///
  /// In ko, this message translates to:
  /// **'다시 보기 ›'**
  String get showAgain;

  /// No description provided for @mainCardTitle.
  ///
  /// In ko, this message translates to:
  /// **'메인 알림 카드'**
  String get mainCardTitle;

  /// No description provided for @mainCardDesc.
  ///
  /// In ko, this message translates to:
  /// **'메인 화면 맨 위에 방송 추천·팁을 보여줘요'**
  String get mainCardDesc;

  /// No description provided for @homeCardTitle.
  ///
  /// In ko, this message translates to:
  /// **'홈 추천 카드'**
  String get homeCardTitle;

  /// No description provided for @homeCardInfoTitle.
  ///
  /// In ko, this message translates to:
  /// **'홈 추천 카드에 나오는 것'**
  String get homeCardInfoTitle;

  /// No description provided for @homeCardInfoFoot.
  ///
  /// In ko, this message translates to:
  /// **'날마다 바뀌고, 정리할 곡이 있으면 정리 카드가 먼저 나와요'**
  String get homeCardInfoFoot;

  /// No description provided for @homeCardDesc.
  ///
  /// In ko, this message translates to:
  /// **'홈 화면에 새로운 추천을 보여줘요'**
  String get homeCardDesc;

  /// No description provided for @secMusicManage.
  ///
  /// In ko, this message translates to:
  /// **'음악 관리'**
  String get secMusicManage;

  /// No description provided for @descClean.
  ///
  /// In ko, this message translates to:
  /// **'곡 제목과 가수 정보를 정리하세요'**
  String get descClean;

  /// No description provided for @descArt.
  ///
  /// In ko, this message translates to:
  /// **'없는 앨범 사진을 찾아 추가해요'**
  String get descArt;

  /// No description provided for @secTools.
  ///
  /// In ko, this message translates to:
  /// **'도구'**
  String get secTools;

  /// No description provided for @descEq.
  ///
  /// In ko, this message translates to:
  /// **'취향에 맞게 음질을 조절하세요'**
  String get descEq;

  /// No description provided for @loudnessTitle.
  ///
  /// In ko, this message translates to:
  /// **'음량 자동 조절'**
  String get loudnessTitle;

  /// No description provided for @loudnessDesc.
  ///
  /// In ko, this message translates to:
  /// **'곡마다 다른 음량을 고르게 맞춰요'**
  String get loudnessDesc;

  /// No description provided for @headsetTitle.
  ///
  /// In ko, this message translates to:
  /// **'이어폰 자동 재생'**
  String get headsetTitle;

  /// No description provided for @headsetDesc.
  ///
  /// In ko, this message translates to:
  /// **'이어폰 연결 시 음악을 이어서 재생해요'**
  String get headsetDesc;

  /// No description provided for @descRingtone.
  ///
  /// In ko, this message translates to:
  /// **'좋아하는 음악을 벨소리로 설정하세요'**
  String get descRingtone;

  /// No description provided for @descFlashlight.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰 플래시를 켜고 끄세요'**
  String get descFlashlight;

  /// No description provided for @descSos.
  ///
  /// In ko, this message translates to:
  /// **'플래시로 긴급 구조 신호를 보내요'**
  String get descSos;

  /// No description provided for @descWidget.
  ///
  /// In ko, this message translates to:
  /// **'홈 화면에서 음악을 간편하게 제어하세요'**
  String get descWidget;

  /// No description provided for @secOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get secOther;

  /// No description provided for @descHelp.
  ///
  /// In ko, this message translates to:
  /// **'권한, 배터리 및 알림 설정을 안내해요'**
  String get descHelp;

  /// No description provided for @heroNoAd.
  ///
  /// In ko, this message translates to:
  /// **'광고 없는 음악, 편안한 일상'**
  String get heroNoAd;

  /// No description provided for @heroDefault.
  ///
  /// In ko, this message translates to:
  /// **'음악 · 라디오 · 자연'**
  String get heroDefault;

  /// No description provided for @inUse.
  ///
  /// In ko, this message translates to:
  /// **'사용 중'**
  String get inUse;

  /// No description provided for @darkModeInfo.
  ///
  /// In ko, this message translates to:
  /// **'화면을 어둡게 바꿔요. 밤에 눈이 편해요.'**
  String get darkModeInfo;

  /// No description provided for @soundEffect.
  ///
  /// In ko, this message translates to:
  /// **'효과음'**
  String get soundEffect;

  /// No description provided for @soundEffectInfo.
  ///
  /// In ko, this message translates to:
  /// **'수정·저장·삭제가 끝나면 물방울 소리로 알려줘요. 진동 모드면 진동, 무음이면 조용해요.'**
  String get soundEffectInfo;

  /// No description provided for @voiceGuide.
  ///
  /// In ko, this message translates to:
  /// **'음성 안내'**
  String get voiceGuide;

  /// No description provided for @voiceGuideInfo.
  ///
  /// In ko, this message translates to:
  /// **'앱을 켜고 끌 때 짧은 인사말이 나와요.'**
  String get voiceGuideInfo;

  /// No description provided for @infoTodaySong.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 한 곡'**
  String get infoTodaySong;

  /// No description provided for @infoTodaySongD.
  ///
  /// In ko, this message translates to:
  /// **'내 음악 중에서 날마다 한 곡을 골라 줘요'**
  String get infoTodaySongD;

  /// No description provided for @infoLongTime.
  ///
  /// In ko, this message translates to:
  /// **'오랜만에 듣기'**
  String get infoLongTime;

  /// No description provided for @infoLongTimeD.
  ///
  /// In ko, this message translates to:
  /// **'한 달 동안 안 들은 곡을 섞어서 틀어요'**
  String get infoLongTimeD;

  /// No description provided for @infoWeek.
  ///
  /// In ko, this message translates to:
  /// **'이번 주 기록'**
  String get infoWeek;

  /// No description provided for @infoWeekD.
  ///
  /// In ko, this message translates to:
  /// **'7일 동안 들은 횟수와 가장 많이 들은 곡'**
  String get infoWeekD;

  /// No description provided for @infoTime.
  ///
  /// In ko, this message translates to:
  /// **'시간대 추천'**
  String get infoTime;

  /// No description provided for @infoTimeD.
  ///
  /// In ko, this message translates to:
  /// **'아침·낮·저녁·밤에 어울리는 자연소리'**
  String get infoTimeD;

  /// No description provided for @infoTips.
  ///
  /// In ko, this message translates to:
  /// **'알아두면 좋은 기능'**
  String get infoTips;

  /// No description provided for @infoTipsD.
  ///
  /// In ko, this message translates to:
  /// **'벨소리 만들기, 빗소리 섞기 같은 팁'**
  String get infoTipsD;

  /// No description provided for @infoAlarm.
  ///
  /// In ko, this message translates to:
  /// **'내일 알람'**
  String get infoAlarm;

  /// No description provided for @infoAlarmD.
  ///
  /// In ko, this message translates to:
  /// **'알람을 켜 두면 저녁 7시부터 내일 깨울 시간'**
  String get infoAlarmD;

  /// No description provided for @pcMusic.
  ///
  /// In ko, this message translates to:
  /// **'음악'**
  String get pcMusic;

  /// No description provided for @pcMusicD.
  ///
  /// In ko, this message translates to:
  /// **'재생 중인 곡 표시, 오른쪽 초성 글자'**
  String get pcMusicD;

  /// No description provided for @pcPlayer.
  ///
  /// In ko, this message translates to:
  /// **'재생 화면'**
  String get pcPlayer;

  /// No description provided for @pcPlayerD.
  ///
  /// In ko, this message translates to:
  /// **'진행 막대, 시디롬 빛 번짐'**
  String get pcPlayerD;

  /// No description provided for @pcLyrics.
  ///
  /// In ko, this message translates to:
  /// **'가사'**
  String get pcLyrics;

  /// No description provided for @pcLyricsD.
  ///
  /// In ko, this message translates to:
  /// **'지금 부르는 줄, 진행 막대'**
  String get pcLyricsD;

  /// No description provided for @pcRadio.
  ///
  /// In ko, this message translates to:
  /// **'라디오'**
  String get pcRadio;

  /// No description provided for @pcRadioD.
  ///
  /// In ko, this message translates to:
  /// **'주파수 바늘·눈금, 재생 중 표시'**
  String get pcRadioD;

  /// No description provided for @pcNature.
  ///
  /// In ko, this message translates to:
  /// **'자연·믹스'**
  String get pcNature;

  /// No description provided for @pcNatureD.
  ///
  /// In ko, this message translates to:
  /// **'소리 막대, 선택 표시, 수면 타이머'**
  String get pcNatureD;

  /// No description provided for @pcVideo.
  ///
  /// In ko, this message translates to:
  /// **'동영상'**
  String get pcVideo;

  /// No description provided for @pcVideoD.
  ///
  /// In ko, this message translates to:
  /// **'진행 표시, 반복·체크 표시'**
  String get pcVideoD;

  /// No description provided for @pcEtc.
  ///
  /// In ko, this message translates to:
  /// **'그 밖에'**
  String get pcEtc;

  /// No description provided for @pcEtcD.
  ///
  /// In ko, this message translates to:
  /// **'스위치, 체크, 알림, 이퀄라이저, 알람'**
  String get pcEtcD;

  /// No description provided for @accentWhere.
  ///
  /// In ko, this message translates to:
  /// **'강조 색상이 바뀌는 곳'**
  String get accentWhere;

  /// No description provided for @accentFoot.
  ///
  /// In ko, this message translates to:
  /// **'큰 버튼과 앱 아이콘은 바뀌지 않아요'**
  String get accentFoot;

  /// No description provided for @accentDesc.
  ///
  /// In ko, this message translates to:
  /// **'스위치와 표시 색상을 변경해요'**
  String get accentDesc;

  /// No description provided for @adsRemoved.
  ///
  /// In ko, this message translates to:
  /// **'광고가 제거됐어요'**
  String get adsRemoved;

  /// No description provided for @adFreeTitle.
  ///
  /// In ko, this message translates to:
  /// **'광고 없이\n듣고 계세요'**
  String get adFreeTitle;

  /// No description provided for @promoKeeps.
  ///
  /// In ko, this message translates to:
  /// **'프로모션 코드 혜택이 계속 적용돼요'**
  String get promoKeeps;

  /// No description provided for @enterCode.
  ///
  /// In ko, this message translates to:
  /// **'코드 입력'**
  String get enterCode;

  /// No description provided for @batteryAskHeadset.
  ///
  /// In ko, this message translates to:
  /// **'폰이 오래 쉬고 있을 때도 이어폰 연결을 바로 알아차리려면 배터리 사용을 \"제한 없음\"으로 해 주세요.\n허용 안 해도 쓸 수 있지만, 가끔 늦거나 안 될 수 있어요.'**
  String get batteryAskHeadset;

  /// No description provided for @headsetNote.
  ///
  /// In ko, this message translates to:
  /// **'듣다가 멈춘 곡·라디오·자연을 아주 작게 시작해서 천천히 키워요.\n앱을 완전히 끄면 동작하지 않아요.'**
  String get headsetNote;

  /// No description provided for @accentSheetHint.
  ///
  /// In ko, this message translates to:
  /// **'체크·스위치·막대 같은 작은 곳의 색이 바뀌어요'**
  String get accentSheetHint;

  /// No description provided for @sizeTiny.
  ///
  /// In ko, this message translates to:
  /// **'아주 작게'**
  String get sizeTiny;

  /// No description provided for @sizeHuge.
  ///
  /// In ko, this message translates to:
  /// **'아주 크게'**
  String get sizeHuge;

  /// No description provided for @headsetOff.
  ///
  /// In ko, this message translates to:
  /// **'끄기'**
  String get headsetOff;

  /// No description provided for @headsetAsk.
  ///
  /// In ko, this message translates to:
  /// **'알림으로 묻기'**
  String get headsetAsk;

  /// No description provided for @headsetPlay.
  ///
  /// In ko, this message translates to:
  /// **'바로 재생'**
  String get headsetPlay;

  /// No description provided for @batteryTitle.
  ///
  /// In ko, this message translates to:
  /// **'배터리 사용을 \"제한 없음\"으로'**
  String get batteryTitle;

  /// No description provided for @allowAction.
  ///
  /// In ko, this message translates to:
  /// **'허용하기'**
  String get allowAction;

  /// No description provided for @resumeAsk.
  ///
  /// In ko, this message translates to:
  /// **'이어서 들을까요?'**
  String get resumeAsk;

  /// No description provided for @helpMediaTitle.
  ///
  /// In ko, this message translates to:
  /// **'음악·동영상 불러오기'**
  String get helpMediaTitle;

  /// No description provided for @helpMediaWhen.
  ///
  /// In ko, this message translates to:
  /// **'음악이나 동영상이 목록에 나타나지 않을 때'**
  String get helpMediaWhen;

  /// No description provided for @helpStepOpen.
  ///
  /// In ko, this message translates to:
  /// **'[설정 열기] 선택'**
  String get helpStepOpen;

  /// No description provided for @helpStepPerm.
  ///
  /// In ko, this message translates to:
  /// **'[권한] 선택'**
  String get helpStepPerm;

  /// No description provided for @helpStepMediaAllow.
  ///
  /// In ko, this message translates to:
  /// **'[음악 및 오디오]와 [사진 및 동영상] 허용'**
  String get helpStepMediaAllow;

  /// No description provided for @helpStepIosMedia.
  ///
  /// In ko, this message translates to:
  /// **'[미디어 및 Apple Music]과 [사진] 켜기'**
  String get helpStepIosMedia;

  /// No description provided for @helpStepBack.
  ///
  /// In ko, this message translates to:
  /// **'앱으로 돌아오기'**
  String get helpStepBack;

  /// No description provided for @helpMediaNote.
  ///
  /// In ko, this message translates to:
  /// **'허용한 뒤 앱으로 돌아오면 목록이 바로 나타나요.'**
  String get helpMediaNote;

  /// No description provided for @helpMediaPath.
  ///
  /// In ko, this message translates to:
  /// **'설정 → 애플리케이션 → 파란소리 → 권한 → 음악 및 오디오 / 사진 및 동영상'**
  String get helpMediaPath;

  /// No description provided for @helpMediaIosPath.
  ///
  /// In ko, this message translates to:
  /// **'설정 → 파란소리 → 미디어 및 Apple Music · 사진'**
  String get helpMediaIosPath;

  /// No description provided for @helpBgTitle.
  ///
  /// In ko, this message translates to:
  /// **'백그라운드 재생'**
  String get helpBgTitle;

  /// No description provided for @helpBgWhen.
  ///
  /// In ko, this message translates to:
  /// **'화면을 껐을 때 음악이 멈추는 경우'**
  String get helpBgWhen;

  /// No description provided for @helpStepBattery.
  ///
  /// In ko, this message translates to:
  /// **'[배터리] 선택'**
  String get helpStepBattery;

  /// No description provided for @helpStepUnrestricted.
  ///
  /// In ko, this message translates to:
  /// **'[제한 없음] 선택'**
  String get helpStepUnrestricted;

  /// No description provided for @helpBgNote.
  ///
  /// In ko, this message translates to:
  /// **'화면을 꺼도 음악과 라디오가 끊기지 않도록 도와줘요.\n휴대폰에 따라 \"최적화 안 함\" 등 다른 이름으로 표시될 수 있어요.'**
  String get helpBgNote;

  /// No description provided for @helpBgPath.
  ///
  /// In ko, this message translates to:
  /// **'설정 → 애플리케이션 → 파란소리 → 배터리 → 제한 없음'**
  String get helpBgPath;

  /// No description provided for @helpAlarmTitle.
  ///
  /// In ko, this message translates to:
  /// **'아침 알람'**
  String get helpAlarmTitle;

  /// No description provided for @helpAlarmWhen.
  ///
  /// In ko, this message translates to:
  /// **'알람이 울리지 않거나 지연되는 경우'**
  String get helpAlarmWhen;

  /// No description provided for @helpStepAlarmAllow.
  ///
  /// In ko, this message translates to:
  /// **'[알람 및 리마인더] 허용'**
  String get helpStepAlarmAllow;

  /// No description provided for @helpAlarmNote.
  ///
  /// In ko, this message translates to:
  /// **'\"백그라운드 재생\"의 배터리 설정도 함께 해 두면 알람이 더 정확하게 울려요.'**
  String get helpAlarmNote;

  /// No description provided for @helpAlarmPath.
  ///
  /// In ko, this message translates to:
  /// **'설정 → 애플리케이션 → 파란소리 → 알람 및 리마인더 → 허용'**
  String get helpAlarmPath;

  /// No description provided for @helpLockTitle.
  ///
  /// In ko, this message translates to:
  /// **'잠금 화면 재생 버튼'**
  String get helpLockTitle;

  /// No description provided for @helpLockWhen.
  ///
  /// In ko, this message translates to:
  /// **'잠금 화면이나 알림창에 재생 버튼이 표시되지 않을 때'**
  String get helpLockWhen;

  /// No description provided for @helpStepNotif.
  ///
  /// In ko, this message translates to:
  /// **'[알림] 선택'**
  String get helpStepNotif;

  /// No description provided for @helpStepNotifAllow.
  ///
  /// In ko, this message translates to:
  /// **'[알림 허용] 켜기'**
  String get helpStepNotifAllow;

  /// No description provided for @helpLockNote.
  ///
  /// In ko, this message translates to:
  /// **'알림을 허용해야 잠금 화면과 알림창에 재생 버튼이 표시돼요.'**
  String get helpLockNote;

  /// No description provided for @helpLockPath.
  ///
  /// In ko, this message translates to:
  /// **'설정 → 애플리케이션 → 파란소리 → 알림 → 알림 허용'**
  String get helpLockPath;

  /// No description provided for @helpLockIosPath.
  ///
  /// In ko, this message translates to:
  /// **'설정 → 파란소리 → 알림 → 알림 허용'**
  String get helpLockIosPath;

  /// No description provided for @helpRingTitle.
  ///
  /// In ko, this message translates to:
  /// **'벨소리 설정'**
  String get helpRingTitle;

  /// No description provided for @helpRingWhen.
  ///
  /// In ko, this message translates to:
  /// **'벨소리나 알림음을 설정할 수 없을 때'**
  String get helpRingWhen;

  /// No description provided for @helpStepModify.
  ///
  /// In ko, this message translates to:
  /// **'[시스템 설정 변경] 선택'**
  String get helpStepModify;

  /// No description provided for @helpStepAllowOn.
  ///
  /// In ko, this message translates to:
  /// **'[허용] 켜기'**
  String get helpStepAllowOn;

  /// No description provided for @helpRingNote.
  ///
  /// In ko, this message translates to:
  /// **'허용한 뒤 벨소리 설정을 다시 시도해 보세요.'**
  String get helpRingNote;

  /// No description provided for @helpRingPath.
  ///
  /// In ko, this message translates to:
  /// **'설정 → 애플리케이션 → 파란소리 → 시스템 설정 변경 → 허용'**
  String get helpRingPath;

  /// No description provided for @helpCantOpen.
  ///
  /// In ko, this message translates to:
  /// **'설정 화면을 열 수 없어요. 아래 \"직접 설정하기\" 순서대로 이동해 주세요'**
  String get helpCantOpen;

  /// No description provided for @mailBodyAsk.
  ///
  /// In ko, this message translates to:
  /// **'어떤 문제가 있나요?\n(여기에 적어 주세요)'**
  String get mailBodyAsk;

  /// No description provided for @mailBodyAuto.
  ///
  /// In ko, this message translates to:
  /// **'── 아래는 자동으로 들어가요 ──'**
  String get mailBodyAuto;

  /// No description provided for @mailModel.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰 모델'**
  String get mailModel;

  /// No description provided for @mailSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템'**
  String get mailSystem;

  /// No description provided for @mailAndroid.
  ///
  /// In ko, this message translates to:
  /// **'안드로이드'**
  String get mailAndroid;

  /// No description provided for @mailAppVersion.
  ///
  /// In ko, this message translates to:
  /// **'앱 버전'**
  String get mailAppVersion;

  /// No description provided for @mailSubject.
  ///
  /// In ko, this message translates to:
  /// **'[파란소리 문의]'**
  String get mailSubject;

  /// No description provided for @mailCopied.
  ///
  /// In ko, this message translates to:
  /// **'메일 앱을 찾을 수 없어 주소를 복사했어요 ({mail})'**
  String mailCopied(String mail);

  /// No description provided for @helpIntro.
  ///
  /// In ko, this message translates to:
  /// **'앱 사용 중 문제가 발생하면 아래 안내를 확인하세요.'**
  String get helpIntro;

  /// No description provided for @setManually.
  ///
  /// In ko, this message translates to:
  /// **'직접 설정하기'**
  String get setManually;

  /// No description provided for @openSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정 열기'**
  String get openSettings;

  /// No description provided for @needMoreHelp.
  ///
  /// In ko, this message translates to:
  /// **'추가 도움이 필요하신가요?'**
  String get needMoreHelp;

  /// No description provided for @tellUsModel.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰 모델과 문제 상황을 알려주세요.'**
  String get tellUsModel;

  /// No description provided for @emailUs.
  ///
  /// In ko, this message translates to:
  /// **'이메일 문의'**
  String get emailUs;

  /// No description provided for @alarmMusicAll.
  ///
  /// In ko, this message translates to:
  /// **'음악 전체 랜덤'**
  String get alarmMusicAll;

  /// No description provided for @alarmMusicFav.
  ///
  /// In ko, this message translates to:
  /// **'음악 즐겨찾기 랜덤'**
  String get alarmMusicFav;

  /// No description provided for @weekdayFull.
  ///
  /// In ko, this message translates to:
  /// **'{wd}요일'**
  String weekdayFull(String wd);

  /// No description provided for @tomorrow.
  ///
  /// In ko, this message translates to:
  /// **'내일'**
  String get tomorrow;

  /// No description provided for @alarmNextLabel.
  ///
  /// In ko, this message translates to:
  /// **'{day} {time}'**
  String alarmNextLabel(String day, String time);

  /// No description provided for @alarmOnce.
  ///
  /// In ko, this message translates to:
  /// **'한 번만'**
  String get alarmOnce;

  /// No description provided for @alarmEveryday.
  ///
  /// In ko, this message translates to:
  /// **'매일'**
  String get alarmEveryday;

  /// No description provided for @alarmWeekdays.
  ///
  /// In ko, this message translates to:
  /// **'평일'**
  String get alarmWeekdays;

  /// No description provided for @alarmWeekend.
  ///
  /// In ko, this message translates to:
  /// **'주말'**
  String get alarmWeekend;

  /// No description provided for @goodMorning.
  ///
  /// In ko, this message translates to:
  /// **'좋은 아침이에요'**
  String get goodMorning;

  /// No description provided for @alarmTime.
  ///
  /// In ko, this message translates to:
  /// **'알람 시간이에요'**
  String get alarmTime;

  /// No description provided for @ringDate.
  ///
  /// In ko, this message translates to:
  /// **'{month}월 {day}일 {weekday}요일'**
  String ringDate(String month, String day, String weekday);

  /// No description provided for @snooze5.
  ///
  /// In ko, this message translates to:
  /// **'5분 뒤 다시'**
  String get snooze5;

  /// No description provided for @alarmOffKeep.
  ///
  /// In ko, this message translates to:
  /// **'알람 끄고 계속 듣기'**
  String get alarmOffKeep;

  /// No description provided for @alarmNeedExact.
  ///
  /// In ko, this message translates to:
  /// **'알람 및 리마인더를 허용해야 울릴 수 있어요'**
  String get alarmNeedExact;

  /// No description provided for @noSongsOnPhone.
  ///
  /// In ko, this message translates to:
  /// **'폰에 있는 노래가 없어요'**
  String get noSongsOnPhone;

  /// No description provided for @pickAlarmSong.
  ///
  /// In ko, this message translates to:
  /// **'알람 곡 고르기'**
  String get pickAlarmSong;

  /// No description provided for @searchTitleOrArtist.
  ///
  /// In ko, this message translates to:
  /// **'제목이나 가수로 찾기'**
  String get searchTitleOrArtist;

  /// No description provided for @makePlaylistFirst.
  ///
  /// In ko, this message translates to:
  /// **'재생목록을 먼저 만들어 주세요'**
  String get makePlaylistFirst;

  /// No description provided for @pickPlaylist.
  ///
  /// In ko, this message translates to:
  /// **'재생목록 고르기'**
  String get pickPlaylist;

  /// No description provided for @addFavStationFirst.
  ///
  /// In ko, this message translates to:
  /// **'라디오 즐겨찾기에 채널을 먼저 담아 주세요'**
  String get addFavStationFirst;

  /// No description provided for @pickRadioChannel.
  ///
  /// In ko, this message translates to:
  /// **'라디오 채널 고르기'**
  String get pickRadioChannel;

  /// No description provided for @pickNatureSound.
  ///
  /// In ko, this message translates to:
  /// **'자연 소리 고르기'**
  String get pickNatureSound;

  /// No description provided for @alarmPermTitle.
  ///
  /// In ko, this message translates to:
  /// **'알람 권한이 필요해요'**
  String get alarmPermTitle;

  /// No description provided for @alarmPermMsg.
  ///
  /// In ko, this message translates to:
  /// **'정해진 시간에 깨우려면 \"알람 및 리마인더\"를 허용해 주세요. 허용하고 돌아오면 바로 저장돼요.'**
  String get alarmPermMsg;

  /// No description provided for @fullScreenTitle.
  ///
  /// In ko, this message translates to:
  /// **'잠금화면에 알람 화면 띄우기'**
  String get fullScreenTitle;

  /// No description provided for @fullScreenMsg.
  ///
  /// In ko, this message translates to:
  /// **'\"전체 화면 알림\"을 허용하면 잠금화면 위로 알람 화면이 바로 떠요. 허용 안 해도 알람 소리는 울려요.'**
  String get fullScreenMsg;

  /// No description provided for @alarmBatteryAsk.
  ///
  /// In ko, this message translates to:
  /// **'정해진 시간에 알람 곡을 틀려면 배터리 사용을 \"제한 없음\"으로 해 주는 게 좋아요.\n허용 안 해도 대부분 잘 울리지만, 일부 폰은 절전 때문에 늦을 수 있어요.'**
  String get alarmBatteryAsk;

  /// No description provided for @wakeYouAt.
  ///
  /// In ko, this message translates to:
  /// **'{time}에 깨워 드릴게요'**
  String wakeYouAt(String time);

  /// No description provided for @alarmOffDone.
  ///
  /// In ko, this message translates to:
  /// **'알람을 껐어요'**
  String get alarmOffDone;

  /// No description provided for @alarmLabel.
  ///
  /// In ko, this message translates to:
  /// **'알람'**
  String get alarmLabel;

  /// No description provided for @ringsAt.
  ///
  /// In ko, this message translates to:
  /// **'{time}에 울려요'**
  String ringsAt(String time);

  /// No description provided for @offNow.
  ///
  /// In ko, this message translates to:
  /// **'꺼져 있어요'**
  String get offNow;

  /// No description provided for @timeLabel.
  ///
  /// In ko, this message translates to:
  /// **'시간'**
  String get timeLabel;

  /// No description provided for @repeatLabel.
  ///
  /// In ko, this message translates to:
  /// **'반복'**
  String get repeatLabel;

  /// No description provided for @noDaysOnce.
  ///
  /// In ko, this message translates to:
  /// **'요일을 하나도 안 고르면 한 번만 울려요'**
  String get noDaysOnce;

  /// No description provided for @alarmSound.
  ///
  /// In ko, this message translates to:
  /// **'알람 소리'**
  String get alarmSound;

  /// No description provided for @oneSong.
  ///
  /// In ko, this message translates to:
  /// **'한 곡'**
  String get oneSong;

  /// No description provided for @oneSongSub.
  ///
  /// In ko, this message translates to:
  /// **'고른 노래 하나를 반복해서'**
  String get oneSongSub;

  /// No description provided for @favChannels.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기한 채널'**
  String get favChannels;

  /// No description provided for @natureExamples.
  ///
  /// In ko, this message translates to:
  /// **'새소리 · 시냇물 · 파도'**
  String get natureExamples;

  /// No description provided for @alarmFadeIn.
  ///
  /// In ko, this message translates to:
  /// **'작은 소리로 시작해서 30초 동안 천천히 커져요'**
  String get alarmFadeIn;

  /// No description provided for @alarmVolume.
  ///
  /// In ko, this message translates to:
  /// **'알람 소리 크기'**
  String get alarmVolume;

  /// No description provided for @alarmVolumeNote.
  ///
  /// In ko, this message translates to:
  /// **'폰 소리를 줄여 놔도 이 크기로 울리고, 끄면 원래대로 돌아가요'**
  String get alarmVolumeNote;

  /// No description provided for @changeAction.
  ///
  /// In ko, this message translates to:
  /// **'바꾸기'**
  String get changeAction;

  /// No description provided for @greetLine1.
  ///
  /// In ko, this message translates to:
  /// **'오늘도 좋은 소리와 함께해요'**
  String get greetLine1;

  /// No description provided for @greetLine2.
  ///
  /// In ko, this message translates to:
  /// **'반가워요, 잠시 쉬어가요'**
  String get greetLine2;

  /// No description provided for @greetLine3.
  ///
  /// In ko, this message translates to:
  /// **'편안한 하루 되세요'**
  String get greetLine3;

  /// No description provided for @greetLine4.
  ///
  /// In ko, this message translates to:
  /// **'오늘 하루도 반가워요'**
  String get greetLine4;

  /// No description provided for @greetLine5.
  ///
  /// In ko, this message translates to:
  /// **'마음이 쉬어가는 곳, 파란소리'**
  String get greetLine5;

  /// No description provided for @byeLine1.
  ///
  /// In ko, this message translates to:
  /// **'좋은 음악과 함께한 하루였어요'**
  String get byeLine1;

  /// No description provided for @byeLine2.
  ///
  /// In ko, this message translates to:
  /// **'오늘 하루도 수고했어요'**
  String get byeLine2;

  /// No description provided for @byeLine3.
  ///
  /// In ko, this message translates to:
  /// **'편안한 밤 되세요'**
  String get byeLine3;

  /// No description provided for @byeLine4.
  ///
  /// In ko, this message translates to:
  /// **'푹 자고 내일 만나요'**
  String get byeLine4;

  /// No description provided for @genreSortedToast.
  ///
  /// In ko, this message translates to:
  /// **'장르별로 정렬했어요'**
  String get genreSortedToast;

  /// No description provided for @genreShuffle.
  ///
  /// In ko, this message translates to:
  /// **'{label} {n}곡 섞어서 재생'**
  String genreShuffle(String label, int n);

  /// No description provided for @genrePickTitle.
  ///
  /// In ko, this message translates to:
  /// **'장르별 선택'**
  String get genrePickTitle;

  /// No description provided for @genreNone.
  ///
  /// In ko, this message translates to:
  /// **'장르 없음'**
  String get genreNone;

  /// No description provided for @genreTypeOwn.
  ///
  /// In ko, this message translates to:
  /// **'직접 쓰기'**
  String get genreTypeOwn;

  /// No description provided for @songGenreBallad.
  ///
  /// In ko, this message translates to:
  /// **'발라드'**
  String get songGenreBallad;

  /// No description provided for @songGenreDance.
  ///
  /// In ko, this message translates to:
  /// **'댄스'**
  String get songGenreDance;

  /// No description provided for @songGenrePop.
  ///
  /// In ko, this message translates to:
  /// **'팝'**
  String get songGenrePop;

  /// No description provided for @songGenreKpop.
  ///
  /// In ko, this message translates to:
  /// **'K-Pop'**
  String get songGenreKpop;

  /// No description provided for @songGenreJpop.
  ///
  /// In ko, this message translates to:
  /// **'J-Pop'**
  String get songGenreJpop;

  /// No description provided for @songGenreCpop.
  ///
  /// In ko, this message translates to:
  /// **'C-Pop'**
  String get songGenreCpop;

  /// No description provided for @songGenreRock.
  ///
  /// In ko, this message translates to:
  /// **'록'**
  String get songGenreRock;

  /// No description provided for @songGenreMetal.
  ///
  /// In ko, this message translates to:
  /// **'메탈'**
  String get songGenreMetal;

  /// No description provided for @songGenreHiphop.
  ///
  /// In ko, this message translates to:
  /// **'힙합'**
  String get songGenreHiphop;

  /// No description provided for @songGenreRnb.
  ///
  /// In ko, this message translates to:
  /// **'R&B'**
  String get songGenreRnb;

  /// No description provided for @songGenreJazz.
  ///
  /// In ko, this message translates to:
  /// **'재즈'**
  String get songGenreJazz;

  /// No description provided for @songGenreClassical.
  ///
  /// In ko, this message translates to:
  /// **'클래식'**
  String get songGenreClassical;

  /// No description provided for @songGenreOst.
  ///
  /// In ko, this message translates to:
  /// **'OST'**
  String get songGenreOst;

  /// No description provided for @songGenreTrot.
  ///
  /// In ko, this message translates to:
  /// **'트로트'**
  String get songGenreTrot;

  /// No description provided for @songGenreEnka.
  ///
  /// In ko, this message translates to:
  /// **'엔카'**
  String get songGenreEnka;

  /// No description provided for @songGenreIndie.
  ///
  /// In ko, this message translates to:
  /// **'인디'**
  String get songGenreIndie;

  /// No description provided for @songGenreElectronic.
  ///
  /// In ko, this message translates to:
  /// **'일렉트로닉'**
  String get songGenreElectronic;

  /// No description provided for @songGenreFolk.
  ///
  /// In ko, this message translates to:
  /// **'포크'**
  String get songGenreFolk;

  /// No description provided for @songGenreBlues.
  ///
  /// In ko, this message translates to:
  /// **'블루스'**
  String get songGenreBlues;

  /// No description provided for @songGenreCountry.
  ///
  /// In ko, this message translates to:
  /// **'컨트리'**
  String get songGenreCountry;

  /// No description provided for @songGenreReggae.
  ///
  /// In ko, this message translates to:
  /// **'레게'**
  String get songGenreReggae;

  /// No description provided for @songGenreNewage.
  ///
  /// In ko, this message translates to:
  /// **'뉴에이지'**
  String get songGenreNewage;

  /// No description provided for @songGenreAnime.
  ///
  /// In ko, this message translates to:
  /// **'애니메이션'**
  String get songGenreAnime;

  /// No description provided for @songGenreKids.
  ///
  /// In ko, this message translates to:
  /// **'동요'**
  String get songGenreKids;

  /// No description provided for @regionBrandLine.
  ///
  /// In ko, this message translates to:
  /// **'전국 {n}개 채널을\n한곳에서'**
  String regionBrandLine(int n);

  /// No description provided for @stationCatMajor.
  ///
  /// In ko, this message translates to:
  /// **'주요 방송'**
  String get stationCatMajor;

  /// No description provided for @stationCatMusicNews.
  ///
  /// In ko, this message translates to:
  /// **'음악·시사'**
  String get stationCatMusicNews;

  /// No description provided for @stationCatForeign.
  ///
  /// In ko, this message translates to:
  /// **'외국어'**
  String get stationCatForeign;

  /// No description provided for @stationCatReligion.
  ///
  /// In ko, this message translates to:
  /// **'종교 방송'**
  String get stationCatReligion;

  /// No description provided for @stationCatTraffic.
  ///
  /// In ko, this message translates to:
  /// **'교통 방송'**
  String get stationCatTraffic;

  /// No description provided for @stationCatRegional.
  ///
  /// In ko, this message translates to:
  /// **'지역 방송'**
  String get stationCatRegional;

  /// No description provided for @stationCatCommunity.
  ///
  /// In ko, this message translates to:
  /// **'공동체 라디오'**
  String get stationCatCommunity;

  /// No description provided for @stationCatPrivate.
  ///
  /// In ko, this message translates to:
  /// **'지역 민방'**
  String get stationCatPrivate;

  /// No description provided for @smsSheetTitle.
  ///
  /// In ko, this message translates to:
  /// **'문자로 사연 보내기'**
  String get smsSheetTitle;

  /// No description provided for @smsSheetDesc.
  ///
  /// In ko, this message translates to:
  /// **'이 번호로 문자를 보내면 방송에 사연이나 신청곡을 보낼 수 있어요.'**
  String get smsSheetDesc;

  /// No description provided for @smsSheetFee.
  ///
  /// In ko, this message translates to:
  /// **'짧은 문자 50원 · 긴 문자·사진 100원의 정보이용료가 붙어요.'**
  String get smsSheetFee;

  /// No description provided for @smsSheetSend.
  ///
  /// In ko, this message translates to:
  /// **'문자 보내기'**
  String get smsSheetSend;

  /// No description provided for @languageMenuDesc.
  ///
  /// In ko, this message translates to:
  /// **'앱 글자를 다른 언어로 볼 수 있어요.'**
  String get languageMenuDesc;

  /// No description provided for @languagePhone.
  ///
  /// In ko, this message translates to:
  /// **'폰 언어'**
  String get languagePhone;

  /// No description provided for @languageTagHant.
  ///
  /// In ko, this message translates to:
  /// **'번체'**
  String get languageTagHant;

  /// No description provided for @languageTagHans.
  ///
  /// In ko, this message translates to:
  /// **'간체'**
  String get languageTagHans;

  /// No description provided for @introTitle.
  ///
  /// In ko, this message translates to:
  /// **'파란소리'**
  String get introTitle;

  /// No description provided for @introTagline.
  ///
  /// In ko, this message translates to:
  /// **'Paransori — 일상에 맑음을 더하다.'**
  String get introTagline;

  /// No description provided for @introQuestion.
  ///
  /// In ko, this message translates to:
  /// **'소리에도 색이 있다면,\n어떤 색일까요?'**
  String get introQuestion;

  /// No description provided for @introPoem.
  ///
  /// In ko, this message translates to:
  /// **'파란 하늘처럼 맑고,\n시원한 바람처럼 상쾌하고,\n잔잔한 바다처럼 편안한 소리.'**
  String get introPoem;

  /// No description provided for @introStarted.
  ///
  /// In ko, this message translates to:
  /// **'파란소리는 그런 소리를 담고 싶은\n마음에서 시작되었습니다.'**
  String get introStarted;

  /// No description provided for @introNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'이름 이야기'**
  String get introNameLabel;

  /// No description provided for @introNameStory.
  ///
  /// In ko, this message translates to:
  /// **'\'파란소리\'라는 이름에는 맑은 하늘과 푸른 바다가 주는 청량함, 시원한 바람이 전하는 상쾌함, 그리고 자연 속에서 느끼는 편안함을 담았습니다.'**
  String get introNameStory;

  /// No description provided for @introEverydayTitle.
  ///
  /// In ko, this message translates to:
  /// **'소리와 함께하는 일상'**
  String get introEverydayTitle;

  /// No description provided for @introMoments.
  ///
  /// In ko, this message translates to:
  /// **'바쁜 하루 중 잠시 쉬어가고 싶을 때,\n좋아하는 음악이 생각날 때,\n새로운 라디오 방송을 만나고 싶을 때,\n자연의 소리와 함께 조용한 시간을 보내고 싶을 때.'**
  String get introMoments;

  /// No description provided for @introEveryday1.
  ///
  /// In ko, this message translates to:
  /// **'파란소리는 일상의 다양한 순간에 가볍게 함께하고 싶습니다.'**
  String get introEveryday1;

  /// No description provided for @introEveryday2.
  ///
  /// In ko, this message translates to:
  /// **'음악 한 곡, 익숙한 라디오 방송, 잔잔한 빗소리 하나가 평범한 하루를 조금 더 기분 좋게 만들어 줄 수 있으니까요. 그래서 파란소리는 복잡하지 않고, 누구나 쉽고 즐겁게 사용할 수 있는 공간을 만들어가고 있습니다.'**
  String get introEveryday2;

  /// No description provided for @introSoundsTitle.
  ///
  /// In ko, this message translates to:
  /// **'파란소리에서 만나는 소리'**
  String get introSoundsTitle;

  /// No description provided for @introWishTitle.
  ///
  /// In ko, this message translates to:
  /// **'파란소리가 전하고 싶은 마음'**
  String get introWishTitle;

  /// No description provided for @introWish1.
  ///
  /// In ko, this message translates to:
  /// **'좋아하는 소리를 듣는 시간은 생각보다 우리 가까이에 있습니다. 아침을 시작할 때도, 일하는 중에도, 하루를 마무리하는 조용한 밤에도.'**
  String get introWish1;

  /// No description provided for @introWish2.
  ///
  /// In ko, this message translates to:
  /// **'한국에서 시작된 파란소리가 이제 세계 여러 곳의 사람들과 함께하며, 저마다의 일상에 작은 즐거움과 여유를 더할 수 있기를 바랍니다.'**
  String get introWish2;

  /// No description provided for @introClosing1.
  ///
  /// In ko, this message translates to:
  /// **'언제 어디서나 편안하게 찾을 수 있는 소리의 공간.'**
  String get introClosing1;

  /// No description provided for @introClosing2.
  ///
  /// In ko, this message translates to:
  /// **'당신의 하루가 조금 더 맑아지도록.'**
  String get introClosing2;

  /// No description provided for @introSign.
  ///
  /// In ko, this message translates to:
  /// **'파란소리, Paransori.'**
  String get introSign;

  /// No description provided for @introVersion.
  ///
  /// In ko, this message translates to:
  /// **'버전'**
  String get introVersion;

  /// No description provided for @introFeature1Title.
  ///
  /// In ko, this message translates to:
  /// **'나만의 음악'**
  String get introFeature1Title;

  /// No description provided for @introFeature1Desc.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰에 저장된 음악을 느긋하게 감상하며, 좋아하는 노래로 나만의 시간을 채워보세요.'**
  String get introFeature1Desc;

  /// No description provided for @introFeature2Title.
  ///
  /// In ko, this message translates to:
  /// **'세계의 라디오'**
  String get introFeature2Title;

  /// No description provided for @introFeature2Desc.
  ///
  /// In ko, this message translates to:
  /// **'다양한 나라의 라디오 방송을 들으며 새로운 음악과 이야기, 세상의 소리를 만나보세요.'**
  String get introFeature2Desc;

  /// No description provided for @introFeature3Title.
  ///
  /// In ko, this message translates to:
  /// **'자연의 소리'**
  String get introFeature3Title;

  /// No description provided for @introFeature3Desc.
  ///
  /// In ko, this message translates to:
  /// **'빗소리, 바람 소리, 숲의 소리 등 자연이 들려주는 편안한 소리를 즐겨보세요.'**
  String get introFeature3Desc;

  /// No description provided for @introFeature4Title.
  ///
  /// In ko, this message translates to:
  /// **'휴식과 집중'**
  String get introFeature4Title;

  /// No description provided for @introFeature4Desc.
  ///
  /// In ko, this message translates to:
  /// **'잠들기 전 조용한 시간부터 집중이 필요한 순간까지, 지금 나에게 어울리는 소리를 찾아보세요.'**
  String get introFeature4Desc;

  /// No description provided for @introFeature5Title.
  ///
  /// In ko, this message translates to:
  /// **'나만의 소리 조합'**
  String get introFeature5Title;

  /// No description provided for @introFeature5Desc.
  ///
  /// In ko, this message translates to:
  /// **'좋아하는 소리들을 함께 재생하며 나만의 분위기를 만들어보세요.'**
  String get introFeature5Desc;

  /// No description provided for @introFeature6Title.
  ///
  /// In ko, this message translates to:
  /// **'아침 알람'**
  String get introFeature6Title;

  /// No description provided for @introFeature6Desc.
  ///
  /// In ko, this message translates to:
  /// **'좋아하는 노래, 라디오, 자연의 소리로 기분 좋게 하루를 시작해 보세요.'**
  String get introFeature6Desc;

  /// No description provided for @introMenuTitle.
  ///
  /// In ko, this message translates to:
  /// **'파란소리 소개'**
  String get introMenuTitle;

  /// No description provided for @introMenuDesc.
  ///
  /// In ko, this message translates to:
  /// **'어떤 앱인지 알려드려요.'**
  String get introMenuDesc;

  /// No description provided for @nature01Name.
  ///
  /// In ko, this message translates to:
  /// **'파도소리'**
  String get nature01Name;

  /// No description provided for @nature01Desc.
  ///
  /// In ko, this message translates to:
  /// **'규칙적인 파도 소리는 마음을 차분히 가라앉혀 깊은 휴식과 수면에 도움을 줘요'**
  String get nature01Desc;

  /// No description provided for @nature02Name.
  ///
  /// In ko, this message translates to:
  /// **'잔잔한 파도'**
  String get nature02Name;

  /// No description provided for @nature02Desc.
  ///
  /// In ko, this message translates to:
  /// **'한결 부드럽고 잔잔하게 밀려오는 파도 소리로 편안한 휴식을 도와줘요'**
  String get nature02Desc;

  /// No description provided for @nature03Name.
  ///
  /// In ko, this message translates to:
  /// **'갈매기와 파도'**
  String get nature03Name;

  /// No description provided for @nature03Desc.
  ///
  /// In ko, this message translates to:
  /// **'갈매기 울음소리가 어우러진 파도 소리로 생생한 해변 분위기를 느껴보세요'**
  String get nature03Desc;

  /// No description provided for @nature04Name.
  ///
  /// In ko, this message translates to:
  /// **'바위에 부딪히는 파도'**
  String get nature04Name;

  /// No description provided for @nature04Desc.
  ///
  /// In ko, this message translates to:
  /// **'바위에 세게 부딪히며 부서지는 파도 소리로 역동적인 바다를 느껴보세요'**
  String get nature04Desc;

  /// No description provided for @nature05Name.
  ///
  /// In ko, this message translates to:
  /// **'멀리서 들리는 갈매기'**
  String get nature05Name;

  /// No description provided for @nature05Desc.
  ///
  /// In ko, this message translates to:
  /// **'고요한 바닷가, 멀리서 은은하게 들려오는 갈매기 소리로 차분한 휴식을 느껴보세요'**
  String get nature05Desc;

  /// No description provided for @nature06Name.
  ///
  /// In ko, this message translates to:
  /// **'거친 파도'**
  String get nature06Name;

  /// No description provided for @nature06Desc.
  ///
  /// In ko, this message translates to:
  /// **'거칠게 밀려와 부서지는 파도 소리로 힘 있는 바다를 느껴보세요'**
  String get nature06Desc;

  /// No description provided for @nature07Name.
  ///
  /// In ko, this message translates to:
  /// **'빗소리'**
  String get nature07Name;

  /// No description provided for @nature07Desc.
  ///
  /// In ko, this message translates to:
  /// **'일정한 빗소리는 집중력을 높이고 불안한 마음을 편안하게 다독여줘요'**
  String get nature07Desc;

  /// No description provided for @nature08Name.
  ///
  /// In ko, this message translates to:
  /// **'창문에 떨어지는 비'**
  String get nature08Name;

  /// No description provided for @nature08Desc.
  ///
  /// In ko, this message translates to:
  /// **'창문을 두드리는 부드러운 빗소리로 편안하게 잠들어보세요'**
  String get nature08Desc;

  /// No description provided for @nature09Name.
  ///
  /// In ko, this message translates to:
  /// **'숲속의 비와 새소리'**
  String get nature09Name;

  /// No description provided for @nature09Desc.
  ///
  /// In ko, this message translates to:
  /// **'숲속에 내리는 빗소리와 새소리가 어우러져 마음을 편안하게 해줘요'**
  String get nature09Desc;

  /// No description provided for @nature10Name.
  ///
  /// In ko, this message translates to:
  /// **'숲속의 거센 밤비'**
  String get nature10Name;

  /// No description provided for @nature10Desc.
  ///
  /// In ko, this message translates to:
  /// **'깊은 밤 숲속에 세차게 내리는 빗소리로 몰입감 있는 휴식을 느껴보세요'**
  String get nature10Desc;

  /// No description provided for @nature11Name.
  ///
  /// In ko, this message translates to:
  /// **'새소리'**
  String get nature11Name;

  /// No description provided for @nature11Desc.
  ///
  /// In ko, this message translates to:
  /// **'청아한 새소리는 스트레스를 줄이고 상쾌한 기분을 만들어줘요'**
  String get nature11Desc;

  /// No description provided for @nature12Name.
  ///
  /// In ko, this message translates to:
  /// **'뻐꾸기와 숲속 새소리'**
  String get nature12Name;

  /// No description provided for @nature12Desc.
  ///
  /// In ko, this message translates to:
  /// **'뻐꾸기 소리가 어우러진 숲속의 새소리로 상쾌한 아침을 느껴보세요'**
  String get nature12Desc;

  /// No description provided for @nature13Name.
  ///
  /// In ko, this message translates to:
  /// **'모닥불'**
  String get nature13Name;

  /// No description provided for @nature13Desc.
  ///
  /// In ko, this message translates to:
  /// **'타닥타닥 장작 타는 소리는 아늑한 분위기로 깊은 이완을 도와줘요'**
  String get nature13Desc;

  /// No description provided for @nature14Name.
  ///
  /// In ko, this message translates to:
  /// **'시냇물'**
  String get nature14Name;

  /// No description provided for @nature14Desc.
  ///
  /// In ko, this message translates to:
  /// **'졸졸 흐르는 시냇물 소리는 마음을 편안하게 하고 잡생각을 줄여줘요'**
  String get nature14Desc;

  /// No description provided for @nature15Name.
  ///
  /// In ko, this message translates to:
  /// **'잔잔한 강물'**
  String get nature15Name;

  /// No description provided for @nature15Desc.
  ///
  /// In ko, this message translates to:
  /// **'넓은 강물이 잔잔하게 흐르는 소리로 편안한 휴식을 느껴보세요'**
  String get nature15Desc;

  /// No description provided for @langNameKo.
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get langNameKo;

  /// No description provided for @langNameEn.
  ///
  /// In ko, this message translates to:
  /// **'영어'**
  String get langNameEn;

  /// No description provided for @langNameJa.
  ///
  /// In ko, this message translates to:
  /// **'일본어'**
  String get langNameJa;

  /// No description provided for @langNameZhHant.
  ///
  /// In ko, this message translates to:
  /// **'중국어 번체'**
  String get langNameZhHant;

  /// No description provided for @langNameZhHans.
  ///
  /// In ko, this message translates to:
  /// **'중국어 간체'**
  String get langNameZhHans;

  /// No description provided for @langNameId.
  ///
  /// In ko, this message translates to:
  /// **'인도네시아어'**
  String get langNameId;

  /// No description provided for @langNameDe.
  ///
  /// In ko, this message translates to:
  /// **'독일어'**
  String get langNameDe;

  /// No description provided for @langNameEs.
  ///
  /// In ko, this message translates to:
  /// **'스페인어'**
  String get langNameEs;

  /// No description provided for @langNameFr.
  ///
  /// In ko, this message translates to:
  /// **'프랑스어'**
  String get langNameFr;

  /// No description provided for @langNamePt.
  ///
  /// In ko, this message translates to:
  /// **'포르투갈어'**
  String get langNamePt;

  /// No description provided for @langNameVi.
  ///
  /// In ko, this message translates to:
  /// **'베트남어'**
  String get langNameVi;

  /// No description provided for @langNameTh.
  ///
  /// In ko, this message translates to:
  /// **'태국어'**
  String get langNameTh;

  /// No description provided for @langNameRu.
  ///
  /// In ko, this message translates to:
  /// **'러시아어'**
  String get langNameRu;

  /// No description provided for @langNameIt.
  ///
  /// In ko, this message translates to:
  /// **'이탈리아어'**
  String get langNameIt;

  /// No description provided for @langNameTr.
  ///
  /// In ko, this message translates to:
  /// **'튀르키예어'**
  String get langNameTr;

  /// No description provided for @langNamePl.
  ///
  /// In ko, this message translates to:
  /// **'폴란드어'**
  String get langNamePl;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'id',
    'it',
    'ja',
    'ko',
    'pl',
    'pt',
    'ru',
    'th',
    'tr',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'th':
      return AppLocalizationsTh();
    case 'tr':
      return AppLocalizationsTr();
    case 'vi':
      return AppLocalizationsVi();
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
