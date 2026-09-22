# Flutter 엔진 자체는 Flutter Gradle 플러그인이 알아서 필요한 규칙을 넣어줘서
# 별도로 통째로 keep 안 해도 돼요. (io.flutter.** 전체 keep 제거)

# 미디어 재생 관련 (media3, ExoPlayer)
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**

# audio_service, just_audio 관련
-keep class com.ryanheise.** { *; }
-keep class com.tekartik.** { *; }

# 우리 앱의 진입점(MainActivity)만 보호 (여긴 리플렉션 안 쓰지만, 메서드 채널
# 콜백이 걸려있어서 안전하게 클래스 자체는 유지)
-keep class kr.ssing.catsong.MainActivity { *; }

# 리플렉션 경고 무시
-dontwarn org.jetbrains.annotations.**

# Flutter의 동적 기능 설치(Deferred Components) 관련 - 안 쓰지만 프레임워크가 참조함
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }