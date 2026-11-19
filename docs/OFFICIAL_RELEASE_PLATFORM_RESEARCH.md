# Barista 공식 출시 재설계를 위한 플랫폼 조사

조사일: 2026-10-03 (Asia/Seoul). 대상: Apple 공개 문서·Apple DTS 답변·설치된 macOS 27 SDK·메뉴 관리 도구의 개발자 공개 설명. 이 문서는 **기술 구현 가능성, 지원되는 API 계약, App Review 승인**을 별도로 판정한다. 생산 코드 수정, 외부 앱 설치·실행, 권한 변경, assessment 세션 실행은 하지 않았다. 별도 실험의 결과와 제품 재설계는 [공식 출시 재설계](OFFICIAL_RELEASE_REDESIGN.md)에서 관리한다.

## 판단

**Helper를 기본 전제로 삼기보다, 공개 `NSStatusItem`의 폭을 조정하여 macOS의 overflow를 사용하는 최소 Sandbox 앱을 먼저 검증할 가치가 있다.** 이것이 사용자가 만족한 현재의 개별 bundle ID 숨김 기능과 같지는 않다. 그러나 메뉴 막대를 정리한다는 제품 목적을 유지하면서 private assessment bridge, AX client, 화면 캡처 없이 출발할 후보가 된다. 해당 geometry 방식이 모든 디스플레이·재부팅·새 앱·macOS 업데이트에서 안정적이고 App Review에 수용되는지는 독립 검증이 필요하다.

화면 기반 아이콘 탐지는 두 번째 연구축이다. **ScreenCaptureKit으로 메뉴 막대의 픽셀을 얻는 것**에는 공개 API 후보가 있지만, **각 픽셀의 소유 앱을 확정하고, 숨겨진 아이콘의 실제 메뉴를 열고, 자동으로 드래그하는 것**까지 해결하지 않는다. 처음부터 화면 캡처+Helper를 필수로 만들면 신뢰·권한·배터리·설치·심사 문제를 함께 떠안게 된다. 이는 플랫폼 자료에 근거한 제품 설계 권고이며 Apple의 심사 결정은 아니다.

## 1. 단순 폭 확장과 macOS 27 대응 폭 확장은 다르다

