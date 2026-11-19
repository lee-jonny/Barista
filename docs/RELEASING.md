# 릴리즈

Resources/Info.plist의 공개 버전과 내부 빌드 번호를 올리고 CHANGELOG.md에 변경 사항을 기록합니다. macOS 27 Apple Silicon에서 실행합니다.

```sh
zsh scripts/check.sh
zsh scripts/build.sh
zsh scripts/release.sh
```

패키징은 `dist/`에 ZIP과 체크섬을 만듭니다. 이미 태그가 있거나 tap에서 배포 중인 버전은 패키징 단계에서 중단됩니다. 공증하는 경우 아래 티켓 부착과 최종 패키징까지 먼저 마칩니다.

앱 소스·버전·변경 기록을 커밋한 뒤 태그와 릴리스를 게시합니다. 아래 릴리스 노트 경로를 실제 파일로 바꾸세요. 기본 빌드는 ad-hoc 서명 Preview이므로 미공증 안내를 포함합니다.

```sh
version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Resources/Info.plist)
archive="Barista-${version}-macos27-arm64.zip"
(cd dist && shasum -a 256 -c SHA256SUMS)
git tag "v${version}"
git push --atomic origin main "v${version}"
gh release create "v${version}" "dist/${archive}" dist/SHA256SUMS --verify-tag --prerelease --title "Barista ${version} Preview" --notes-file /path/to/release-notes.md
```

릴리스 게시가 끝난 뒤 아래 명령을 실행합니다. 스크립트는 공개 URL에서 받은 ZIP의 버전과 SHA-256을 확인한 후 cask를 갱신합니다. 업로드가 실패했으면 같은 태그의 릴리스와 누락된 자산을 먼저 확인하고 이 단계부터 재시도하세요.

```sh
zsh scripts/update-cask.sh && git add -- Casks/barista.rb && git commit -m "Update Barista cask to ${version}" && git push origin main
brew update
brew fetch --force --cask willofi/barista/barista
```

Developer ID 인증서가 있는 환경에서는 다음처럼 빌드합니다.

```sh
BARISTA_SIGNING_IDENTITY='Developer ID Application: YOUR NAME (TEAMID)' zsh scripts/build.sh
zsh scripts/release.sh
version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Resources/Info.plist)
xcrun notarytool submit "dist/Barista-${version}-macos27-arm64.zip" --keychain-profile YOUR_PROFILE --wait
xcrun stapler staple build/Barista.app
xcrun stapler validate build/Barista.app
zsh scripts/release.sh
```

공증 성공을 확인한 뒤 티켓을 부착하고 ZIP과 체크섬을 다시 생성합니다. 인증서나 키체인 비밀은 저장소에 추가하지 않습니다.

## 실기 확인

앱을 /Applications에 설치하고 현재 앱의 손쉬운 사용 권한을 확인합니다. 접은 뒤 충분히 기다려 자기 버튼이 남는지, 클릭·우클릭이 가능한지, 5가지 미리보기와 자동 접기 시간, 시계 영역 임시 펼치기, Finder 재실행 복구를 확인합니다. 빌드마다 개발 서명이 바뀔 수 있으므로 모든 빌드를 끝낸 뒤 권한을 재등록하세요.

테스트 중 SetupChecks 실행 파일은 손쉬운 사용 권한이 없는 프로세스여야 합니다. 전체 검사 스크립트는 macOS 27 실행 환경을 요구합니다.

## 버전 번호

첫 공개는 0.1.0, 다음 기능 릴리즈는 0.2.0입니다. 공개한 뒤 버그 수정 배포에는 패치 버전을 올립니다. 로컬 테스트마다 공개 버전을 바꾸지 않으며 CFBundleVersion의 내부 빌드 번호만 올립니다.
