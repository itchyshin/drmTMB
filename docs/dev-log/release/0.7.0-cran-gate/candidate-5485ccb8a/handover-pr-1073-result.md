# Handover PR #1073 verification

Date verified: 2026-08-18

PR: https://github.com/itchyshin/drmTMB/pull/1073

GitHub reports PR #1073 `MERGED` at `2026-08-18T13:53:56Z`, with merge commit
`12a5cc5bcc36ed1b83d969e5147e29bc98aaadf6`.

The PR changed exactly four files:

- `AGENTS.md`;
- `docs/dev-log/after-task/2026-08-18-codex-ligges-handover.md`;
- `docs/dev-log/coordination-board.md`;
- `docs/dev-log/handover/2026-08-18-codex-handover.md`.

Direct inspection of frozen candidate
`drmTMB_0.7.0.tar.gz` (SHA-256
`6b45164ba1221538de5dbf01eb15d83d77fae8b4e3e15de557f2b39372eedc62`)
found all four paths absent. `.Rbuildignore` excludes both `^docs$` and
`^AGENTS\\.md$`.

Therefore the handover PR is landed and does not change the bytes shipped
inside the source package except through its already-incorporated repository
ancestry; its four own files are build-excluded.
