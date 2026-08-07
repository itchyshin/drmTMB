# GitHub Actions 3-OS matrix — platform-clean evidence
- URL: https://github.com/itchyshin/drmTMB/actions/runs/31195187084
- Event: `workflow_dispatch` (full matrix)
- Head SHA: `744b9fbeec226784fa0b94f27e63bf121f31bed7`
- Run status/conclusion: **completed / success**
- Created: 2026-08-07T15:57:19Z · Updated: 2026-08-07T16:56:27Z

## Jobs

| Job | Status | Conclusion | Started | Completed | Duration (min) |
| --- | --- | --- | --- | --- | --- |
| os-matrix | completed | success | 2026-08-07T15:57:33Z | 2026-08-07T15:57:35Z | 0.0 |
| windows-latest (release) | completed | success | 2026-08-07T15:57:39Z | 2026-08-07T16:56:26Z | 58.8 |
| macos-latest (release) | completed | success | 2026-08-07T15:57:38Z | 2026-08-07T16:29:19Z | 31.7 |
| ubuntu-latest (release) | completed | success | 2026-08-07T15:57:39Z | 2026-08-07T16:44:10Z | 46.5 |

All three OS cells **success**. Durations below the 75-minute job ceiling (not a timeout-cancel).
Superseded ubuntu-only push run 31194260935 was **cancelled** by concurrency when this workflow_dispatch started — that cancel is pacing, not a platform failure.
