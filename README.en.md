# cowork

[한국어](README.md)

A small execution layer that installs **the same rules and the same guardrails** into Claude Code and Codex CLI. It is a single Go binary distributed through Homebrew.

- **Guard**: a PreToolUse hook judges every shell, file, and MCP call (allow / ask / deny). It stops mistakes such as prod changes, edits to protected files, and force pushes. On failure it blocks (fail-closed).
- **Rule injection**: a SessionStart hook adds the machine's prod level, reporting rules, and default language to each session. The global rules (`RULES.md`) are linked through managed blocks in `CLAUDE.md` and `AGENTS.md`.
- **Safe install**: changes are applied as lock → backup → atomic writes → doctor check, and rolled back automatically on failure. Installed items are recorded in a manifest so uninstall removes only those.
- **Playbooks**: playbooks (skills) from a separate repo are linked into the skills directory once registered in the config.

Guard prevents mistakes; it is not a security boundary. Server-side permissions are the last line of defense.

## Supported environments

- macOS, Linux (amd64, arm64)
- Claude Code (`~/.claude`, `$CLAUDE_CONFIG_DIR`, Orca profiles)
- Codex CLI (`~/.codex` or `$CODEX_HOME`). Guard blocking was verified live on Codex 0.166.0

## Install

```bash
brew install withwontae/tap/cowork
cowork init      # asks role, prod level, language, git setup, task backend and playbook repo, previews, then installs
```

`init` needs a terminal. In scripts or CI, use the individual commands:

```bash
cowork machine set --role <role> --prod none   # this machine's prod level: none | read | change
cowork config set language en                  # (optional) default language
cowork install --yes
```

After installing, any remaining work is printed as a `다음 단계` (next steps) checklist. With Codex, start a new Codex session and approve the two cowork hooks on the `Hooks need review` screen (or with `/hooks` inside a session). You are done when `cowork doctor` passes everything.

To migrate from a legacy `~/cowork` install, use `cowork install --takeover`. See [docs/installation.md](docs/installation.md) (Korean).

## Update

```bash
brew upgrade cowork
cowork apply
```

Rules and hooks are embedded in the binary, so they take effect only after `apply`. A session-start line `적용 버전 … ≠ 바이너리 …` (applied version ≠ binary) means `apply` is needed.

## Commands

| Command | Description |
|---|---|
| `init` | Interactive first-time setup, then install (terminal only). Registers the team cowork-space as a playbook repo |
| `install` / `apply` | Install or update. `--dry-run`, `--host claude,codex`, `--bin <path>`, `--yes` |
| `status` | Binary, manifest, and per-target block versions |
| `doctor [--json]` | Checks hook registration, guard self-test, Codex trust, plugins, playbooks |
| `uninstall` | Removes only what the manifest recorded |
| `machine set\|show` | Machine role and prod level |
| `config get\|set language <code>` | Default language (e.g. `ko`, `en`) |
| `guard explain "<command>"` | Guard verdict and reason for one command |
| `auth jira` | Register a Jira API token (terminal only; verified, then kept in the OS keychain) |
| `auth check github\|gitlab\|jira [--online]` | Readiness check right before use; prints the command to run and exits 1 if not ready |
| `auth status` | Login and token state of the configured services |
| `task list\|show\|new\|status\|assign\|note\|migrate` | Task management over a team repo (T-N, commit and push), a personal local space, and Jira issues (transitions, assign to me, comments) in one list. Notes on Jira issues go to a Jira comment and to cowork-space. `new --jira KAN "<title>"` creates a Jira issue. `migrate` moves the open tasks of a personal space into the team repo under new numbers (init offers it when switching to a team repo). |
| `daily show\|add\|plan\|close` | Per-user daily note `notes/<name>/<date>.md` (morning plan, memos, end-of-day summary). show also collects that day's task notes. Team-visible in a team repo, private in a personal space |
| `jira get <KEY> [--json]` | Show one Jira issue (read-only, configured projects only). The token is taken from the keychain for the request only |
| `jira search "<JQL>" [--limit N] [--json]` | JQL search (default 20, max 100), automatically scoped to the configured projects |
| `secret-scan --staged\|<range>` | Pre-commit secret scan (uses gitleaks when available) |
| `report [add\|send\|clear]` | Collect cowork errors and annoyances and send them to this repo's Issues (see "Reporting problems") |

CLI messages are in Korean.

## Configuration

`~/.config/cowork/config.yaml`

```yaml
schema_version: 1
hosts: [claude, codex]
language: en
playbooks:
  repos: ["~/my-playbooks"]
guard:
  mcp_allow: []        # regexes that must match the whole MCP tool name
git:
  host: github         # github | gitlab | none — init checks the gh/glab login
work:                  # filled by init; the mode follows from what is set
  space: {url: "git@github.com:org/cowork-space.git", path: "~/cowork-space"}   # empty url = personal (local) space
  jira: {site: "https://company.atlassian.net", project_keys: ["ABC"]}          # optional
```

No secrets (tokens) go in this file. Git host logins are kept by the official `gh`/`glab` login, and the Jira token is registered with `cowork auth jira` in a terminal when Jira is first used. The token is verified against the Jira API and stored only in the macOS Keychain (Secret Service on Linux); the config keeps just the account email and an `auth_ref`.

| Path | Contents |
|---|---|
| `~/.config/cowork/` | `config.yaml`, `machine.json`, `RULES.md` |
| `~/.local/state/cowork/` | `manifest.json`, `guard.jsonl` (verdict log), `backups/` |

Guard protects both directories. Use `cowork` commands instead of editing them directly.

## Reporting problems

cowork collects problems it hits only locally (`~/.local/state/cowork/reports.jsonl`). Nothing is sent automatically.

- What is collected: failed commands (command name only, argument values are dropped), failed blocking `doctor` checks, and suggestions you add (`cowork report add "<one line>"`). Suspected guard false positives are picked from recent deny reasons when you send.
- `cowork report` lists them and `cowork report send` sends them. Before sending it shows each issue title and body exactly as they will be posted and asks `y/n/e/q`. `--dry-run` only previews.
- Masked: home path, user name, host name, email, IP, private domains (`*.local` etc. and the `report.redact_domains` setting). A report that looks like it contains a secret is not sent.
- The same problem is grouped into one issue; if an open issue already exists, a comment adds the count.
- Issues are posted with the sender's own `gh` login, so **your GitHub account name is public.**


It holds only the install guide and the release files (Releases). The source code is not public. Use Issues for problems and suggestions.

## License

MIT
