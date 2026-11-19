# Official Release Lab

2026-10-03: Barista의 공식 출시 재설계 가능성을 검토하는 **독립 실험**이다. `Package.swift`, 생산 소스, 기존 build/release script에 연결하지 않았다. SDK 27 / Swift 6 / macOS 27 / arm64용이며 앱스토어 제출본은 아니다.

## 재현

저장소 루트에서:

```sh
zsh Experiments/OfficialRelease/build-lab.sh
.build/official-release/BaristaLab.app/Contents/MacOS/BaristaLab --diagnose
.build/official-release/BaristaLab.app/Contents/MacOS/BaristaLab --capture-probe
```

빌드 script는 geometry 계획 검사를 실행하고, capture 선언을 typecheck하고, lab 앱을 `app-sandbox=true` + hardened runtime + ad-hoc 서명한다. 빌드 자체는 GUI trial을 실행하지 않는다. 임시 산출물은 `.build/official-release/`에 있다.

`--diagnose`는 Sandbox container 환경 값, 권한 **preflight**, display 폭만 출력하고 종료한다. 권한을 요청하지 않는다. `--capture-probe`는 preflight가 false면 종료하고 true면 화면 모서리 **1×1 point**만 메모리에 읽고 이미지 크기만 출력한다. 파일이나 픽셀 값을 저장하지 않는다. 실행 호스트의 기존 권한이 영향을 줄 수 있으므로 clean-install TCC 증거로 쓰지 않는다.

## 수동 geometry trial

`BaristaLab.app`을 열면 설명 창과 수동 trial 버튼이 나온다. 처음 실행만으로 상태 아이템을 만들지 않는다. 알려진 메뉴 관리자가 실행 중이면 trial은 거부한다. 현재 Barista를 종료·교체하지 않는다.

수동 trial은 LAB 버튼, 자체 spacer, T1/T2 표본을 생성하고 1초 후 제한된 폭으로 늘린다. 5초 뒤 자체 아이템을 모두 제거한다. 'Remove trial items' 또는 창 닫기도 제거한다. 다른 앱의 아이콘·환경설정에 직접 쓰거나 합성 클릭·드래그를 보내지 않는다. 자체 폭 변화는 OS 메뉴 막대 배치에 잠시 영향을 줄 수 있다.

자체 window frame 로그는 layout 관찰 자료다. 그것만으로 다른 앱 아이콘이 숨겨졌거나 `«`에서 클릭 가능하다고 판정하지 않는다. 실제 다른 앱·노치·mixed display·재부팅·crash·App Review는 별도 검증 관문이다.

## 기록된 결과

- geometry 계산: 비노치·노치·혼합 display 4개 시나리오, invalid input 및 7개로 덮지 못하는 극단적인 배치 검사 통과.
- 공개 capture 선언: SDK 27 Swift 6 타입 검사 통과.
- 앱 strict signature 검증 통과; sandbox entitlement는 true 하나.
- macOS 27.0.1 / 26A434 진단에서 sandbox container 존재, capture preflight=true / listen=false / post=false, 1680pt 비노치 화면.
- 일회성 capture 전송: 1×1 point → 2×2 pixel 성공. 이미지 인식이나 메뉴 캡처 시험은 아님.
- GUI geometry trial은 이 조사에서 실행하지 않음. 운영 중인 Barista와 실제 타 앱 배치를 실험 대상에 포함하지 않음.

계획 계산의 임계치는 [MenubarHide의 실측 소스](https://github.com/junior-rj/menubar-hide/blob/6d1a9c50fd939cf1a6c038681037db8f8f748e2f/MenubarHide/CollapsedGeometry.swift)를 연구 가설로 삼았다. 소스는 별도로 작성했으며 Apple 지원 계약이 아니다. 충분한 폭을 만들 수 없을 때는 성공처럼 최대값으로 자르지 않고 unsupported로 처리한다.

[재설계 제안](../../docs/OFFICIAL_RELEASE_REDESIGN.md) · [플랫폼 근거](../../docs/OFFICIAL_RELEASE_PLATFORM_RESEARCH.md)
