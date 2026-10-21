# -*- coding: utf-8 -*-
# 말로 틀기: "헤이 구글, 파란소리에서 KBS 쿨FM / 아이유 노래 / 빗소리 틀어줘"
import os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
NEW_FILE = os.path.join('lib', 'services', 'voice_search.dart')
PLAYER = os.path.join('lib', 'providers', 'player_provider.dart')
MAIN = os.path.join('lib', 'main.dart')

import base64
VOICE_SRC = base64.b64decode(
    'aW1wb3J0ICdwYWNrYWdlOmZsdXR0ZXIvZm91bmRhdGlvbi5kYXJ0JzsKaW1wb3J0ICcuLi9tb2RlbHMvc29uZy5kYXJ0JzsKaW1wb3J0ICcuLi9tb2RlbHMvcmFkaW9fc3RhdGlvbi5kYXJ0JzsKaW1wb3J0ICcuLi9wcm92aWRlcnMvcGxheWVyX3Byb3ZpZGVyLmRhcnQnOwppbXBvcnQgJy4uL3Byb3ZpZGVycy9yYWRpb19wcm92aWRlci5kYXJ0JzsKaW1wb3J0ICcuLi9wcm92aWRlcnMvbXVzaWNfcHJvdmlkZXIuZGFydCc7CmltcG9ydCAnLi4vc2NyZWVucy9yYWRpb19rb3JlYV9zY3JlZW4yLmRhcnQnIHNob3cga29yZWFuUmFkaW9TdGF0aW9ucywgbmljZUtvcmVhblN0YXRpb25Ob3c7CmltcG9ydCAnaGVhZHNldF9yZXN1bWUuZGFydCc7CgovLy8g66eQ66GcIO2LgOq4sDogIu2XpOydtCDqtazquIAsIO2MjOuegOyGjOumrOyXkOyEnCDil4vil4sg7YuA7Ja07KSYIgovLy8g6rWs6riA7J20IOuztOuCuCDquIDsnpDroZwg652865SU7JikIOuwqeyGoSDihpIg7J6Q7Jew7IaM66asIOKGkiDrgrQg7J2M7JWFIOyInOyEnOuhnCDssL7slYTshJwg7YuA6riwCmNsYXNzIFZvaWNlU2VhcmNoIHsKICBzdGF0aWMgUGxheWVyUHJvdmlkZXI/IF9wcDsKICBzdGF0aWMgUmFkaW9Qcm92aWRlcj8gX3JhZGlvOwogIHN0YXRpYyBNdXNpY1Byb3ZpZGVyPyBfbXVzaWM7CgogIHN0YXRpYyB2b2lkIGluaXQoUGxheWVyUHJvdmlkZXIgcHAsIFJhZGlvUHJvdmlkZXIgcmFkaW8sIE11c2ljUHJvdmlkZXIgbXVzaWMpIHsKICAgIF9wcCA9IHBwOwogICAgX3JhZGlvID0gcmFkaW87CiAgICBfbXVzaWMgPSBtdXNpYzsKICB9CgogIC8vIO2VnOq4gOuhnCDrp5DtlbTrj4Qg7JiB7Ja0IOydtOumhCDrsKnshqHsnYQg7LC+6rKMICjrsKnshqEg7J2066aE6rO8IOunkO2VnCDquIDsnpAg65GYIOuLpCDqsJnsnYAg6rec7LmZ7Jy866GcIOuwlOq/lOyEnCDruYTqtZApCiAgc3RhdGljIGNvbnN0IF9hbGlhcyA9IDxTdHJpbmcsIFN0cmluZz57CiAgICAn7JeQ7ZSE7JegJzogJ2ZtJywKICAgICfsvIDsnbTruYTsl5DsiqQnOiAna2JzJywKICAgICfsl6DruYTslKgnOiAnbWJjJywKICAgICfsl5DsiqTruYTsl5DsiqQnOiAnc2JzJywKICAgICfslKjruYTsl5DsiqQnOiAnY2JzJywKICAgICfsnbTruYTsl5DsiqQnOiAnZWJzJywKICAgICfsmYDsnbTti7Dsl5QnOiAneXRuJywKICAgICfti7DruYTsl5DsiqQnOiAndGJzJywKICAgICfti7DruYTsl5QnOiAndGJuJywKICAgICftgbTrnpjsi50nOiAnY2xhc3NpYycsCiAgICAn7Y+s7JygJzogJ2ZtNHUnLAogICAgJ+y/qCc6ICdjb29sJywKICAgICftjIzsm4wnOiAncG93ZXInLAogICAgJ+ufrOu4jCc6ICdsb3ZlJywKICAgICftlbTtlLwnOiAnaGFwcHknLAogICAgJ+ygnOydvCc6ICfsoJwxJywKICB9OwoKICAvLyDrqoXroLnslrQg67aA67aEICjssL7snYQg7J2066aE7J20IOyVhOuLmCkKICBzdGF0aWMgY29uc3QgX2ZpbGxlcnMgPSBbCiAgICAn7YyM656A7IaM66as7JeQ7IScJywgJ+2MjOuegOyGjOumrOuhnCcsICftjIzrnoDshozrpqwnLCAncGFyYW5zb3JpJywKICAgICfti4DslrTspJgnLCAn7YuA7Ja0JywgJ+uTpOugpOykmCcsICfsnqzsg53tlbTspJgnLCAn7J6s7IOd7ZW0JywgJ+yerOyDnScsCiAgXTsKICBzdGF0aWMgY29uc3QgX2tpbmRzID0gWyfrnbzrlJTsmKQnLCAncmFkaW8nLCAn64W4656YJywgJ+ydjOyVhScsICdtdXNpYycsICdzb25ncycsICdzb25nJywgJ+qzoSddOwoKICBzdGF0aWMgU3RyaW5nIF9ub3JtKFN0cmluZyBzKSB7CiAgICB2YXIgdCA9IHMudG9Mb3dlckNhc2UoKTsKICAgIF9hbGlhcy5mb3JFYWNoKChrLCB2KSA9PiB0ID0gdC5yZXBsYWNlQWxsKGssIHYpKTsKICAgIHQgPSB0LnJlcGxhY2VBbGwoUmVnRXhwKHInJydbXHNcLlwtX8K3LCE/ficiKClcW1xdXScnJyksICcnKTsKICAgIHJldHVybiB0LnJlcGxhY2VBbGwoJ2ZtZm0nLCAnZm0nKTsgLy8gIuyXkO2UhOyXoCDtj6zsnKAiIOKGkiBmbTR1CiAgfQoKICBzdGF0aWMgU3RyaW5nIF9zdHJpcChTdHJpbmcgdCwgTGlzdDxTdHJpbmc+IHdvcmRzKSB7CiAgICBmb3IgKGZpbmFsIHcgaW4gd29yZHMpIHsKICAgICAgdCA9IHQucmVwbGFjZUFsbCh3LCAnJyk7CiAgICB9CiAgICByZXR1cm4gdDsKICB9CgogIHN0YXRpYyBGdXR1cmU8dm9pZD4gcGxheShTdHJpbmcgcXVlcnksIE1hcDxTdHJpbmcsIGR5bmFtaWM+PyBleHRyYXMpIGFzeW5jIHsKICAgIGZpbmFsIHBwID0gX3BwLCByYWRpbyA9IF9yYWRpbywgbXVzaWMgPSBfbXVzaWM7CiAgICBpZiAocHAgPT0gbnVsbCB8fCByYWRpbyA9PSBudWxsIHx8IG11c2ljID09IG51bGwpIHJldHVybjsKICAgIHRyeSB7CiAgICAgIGZpbmFsIHFTdGF0aW9uID0gX3N0cmlwKF9ub3JtKHF1ZXJ5KSwgX2ZpbGxlcnMpOwogICAgICBmaW5hbCBxID0gX3N0cmlwKHFTdGF0aW9uLCBfa2luZHMpOwogICAgICBmaW5hbCB3YW50c1JhZGlvID0gcVN0YXRpb24uY29udGFpbnMoJ+udvOuUlOyYpCcpIHx8IHFTdGF0aW9uLmNvbnRhaW5zKCdyYWRpbycpOwogICAgICBmaW5hbCBleCA9IGV4dHJhcyA/PyBjb25zdCA8U3RyaW5nLCBkeW5hbWljPnt9OwogICAgICBmaW5hbCBleEFydGlzdCA9IF9ub3JtKCcke2V4WydhbmRyb2lkLmludGVudC5leHRyYS5hcnRpc3QnXSA/PyAnJ30nKTsKICAgICAgZmluYWwgZXhUaXRsZSA9IF9ub3JtKCcke2V4WydhbmRyb2lkLmludGVudC5leHRyYS50aXRsZSddID8/ICcnfScpOwogICAgICBmaW5hbCBleEFsYnVtID0gX25vcm0oJyR7ZXhbJ2FuZHJvaWQuaW50ZW50LmV4dHJhLmFsYnVtJ10gPz8gJyd9Jyk7CgogICAgICAvLyAxKSDsnbTrpoQg7JeG7J20ICLtjIzrnoDshozrpqwg7YuA7Ja07KSYIiAvICLrnbzrlJTsmKQg7YuA7Ja07KSYIgogICAgICBpZiAocS5pc0VtcHR5ICYmIGV4QXJ0aXN0LmlzRW1wdHkgJiYgZXhUaXRsZS5pc0VtcHR5ICYmIGV4QWxidW0uaXNFbXB0eSkgewogICAgICAgIGlmICh3YW50c1JhZGlvKSB7CiAgICAgICAgICBmaW5hbCBzID0gbmljZUtvcmVhblN0YXRpb25Ob3coKTsKICAgICAgICAgIGlmIChzICE9IG51bGwpIGF3YWl0IF9wbGF5U3RhdGlvbihyYWRpbywgcyk7CiAgICAgICAgICByZXR1cm47CiAgICAgICAgfQogICAgICAgIGlmIChyYWRpby5pc1BsYXlpbmcgfHwgcHAuaXNQbGF5aW5nKSByZXR1cm47IC8vIOydtOuvuCDrk6PripQg7KSR7J2066m0IOq3uOuMgOuhnAogICAgICAgIGF3YWl0IEhlYWRzZXRSZXN1bWUud2lkZ2V0UGxheSgpOyAvLyDrp4jsp4Drp4nsl5Ag65Oj642YIOqygwogICAgICAgIHJldHVybjsKICAgICAgfQoKICAgICAgLy8gMikg652865SU7JikIOuwqeyGoSDsnbTrpoQKICAgICAgaWYgKGV4QXJ0aXN0LmlzRW1wdHkgJiYgZXhUaXRsZS5pc0VtcHR5ICYmIGV4QWxidW0uaXNFbXB0eSkgewogICAgICAgIGZpbmFsIGxpc3QgPSBrb3JlYW5SYWRpb1N0YXRpb25zKCk7CiAgICAgICAgdmFyIGJlc3QgPSAtMSwgYmVzdFNjb3JlID0gMDsKICAgICAgICBmaW5hbCBsb29zZSA9IHdhbnRzUmFkaW8gfHwgcS5jb250YWlucygnZm0nKSB8fCBxLmNvbnRhaW5zKCdhbScpOwogICAgICAgIGZvciAodmFyIGkgPSAwOyBpIDwgbGlzdC5sZW5ndGg7IGkrKykgewogICAgICAgICAgZmluYWwga2V5ID0gX25vcm0obGlzdFtpXS5uYW1lKTsKICAgICAgICAgIGlmIChrZXkuaXNFbXB0eSkgY29udGludWU7CiAgICAgICAgICB2YXIgc2NvcmUgPSAwOwogICAgICAgICAgaWYgKHFTdGF0aW9uLmNvbnRhaW5zKGtleSkpIHsKICAgICAgICAgICAgc2NvcmUgPSBrZXkubGVuZ3RoICogMjsgLy8g67Cp7IahIOydtOumhOydhCDri6Qg66eQ7ZWoCiAgICAgICAgICB9IGVsc2UgaWYgKGxvb3NlICYmIHEubGVuZ3RoID49IDIgJiYga2V5LmNvbnRhaW5zKHEpKSB7CiAgICAgICAgICAgIHNjb3JlID0gcS5sZW5ndGg7IC8vICLsv6hGTSLsspjrn7wg7J2867aA66eMIOunkO2VqAogICAgICAgICAgfQogICAgICAgICAgaWYgKHNjb3JlID4gYmVzdFNjb3JlKSB7CiAgICAgICAgICAgIGJlc3RTY29yZSA9IHNjb3JlOwogICAgICAgICAgICBiZXN0ID0gaTsKICAgICAgICAgIH0KICAgICAgICB9CiAgICAgICAgaWYgKGJlc3QgPj0gMCkgewogICAgICAgICAgcmFkaW8uc2V0UXVldWUobGlzdCwgYmVzdCk7IC8vIOydtOyghMK364uk7J2MIOuwqeyGoeuPhCDrkJjqsowKICAgICAgICAgIGF3YWl0IHJhZGlvLnBsYXlTdGF0aW9uKGxpc3RbYmVzdF0pOwogICAgICAgICAgcmV0dXJuOwogICAgICAgIH0KICAgICAgICBpZiAod2FudHNSYWRpbykgewogICAgICAgICAgZmluYWwgcyA9IG5pY2VLb3JlYW5TdGF0aW9uTm93KCk7CiAgICAgICAgICBpZiAocyAhPSBudWxsKSBhd2FpdCBfcGxheVN0YXRpb24ocmFkaW8sIHMpOwogICAgICAgICAgcmV0dXJuOwogICAgICAgIH0KCiAgICAgICAgLy8gMykg7J6Q7Jew7IaM66asICgi67mX7IaM66asIO2LgOyWtOykmCIpCiAgICAgICAgU3RyaW5nPyBuYXR1cmU7CiAgICAgICAgU3RyaW5nPyBuYXR1cmVQYXRoOwogICAgICAgIHZhciBuYXR1cmVMZW4gPSAwOwogICAgICAgIGZvciAoZmluYWwgbiBpbiBQbGF5ZXJQcm92aWRlci5uYXR1cmVTb3VuZE9yZGVyKSB7CiAgICAgICAgICBmaW5hbCBrZXkgPSBfbm9ybShuWyduYW1lJ10hKTsKICAgICAgICAgIGlmIChrZXkubGVuZ3RoID4gbmF0dXJlTGVuICYmIHEuY29udGFpbnMoa2V5KSkgewogICAgICAgICAgICBuYXR1cmUgPSBuWyduYW1lJ107CiAgICAgICAgICAgIG5hdHVyZVBhdGggPSBuWydhc3NldFBhdGgnXTsKICAgICAgICAgICAgbmF0dXJlTGVuID0ga2V5Lmxlbmd0aDsKICAgICAgICAgIH0KICAgICAgICB9CiAgICAgICAgaWYgKG5hdHVyZSAhPSBudWxsICYmIG5hdHVyZVBhdGggIT0gbnVsbCkgewogICAgICAgICAgYXdhaXQgcHAucGxheU5hdHVyZVNvdW5kKG5hdHVyZVBhdGgsIG5hdHVyZSk7CiAgICAgICAgICByZXR1cm47CiAgICAgICAgfQogICAgICB9CgogICAgICAvLyA0KSDrgrQg7J2M7JWFICjsoJzrqqkgwrcg6rCA7IiYIMK3IOyVqOuylCkKICAgICAgaWYgKG11c2ljLmFsbFNvbmdzLmlzRW1wdHkgJiYgIW11c2ljLmlzTG9hZGluZykgYXdhaXQgbXVzaWMuaW5pdGlhbGl6ZSgpOwogICAgICBmaW5hbCBzb25ncyA9IG11c2ljLmFsbFNvbmdzLndoZXJlKChzKSA9PiBzLnVyaSAhPSBudWxsICYmICFtdXNpYy5pc0NhbGxSZWNvcmRpbmdQYXRoKHMudXJpKSkudG9MaXN0KCk7CiAgICAgIGlmIChzb25ncy5pc0VtcHR5KSByZXR1cm47CiAgICAgIFN0cmluZyB0KFNvbmcgcykgPT4gX25vcm0ocy50aXRsZURpc3BsYXkpOwogICAgICBTdHJpbmcgYShTb25nIHMpID0+IF9ub3JtKHMuYXJ0aXN0RGlzcGxheSk7CiAgICAgIFN0cmluZyBhbChTb25nIHMpID0+IF9ub3JtKHMuYWxidW1EaXNwbGF5KTsKCiAgICAgIExpc3Q8U29uZz4gZm91bmQgPSBbXTsKICAgICAgdmFyIHNodWZmbGUgPSBmYWxzZTsKICAgICAgaWYgKGV4QXJ0aXN0LmlzTm90RW1wdHkgfHwgZXhUaXRsZS5pc05vdEVtcHR5IHx8IGV4QWxidW0uaXNOb3RFbXB0eSkgewogICAgICAgIGZvdW5kID0gc29uZ3MKICAgICAgICAgICAgLndoZXJlKChzKSA9PgogICAgICAgICAgICAgICAgKGV4QXJ0aXN0LmlzRW1wdHkgfHwgYShzKS5jb250YWlucyhleEFydGlzdCkpICYmCiAgICAgICAgICAgICAgICAoZXhUaXRsZS5pc0VtcHR5IHx8IHQocykuY29udGFpbnMoZXhUaXRsZSkpICYmCiAgICAgICAgICAgICAgICAoZXhBbGJ1bS5pc0VtcHR5IHx8IGFsKHMpLmNvbnRhaW5zKGV4QWxidW0pKSkKICAgICAgICAgICAgLnRvTGlzdCgpOwogICAgICAgIHNodWZmbGUgPSBleFRpdGxlLmlzRW1wdHk7IC8vIOqwgOyImMK37JWo67KU66eMIOunkO2VmOuptCDshJ7slrTshJwKICAgICAgfQogICAgICBpZiAoZm91bmQuaXNFbXB0eSAmJiBxLmlzTm90RW1wdHkpIHsKICAgICAgICBmb3VuZCA9IHNvbmdzLndoZXJlKChzKSA9PiB0KHMpID09IHEpLnRvTGlzdCgpOyAvLyDsoJzrqqkg6re464yA66GcCiAgICAgICAgaWYgKGZvdW5kLmlzRW1wdHkpIHsKICAgICAgICAgIGZvdW5kID0gc29uZ3Mud2hlcmUoKHMpID0+IGEocykgPT0gcSB8fCAocS5sZW5ndGggPj0gMiAmJiBhKHMpLmNvbnRhaW5zKHEpKSkudG9MaXN0KCk7IC8vIOqwgOyImAogICAgICAgICAgc2h1ZmZsZSA9IGZvdW5kLmlzTm90RW1wdHk7CiAgICAgICAgfQogICAgICAgIGlmIChmb3VuZC5pc0VtcHR5KSBmb3VuZCA9IHNvbmdzLndoZXJlKChzKSA9PiBxLmxlbmd0aCA+PSAyICYmIHQocykuY29udGFpbnMocSkpLnRvTGlzdCgpOyAvLyDsoJzrqqkg7J2867aACiAgICAgICAgaWYgKGZvdW5kLmlzRW1wdHkpIHsKICAgICAgICAgIGZvdW5kID0gc29uZ3Mud2hlcmUoKHMpID0+IHEubGVuZ3RoID49IDIgJiYgYWwocykuY29udGFpbnMocSkpLnRvTGlzdCgpOyAvLyDslajrspQKICAgICAgICAgIHNodWZmbGUgPSBmYWxzZTsKICAgICAgICB9CiAgICAgIH0KICAgICAgaWYgKGZvdW5kLmlzRW1wdHkpIHsKICAgICAgICAvLyDrqrsg7LC+7Jy866m0OiDrk6PrjZgg6rKMIOyXhuydhCDrlYzrp4wg66eI7KeA66eJ7JeQIOuTo+uNmCDqsoMKICAgICAgICBpZiAoIXJhZGlvLmlzUGxheWluZyAmJiAhcHAuaXNQbGF5aW5nKSBhd2FpdCBIZWFkc2V0UmVzdW1lLndpZGdldFBsYXkoKTsKICAgICAgICByZXR1cm47CiAgICAgIH0KICAgICAgaWYgKHNodWZmbGUpIGZvdW5kLnNodWZmbGUoKTsKICAgICAgYXdhaXQgcHAucGxheUZyb21MaXN0KGZvdW5kLCAwKTsKICAgIH0gY2F0Y2ggKGUpIHsKICAgICAgZGVidWdQcmludCgn66eQ66GcIO2LgOq4sCDsmKTrpZg6ICRlJyk7CiAgICB9CiAgfQoKICBzdGF0aWMgRnV0dXJlPHZvaWQ+IF9wbGF5U3RhdGlvbihSYWRpb1Byb3ZpZGVyIHJhZGlvLCBSYWRpb1N0YXRpb24gcykgYXN5bmMgewogICAgZmluYWwgbGlzdCA9IGtvcmVhblJhZGlvU3RhdGlvbnMoKTsKICAgIGZpbmFsIGkgPSBsaXN0LmluZGV4V2hlcmUoKHgpID0+IHgubmFtZSA9PSBzLm5hbWUpOwogICAgaWYgKGkgPj0gMCkgcmFkaW8uc2V0UXVldWUobGlzdCwgaSk7CiAgICBhd2FpdCByYWRpby5wbGF5U3RhdGlvbihpID49IDAgPyBsaXN0W2ldIDogcyk7CiAgfQp9Cg=='
).decode('utf-8')  # 새 파일 voice_search.dart 내용

PLAYER_EDITS = [
    ('말로 틀기 파일 불러오기',
     "import '../services/headset_resume.dart';\n",
     "import '../services/headset_resume.dart';\nimport '../services/voice_search.dart';\n", 1),
    ('처음부터 말로 틀기 받을 수 있다고 알리기',
     "  SimpleAudioHandler(this._provider) : _player = _provider.player {\n",
     "  // 구글 어시스턴트가 '검색해서 틀기'를 보낼 수 있다고 알려 두기\n"
     "  static const _voiceActions = {MediaAction.playFromSearch};\n\n"
     "  SimpleAudioHandler(this._provider) : _player = _provider.player {\n"
     "    playbackState.add(playbackState.value.copyWith(systemActions: _voiceActions)); // 앱이 막 켜졌을 때도\n", 1),
    ('라디오·믹스 재생 상태에도 알리기',
     "      androidCompactActionIndices: const [0, 1, 2],\n      playing: playing,\n",
     "      androidCompactActionIndices: const [0, 1, 2],\n      systemActions: _voiceActions,\n      playing: playing,\n", 2),
    ('음악·자연 재생 상태에도 알리기',
     "      androidCompactActionIndices: const [0, 1, 2],\n      processingState: const {\n",
     "      androidCompactActionIndices: const [0, 1, 2],\n      systemActions: _voiceActions,\n      processingState: const {\n", 1),
    ('구글이 보낸 글자 받기',
     "  /// 완전히 끝: '정지(idle)'로 알려야",
     "  // 말로 틀기: \"헤이 구글, 파란소리에서 ○○ 틀어줘\" → 구글이 보낸 글자로 찾아서 틀기\n"
     "  @override\n"
     "  Future<void> playFromSearch(String query, [Map<String, dynamic>? extras]) =>\n"
     "      VoiceSearch.play(query, extras);\n\n"
     "  /// 완전히 끝: '정지(idle)'로 알려야", 1),
]

