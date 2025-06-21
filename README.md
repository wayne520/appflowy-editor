# 📝 AppFlowy Editor (Custom Fork)

> 🛠 A Rich Text Editor for Flutter - Fixed for intl 0.20.2 compatibility  
> 🛠 Flutter용 고급 리치 텍스트 에디터 - intl 0.20.2 호환 문제 해결 버전입니다

---

## 📌 Introduction | 소개

This repository is a **custom fork** of [AppFlowy Editor](https://github.com/AppFlowy-IO/appflowy-editor),  
resolving compatibility issues with `intl: ^0.20.2` when used with `flutter_localizations`.

이 저장소는 [AppFlowy Editor 공식 저장소](https://github.com/AppFlowy-IO/appflowy-editor)의 **포크(fork)**이며,  
Flutter 최신 버전에서 `flutter_localizations`와 `intl` 패키지 간 충돌 문제를 해결합니다.

---

## ✅ How to Use | 사용 방법

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  appflowy_editor:
    git:
      url: https://github.com/your-username/appflowy-editor.git
      ref: main
  flutter_localizations:
    sdk: flutter
