# 설치와 업데이트

cowork는 Homebrew로만 배포한다. 규칙·hook·권한 같은 자산은 바이너리에 들어 있어서, 바이너리를 바꾼 뒤 `cowork apply`를 한 번 실행하면 적용된다.

## 처음 설치

대화형으로 한 번에 하려면 `cowork init`을 실행한다. 역할·prod 등급·언어, git 이름·이메일과 Git 호스트(github·gitlab) 로그인, 업무 관리(팀 cowork-space 레포 URL, Jira 사용 여부)·플레이북 레포를 묻고 설치한다. 팀 레포 URL을 비우면 private 레포를 새로 만들지 묻고, `-`면 팀 레포 없이 간다. 팀 레포가 없으면 개인 공간(원격 없는 로컬 git 레포)을 만든다(Jira를 쓰면 만들지 묻는다). 팀 레포는 플레이북 레포로도 자동 등록되어 `playbooks/<이름>/`의 팀 플레이북이 연결되고, README·`.gitattributes`(notes.md union merge)가 없으면 넣는다. 레포에 README.md가 없으면(원격에도 없을 때) 사용법 README를 넣고 push한다. 개인 공간을 쓰다가 같은 경로로 팀 레포 URL을 넣으면 개인 공간을 `<경로>.personal-날짜`로 옮겨 두고 팀 레포를 clone한 뒤, 끝나지 않은 개인 업무를 팀 레포로 옮길지 묻는다(새 번호, 이전 ID는 기록에 남김). Jira 토큰은 init에서 받지 않고, Jira를 처음 쓸 때 터미널에서 `cowork auth jira`로 등록한다(API로 확인 후 OS 키체인에 저장). 구 설치본을 넘겨받거나 스크립트로 설치할 때는 아래처럼 단계별로 한다.

```bash
brew install withwontae/tap/cowork
cowork machine set --role <역할> --prod none        # 이 머신의 prod 등급(none|read|change)
cowork install --takeover --dry-run                 # 바뀔 파일과 넘겨받을 구 ~/cowork 항목 확인
cowork install --takeover                           # 백업 → 원자적 적용 → doctor, 실패하면 자동 복원
cowork doctor
```

- 구 `~/cowork` 설치본이 없으면 `--takeover`는 아무것도 넘겨받지 않고 일반 설치와 같다.
- 구 설치본이 있는데 `--takeover` 없이 설치하면, hook이 겹치지 않도록 멈춘다.
- 설치가 끝나면 남은 일이 `다음 단계` 체크리스트로 출력된다.
- Codex를 쓰면 설치 후 Codex를 새로 시작해 `Hooks need review` 화면(또는 `/hooks`)에서 cowork hook 2개를 승인한다. `cowork doctor`의 `codex.trust`로 확인한다.
- 플레이북 레포를 쓰면 `~/.config/cowork/config.yaml`의 `playbooks.repos`에 경로를 넣고 `cowork apply`를 실행한다.

## 업데이트

```bash
brew upgrade cowork
cowork apply
```

세션 시작 때 `[cowork] 적용 버전 … ≠ 바이너리 …` 줄이 보이면 `cowork apply`가 필요하다는 뜻이다.

## 제거

```bash
cowork uninstall          # manifest에 기록된 항목만 제거. config.yaml, RULES.md, machine.json, 로그는 남긴다
brew uninstall cowork
```
