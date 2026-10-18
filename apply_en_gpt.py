# -*- coding: utf-8 -*-
# GPT가 다듬은 영어 문구 넣기 (app_en.arb, 131곳)
#  - 키 이름 + 지금 문구가 정확히 맞을 때만 바꿈 (다르면 ❌, 아무것도 저장 안 함)
#  - 뺀 것: introMenuDesc(오늘 정한 문장 유지), radioKoreaSlogan(뜻이 달라짐),
#           radioNotPlaying·radioAfterEnd(좁은 칸이라 길면 잘림)
import os, sys, json

PATH = os.path.join('lib', 'l10n', 'app_en.arb')
CHANGES = [
 [
  "noSongs",
  "No MP3 files found",
  "No music files found"
 ],
 [
  "addMusic",
  "Add music files to your device",
  "Add music to your phone to get started"
 ],
 [
  "scanningMusic",
  "Scanning music...",
  "Finding your music..."
 ],
 [
  "editSong",
  "Edit song info",
  "Edit song details"
 ],
 [
  "songInfo",
  "Song info",
  "Song details"
 ],
 [
  "version",
  "Version info",
  "App version"
 ],
 [
  "noRecentSongs",
  "No recently played songs",
  "Nothing played recently"
 ],
 [
  "playMusic",
  "Play some music",
  "Start listening"
 ],
 [
  "clearRecent",
  "Clear recent songs",
  "Clear listening history"
 ],
 [
  "clearRecentConfirm",
  "Clear all recently played songs?",
  "Clear your listening history?"
 ],
 [
  "ringtoneFailed",
  "Failed to set ringtone",
  "Couldn't set ringtone"
 ],
 [
  "promoInvalid",
  "Invalid promo code",
  "That promo code isn't valid"
 ],
 [
  "permissionRequired",
  "Storage permission required",
  "Music access needed"
 ],
 [
  "permissionMessage",
  "Storage permission is required\nto scan MP3 files.",
  "Allow access to your music\nto find songs on your phone."
 ],
 [
  "allowPermission",
  "Allow permission",
  "Allow access"
 ],
 [
  "deleteFailed",
  "Delete failed",
  "Couldn't delete"
 ],
 [
  "flashlightError",
  "Flashlight error",
  "Couldn't turn on flashlight"
 ],
 [
  "enhancesBass",
  "Enhances bass sound",
  "Boosts low frequencies"
 ],
 [
  "surroundEffect",
  "Creates surround sound effect",
  "Adds a surround sound effect"
 ],
 [
  "reviewMessage",
  "Please leave a rating!\nIt helps us improve the app 😊",
  "Enjoying Paransori?\nYour rating helps us improve 😊"
 ],
 [
  "styleCD",
  "CD rotation",
  "Spinning CD"
 ],
 [
  "styleCard",
  "Album art card",
  "Album art"
 ],
 [
  "autoStopCountdownSuffix",
  "until auto stop",
  "until playback stops"
 ],
 [
  "radioRecentListening",
  "Recently listened",
  "Recently played"
 ],
 [
  "radioSelectCountry",
  "Select country",
  "Choose a country"
 ],
 [
  "sleepTimerDesc",
  "Turns off automatically after the selected time",
  "Stops playback after the time you choose"
 ],
 [
  "sleepTimerActiveDesc",
  "Timer is running",
  "Your sleep timer is running"
 ],
 [
  "radioNoFavoritesDesc",
  "Tap ♡ on a channel to add it",
  "Tap ♡ on a station to save it"
 ],
 [
  "radioPlayFirst",
  "Please play a radio station first",
  "Play a radio station first"
 ],
 [
  "radioScheduleCompleteToast",
  "{title} {time} scheduled",
  "Scheduled {title} for {time}"
 ],
 [
  "radioPlaybackFailed",
  "Playback failed.",
  "Couldn't play this station"
 ],
 [
  "radioRerun",
  "Rerun",
  "Replay"
 ],
 [
  "radioStatusFailed",
  "Connection failed",
  "Couldn't connect"
 ],
 [
  "categoryRegionalPrivate",
  "Regional private",
  "Local commercial stations"
 ],
 [
  "categoryTraffic",
  "Traffic broadcasting",
  "Traffic radio"
 ],
 [
  "categoryEtc",
  "Others",
  "Other"
 ],
 [
  "countryBA",
  "Bosnia",
  "Bosnia and Herzegovina"
 ],
 [
  "radioKoreaTitle",
  "Korea Radio",
  "Korean Radio"
 ],
 [
  "homeRecentEmptySub",
  "Anything played for 30s+ shows up here",
  "Listen for 30 seconds to see it here"
 ],
 [
  "dailyLongTime",
  "Long time no listen",
  "It’s been a while"
 ],
 [
  "dailyNotPlayedSub",
  "Give them another listen?",
  "Want to hear them again?"
 ],
 [
  "dailyTipMixTitle",
  "Add rain to your music",
  "Add the sound of rain to your music"
 ],
 [
  "dailyTipMixSub",
  "Player ⋮ menu → Nature sound mix",
  "Player ⋮ menu → Mix nature sounds"
 ],
 [
  "dailyOffTitle",
  "Turn off the daily card?",
  "Hide the daily card?"
 ],
 [
  "musicLoadError",
  "Error loading music",
  "Couldn't load your music"
 ],
 [
  "musicScanError",
  "Music scan error",
  "Couldn't find your music"
 ],
 [
  "natureMix",
  "Nature sound mix",
  "Mix nature sounds"
 ],
 [
  "lyricsDeleteMessage",
  "We'll search online again after deleting.",
  "We’ll look for lyrics online again."
 ],
 [
  "lyricsNotFoundYet",
  "Couldn't find lyrics for this song yet",
  "No lyrics available for this song yet"
 ],
 [
  "cardMakeFailed",
  "Couldn't make the card. Please try again.",
  "Couldn't create the card. Try again."
 ],
 [
  "pleaseWait",
  "Please wait a moment",
  "Just a moment..."
 ],
 [
  "noSongsWithoutArt",
  "No songs are missing art",
  "All songs have album art"
 ],
 [
  "allowModifySettings",
  "Turn on \"Modify system settings\", then come back and tap again",
  "Allow “Modify system settings,” then try again"
 ],
 [
  "mayHaveErrors",
  "(may contain errors)",
  "(may not be accurate)"
 ],
 [
  "callEmptyHint",
  "Turn on call recording in your Phone app\nand recorded calls will appear here",
  "Enable call recording in your Phone app\nto see your recordings here"
 ],
 [
  "trashInfo",
  "It moves to the trash and is deleted after 30 days.",
  "Moved to Trash and permanently deleted after 30 days."
 ],
 [
  "deleteForeverMsg",
  "{count, plural, =1{1 recording will be gone for good.} other{{count} recordings will be gone for good.}}",
  "{count, plural, =1{This recording will be permanently deleted.} other{These {count} recordings will be permanently deleted.}}"
 ],
 [
  "deleteVideosForeverMsg",
  "{count, plural, =1{1 video will be gone for good.} other{{count} videos will be gone for good.}}",
  "{count, plural, =1{This video will be permanently deleted.} other{These {count} videos will be permanently deleted.}}"
 ],
 [
  "deleteVideoForeverMsg",
  "This video will be gone for good.",
  "This video will be permanently deleted."
 ],
 [
  "videoPermSub",
  "Please allow video access once",
  "Allow access to your videos to continue"
 ],
 [
  "castFailedRetry",
  "Couldn't send to TV. Please try again.",
  "Couldn't cast to your TV. Try again."
 ],
 [
  "videoScanError",
  "Video scan error",
  "Couldn't find your videos"
 ],
 [
  "saveMusicFailed",
  "Couldn't save as music",
  "Couldn't save the audio"
 ],
 [
  "radioShareSub",
  "Share what you're listening to.",
  "Share this station with someone."
 ],
 [
  "scheduleFull",
  "Can't add more. Delete old ones in Schedules.",
  "Schedule limit reached. Remove an existing schedule to add another."
 ],
 [
  "noCountryFound",
  "No country found",
  "No countries found"
 ],
 [
  "scheduleLimit",
  "Up to 5 schedules. Delete old ones to add more.",
  "You can have up to 5 schedules. Remove one to add another."
 ],
 [
  "diceNoProgram",
  "No program info",
  "No program details available"
 ],
 [
  "savedSongsEmpty",
  "Tap ♡ next to songs played on air\nto collect them here",
  "Tap ♡ beside a song playing on the radio\nto save it here"
 ],
 [
  "noRegionStations",
  "No stations with region info",
  "No stations with region details"
 ],
 [
  "noSongInfoYet",
  "No song info yet",
  "Song details aren’t available yet"
 ],
 [
  "stationLoadFailed",
  "Can't load this station.\nPlease choose another one.",
  "Couldn't load this station.\nTry another one."
 ],
 [
  "soundPlayFailed",
  "Couldn't play the sound",
  "Couldn't play this sound"
 ],
 [
  "natureSub",
  "Sounds to calm your mind",
  "Find a little calm in nature"
 ],
 [
  "mixSub",
  "Create your own relaxing soundscape.",
  "Blend your favorite sounds into a relaxing soundscape."
 ],
 [
  "noMyMusic",
  "No music on this phone",
  "No music saved on this phone"
 ],
 [
  "myMixDefault",
  "My sound mix",
  "My Mix"
 ],
 [
  "overlayOnHint",
  "Layer nature sounds softly under your music",
  "Play nature sounds softly alongside your music"
 ],
 [
  "noFavRadio",
  "No favorite stations",
  "No favorite radio stations yet"
 ],
 [
  "noFavNature",
  "No favorite nature sounds",
  "No favorite nature sounds yet"
 ],
 [
  "restFocusSub",
  "Calm sounds to rest and focus",
  "Sounds for rest and focus"
 ],
 [
  "descEq",
  "Tune the sound to your taste",
  "Make the sound your own"
 ],
 [
  "soundEffectInfo",
  "A soft drop sound when you edit, save or delete. Vibrates in vibrate mode and stays silent when muted.",
  "Plays a soft sound when you edit, save, or delete. Uses vibration in vibrate mode and stays quiet when muted."
 ],
 [
  "infoTimeD",
  "Nature sounds for morning, day, evening and night",
  "Nature sounds for every part of your day"
 ],
 [
  "infoAlarmD",
  "If an alarm is on, shows wake-up time from 7 PM",
  "Shows your next alarm after 7 PM when an alarm is set"
 ],
 [
  "headsetDesc",
  "Resumes playback when headphones connect",
  "Resume playback when headphones connect"
 ],
 [
  "headsetNote",
  "Resumes your song, radio or nature sound softly and slowly turns it up.\nIt won't work if the app is fully closed.",
  "Gently resumes your music, radio, or nature sounds when headphones connect.\nDoesn’t work if the app is fully closed."
 ],
 [
  "helpCantOpen",
  "Can't open settings. Please follow \"Set it manually\" below.",
  "Couldn't open Settings. Follow the steps under “Set it manually.”"
 ],
 [
  "mailBodyAsk",
  "What's the problem?\n(Please write here)",
  "How can we help?\n(Describe the issue here)"
 ],
 [
  "mailCopied",
  "No mail app found, so the address was copied ({mail})",
  "No email app found. Email address copied: {mail}"
 ],
 [
  "alarmNeedExact",
  "Allow Alarms & reminders so the alarm can ring",
  "Allow Alarms & reminders so your alarm can ring on time"
 ],
 [
  "noSongsOnPhone",
  "No songs on this phone",
  "No music found on this phone"
 ],
 [
  "pickAlarmSong",
  "Choose alarm song",
  "Choose an alarm song"
 ],
 [
  "makePlaylistFirst",
  "Create a playlist first",
  "Create a playlist to get started"
 ],
 [
  "addFavStationFirst",
  "Add stations to radio favorites first",
  "Add a station to your favorites first"
 ],
 [
  "alarmPermTitle",
  "Alarm permission needed",
  "Allow alarm access"
 ],
 [
  "alarmPermMsg",
  "To wake you on time, allow \"Alarms & reminders\". It saves as soon as you come back.",
  "Allow “Alarms & reminders” so your alarm can ring on time. Your settings will be saved when you return."
 ],
 [
  "fullScreenMsg",
  "Allow \"Full-screen notifications\" to show the alarm over the lock screen. The alarm still rings without it.",
  "Allow full-screen notifications to show the alarm on your lock screen. It will still ring without this permission."
 ],
 [
  "alarmVolumeNote",
  "Rings at this volume even if your phone is quiet, then goes back after",
  "Uses this volume even if your phone is silent, then restores your previous volume."
 ],
 [
  "noDaysOnce",
  "With no days picked, it rings once",
  "If no days are selected, the alarm rings once"
 ],
 [
  "oneSongSub",
  "Repeats the song you pick",
  "Repeat the song you choose"
 ],
 [
  "byeLine1",
  "What a day with good music",
  "A day well spent with music"
 ],
 [
  "genreTypeOwn",
  "Type your own",
  "Enter a genre"
 ],
 [
  "stationCatPrivate",
  "Regional private",
  "Local commercial stations"
 ],
 [
  "smsSheetDesc",
  "Send a text to this number to share a story or request a song.",
  "Text the station to share a story or request a song."
 ],
 [
  "smsSheetFee",
  "An information fee applies: 50 KRW for short texts, 100 KRW for long texts or photos.",
  "Message fees apply: ₩50 for a short text, or ₩100 for a long text or photo."
 ],
 [
  "languageMenuDesc",
  "Show the app in another language.",
  "Choose the language used in the app."
 ],
 [
  "introTagline",
  "Adding clarity to your everyday.",
  "A little clarity for every day."
 ],
 [
  "introStarted",
  "Paransori began with the wish to capture sounds like these.",
  "Paransori began with a simple wish: to bring these sounds into everyday life."
 ],
 [
  "introEveryday1",
  "Paransori hopes to be there, lightly, in all the different moments of your day.",
  "Paransori is here for the little moments throughout your day."
 ],
 [
  "introWish2",
  "Paransori began in Korea and now joins people all around the world. We hope it adds a little joy and ease to each of your days.",
  "Created in Korea, Paransori is made for listeners everywhere. We hope it brings a little more ease and joy to your day."
 ],
 [
  "introClosing1",
  "A space for sound you can turn to anytime, anywhere.",
  "Your place for music, radio, and nature sounds, anytime."
 ],
 [
  "introClosing2",
  "So your day can be a little clearer.",
  "A little more calm in every day."
 ],
 [
  "introFeature1Desc",
  "Relax with the music saved on your phone and fill your time with the songs you love.",
  "Enjoy the music saved on your phone, wherever your day takes you."
 ],
 [
  "introFeature4Desc",
  "From quiet moments before sleep to times when you need to focus, find the sound that suits you right now.",
  "Whether you’re winding down for bed or settling in to focus, find the sounds that fit the moment."
 ],
 [
  "introFeature5Title",
  "Your own sound mix",
  "Your sound mix"
 ],
 [
  "introFeature5Desc",
  "Play your favorite sounds together and create a mood that's all yours.",
  "Blend music and nature sounds to create your own atmosphere."
 ],
 [
  "nature01Desc",
  "Steady waves calm your mind and help you rest and sleep deeply",
  "Let the steady rhythm of ocean waves help you unwind"
 ],
 [
  "nature02Desc",
  "Soft, gentle waves rolling in for a peaceful rest",
  "Soft waves rolling onto the shore for a peaceful break"
 ],
 [
  "nature03Desc",
  "Waves with seagull calls for a lively beach mood",
  "Seagull calls and rolling waves bring the beach to you"
 ],
 [
  "nature04Desc",
  "Waves crashing hard against rocks for a dynamic sea",
  "Waves crashing against rocks along a rugged coast"
 ],
 [
  "nature05Desc",
  "A quiet shore with seagulls softly calling far away",
  "Distant seagull calls along a quiet shoreline"
 ],
 [
  "nature07Desc",
  "Steady rain helps you focus and soothes an anxious mind",
  "The gentle rhythm of rain for a moment of calm"
 ],
 [
  "nature08Desc",
  "Soft rain tapping on the window to help you fall asleep",
  "Raindrops tapping softly against a window"
 ],
 [
  "nature09Desc",
  "Rain in the forest blended with birdsong to calm your mind",
  "Forest rainfall and birdsong for a peaceful escape"
 ],
 [
  "nature10Desc",
  "Heavy rain falling in a forest at night for deep relaxation",
  "Heavy nighttime rain falling through the forest"
 ],
 [
  "nature11Desc",
  "Clear birdsong eases stress and lifts your mood",
  "Bright birdsong to welcome a peaceful moment"
 ],
 [
  "nature12Desc",
  "Forest birdsong with a cuckoo for a fresh morning",
  "A cuckoo calling among the birds of the forest"
 ],
 [
  "nature13Desc",
  "Crackling firewood creates a cozy mood for deep relaxation",
  "The cozy crackle of a warm campfire"
 ],
 [
  "nature14Desc",
  "A babbling stream calms your mind and quiets busy thoughts",
  "The gentle flow of a babbling stream"
 ],
 [
  "nature15Desc",
  "A wide river flowing calmly for a peaceful rest",
  "A slow, steady river flowing through a quiet landscape"
 ]
]

