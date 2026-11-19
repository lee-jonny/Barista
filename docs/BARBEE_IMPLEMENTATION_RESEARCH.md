# Barbee 구현 공개 근거 조사

조사일: 2026-10-03 (Asia/Seoul). 조사 대상: Barbee 개발자가 공개한 앱스토어 설명·버전 기록, 직접 작성한 V2EX 게시글과 댓글, GitHub 저장소. 생산 코드는 변경하지 않았다. 공개 증거와 추론을 구분하며, Barbee 바이너리를 역공학하거나 실제 동작을 검증한 보고서는 아니다.

## 결론

**Barbee는 화면 캡처와 이미지 비교를 이용한 메뉴 관리 방식이 있었고, 별도 helper app도 사용한 이력이 있다.** 따라서 “앱스토어 메뉴 관리자도 Barista와 같은 private assessment bridge를 써야 한다”는 가정은 맞지 않는다. 그러나 **현재 Barbee 5.0의 숨김 구현, helper의 sandbox entitlement, 외부 설치 여부, App Review 승인 사유는 공개 자료로 확정하지 못했다.** 별도 helper가 있다는 사실만으로 샌드박스 밖에서 실행된다고 단정할 수 없다.

이 조사로 Barista의 `MenuBarClientCore` 방식이 앱스토어에 적합해지는 것은 아니다. 대신 화면 기반 탐지·사용자 입력 자동화·기능별 모드 구분 등, 다른 구현을 조사할 근거가 생겼다.

## 확인한 사실

### 개발자의 구현 설명: 화면 캡처와 비교

개발자는 2024-05-07 V2EX 댓글 #72에서 숨긴 아이콘을 화면 녹화·스크린샷 비교로 찾는지 묻는 질문에 긍정하고, 스크린샷 권한을 받아 비교 작업을 한다고 설명했다. 문서가 거의 없으며 실제 구현 규모가 예상보다 커졌다고 덧붙였다. 이는 당시 버전의 구현 설명이며 5.0 전체 구조를 증명하지 않는다. [개발자 게시글·댓글 #71–72](https://www.v2ex.com/t/1037737#reply72)

같은 게시글의 2024-05-05 댓글 #12에서 개발자는 일반 모드에서는 아이콘 정리와 화면 녹화가 발생하지 않으며 Hidden Bar의 강화판과 비슷하다고 설명했다. 강화 모드와 일반 모드에 서로 다른 기능·권한 요구가 있었음을 보여준다. 정확한 일반 모드의 숨김 알고리즘은 설명하지 않았다. [개발자 댓글 #12](https://www.v2ex.com/t/1037737#reply12)

댓글 #6에서는 처음 설치 시 순서 정리가 필요해 커서 움직임이 생길 수 있다고 설명하고, #24에서는 강화 모드의 드래그 순서 저장을 안내했다. **마우스 동작과 연결된 정리 구현의 흔적**이지, 사용한 CGEvent API나 AX API를 특정하는 근거는 아니다. [개발자 댓글 #6, #24](https://www.v2ex.com/t/1037737)

### 공식 앱스토어 버전 기록

