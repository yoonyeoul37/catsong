# Flutter 기본 유지 규칙
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# 미디어 재생 관련 (media3, ExoPlayer)
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**

# audio_service, just_audio, media_kit 관련
-keep class com.ryanheise.** { *; }
-keep class com.tekartik.** { *; }

# 알림/위젯 관련
-keep class kr.ssing.catsong.** { *; }

# 리플렉션 경고 무시
-dontwarn org.jetbrains.annotations.**

# Flutter의 동적 기능 설치(Deferred Components) 관련 - 안 쓰지만 프레임워크가 참조함
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }