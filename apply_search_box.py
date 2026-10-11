# -*- coding: utf-8 -*-
# 홈 검색칸: 크림 상자 · 회갈색 아이콘, 글자 있으면 ✕(지우기), 검색/목록 밀면 키보드만 내려가기
import sys, glob, os, shutil

hits = [h for h in glob.glob(os.path.join('lib', '**', 'home_screen.dart'), recursive=True)
        if os.path.basename(h) == 'home_screen.dart']
if not hits:
    print('❌ home_screen.dart 파일을 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
path = hits[0]
raw = open(path, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
if 'TextInputAction.search' in s:
    print('✔ 이미 적용돼 있어요'); sys.exit(0)

def fail(label, n):
    print(f'❌ [{label}] 찾을 곳이 {n}개예요. 아무것도 저장하지 않고 멈춰요.'); sys.exit(1)

NEW_FIELD = r"""  Widget _buildSearchField() {
    // 크림 상자 · 회갈색 아이콘 (⋮ 메뉴 카드·아이콘과 같은 색)
    final dark = context.watch<ThemeProvider>().isDarkMode;
    final ink = dark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    const iconColor = Color(0xFF8A8378);
    final hasText = _searchController.text.isNotEmpty;
    return TextField(
      controller: _searchController,
      autofocus: true,
      // 키보드 [검색] 누르면 키보드만 내려가서 결과가 다 보이게
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      cursorColor: ink,
      style: TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.searchHint,
        hintStyle: TextStyle(color: ink.withOpacity(0.38), fontSize: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: dark ? const Color(0xFF34312C) : const Color(0xFFFBF8F2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        prefixIcon: const Icon(Icons.search, color: iconColor, size: 20),
        // 글자가 있으면 ✕(글자만 지우기), 없으면 마이크
        suffixIcon: hasText
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  context.read<MusicProvider>().search('');
                  setState(() {});
                },
                icon: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(color: ink.withOpacity(0.2), shape: BoxShape.circle),
                  child: Icon(Icons.close_rounded, size: 12, color: dark ? const Color(0xFF24221F) : Colors.white),
                ),
              )
            : IconButton(
                icon: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: _isListening ? Colors.redAccent : iconColor,
                  size: 20,
                ),
                onPressed: _toggleListening,
              ),
        isDense: true,
      ),
      onChanged: (value) {
        context.read<MusicProvider>().search(value);
        setState(() {});
      },
    );
  }

"""

a_mark = "  Widget _buildSearchField() {\n"
b_mark = "  Widget _buildBody() {\n"
for m in (a_mark, b_mark):
    if s.count(m) != 1: fail('검색칸 자리', s.count(m))
a = s.index(a_mark); b = s.index(b_mark)
if b < a: fail('검색칸 순서', 0)
s = s[:a] + NEW_FIELD + s[b:]
print('✔ 검색칸: 크림 상자 · 회갈색 아이콘 · ✕ 지우기 · [검색]이면 키보드 내리기')

old = """        _scrollPokeIndexBar();
      }
    });"""
new = """        _scrollPokeIndexBar();
        // 검색 중에 목록을 밀면 키보드만 내려가기
        if (_isSearching) FocusManager.instance.primaryFocus?.unfocus();
      }
    });"""
if s.count(old) != 1: fail('목록 밀면 키보드 내리기', s.count(old))
s = s.replace(old, new)
print('✔ 목록 밀면 키보드 내려가기')

old = """              child: Text(AppLocalizations.of(context)!.cancel,
                  style: TextStyle(color: baseColor.withOpacity(0.7), fontWeight: FontWeight.w600)),"""
new = """              child: Text(AppLocalizations.of(context)!.cancel,
                  style: TextStyle(color: baseColor, fontWeight: FontWeight.w700)),"""
if s.count(old) != 1: fail("'취소' 글자", s.count(old))
s = s.replace(old, new)
print("✔ '취소' 먹색으로 또렷하게")

shutil.copy(path, path + '.bak_search')
if crlf: s = s.replace('\n', '\r\n')
open(path, 'wb').write(s.encode('utf-8'))
print('끝! (원본은 .bak_search)')
