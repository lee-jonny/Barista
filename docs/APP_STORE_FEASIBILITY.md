# Barista의 Mac App Store 전환 가능성

조사일: 2026-10-03 (Asia/Seoul). 조사 대상: 현재 Barista 소스, 설치된 macOS 27.0 공개 SDK, Apple 공식 문서. 생산 코드·설치 앱·버전·Git 커밋은 이 조사에서 변경하지 않았다.

## 결론

후속 Barbee 조사에서는 개발자의 스크린샷·이미지 비교 방식 설명과 공식 릴리즈 기록의 별도 Helper 앱 존재를 확인했다. 따라서 이 문서의 결론을 “메뉴 관리 기능 자체는 App Store에서 구현 불가능하다”로 확대하면 안 된다. 기존 Barista의 구현을 유지하는 단일 Sandbox 앱 전환과, 식별 방식을 바꾸거나 별도 구성 요소를 사용하는 제품 설계는 서로 다른 검토 대상이다. Barbee의 실제 Helper entitlement, 최신 macOS 27 숨김 API, 심사에서 승인된 조건은 아직 확인하지 못했다. 근거와 확인 범위는 [Barbee 구현 조사](BARBEE_IMPLEMENTATION_RESEARCH.md)를 참고한다.

**현재 기능과 동작을 유지하면서 일반 메뉴 막대 관리 앱으로 공개 API + App Sandbox에 전환할 수 있는 승인된 경로는 확인하지 못했다.** 단순히 `MenuVisibilityBridge`를 교체하고 Sandbox entitlement를 추가하는 작업으로는 해결되지 않는다. 다른 앱 아이콘의 위치·소유자 조회와 메뉴 사용 중 감지도 별도로 바꿔야 한다. 이 결론은 아래 문서와 SDK에 근거한 구현 가능성 판단이며, Apple의 심사 결정이나 모든 미래 API에 대한 단정은 아니다.