공식 기록은 아래를 명시한다. 본문 기능 안내와 변경 기록은 개발자 작성 내용이며 독립적인 실사용 검증은 아니다. [Barbee App Store 버전 기록](https://apps.apple.com/gb/app/barbee-hide-menu-bar-items/id1548711022?mt=12)

| 버전·게시일 | 확인되는 구현·호환성 단서 |
| --- | --- |
| 3.5.7 · 2024-10-22 | 이미지 매칭 알고리즘 최적화 |
| 3.5.8 · 2024-11-28 | 메뉴 아이콘 순서를 위한 drag/drop 재구현 |
| 3.6.1 · 2025-02-12 | 화면 캡처 알림 관련 해결책 추가 |
| 4.1 · 2025-09-11 | macOS 26 호환 명시 |
| 4.1.1 · 2025-09-28 | helper app의 에너지 소비 문제 수정 |
| 5.0 · 2026-09-10 | 최신 macOS 호환성과 안정성을 위한 코드 재구성 |

**5.0 기록은 macOS 27이라는 버전명을 직접 명시하지 않는다.** macOS 26에서의 방식을 그대로 27로 일반화하거나, 27에서 모든 기능이 동작한다고 확정하면 안 된다. 스크린샷 권한 설명과 helper 기록은 서로 다른 시점의 증거다.

### 앱스토어와 TestFlight 구분

개발자는 2024 게시글에서 정식 다운로드로 Mac App Store를 연결하고, 버그가 있는 경우 TestFlight 버전을 따로 안내했다. 따라서 공개 글에서 “Barbee가 동작한다”는 사례는 정식 빌드인지 TestFlight 빌드인지 확인해야 한다. 이 링크만으로 현재 TestFlight 빌드·helper의 배포 경로를 알 수는 없다. [개발자 게시글](https://www.v2ex.com/t/1037737), [안내된 TestFlight 채널](https://testflight.apple.com/join/HPKNaKKv)

## 개발자의 별도 샌드박스 실험: Barbee와의 연결은 미확인

같은 GitHub 계정에는 `mas-plugins-solution`이라는 공개 샌드박스 플러그인 예제가 있다. README는 Mac App Sandbox용 플러그인 실험이라고만 설명한다. [저장소](https://github.com/HsiangHo/mas-plugins-solution)

공개 소스의 demo는 sandbox entitlement를 켠다. 플러그인 코드는 사용자 파일 선택·bookmark 권한을 거쳐 패키지를 임시 위치에 풀고, pasteboard로 인수를 전달하며 `NSWorkspace`로 별도 loader를 실행한다. loader는 별도 실행 파일을 띄우고 관리자 실행 분기에는 오래된 `AuthorizationExecuteWithPrivileges` 코드도 있다. loader의 entitlement 파일에도 sandbox가 켜져 있다. [demo entitlement](https://github.com/HsiangHo/mas-plugins-solution/blob/master/mas-plugin-demo/mas-plugin-demo/mas-plugin-demo.entitlements), [플러그인 코드](https://github.com/HsiangHo/mas-plugins-solution/blob/master/mas-plugin/mas-plugin/pluginObject/MPPluginObject.m), [loader main](https://github.com/HsiangHo/mas-plugins-solution/blob/master/mas-plugin-loader/mas-plugin-loader/mas-plugin-loader/main.m), [loader entitlement](https://github.com/HsiangHo/mas-plugins-solution/blob/master/mas-plugin-loader/mas-plugin-loader/mas-plugin-loader/mas_plugin_loader.entitlements)

이는 개발자의 과거 별도 프로세스·플러그인 설계 실험을 보여주는 자료일 뿐, **Barbee가 이 코드를 사용한다는 연결 증거는 없다.** 오래된 예제를 현 OS나 현 App Review에서 허용되는 해법으로 추천하지 않는다.

## 미확인 항목

- Barbee 5.0은 어떤 API로 타 앱 아이콘을 실제 숨기거나 다시 배치하는가? 이미지 인식·입력 자동화·폭을 이용한 밀어내기·private API 사용 중 어느 조합인가?
- helper는 앱 번들 내부 구성요소인가, 별도로 설치되는 외부 앱인가? 어떤 서명과 sandbox entitlement로 실행되는가?
- macOS 27에서는 과거 일반 모드/강화 모드와 API 경로가 유지되는가?
- 공개 API만 사용하는가? 심사에 임시 예외나 별도 조건을 제시했는가? 개별 승인 사유는 공개되지 않았다.
- App Store 배포본, TestFlight, 외부 helper에 동일한 기능과 권한 요구가 적용되는가?

`Barbee-Feedback` 공개 저장소의 루트는 한 줄 README뿐이다. 위키는 Home·Privacy Policy·Terms of Use 세 페이지이며 기술 문서는 확인되지 않았다. 전체 공개 이슈·댓글 API 조회에서도 개발자 본인의 구현 답변은 확인하지 못했다. 사용자 진단 글은 출처가 개발자의 공식 저장소라는 이유만으로 개발자 설명이 되지 않으므로 구현 확정 근거로 쓰지 않았다. [공개 저장소](https://github.com/HsiangHo/Barbee-Feedback), [이슈](https://github.com/HsiangHo/Barbee-Feedback/issues), [위키](https://github.com/HsiangHo/Barbee-Feedback/wiki)

## Barista에 대한 시사점

기존 전환 검토의 “현재 private bridge와 AX client 구조를 단순 교체하여 동일 UX를 유지할 승인된 경로를 확인하지 못했다”는 결론은 유지된다. 다만 이는 **가능한 모든 메뉴 관리 앱 설계를 배제하는 결론이 아니다.** Barbee는 화면 기반 처리와 helper를 포함하는 다른 구조를 검토할 필요가 있음을 보여준다.

향후 실험은 먼저 캡처로 아이콘을 인식할 수 있는지, 사용자 입력을 통해 배치·표시를 제어할 수 있는지, macOS 27에서도 성립하는지를 분리해 검증해야 한다. 그 뒤 각 프로세스의 공개 API·sandbox·배포 요구를 확인해야 하며, Barbee의 앱스토어 존재만으로 같은 구조의 승인 가능성을 보장할 수 없다. 현재 작동 중인 Barista 코드는 이 조사에서 변경하지 않았다.
