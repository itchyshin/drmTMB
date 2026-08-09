# Plan versus actual: CRAN reader boundaries (2026-08-08)

Plan: `docs/dev-log/2026-08-08-cran-reader-boundaries-ultra-plan.md`.

| Planned commitment | Actual | Verdict |
| --- | --- | --- |
| M1 reader boundary live before freezing M2 | PR #948 merged at `ad475cc39`; main package check and pkgdown deploy green; live page, redirect, search, sitemap, desktop, and mobile verified | Met |
| First screen separates fit, point, named interval, exact scope, and fallback | Generated reader cards provide all five fields and keep internal evidence tokens below the fold | Met |
| Canonical-ledger freshness and tarball-contained rendering | Selected scopes are bound by canonical claim fingerprints; mutation test fails closed; extracted tarball renders without repo-only inputs | Met |
| Public roadmap retired, old URL preserved | Root roadmap moved byte-for-byte internally; public body removed; old URL redirects exactly once | Met |
| Independent user, visual, claim, and reproducibility reviews | Pat, Florence, Rose, and Grace returned PASS after repairs | Met |
| One exact post-M1 current-main `0.6.0` tarball | Source `ad475cc39`, SHA `2e5234bd…`, 9,831,204 bytes, 922 entries | Met |
| Exact local CRAN-shaped check and identity verification | 0 ERROR, 0 WARNING, 1 expected new-submission NOTE; independent Luna identity and extracted render PASS | Met |
| Stop at `tarball-clean` | Ledger remains `tarball-clean`; no platform campaign or higher claim | Met |
| Preserve scope exclusions | No DESCRIPTION bump, upload, D-43, `cran-comments.md` finalization, simulation, #858, #937, #947, or dirty-primary edit | Met |

## Material adaptations

- The planned base `5affb962b` advanced through a human-owned change before
  production. The fresh lane was rebased to current `origin/main`; the reader PR
  then merged as `ad475cc39`. Protected subjects were not absorbed.
- The first CRAN-shaped check was blocked by sandbox DNS before installation.
  The same tarball was rerun with network access; its identity did not change.
- The first independent extraction audit intentionally lacked write access and
  preserved a FAIL. A narrower rerun allowed only scratch output and passed.
- CI wall time exceeded the optimistic path: the PR and post-merge Ubuntu checks
  each took about 46 minutes. This changed elapsed time, not scope or evidence.
- Mission Control retains 17 inherited DRM.jl/evidence failures. Introduced
  roadmap/README regressions were repaired; inherited failures are disclosed.

## Safety and claim reconciliation

All post-freeze edits are under build-excluded `docs/dev-log`. No installed
byte changed. Earlier win-builder and platform receipts remain predecessor
evidence and were not used to label this artifact platform-clean. The final
claim is exactly:

> Highest proven rung: `tarball-clean` for current-main `0.6.0` artifact
> `2e5234bd4bf819663e9ef95f10a1944d51c90ce64ffd5dd7a9641b69fa50c5ea`.

The next unproven rung is `platform-clean` for a future, explicitly authorized
`0.7.0` candidate.