macOS 27에는 실제로 메뉴 막대 표시를 제한하는 **공개 시험 환경 API**가 있다. 따라서 “공개 API가 전혀 없다”는 표현은 부정확하다. 다만 이 API의 용도·권한·세션 부작용은 일반 메뉴 관리 앱과 다르다. [Apple WWDC26: What’s new in assessment on macOS](https://developer.apple.com/videos/play/wwdc2026/230/)

## 현재 구현과 두 가지 독립적인 장애물

1. `Sources/Barista/MenuVisibilityBridge.swift`는 `/System/Library/PrivateFrameworks/MenuBarClientCore.framework`를 `dlopen`하고, `MBAssessmentModeAssertion`, `MBAssessmentModeConfiguration`, 비공개 selector를 호출한다. 공개 API만 사용하고 프레임워크를 의도된 목적으로 사용해야 한다는 2.5.1과 맞지 않는다. 동적 호출로 바꿔도 API 성격은 달라지지 않는다. [App Review Guidelines 2.5.1](https://developer.apple.com/app-store/review/guidelines/#software-requirements)
2. `MenuItemDiscovery.swift`, `SystemMenuArea.swift`, `MenuInteractionMonitor.swift`는 다른 프로세스의 `AXUIElement`를 읽거나 `AXObserver` 알림을 관찰한다. AX 자체는 공개 API지만, Apple은 assistive client로서의 접근성 API 사용을 Sandbox 비호환 기능으로 명시한다. 자신의 버튼·행을 VoiceOver에 설명하는 `NSAccessibility` 지원과 다른 앱의 UI를 읽는 AX client 사용을 구분해야 한다. [App Sandbox 공식 설명](https://developer.apple.com/documentation/security/protecting-user-data-with-app-sandbox), [AXUIElement 공식 설명](https://developer.apple.com/documentation/applicationservices/axuielement)

Mac App Store는 적절한 Sandbox 적용을 요구한다. 사용자에게 접근성 권한을 받는 것만으로 Sandbox 제한이 해소된다고 판단할 수 없다. Apple DTS는 Sandbox 앱의 AX 사용을 지원하지 않는다고 재확인했다. [심사 지침 2.4.5](https://developer.apple.com/app-store/review/guidelines/#hardware-compatibility), [Apple DTS: Sandbox Entitlements Question](https://developer.apple.com/forums/thread/789663), [Apple DTS: AXIsProcessTrusted returns true, but…](https://developer.apple.com/forums/thread/794253)

## 공개 API 후보별 검토

| 후보 | 확인한 범위 | 현 기능 유지 가능성 |
| --- | --- | --- |
| `NSStatusBar`, `NSStatusItem.isVisible`, `length` | 앱이 생성한 아이템의 표시·폭을 제어한다. 공개 인터페이스에서 다른 앱 아이템의 객체 목록이나 bundle ID별 숨김 권한은 확인하지 못했다. | Barista 자체 아이콘에는 사용 가능. 다른 앱·시스템 아이콘의 개별 숨김 대체는 확인 못함. |
| macOS 27 `NSStatusItemExpandedInterfaceDelegate` / session | 자신의 아이템이 펼친 창 등의 시작·종료와 키보드 탐색 참여를 관리한다. | 다른 앱의 메뉴 감시 또는 숨김 서비스 대체가 아님. |
| `AEAssessmentConfiguration.allowsMenuBar`, `allowedMenuBarItems` | 시험 세션에서 메뉴 막대 허용 항목을 설정한다. `AEMenuBarItem`에는 시스템 항목 상수와 제3자 bundle ID raw value가 있다. | 기술적으로 가장 가까운 공개 후보지만, 시험용 권한·세션에 묶여 있고 일반 메뉴 관리 용도로 승인된 경로는 확인 못함. |
| Input Monitoring + `CGEventTap` | Sandbox 앱의 입력 관찰 경로로 Apple DTS가 안내한다. | 입력 관찰 일부를 바꿀 수 있으나 AX 트리·아이콘 소유자·메뉴 열림 상태·표시 제어는 제공하지 않음. |

근거: [NSStatusBar](https://developer.apple.com/documentation/appkit/nsstatusbar), [NSStatusItem.isVisible](https://developer.apple.com/documentation/appkit/nsstatusitem/isvisible), [NSStatusItem.length](https://developer.apple.com/documentation/appkit/nsstatusitem/length), [expanded interface session](https://developer.apple.com/documentation/appkit/nsstatusitemexpandedinterfacesession), [allowedMenuBarItems](https://developer.apple.com/documentation/automaticassessmentconfiguration/aeassessmentconfiguration/allowedmenubaritems), [Apple DTS: Input Monitoring 대안](https://developer.apple.com/forums/thread/811443).

### 시험 환경 API를 바로 교체하지 않은 이유

`allowedMenuBarItems`는 `allowsMenuBar == true`인 **assessment session 안에서** 작동한다. nil은 모든 메뉴 항목 허용이고, 집합을 지정하면 해당 항목만 허용한다. 공개 SDK의 `AEMenuBarItem.h`는 제3자 menu extra에 bundle ID raw value를 사용할 수 있다고 설명한다. 따라서 표시 집합 구성 자체는 현재 private bridge와 유사한 부분이 있다. [allowedMenuBarItems](https://developer.apple.com/documentation/automaticassessmentconfiguration/aeassessmentconfiguration/allowedmenubaritems)

그러나 framework는 교육 시험·인증 환경을 잠그기 위한 것이다. 사용하려면 Apple에서 `com.apple.developer.automatic-assessment-configuration` entitlement 승인을 받아야 한다. 일반 메뉴 관리 도구에 승인될지는 확인되지 않았으며 plist에 키를 추가하는 것으로 승인이나 배포 권한을 획득하는 것이 아니다. [공식 entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.automatic-assessment-configuration), [WWDC26 framework 목적·승인 설명](https://developer.apple.com/videos/play/wwdc2026/230/)

세션은 메뉴 막대만 제어하는 독립 서비스가 아니다. 공개 SDK 설명상 Dock·사용자 스크립트·여러 입력 기능 등의 제한도 관련되며, 공식 발표에서도 시스템 보안·접근성·실행 환경 제어를 다룬다. 모든 부작용을 현재 앱과 동일하게 완화할 수 있는지 검증하지 않았다. 이 API를 일상 메뉴 관리에 쓰는 것이 2.5.1의 의도된 목적에 맞는지도 Apple 확인이 필요하다. 또한 이 후보만으로 AX 기반 위치 분류·새 아이콘 판정·메뉴 사용 중 대기가 해결되지는 않는다. [WWDC26](https://developer.apple.com/videos/play/wwdc2026/230/), [심사 지침 2.5.1](https://developer.apple.com/app-store/review/guidelines/#software-requirements)

### 폭을 늘려 밀어내는 우회

후속 조사에서는 macOS 27에서 한 개의 큰 폭 대신 여러 자체 상태 아이템의 폭을 제한해 OS `«` overflow를 이용하는 공개 구현을 확인했다. 따라서 아래의 기존 방식 실패 기록은 모든 geometry 방식의 불가능을 뜻하지 않는다. 새 후보·노치/다중 화면·UX 비용과 독립 Sandbox 실험 결과는 [공식 출시 재설계](OFFICIAL_RELEASE_REDESIGN.md)와 [플랫폼 조사](OFFICIAL_RELEASE_PLATFORM_RESEARCH.md)에 정리했다. 실제 Barista의 타 앱 아이콘 숨김·복원과 심사 적합성은 아직 미검증이다.

Hidden Bar 작성자는 자신의 상태 아이템 폭을 늘려 왼쪽 아이콘을 화면 밖으로 밀어내는 구조를 문서화했다. 이는 타 앱의 표시 상태를 변경하는 공개 관리 API가 아니라 geometry 우회다. 작성자의 현 architecture 문서는 macOS 27 재구성에서 이 방식이 깨진다는 제한도 기록한다. 이 조사는 해당 우회를 실기기에서 재현하지 않았고, 이 앱의 현재 심사 승인이나 동작을 보장하는 근거로 사용하지 않는다. [Hidden Bar 작성자 architecture](https://github.com/dwarvesf/hidden/blob/develop/docs/ARCHITECTURE.md)

Barista의 단일 22pt 아이콘·간격 유지와 같은 UX를 그대로 보장할 근거가 없으므로 자동으로 이 방식으로 되돌리는 것은 권장하지 않는다.

## 예외 entitlement와 불확실성

Apple의 공개 임시 예외 문서는 Apple Events, Mach service lookup, 파일·공유 환경설정 등에 대한 예외와 필요성 설명 절차를 다룬다. 그 공개 목록에서 AX client 전체를 허용하는 `com.apple.security.temporary-exception.accessibility`는 확인하지 못했다. 인터넷에서 언급되는 미문서화 키나 임의의 Mach 예외를 승인된 해결책으로 적용하지 않는다. 예외가 로컬에서 작동하더라도 공개 API 요구사항 또는 App Review 승인이 자동으로 충족되지는 않는다. [App Sandbox Temporary Exception Entitlements](https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/AppSandboxTemporaryExceptionEntitlements.html)

Apple DTS도 기술 지원과 App Review 결정을 구분하며, 심사 정책 질문은 App Review 상담을 권한다. 현재 조사로 예외 승인 가능성에 확률을 부여할 수 없다. [Apple DTS / App Review 답변](https://developer.apple.com/forums/thread/794428)

## 검증 범위

- `xcrun --show-sdk-path`가 가리키는 SDK의 `SDKSettings.json`에서 macOS 27.0을 확인했다.
- Xcode 27.0 (27A266a), SDK 27.0에서 아래 probe를 Swift 6 / arm64 / macOS 27 대상으로 `-typecheck`했고 exit 0을 확인했다. 이는 공개 선언과 Swift 타입 검사만 확인하며 Sandbox 허용 여부를 검사하지 않는다.
- 공개 `AppKit.framework/Headers/NSStatusBar.h`, `NSStatusItem.h`와 `AutomaticAssessmentConfiguration.framework/Headers/AEAssessmentConfiguration.h`, `AEMenuBarItem.h`, `AEAssessmentSession.h`를 읽었다. 공개 NSStatusItem 인터페이스에는 타 앱 숨김 API를 확인하지 못했고, assessment 후보는 실제 공개 선언을 확인했다.
- Apple 웹 문서의 일부 HTML은 JavaScript 전용이었다. 해당 주장은 검색에 노출된 공식 본문, Apple WWDC 공식 transcript, 설치된 공개 SDK 주석을 함께 대조했다. API 페이지에 beta 표기가 남아 있으므로 실제 배포 시점의 최종 OS·SDK·문서를 다시 확인해야 한다.
- 이 보고서는 정적 코드·문서 조사다. Sandbox 서명 빌드의 실기기 동작, 제한 entitlement 취득, assessment 세션 실행, 새 Apple API의 완전한 부작용 제거, App Store 승인 여부를 검증하지 않았다.

컴파일 재현용 코드 (`.build/app-store-feasibility/PublicAPIProbe.swift`, 빌드 산출물 경로이므로 Git 추적 대상은 아님):

```swift
import AppKit
import AutomaticAssessmentConfiguration

@MainActor
func configureOwnItem(_ item: NSStatusItem) {
  item.isVisible = true
  item.length = NSStatusItem.squareLength
}

@available(macOS 27.0, *)
func assessmentMenuConfiguration() -> AEAssessmentConfiguration {
  let configuration = AEAssessmentConfiguration()
  configuration.allowsMenuBar = true
  configuration.allowedMenuBarItems = [
    .battery, .bluetooth, .clock, .displays, .keyboard, .volume, .wifi,
    AEMenuBarItem(rawValue: "dev.eden.barista"),
  ]
  return configuration
}
```

저장소 루트에서 실행한 명령:

```sh
xcrun swiftc -swift-version 6 -target arm64-apple-macos27.0 \
  -module-cache-path "$PWD/.build/module-cache" \
  -typecheck .build/app-store-feasibility/PublicAPIProbe.swift
```

`AEAssessmentSession`을 생성하거나 시작하지 않았다. Apple의 제한 entitlement 승인을 확인하지 못했고, 세션은 사용자의 실행 환경을 잠글 수 있으며, 일반 메뉴 관리 목적의 허용 여부도 미확인이다. 이 상태에서 실제 시험 세션을 켜는 것은 API 존재를 확인하기 위한 최소 검증 범위를 넘어선다.

## 현실적인 다음 단계

1. 현재 배포본의 기능을 유지한다. App Store 적합성을 주장하는 릴리즈나 비공개 bridge 제거를 먼저 하지 않는다.
2. Apple에 **일반 메뉴 관리 도구에 적합한 공개 표시 제어 API가 있는지**, **assessment의 메뉴 허용 목록을 그 용도로 사용할 권한을 받을 수 있는지**, **Sandbox 안에서 아이콘 위치를 구분할 지원 경로가 있는지**를 구체적인 최소 재현 사례와 함께 문의한다. 기술 질문은 개발자 지원, 사용 목적·승인 질문은 App Review 상담으로 구분한다. [App Review 지원 경로](https://developer.apple.com/app-store/review/)
3. Apple이 일반 용도 경로를 확인하면 기존 `MenuVisibilityControlling` seam을 활용해 별도 실험 구현을 만든다. 이어 AX 조회·관찰도 지원되는 방식으로 대체하고 깨끗한 테스트 환경에서 Sandbox 실행, 시스템 아이콘·새 앱·재부팅·사용 중 대기·복원을 확인한다.
4. 지원 경로가 없다면 선택은 제품 범위를 바꾼 Sandbox용 앱 또는 현재 기능을 유지하는 외부 배포다. 외부 배포의 개발자 서명·공증은 설치 신뢰성을 높이는 별도 작업이며, 비공개 API를 공개 API로 바꾸거나 OS 업데이트 호환성을 보장하지 않는다.