MAIN_EDITS = [
    ('말로 틀기 파일 불러오기 (main)',
     "import 'services/headset_resume.dart';\n",
     "import 'services/headset_resume.dart';\nimport 'services/voice_search.dart';\n", 1),
    ('말로 틀기 준비',
     "  HeadsetResume.attachRecent(recentContentProvider, musicProvider); // 위젯 재생: 마지막에 듣던 것\n",
     "  HeadsetResume.attachRecent(recentContentProvider, musicProvider); // 위젯 재생: 마지막에 듣던 것\n"
     "  VoiceSearch.init(playerProvider, radioProvider, musicProvider); // \"헤이 구글, 파란소리에서 ○○ 틀어줘\"\n", 1),
]


def load(p):
    with open(p, 'rb') as f:
        raw = f.read().decode('utf-8')
    return raw.replace('\r\n', '\n'), '\r\n' in raw


def edit(path, edits):
    if not os.path.exists(path):
        print('❌ 파일을 못 찾았어요:', path, '— 아무것도 저장 안 했어요')
        sys.exit(1)
    text, crlf = load(path)
    for name, old, new, cnt in edits:
        n = text.count(old)
        if n != cnt:
            print('❌', name, '(찾은 개수: %d) — 아무것도 저장 안 했어요' % n)
            sys.exit(1)
        text = text.replace(old, new)
        print('✔', name)
    return text, crlf


def main():
    if os.path.exists(NEW_FILE):
        print('이미 적용돼 있어요')
        return
    player = edit(PLAYER, PLAYER_EDITS)
    main_ = edit(MAIN, MAIN_EDITS)
    for path, (text, crlf) in [(PLAYER, player), (MAIN, main_)]:
        if crlf:
            text = text.replace('\n', '\r\n')
        with open(path, 'wb') as f:
            f.write(text.encode('utf-8'))
    os.makedirs(os.path.dirname(NEW_FILE), exist_ok=True)
    with open(NEW_FILE, 'wb') as f:
        f.write(VOICE_SRC.replace('\n', '\r\n').encode('utf-8'))
    print('✔ 새 파일 만들었어요:', NEW_FILE)
    print('✔ 저장했어요')


main()
