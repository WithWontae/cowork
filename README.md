# cowork

[English](README.en.md)

Claude Code와 Codex CLI에 **같은 규칙과 같은 안전장치**를 설치하는 작은 실행 계층이다. Go 단일 바이너리이고 Homebrew로 배포한다.

- **Guard**: PreToolUse hook이 모든 셸·파일·MCP 호출을 판정한다(allow / ask / deny). prod 변경, 보호 파일 수정, 강제 push 같은 실수를 막는다. 실패하면 막는 쪽(fail-closed)으로 동작한다.
- **규칙 주입**: SessionStart hook이 머신의 prod 등급, 보고 규칙, 기본 언어를 세션에 넣는다. 전역 규칙(`RULES.md`)은 `CLAUDE.md`·`AGENTS.md` 관리 블록으로 연결한다.
- **안전한 설치**: 잠금 → 백업 → 원자적 쓰기 → doctor 점검 순서로 적용하고, 실패하면 자동으로 되돌린다. 설치한 항목은 manifest에 기록해 제거할 때 그것만 지운다.
- **플레이북 연결**: 별도 레포의 플레이북(스킬)을 설정에 등록하면 스킬 디렉터리에 링크한다.

Guard는 실수 방지 장치이지 보안 경계가 아니다. 최종 방어선은 서버 측 권한이다.

## 지원 환경

- macOS, Linux (amd64, arm64)
- Claude Code (`~/.claude`, `$CLAUDE_CONFIG_DIR`, Orca 프로필)
- Codex CLI (`~/.codex` 또는 `$CODEX_HOME`). Guard 차단은 Codex 0.166.0에서 실측했다

## 설치

```bash
brew install withwontae/tap/cowork
cowork init      # 역할·prod 등급·언어·git 기본 설정·업무 관리 방식·플레이북 레포를 묻고, 미리보기 확인 후 설치
```

`init`은 터미널에서만 동작한다. 스크립트나 CI에서는 단계별 명령을 쓴다.

```bash
cowork machine set --role <역할> --prod none   # 이 머신의 prod 등급: none | read | change
cowork config set language ko                  # (선택) 기본 언어
cowork install --yes
```

설치가 끝나면 아직 남은 일이 `다음 단계` 체크리스트로 출력된다. Codex를 쓰면 Codex를 새로 시작해 `Hooks need review` 화면(또는 세션 안 `/hooks`)에서 cowork hook 두 개를 승인한다. `cowork doctor`가 모두 PASS면 끝이다.

구 `~/cowork` 설치본에서 옮겨 올 때는 `cowork install --takeover`를 쓴다. 자세한 내용은 [docs/installation.md](docs/installation.md).

## 업데이트

```bash
brew upgrade cowork
cowork apply
```

규칙·hook 같은 자산은 바이너리에 들어 있어서 `apply`를 해야 반영된다. 세션 시작 때 `적용 버전 … ≠ 바이너리 …` 줄이 보이면 `apply`가 필요하다는 뜻이다.

## 명령

| 명령 | 설명 |
|---|---|
| `init` | 대화형 초기 설정 후 설치(터미널 전용). 팀 cowork-space를 플레이북 레포로 자동 등록 |
| `install` / `apply` | 설치·갱신. `--dry-run`, `--host claude,codex`, `--bin <경로>`, `--yes` |
| `status` | 바이너리·manifest·대상별 블록 버전 |
| `doctor [--json]` | hook 등록, guard 자가 시험, Codex 신뢰, 플러그인, 플레이북 점검 |
| `uninstall` | manifest에 기록된 항목만 제거 |
| `machine set\|show` | 머신 역할과 prod 등급 |
| `config get\|set language <코드>` | 기본 언어(예: `ko`, `en`) |
| `guard explain "<명령>"` | 명령 하나의 Guard 판정과 사유 |
| `auth jira` | Jira API 토큰 등록(터미널 전용, 확인 후 OS 키체인에 저장) |
| `auth check github\|gitlab\|jira [--online]` | 쓰기 직전 준비 상태 확인. 안 되면 실행할 명령 안내, exit 1 |
| `auth status` | 설정된 연동의 로그인·토큰 상태 |
| `task list\|show\|new\|status\|assign\|note\|migrate` | 업무 관리. 팀 레포(T-N, commit·push), 개인 공간(로컬), Jira 이슈(상태 전환·담당 me·댓글)를 한 목록으로 다룬다. Jira 이슈 기록은 Jira 댓글과 cowork-space에 함께 남는다. `new --jira KAN "<제목>"`은 Jira 이슈를 만든다. `migrate`는 개인 공간의 끝나지 않은 업무를 팀 레포로 새 번호로 옮긴다(init에서 팀 레포로 바꿀 때 자동으로 묻는다). |
| `daily show\|add\|plan\|close` | 사용자별 하루 기록 `notes/<이름>/날짜.md`(아침 계획·메모·퇴근 정리). show는 그날 내 업무 기록을 자동으로 모아 보여 준다. 팀 레포면 팀 공개, 개인 공간이면 본인만 |
| `jira get <KEY> [--json]` | Jira 이슈 하나 조회(읽기 전용, 등록된 프로젝트만). 토큰은 키체인에서 꺼내 요청에만 쓴다 |
| `jira search "<JQL>" [--limit N] [--json]` | JQL 검색(기본 20건, 최대 100). 등록된 프로젝트로 범위를 자동 제한 |
| `secret-scan --staged\|<범위>` | 커밋 전 비밀값 검사(gitleaks가 있으면 사용) |

## 설정

`~/.config/cowork/config.yaml`

```yaml
schema_version: 1
hosts: [claude, codex]
language: ko
playbooks:
  repos: ["~/my-playbooks"]
guard:
  mcp_allow: []        # 허용할 MCP 도구 이름 정규식(전체 이름과 일치해야 함)
git:
  host: github         # github | gitlab | none — init이 gh/glab 로그인을 확인
work:                  # init이 채운다. 팀 레포·Jira 유무로 방식이 정해진다
  space: {url: "git@github.com:org/cowork-space.git", path: "~/cowork-space"}   # url이 비면 개인 공간(로컬)
  jira: {site: "https://회사.atlassian.net", project_keys: ["ABC"]}            # 선택
```

비밀값(토큰)은 이 파일에 두지 않는다. Git 호스트 로그인은 `gh`/`glab`의 공식 로그인이 관리하고, Jira 토큰은 처음 쓸 때 터미널에서 `cowork auth jira`로 등록한다. 토큰은 Jira API로 확인한 뒤 macOS Keychain(Linux는 Secret Service)에만 저장하고, 설정에는 계정 이메일과 `auth_ref`만 남는다.

| 경로 | 내용 |
|---|---|
| `~/.config/cowork/` | `config.yaml`, `machine.json`, `RULES.md` |
| `~/.local/state/cowork/` | `manifest.json`, `guard.jsonl`(판정 로그), `backups/` |

두 디렉터리는 Guard가 보호한다. 직접 고치지 말고 `cowork` 명령을 쓴다.

## 이 레포

설치 안내와 배포 파일(Releases)만 둔다. 소스 코드는 공개하지 않는다. 문제나 제안은 Issues에 남긴다.

## 라이선스

MIT
