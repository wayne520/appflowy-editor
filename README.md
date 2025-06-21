# 📝 AppFlowy Editor (Custom Fork)

> 🛠 Flutter용 고급 Rich Text Editor - `intl 0.20.2` 호환 문제 해결 버전입니다.

---

## 📌 소개

이 저장소는 [AppFlowy Editor 공식 저장소](https://github.com/AppFlowy-IO/appflowy-editor)를 기반으로 하며,  
**Flutter SDK 최신 버전에서 `intl: ^0.20.2`로 인한 충돌을 해결한 커스텀 포크입니다.**

공식 버전에서는 `flutter_localizations`와 충돌하여 `pub get`이 실패하지만,  
이 포크는 해당 문제를 해결하여 **최신 Flutter 환경에서도 정상적으로 사용**할 수 있습니다.

---

## ✅ 사용 방법

`pubspec.yaml`에 아래처럼 추가하세요:

```yaml
dependencies:
  appflowy_editor:
    git:
      url: https://github.com/your-username/appflowy-editor.git
      ref: main
