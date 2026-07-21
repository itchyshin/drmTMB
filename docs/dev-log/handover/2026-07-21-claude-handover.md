# Session Handoff: drmTMB 0.6.0 pre-CRAN content review and reader path

**From:** Codex  
**To:** Claude Code  
**Date:** 2026-07-21  
**Repository:** `drmTMB`

## Critical Context

`drmTMB` 0.6.0 remains a first CRAN submission candidate, not CRAN-ready. The
tarball-clean and local UBSAN rung was previously completed and must **not** be
rerun in this lane. The remaining sequence is: resolve/review the pre-CRAN
content PR, then separately run the platform-clean gate, then leave CRAN
submission to Shinichi.

The branch below contains only reader/documentation work. It does not alter a
likelihood, estimator, formula grammar, capability tier, coverage floor, or
Julia implementation. Any proposed capability or claim change remains
Shinichi's decision.

## Goals / Mission

Keep the 0.6 public surface honest and usable before platform verification:
native R/TMB is the documented release path; Julia cross-family work is
optional and post-0.6; detailed capability claims belong to the manifest and
generated maps rather than an overloaded home page.

## What Was Accomplished

- Completed the independent pre-CRAN content/Rd/pkgdown audit and pushed its
  corrections in PR [#810](https://github.com/itchyshin/drmTMB/pull/810).
  Gamma, regression-`rho12`, Julia/cross-family, and zero-one-beta reader
  wording were reconciled to the manifest without broadening a claim.
- Added and merged the function-map and cheat-sheet page in PR #809
  (`origin/main` `99bf0974`).
- Rebuilt the landing page as a compact reader path: first model, family/scale,
  diagnostics, specialist routes, and explicit capability limits. Pat and Rose
  approved the final render; it is commit `d78c7353` on #810.
- Checks on the PR candidate passed: `pkgdown::build_site()`/home rebuild,
  `pkgdown::check_pkgdown()`, `python3 tools/capability_ledger.py --check`, and
  `Rscript tools/check-capability-runtime.R` (18 routes; G0/G1/G2 = 0).
- A separate external q2 gllvmTMB diagnostic was archived as a **post-0.6
  design lead only**. It made no drmTMB code, public claim, or release decision.

## Current Working State

- **Working / pushed:** `codex/precran-review-20260721` at `d78c7353`, PR #810
  open against `main`. It is ahead of `origin/main` `99bf0974` by the pre-CRAN
  content corrections and landing-page revision.
- **Not deployed:** public pkgdown Pages remains unchanged; do not deploy from
  this branch before review/merge through the normal docs path.
- **Not started:** platform-clean (win-builder, R-hub UBSAN/valgrind/rchk,
  3-OS matrix, Windows vignette timing) and CRAN submission.

## Key Decisions and Rationale

- The release manifest is the truth ceiling:
  `docs/dev-log/release-audits/2026-07-20-0.6.0-release-scope-manifest.md`.
  The review fence is narrow: only a correctness defect or false shipped claim
  blocks; all other debt is a follow-up.
- The cross-family Julia bridge has incomplete post-fit extractors behind #806.
  The shipped 0.6 content now describes cross-family Julia as post-0.6
  development rather than a release workflow. Do not silently restore a broad
  Julia claim; any repair and new wording require Shinichi's decision.
- Native `coef.drmTMB()` returning a dpar-keyed list was reviewed as internally
  coherent but insufficiently discoverable. It is follow-up debt, not a reason
  to change the list-return API during this release lane.
- The C++ likelihood review found no demonstrated defect. Do not re-run the
  frozen tarball-clean rung merely because the content PR is open.

## Landing State

`~/shinichi-brain/tools/handoff_gate.sh /private/tmp/drmtmb-precran-review-7abdd7e9`
was run before this handover. It also reports many unrelated stale local
branches; they are outside this lane and must not be acted on here.

| Artifact / branch | Committed | Pushed | PR | State |
|---|---:|---:|---|---|
| `codex/precran-review-20260721` @ `d78c7353` | yes | yes | #810 open | LANDED; review/merge pending |
| `origin/main` @ `99bf0974` | yes | yes | #809 merged | LANDED |
| `docs/dev-log/release-audits/2026-07-21-pre-cran-code-content-review.md` | no | no | none | CARRIED-OVER; untracked review draft in this worktree, intentionally not staged; do not rely on it from a fresh checkout |
| This handover + `AGENTS.md` pointer | pending | pending | #810 open | to be committed and pushed with this handover |

## Files Created / Modified

PR #810 contains `README.md`; affected `vignettes/*.Rmd`; `docs/dev-log/check-log.md`;
`docs/dev-log/release-audits/2026-07-21-pre-cran-pkgdown-rd-audit.md`;
`docs/dev-log/after-task/2026-07-21-pre-cran-content-audit.md`; and
`docs/dev-log/after-task/2026-07-21-landing-page-reader-path.md`.

This handover adds `docs/dev-log/handover/2026-07-21-claude-handover.md` and
refreshes the `AGENTS.md` latest pointer.

## Next Immediate Steps

1. Read this handover, the current `AGENTS.md` snapshot, the release-scope
   manifest, the two after-task reports named above, and PR #810's diff.
2. Have Rose independently audit the candidate PR's public wording before any
   claim or merge decision. Keep the manifest ceiling and post-0.6 Julia
   boundary intact.
3. If review is clean, obtain Shinichi's normal review/merge decision for #810;
   do not deploy Pages directly from the feature branch.
4. Only after the content candidate is merged and frozen again, open the
   separate platform-clean gate. Do not submit to CRAN without Shinichi.
5. Treat #806 Julia extractor repair and the q2 gllvmTMB diagnostic as post-0.6
   work unless Shinichi explicitly changes that scope.

## Blockers / Open Questions

- PR #810 is not merged. Its change is documentation and reader flow, not a
  release authorization.
- Platform evidence is intentionally absent; do not call 0.6 CRAN-ready.
- The local carried-over review draft is not on origin. If it becomes needed,
  re-run/recreate an evidence-backed review rather than treating it as landed.

## Gotchas / Failed Approaches

- Run claim-bearing checks with `NOT_CRAN` unset. `devtools::test()` sets it
  and is not the CRAN release lane.
- A sandbox-only pkgdown build could not resolve `cloud.r-project.org`; the
  approved network-enabled rerun built successfully. Do not mistake the first
  DNS failure for a package defect.
- The current checkout is an isolated worktree. Do not use `git add -A`; the
  untracked code-review memo is intentionally excluded.

## How to Resume

Claude should first read `AGENTS.md`, this handover, and the manifest. Before
any public claim, spawn Rose for an independent audit. Claude can plan, refactor,
and review prose/logic; use Codex or CI for live R/TMB compilation and platform
checks when those gates are authorized.

From the repository root, paste:

```sh
claude "Rehydrate from docs/dev-log/handover/2026-07-21-claude-handover.md + the AGENTS.md snapshot, then continue with the Next Immediate Steps. Preserve the 0.6 release fence: do not rerun tarball-clean, do not broaden a capability claim, and do not deploy or merge without review."
```

## Mission Control

| Repo | Branch / main | CI | What shipped | Plan by leverage |
|---|---|---|---|---|
| drmTMB | #810: `codex/precran-review-20260721` @ `d78c7353`; `main` @ `99bf0974` | Local pkgdown + capability checks pass; remote platform checks not run | Pre-CRAN wording corrections and an approved compact landing-page source; #809 function map merged | 1. Rose/PR review and merge decision; 2. post-merge docs read-back; 3. separate platform-clean gate; 4. maintainer CRAN decision |
