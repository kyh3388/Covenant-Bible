enum BibleDisplayMode { krv, kjv, krvKjv }

extension BibleDisplayModeX on BibleDisplayMode {
  String get label {
    switch (this) {
      case BibleDisplayMode.krv:
        return '개역한글';
      case BibleDisplayMode.kjv:
        return 'KJV';
      case BibleDisplayMode.krvKjv:
        return '개역한글/KJV';
    }
  }

  bool get isKoreanOnly => this == BibleDisplayMode.krv;

  bool get isEnglishOnly => this == BibleDisplayMode.kjv;

  bool get isBilingual => this == BibleDisplayMode.krvKjv;
}