def raw(s):
    return json.dumps(s, ensure_ascii=False)[1:-1]

def main():
    if not os.path.exists(PATH):
        print('❌ 파일을 못 찾았어요:', PATH, '— 프로젝트 폴더(mp3_player_new)에서 실행해 주세요'); return 1
    b = open(PATH, 'rb').read()
    crlf = b'\r\n' in b
    text = b.decode('utf-8').replace('\r\n', '\n')
    ok = True; changed = 0; already = 0
    for key, old, new in CHANGES:
        o = '"%s": "%s"' % (key, raw(old)); n = '"%s": "%s"' % (key, raw(new))
        if text.count(n) == 1:
            already += 1; continue
        if text.count(o) == 1:
            text = text.replace(o, n); changed += 1; print('✔', key, ':', new.replace('\n', ' / '))
        else:
            print('❌', key, ': 지금 문구가 달라서 못 바꿨어요'); ok = False
    if changed == 0 and ok:
        print('이미 적용돼 있어요'); return 0
    try:
        json.loads(text)
    except Exception as e:
        print('❌ 번역 파일 모양이 깨졌어요:', e); ok = False
    if not ok:
        print('\n아무것도 저장하지 않았어요.'); return 1
    if crlf:
        text = text.replace('\n', '\r\n')
    open(PATH, 'wb').write(text.encode('utf-8'))
    print('\n저장했어요: %d곳 바꿈 (이미 바뀐 곳 %d)' % (changed, already))
    return 0

if __name__ == '__main__':
    sys.exit(main())