MenubarHide 작성자는 macOS 27에서 단일 상태 아이템의 길이가 화면 폭의 절반 부근에 이르면 버려지는 현상을 기록한다. README의 비노치 설명은 가장 좁은 디스플레이에 대해 `max(200, floor(width / 2 - 64))`이며, 실제 소스는 노치 화면에서 오른쪽 status 영역에 대한 `max(200, floor(statusWidth * 0.75 - 64))`를 추가한다. separator와 최대 6개 spacer를 함께 확장한다. 왼쪽 아이콘은 시스템 `«` overflow로 이동하며, 사용자는 Command-drag로 경계를 정한다. 같은 문서는 27에서는 종전의 per-icon window 패널·배치 복원이 꺼지고 기본 sideways 모드에는 권한이 필요 없다고 설명한다. 이것은 **작성자의 구현·테스트 주장**이며 Apple의 안정성 보증이나 Barista 실측 결과가 아니다. [개발자 README](https://github.com/junior-rj/menubar-hide#macos-27), [고정 revision 소스](https://github.com/junior-rj/menubar-hide/blob/6d1a9c50fd939cf1a6c038681037db8f8f748e2f/MenubarHide/CollapsedGeometry.swift)

이 증거는 이전 [App Store 가능성 검토](APP_STORE_FEASIBILITY.md)의 “기존 큰 폭 separator 방식은 macOS 27에서 깨진다”는 설명을 세분화한다. **10,000pt 한 개가 실패한다는 관찰을 모든 공개 geometry 방식의 불가능으로 일반화하면 안 된다.** 공개 `NSStatusItem.length`로 앱 자신의 아이템 폭을 조정하는 것과 타 앱의 표시 속성을 직접 제어하는 API는 여전히 별개다. [NSStatusItem.length](https://developer.apple.com/documentation/appkit/nsstatusitem/length)

Barista에서 검증할 지점:

- Sandbox 서명 빌드에서 자체 아이템만 조정했는지, 타 앱 환경설정·AX·private API·합성 입력 없이 숨김과 복원이 되는지 확인한다.
- `«`가 보여도 제품 약속이 성립하는지, 펼칠 때 divider나 여분의 빈 폭이 어느 정도 생기는지 측정한다. 기존 단일 커피콩 아이콘과 동일한 외관이라고 약속하지 않는다.
- 노치, 작은 화면과 큰 외부 화면의 조합, 메뉴가 긴 전면 앱, Space·전체 화면·자동 숨김 메뉴 막대, 연결 해제·해상도 변경, 앱 아이콘 추가·종료·재부팅을 확인한다.
- 여러 spacer를 사용하는 숨김은 bundle ID 단위 allowlist가 아니다. 그룹은 실제 위치에 의존하며 신규 앱을 정확히 자동 분류한다는 기능은 별도로 검증해야 한다.

### 후속 명확화: 커피콩 아이콘과 시스템 `«`는 다른 제어 대상

사용자는 공식 Store 버전에서도 현재 커피콩 또는 자신이 지정한 아이콘과 거의 같은 기능을 유지하기를 원한다. **앱 자신의 토글 아이콘은 공개 API로 유지할 수 있다.** Apple의 `NSStatusItem.button` 문서는 `image`, `target`, `action`, tooltip 변경을 허용한다. macOS 27 SDK의 `NSStatusBarButton.h`도 template image를 메뉴 막대의 밝기·상태에 맞게 그린다고 설명한다. geometry backend를 사용하는 것 자체가 Barista의 버튼 그림을 `«`로 바꾸도록 요구하는 것은 아니다. [NSStatusItem.button](https://developer.apple.com/documentation/appkit/nsstatusitem/button), [NSStatusBarButton](https://developer.apple.com/documentation/appkit/nsstatusbarbutton)

반면 **시스템 overflow의 `«`를 커피콩으로 교체·숨김·병합하는 공개 경로는 이번 조사에서 찾지 못했다.** macOS 27 SDK의 `NSStatusBar.h`, `NSStatusItem.h`, `NSStatusBarButton.h` 전체 선언을 확인하고 AppKit headers와 SwiftUI module interface에서 status/menu bar overflow 제어를 검색했다. 자신의 `length`, `isVisible`, `button`, menu, expanded interface만 확인됐으며 시스템 overflow button의 이미지·표시·target/action을 지정하는 API는 확인하지 못했다. 이것은 확인한 공개 API 표면의 한계이고 모든 구현의 절대 불가능을 증명하는 결론은 아니다. [NSStatusBar](https://developer.apple.com/documentation/appkit/nsstatusbar), [NSStatusItem](https://developer.apple.com/documentation/appkit/nsstatusitem)

따라서 overflow를 숨김 수단으로 쓰는 후보는 **Barista 커피콩 버튼은 유지하지만 접힌 상태에 시스템 `«`가 함께 생길 수 있는 UX**다. 커피콩을 눌러 spacer 폭을 줄이거나 펼치는 동작은 우리 버튼의 action으로 설계할 수 있으나, 시스템 `«` 자체의 교체나 같은 위치 유지까지 보장하지 못한다. OS 표시 여부·실제 위치·복원은 실험 대상이다. macOS 27의 새 `expandedInterfaceDelegate`도 앱 자신의 펼친 UI lifecycle과 키보드 탐색용이며, 다른 앱 아이콘의 system overflow controller를 위임받는 API라고 볼 근거가 없다. [NSStatusItem.expandedInterfaceDelegate](https://developer.apple.com/documentation/appkit/nsstatusitem/expandedinterfacedelegate)

사용자의 “커피콩만으로 현재와 거의 동일한 제어” 요구를 만족했다는 판정은 이 geometry 후보에 아직 내릴 수 없다. 기존 기능과 추가 시스템 버튼 사이의 차이를 감춘 채 Store 제품 경로로 확정하지 않는다.

## 2. ScreenCaptureKit: 탐지를 대체할 후보

### 공개 API에서 확인한 내용

Apple은 macOS 14의 `SCScreenshotManager`로 `SCContentFilter`와 configuration을 사용한 일회성 캡처를 설명한다. 지속 스트림을 만들지 않아도 이미지나 sample buffer를 받을 수 있다. 시스템 `SCContentSharingPicker`로 사용자가 선택한 콘텐츠의 filter를 받는 경로도 있다. [WWDC23: What’s new in ScreenCaptureKit, Screenshot API](https://developer.apple.com/videos/play/wwdc2023/10136/)

설치된 macOS 27 공개 SDK 헤더에서 다음 선언과 주석을 확인했다. 웹 문서 일부는 JavaScript 전용이므로 링크와 SDK 선언을 대조했다.

| 공개 선언 | SDK의 범위 | Barista 연구 용도 |
| --- | --- | --- |
| `SCContentFilter.includeMenuBar` | macOS 14.2+. display excluding filter 기본값 true, including filter 기본값 false. desktop-independent window filter에는 효과 없음. | 메뉴 막대를 포함한 display 기반 캡처 후보 |
| `SCStreamConfiguration.sourceRect` | 입력 프레임 일부를 샘플링 | 디스플레이 상단 영역만 처리 |
| `SCScreenshotManager.captureImage(in:)` | macOS 15.2+. 전역 screen space의 points, 여러 디스플레이 지원 | 작은 메뉴 영역을 일회성 이미지로 얻는 간단한 후보 |
| `SCScreenshotManager.captureScreenshot(rect:configuration:)` | macOS 26+. screenshot output 객체 반환 | SDR 이미지·커서·파일 저장 옵션을 명시한 캡처 |
| `SCScreenshotConfiguration.fileURL` | nil이면 파일 저장 안 함 | 임시 이미지를 메모리에만 보관 |
| `SCWindow.owningApplication`, `.frame` | 캡처 가능한 **창**의 소유 앱과 frame | 창 단위 정보. 아이콘별 소유자 API로 간주하면 안 됨 |

근거: [SCContentFilter](https://developer.apple.com/documentation/screencapturekit/sccontentfilter), [captureImage(in:)](https://developer.apple.com/documentation/screencapturekit/scscreenshotmanager/captureimage(in:completionhandler:)), [captureScreenshot(rect:configuration:)](https://developer.apple.com/documentation/screencapturekit/scscreenshotmanager/capturescreenshot(rect:configuration:completionhandler:)), [SCScreenshotConfiguration](https://developer.apple.com/documentation/screencapturekit/scscreenshotconfiguration), [SCWindow](https://developer.apple.com/documentation/screencapturekit/scwindow).

로컬 근거 파일: `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/Library/Frameworks/ScreenCaptureKit.framework/Headers/SCStream.h`, `SCScreenshotManager.h`, `SCShareableContent.h`. 선언 확인은 샌드박스 실행·실제 픽셀 획득·App Review를 검증하지 않는다.

### 권한·프라이버시 설계

Apple은 시스템 picker에서 선택된 콘텐츠를 캡처하는 세션은 별도 전체 화면 허용 없이 동작할 수 있다고 설명한다. 또한 캡처 중임을 보여주는 시스템 메뉴 아이템과 콘텐츠 변경·종료 UI를 제공한다. 이것은 사용자의 명시적 선택이 있는 **해당 세션**의 권한이다. 백그라운드에서 모든 메뉴 막대를 항상 읽는 권한과 동일하게 취급하면 안 된다. [WWDC23: What’s new in privacy, Screen capture picker](https://developer.apple.com/videos/play/wwdc2023/10053/?time=344)

Screen Recording 권한 상태는 `CGPreflightScreenCaptureAccess`, 요청은 `CGRequestScreenCaptureAccess`로 확인할 수 있다. Apple DTS는 macOS 27 관련 답변에서 창 metadata의 nil 여부로 권한을 추정하는 것은 미문서화 동작이며 변경될 수 있다고 경고하고, 새 창 목록에는 `SCShareableContent`를 권한다. [Apple DTS, 2026-07](https://developer.apple.com/forums/thread/839069)

Barista 제안: 설정 화면에서 사용자가 “아이콘 목록 가져오기”를 눌렀을 때만 선택·권한 흐름을 시작하고, 상단 작은 영역을 메모리에서 처리한다. 보통 동작은 geometry 엔진으로 수행하고 캡처는 선택 기능으로 둔다. 이미지나 OCR 결과를 원격 전송하지 않고, raw screenshot을 진단 로그·crash attachment에 포함하지 않는다. 캡처 거절·철회·화면 잠금·검은 프레임·display 변경은 normal 상태로 처리한다. 이는 제안이며 아직 구현·검증하지 않았다.

### 소유자 식별의 한계

`SCWindow.owningApplication`은 창의 소유자다. macOS 27에서 메뉴 막대가 `MenuBarAgent`의 단일 창으로 합쳐진다는 개발자 설명이 맞다면, 그 창의 owner를 조회해도 각 third-party 아이콘의 bundle ID가 나오지 않는다. 기존 “창 하나=아이콘 하나” 패널을 그대로 이식할 근거가 없다. [SCWindow](https://developer.apple.com/documentation/screencapturekit/scwindow), [MenubarHide 개발자 설명](https://github.com/junior-rj/menubar-hide#how-it-works)

따라서 이미지 탐지 결과는 `visual fingerprint + 화면상의 영역 + 사용자 이름 + 신뢰도`로 모델링하고 bundle ID는 별도의 확정 근거가 있을 때만 붙이는 설계가 적절하다. 동적 숫자·배터리·상태점·다크 모드·애니메이션·동일한 아이콘·노치에 가려진 영역은 ambiguity로 남겨야 한다. 숨겨졌거나 OS가 렌더링하지 않은 아이콘은 단순 display crop만으로 얻을 수 있다고 가정하지 않는다. 이 항목은 API 범위에서 도출한 추론이다.

## 3. 입력 관찰, 합성 입력, AX client를 나눠야 한다

| 기능 | 공식 근거 | 출시 판단 |
| --- | --- | --- |
| 자신의 상태 아이템 버튼·패널 입력 | 일반 AppKit | 최소 제품에 사용 |
| 글로벌 입력 관찰 | Apple DTS가 `.listenOnly` `CGEventTap`과 Input Monitoring의 Sandbox 동작을 직접 확인 | 가능 후보. 필요한 기능이 생길 때만 요구 |
| 타 앱 UI 읽기·쓰기·AXObserver | DTS는 일반 AX client를 Sandbox 앱에서 지원하지 않는다고 설명하며 temporary exception을 별도로 언급 | Store 기본 경로에서 제거 |
| `CGEventPost`로 타 앱 클릭·드래그 | 과거 불가 답변과 현대 TCC 도입 후의 미확인 가능성 발언이 공존 | 27의 실제 Sandbox 동작과 DTS 답변을 얻기 전 확정 불가 |

Input Monitoring의 실제 공개 예제는 Apple DTS의 2023 답변에 있다. `.listenOnly` tap, TCC 승인, run loop 등록을 사용하며 sandboxed macOS 13.2.1에서 확인했다. 27에서의 모든 이벤트 종류나 심사 결과를 보증하는 자료는 아니다. [Apple DTS: App with sandbox TCC deny IOHIDDeviceOpen](https://developer.apple.com/forums/thread/724608)

`CGEventPost`의 연대별 증거를 함께 읽어야 한다. 2015 DTS는 Sandbox에서 불가라고 답했고, 2022 후속 답변은 Input Monitoring이 10.15 이후 허용됨을 확인하면서 **event generation은 자세히 조사하지 않았고 같은 논리가 적용될 것 같다는 추측**임을 명시했다. 2025 별도 답변은 Input Monitoring 기술 지원과 AX privilege 미지원, App Review 정책을 구분한다. 따라서 “2022에 합성 입력이 승인됐다”도 “2015 답변만으로 27에서도 절대 불가”도 현재 근거의 범위를 벗어난다. [2015–2022 DTS 토론](https://developer.apple.com/forums/thread/28605?answerId=712736022), [2025 DTS 구분](https://developer.apple.com/forums/thread/780626)

실험은 숨김 연구와 분리한다. 자신이 만든 테스트용 target 창에서 지정된 클릭·작은 드래그를 확인하고 즉시 되돌리는 signed Sandbox probe, 서명/TCC/로그 기록, 실패 원인 분류가 필요하다. 사용자의 실제 아이콘 순서·다른 앱 상태를 임의로 바꾸는 것으로 시작하지 않는다. **이 조사에서는 합성 입력을 실행하지 않았다.** geometry 기본 제품이 안정되면 입력 자동화가 필수인지 먼저 판단할 수 있다.

## 4. System Events와 사용자 스크립트는 범용 면제권이 아니다

`com.apple.security.automation.apple-events`는 Hardened Runtime 앱이 타 앱으로 Apple Events를 보내기 위한 **사용자 권한 요청**을 허용하는 키다. App Sandbox의 target 제한은 별개이며 `com.apple.security.scripting-targets` 또는 Apple Events temporary exception으로 다뤄야 한다. 후자는 target bundle ID를 특정하고 필요성·이슈 번호를 설명하는 심사 항목이다. [Apple Events Entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.automation.apple-events), [Enabling Scripting of Other Apps](https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html), [Temporary Exception 문서](https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/AppSandboxTemporaryExceptionEntitlements.html)

로컬 macOS 27 `/System/Library/CoreServices/System Events.app/Contents/Resources/SystemEvents.sdef`를 정적으로 확인했다. `click`, `key code`, `keystroke`, `perform`과 UI process/menu bar 정의가 있다. `com.apple.systemevents.window.position` access group도 있으나 읽기·쓰기 window position/size 관련이다. **이 그룹을 메뉴 아이콘 클릭·드래그 전체 권한이라고 해석할 근거는 없다.** 스크립트 명령 존재는 Sandbox·TCC·App Review 통과를 의미하지 않는다.

`NSUserAppleScriptTask`와 `NSUserUnixTask`는 사용자가 `ApplicationScripts`에 넣은 스크립트를 앱 Sandbox 밖에서 실행하도록 설계됐다. 앱은 그 폴더를 읽을 수 있지만 쓰지는 못하며, 내장 코드 실행을 위한 API가 아니다. Apple DTS는 2025에 이 메커니즘을 일반적 Sandbox 우회로 사용해서는 안 된다고 다시 설명했다. [NSUserAppleScriptTask](https://developer.apple.com/documentation/foundation/nsuserapplescripttask), [NSUserUnixTask](https://developer.apple.com/documentation/foundation/nsuserunixtask), [DTS: Implementing Script Attachment in a Sandboxed App](https://developer.apple.com/forums/thread/794355)

결과: 사용자 선택형 일반 automation 확장으로 검토할 수 있지만, “설치 때 우리 스크립트를 넣어야 핵심 숨김이 작동한다”는 제품의 기초로 채택하지 않는다. `osascript`, `NSAppleScript`, Scripting Bridge로 호출 형태를 바꿔도 목적·권한 검토가 사라지지 않는다.

## 5. Helper 종류별 실제 경계

| 구조 | 기술적 경계 | 공식 출시 의미 |
| --- | --- | --- |
| 앱이 `Process`/`posix_spawn`으로 실행하는 번들 내 command-line tool | parent sandbox 상속. Store helper에는 `app-sandbox`+`inherit` 패턴 | 프로세스 분리·안정성 용도이며 AX/private 사용 권한 확대가 아님 |
| 번들 내 XPC service | 각 target의 entitlement·sandbox 별도 설정 | 최소 권한 분리에 유용. Store에서 unsandboxed engine을 넣을 허가 근거가 아님 |
| Sandbox main app이 `SMAppService`로 등록하는 agent/daemon | Apple DTS는 job도 Sandbox 필요, nonsandboxed job 등록은 14.2 이후 차단이라고 설명 | 기본 Store 앱에서 밖의 engine을 자동 설치하는 우회로로 쓰지 못함 |
| 사용자가 별도로 설치한 Developer ID companion | 독립 배포·서명·TCC 주체, 통신 권한·lifecycle·버전 호환성 설계 필요 | 기능 추가·심사 전체 공개·업데이트·설치 정책을 App Review에 확인해야 할 별도 제품 구조 |
| Developer ID main app + 필요한 sandboxed worker | direct distribution에서는 Sandbox 선택 가능 | 기능을 유지하는 공식 출시 후보. Store 승인과 다른 절차 |

번들 helper 공식 구현은 Apple의 [Embedding a command-line tool in a sandboxed app](https://developer.apple.com/documentation/xcode/embedding-a-helper-tool-in-a-sandboxed-app)을 참고한다. `com.apple.security.inherit`의 역할은 부모의 static sandbox 권리를 상속하는 것이며, 별도 권한을 얻는 것이 아니다. [App Sandbox Inheritance](https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html)

**새로 확인한 강한 제약:** Apple DTS의 2025-09 `Getting Started with SMAppService`는 `App Sandboxed=yes / Job Sandboxed=no` 조합을 지원하지 않으며, 초기에 가능했던 nonsandboxed daemon 등록이 **macOS 14.2 이후 차단**됐다고 명시한다. 따라서 Barbee에 Helper가 있다는 사실만으로 Barista가 동일한 Store 내부 분리를 할 수 있다고 추정하면 안 된다. [Apple DTS](https://developer.apple.com/forums/thread/802443)

**등록 제한과 IPC 제한을 혼동하지 않는다.** 2026-09의 더 최근 Apple DTS 답변은 App Group을 통한 Sandbox 앱→nonsandbox 앱/launch agent IPC가 기술적으로 지원되며, 본인이 직접 확인했다고 설명한다. 직접 배포 제품의 sandboxed main+nonsandbox XPC 분리도 합리적인 설계라고 평가한다. 같은 답변에서 Store 앱+외부 Helper 구조는 기술적으로 동작할 수 있어도 App Review의 판단에는 의견을 줄 수 없다고 구분한다. 이 스레드의 일반 참여자가 제기한 IPC 불가능이나 심사 단정은 DTS의 답변과 구분해야 한다. [Apple DTS: CTFontManagerCreateFontRequestRunLoopSource, 2026-09](https://developer.apple.com/forums/thread/845853)

따라서 외부 companion을 **기술적으로 불가능한 구조**라고 결론내리지 않는다. 등록·설치·통신·승인은 각각 다른 단계다. 별도 companion의 IPC도 모든 요청을 신뢰하면 안 된다. App Group/Mach service 범위, Team ID·bundle ID·서명 확인, 최소 request schema, 예상치 않은 caller·protocol version·helper 종료를 처리하는 설계가 필요하다. 이는 설계 제안이다. IPC 채널이 있다는 사실은 그 채널로 핵심 Sandbox 제한 기능을 위임하는 심사 승인을 뜻하지 않는다.

## 6. 심사와 직접 배포

Mac App Store 2.4.5는 적절한 Sandbox, 단일 자체 완결 app bundle, 동의 있는 startup, 심사본과 달라지는 standalone app·추가 코드 다운로드/설치 제한, Store 업데이트를 요구한다. 2.5.1은 공개 API와 의도된 framework 용도를 요구한다. 2.3.1은 숨겨지거나 문서화되지 않은 기능을 허용하지 않는다. 따라서 **심사 후 Helper를 붙여 핵심 기능을 활성화하는 설계**를 승인된 해결책으로 취급하지 않는다. [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

Apple DTS는 기술 동작을 지원하는 조직과 App Review를 명확히 나누며, App Review는 별도 상담을 안내한다. “다른 Store 앱이 존재한다”는 증거는 시장의 실제 사례지만, 해당 앱의 entitlement·예외·현재 승인 조건을 알 수 없으므로 우리 앱의 승인을 증명하지 않는다. [DTS 기술·정책 구분](https://developer.apple.com/forums/thread/780626), [App Review 상담 답변](https://developer.apple.com/forums/thread/780722)

직접 배포도 정식 제품 출시다. Apple의 distribution 준비 문서는 Store는 Sandbox 필수, 외부 notarized app은 Hardened Runtime 필수이며 Sandbox는 선택이라고 설명한다. Developer ID 서명과 notarization·stapling·업데이트·제거·권한 onboarding을 갖추면 consumer 설치 경로를 만들 수 있다. 공증은 Store 심사나 private API 안정성 보증은 아니다. [Preparing your app for distribution](https://developer.apple.com/documentation/xcode/preparing-your-app-for-distribution), [Security: Developer ID and notarization](https://developer.apple.com/security/)

## 7. 출시 후보의 우선순위와 검증 관문

| 후보 | 필요한 기술 검증 | 정책 검증 | 권고 |
| --- | --- | --- | --- |
| Sandbox + capped spacer + OS overflow | 숨김·복원·디스플레이·startup·새 앱 동작; 앱 자신의 공개 API만 사용 | 전체 동작·UI·추가 separator 설명과 실제 심사 | **최우선 feasibility prototype** |
| 위 구조 + 선택형 ScreenCaptureKit 아이콘 목록 | 권한 허용/거절·crop·신뢰도·동적 아이콘; 숨김과 분리 | 데이터 사용·권한 목적·실제 리뷰 | 가치가 있을 때 2단계 |
| ScreenCaptureKit + `CGEventPost` 자동 드래그·활성화 | signed Sandbox27에서 실제 생성·TCC 및 failure mode, DTS 지원 범위 | 용도·권한·자동화 review | **보류 후보**, 기본 숨김의 전제 금지 |
| Store UI + 외부 companion | 양쪽 서명/IPC/TCC/lifecycle·사용자 설치 | 2.4.5에 대한 구체적 App Review 상담 | 초기 공식 제품의 기본 구조로 권하지 않음 |
| Developer ID 완전판 | 기존 private backend의 fail-open·OS 변경 탐지, 서명/공증/업데이트 | notarization 및 배포 조건 | Store prototype 실패 시 현실적인 공식 출시 경로 |

현재 새 geometry 경로가 남아 있으므로 완전한 rewrite나 Helper 제작부터 착수하지 않는다. 먼저 작동하는 최소 엔진으로 `숨김→OS overflow→복원`을 확인한다. 다음에 사용자가 받아들일 UX 범위를 결정하고, 필요한 관찰·인식·자동화만 더한다. 단일 probe의 컴파일 성공이나 한 대에서의 숨김 성공을 출시 readiness로 표시하지 않는다.

Apple에 보낼 기술 질문 초안:

1. macOS 27에서 자체 `NSStatusItem.length`들을 조절해 외부 아이템을 시스템 overflow로 보내는 방식의 지원 범위나 권장 크기 제한이 있는가?
2. Sandbox 앱에서 합성 mouse drag/click을 보내는 `CGEventPost`에 대한 현재 지원 범위와 필요한 공개 entitlement/TCC 조합은 무엇인가? AX client 없이도 지원되는가?
3. `SCShareableContent`나 다른 공개 API로 개별 menu extra와 소유 앱 사이를 안정적으로 식별하는 방법이 있는가? 한 창에 그려진 아이콘을 user-labelled image로 다루는 대안 외에 알려진 경로가 있는가?
4. 기본 동작을 충분히 제공하는 Sandbox 메뉴 관리 앱과 사용자가 별도로 설치하는 optional companion을 함께 제공할 때 2.4.5(ii)(iv)를 만족하는 조건은 무엇인가? 설치·업데이트·심사 접근·권한 흐름을 구체적으로 공개한다.

이 초안은 문의 준비 자료이며, Apple 또는 제3자에게 메시지를 보내지 않았다.

## 조사 한계

- 후속으로 만든 [독립 실험 앱](../Experiments/OfficialRelease/)에서 Sandbox 서명·컨테이너 실행, 기존 캡처 권한이 있는 환경의 1×1pt 메모리 캡처와 geometry 계산 검증은 수행됐다. 이는 깨끗한 설치의 TCC 흐름이나 실제 타 앱 숨김·복원을 입증하지 않는다. 현재 Barista와 충돌하는 실제 geometry 실행은 하지 않았으며, 전체 결과는 [재설계·실험 기록](OFFICIAL_RELEASE_REDESIGN.md)을 참고한다.
- 이 문서는 공식 선언·문서·DTS 답변과 개발자 공개 설명을 대조한 조사다. 운영 환경의 권한을 바꾸거나 잠재적으로 입력을 전달하는 앱을 실행하지 않았다.
- MenubarHide의 runtime 주장과 Barbee의 공개 설명은 Apple가 소유하는 API 계약이 아니다. Barista 자체 실험 결과는 별도 기록해야 한다.
- 옛 sandbox 문서의 금지와 현대 TCC 설명이 다른 영역은 불확실성을 남겼다. 특히 CGEvent generation은 새로운 API 선언이 있어도 지원·심사 결론을 추정하지 않는다.
- API 문서 일부에 beta 표기가 남아 있고 창 구성·status item 폭 임계치는 OS 구현 세부사항일 수 있다. 최종 OS/SDK 기준의 회귀 검증과 Apple 문의가 필요하다.
- [이전 Barbee 조사](BARBEE_IMPLEMENTATION_RESEARCH.md)의 Helper 배포·sandbox·최신 숨김 구현 미확인 사항은 이 조사로 확정되지 않았다.
