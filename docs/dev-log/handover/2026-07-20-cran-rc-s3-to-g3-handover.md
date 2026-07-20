# Handover (2026-07-20): drmTMB 0.6.0 CRAN RC gate — S1+S2 DONE, resume at S3 → pause at G3

You are the continuing **drmTMB_final** Claude lane running the Phase-20 CRAN release-**candidate** gate.
This doc stands alone. Read `AGENTS.md`, then this, then the full ultra-plan at
`~/.claude/plans/hidden-soaring-fern.md` (the authoritative WHAT; slice table S0–S10 + fences + stops).

## Where things stand

Plan approved (G1) after an **11-lens review** (Rose, Grace, Ada, Fisher, Noether, Gauss, Emmy, Pat,
Curie, Darwin, Florence). **S1 (preflight) and S2 (reader-surface & release-state repair) are DONE**;
resume at **S3**. The loop is L2 — autonomous between stops, human ONLY at **G3** (version bump) and
**G4** (RC PR merge). Finish line = **local tarball-clean RC + a local clang-UBSAN probe**; the REMOTE
platform matrix (win-builder/R-hub/valgrind/rchk) + CRAN submission are the declared NEXT gates, out of lane.

## Workspace (IMPORTANT)

- Fresh clone OUTSIDE Dropbox: **`~/worktrees/drmTMB-final`**, branch **`claude/release-0.6.0-cran-rc`**,
  cut from `origin/main` @ `919a0b3a`. **Pushed** to `origin/claude/release-0.6.0-cran-rc`.
- Package **installed** from this checkout (`0.6.0.9000`, namespace==HEAD). Reinstall after any R/ or
  vignette change before `build_site` (pkgdown loads the installed pkg; the §7 stale-install guard).
- The Dropbox repo root (`~/Dropbox/Github Local/drmTMB`, another branch) — never touch.

## What S1 + S2 did (all verified)

- **S1:** branch cut; `R CMD INSTALL` clean (log read); namespace==HEAD; precondition 0 (the #803-merge
  R-CMD-check on `main`, run `29764335503`) **GREEN**. Mission Control kickoff written + committed.
- **S2 — committed + pushed** (one commit; docs/release-state only, NO version bump):
  - **Manifest** (`docs/dev-log/release-audits/2026-07-20-0.6.0-release-scope-manifest.md`): #710 status
    corrected (§5/§6/§7). **NOTE — broader than the originally-approved "just finding #5":** verifying the
    issue showed the whole §5 bullet was stale. The maintainer's own status is **5 of 6 fixed**
    (#710.1/3/4/5/6); only **#710.2** (a reverted sigma-slope start fix) is deferred. #710.5 is fixed by
    PR #722 (`ace97fc0`, `R/profile.R:3021` floors the endpoint refit iter.max/eval.max ≥1000), an ancestor
    of every certified profile-CI cell. Basis header corrected `ac378024`→`919a0b3a`. This is a factual
    correction, not a capability-claim expansion. **Flag for Shinichi's awareness.**
  - **cran-comments.md:** clean FIRST submission — dropped the "resubmission of 0.5.0" section and the
    win-builder/R-hub/3-OS "submitted/all clean" platform over-claims; now states only local `--as-cran` +
    local UBSAN, with the remote matrix marked as the pre-submission step. **S7 must reconcile its
    `0/0/1` counts against the real S6 build log.**
  - **NEWS.md:** zero-one-beta line = the closed generator-qualified fence (not a pending rerun).
  - **README.md + vignettes/drmTMB.Rmd:** install no longer defaults to the ditched `v0.5.0` tag.
  - **capability-and-limits.Rmd:** new shipped `## Known limitations for 0.6.0` section (corpairs/coscale
    `rho12` interval gap #802 · Arc 4c `sd_hat`/Wald NA gap · #710.5 fixed/#710.2 deferred · Julia xfam
    extractors not wired). Reviewed verbatim — honest, within the manifest.
  - **docs/cran-readiness-checklist.md:** banner-superseded by the manifest.
  - **inst/COPYRIGHTS:** confirmed still accurate (no ports) — no edit.

## CARRIED-OVER (uncommitted in the working tree — land in S3)

- **R/ `@seealso`** (roxygen only, no code logic): `confint.drmTMB` (`R/profile.R:254-258`) and
  `summary.drmTMB` (`R/methods.R:3671-3675`) now point to `vignette("capability-and-limits")`. **Run
  `devtools::document()` to regenerate `man/confint.drm.Rd` + `man/summary.drmTMB.Rd`, verify the diff is
  ONLY those two Rd (a larger diff = pre-existing roxygen drift to handle in S3), then commit R/ + man/ as
  part of S3.**
- **`scratchpad/xfam-extractor-issue-draft.md`** — the drafted Julia xfam follow-up issue. **File it at G2**
  (propose-first), do NOT commit the draft to the RC branch.
- **S4 (Fisher): SIGN-OFF — DONE** (read-only verification). #710.5 fixed + present (guard
  `R/profile.R:3021` floors the endpoint refit `iter.max`/`eval.max` ≥1000; `ace97fc0` / PR #722 is an
  ancestor of HEAD *and* every certified cell — confirmed by `git merge-base --is-ancestor`, all YES); the
  manifest #710 correction is accurate with **no capability overclaim**; the `sd_hat` negative space is
  sound (13,200 artifact rows `sd_hat`/Wald NA, profile populated; `cells.tsv` mc-0464/0539/0575 profile-only
  ML, no point-bias/Wald claim). **Carry the mc-0575 2-1 promotion split (Noether WITHHELD) into S9's rung
  report.** One pre-existing cosmetic nit: manifest §6 "Remaining" sub-list restarts at `4.`/`5.` (dup of the
  `4.` at line 207) — optional S9 cleanup, non-blocking. **S4 need not be re-run.**

## Resume at S3 — Documentation + pkgdown CAREFUL check (the review-derived checklist)

1. `devtools::document()` → commit the R/ `@seealso` + regenerated Rd (see CARRIED-OVER); reinstall.
2. `tools::checkRd()` over all Rd = **0 warnings**.
3. **Add `\examples`** to `imputed()`, `drm_phylo_penalty()`, `drm_phylo_penalty_sweep()` (`man/*.Rd`) —
   the only three exported-non-`internal` topics lacking them (Emmy/doc-scout). Deprecated `gr`/`meta_known_V`
   are `\keyword{internal}` — leave.
4. **Broaden the doc audit to S3 methods with no Rd** — ~14 `drmTMB_julia`/`_xfam` methods have no Rd/`\alias`
   (Emmy). Decide per method: fold under an `@rdname` or accept as undocumented-but-legal (no R CMD NOTE).
5. `pkgdown::check_pkgdown()`; then **full `pkgdown::build_site()` — READ THE LOG** (a prior session saw
   exit 0 while the log said "Execution halted"). No `tools/build-site.R` exists — build inline.
6. **Inspect EVERY reference page + article + the rendered HOME PAGE (= README; no `index.md`)** (Pat) for
   stale claims / layout / leaked internal pages / missing assets / broken links / text-outside-figures.
7. **Figure checks name uncertainty-honesty / colour-blind-safety / caption-vs-drawn-element** (Florence);
   cite the D2 audit (`docs/dev-log/figure-audits/2026-07-19-reader-arc-d2/figure-audit.md`) and **extend to
   the independent worm/qq/centile figures in `distributional-outputs-and-adequacy.Rmd`**; save a dated RC
   figure-audit under `docs/dev-log/figure-audits/2026-07-20-0.6.0-rc/`.
8. **Repo-wide `docs/` dead-link sweep** — `grep -rnE "docs/dev-log|docs/design" vignettes/` = **58 hits in
   10 files** (Pat); these plain-text refs into the build-excluded `docs/` are dead for a pkgdown reader.
9. **Audience-readability acceptance** (Darwin): the README "stable-core matrix" + the rendered
   `capability-ledger-family-map` table are contributor-grade ledger jargon — flag for a trim decision.
10. `urlchecker::url_check()`; **time each vignette + a stated Mac→Windows multiplier** (heavy:
    `phylogenetic-spatial` 21 fits, `missing-data` 21, `location-scale` 22, `which-scale` 14,
    `model-workflow`, `figure-gallery`); treat proximity to ~10-min incoming as a blocker even at NOTE.
11. State whether the prose pass is **exhaustive or a scoped sample** (Pat/Noether). Fan the inspection
    out with a Workflow (Florence/Emmy/Pat/Darwin) to keep it out of the orchestrator's context.

## Then S5→S10 (see the plan for full detail)

- **S5 — G3 STOP:** bump `DESCRIPTION` `0.6.0.9000`→`0.6.0` (strip `.9000`) + NEWS heading + `_pkgdown`
  banner. **Pause for Shinichi.**
- **S6:** `document`→`build_readme`→`test`→`check`→`R CMD build`→`R CMD check --as-cran --run-donttest` +
  cran-extrachecks. **`NOT_CRAN` unset/false** (it's `=true` 644× in this repo's logs — muscle-memory
  trap); **PROVE the lane** — compute the exact expected count via
  `devtools::test(filter="phase18|structured-re-conversion-contracts", invert=TRUE)`, require the
  `--as-cran` log to MATCH it + heavy-test presence/absence (Curie); `cran-extrachecks` is a manual
  checklist (recorded, not "log-proven"). **LOCAL clang-UBSAN:** `pkgbuild::compile_dll()`
  `-fsanitize=undefined -fno-sanitize-recover=undefined`; run MI-family + ordinal suites; target the six
  casts `src/drmTMB.cpp:1197,1301,1648,3241,3784,3856` + the `:1648` bad-alloc path. Fix ONLY check-forced
  (+ a test; doc-only fixes self-verify via `checkRd`/`check`); **a real UBSAN defect = STOP** (your approval).
- **S7:** freeze ONE tarball (path/**SHA-256**/size/inventory+forbidden-path scan/clean-worktree/log +
  lane-proof count + UBSAN result); reconcile cran-comments counts vs the S6 log; author the ledger JSON
  from `~/shinichi-brain/protocols/cran-release-ledger.template.json` (`compiled_code`,
  `system_or_external_services`=true [JuliaCall], `first_submission`=true; target=`tarball-clean`); run
  **`python3 ~/shinichi-brain/tools/cran_release_gate.py <ledger.json>`** (BRAIN path — the script is NOT
  repo-local); temp-lib install smoke.
- **S8:** D-43 panel (Grace/Rose/Pat) on the frozen artifact; default NOT-READY; **two NOT-READY withhold**;
  any installed-byte fix → re-freeze loop S6→S7.
- **S9:** cran-release-gate **rung report** (proven=tarball-clean + which sanitizer ran locally vs the
  remote next gate — Gauss) + **manifest 7-field self-check as a literal `git diff`-vs-manifest** (Noether)
  + carry the zero-one-beta **2-1 promotion split** (Fisher) + the "certified cells never run against the
  tarball" residual caveat (Curie) + after-task + handover.
- **S10 — G4 STOP:** open the RC PR (GHA checks+docs only); **#61 stays OPEN** (its DoD includes
  paper-prep/comparator we defer); after merge re-verify from fetched `origin/main`. Then MV + reconcile.

## G2 propose-first (apply only after Shinichi approves)

`.github/workflows/phase18-simulation-grid.yaml` (a live compute-campaign workflow — D-50 conflict; propose
delete/disable) · GitHub issues: file the xfam draft, edit #59 (D-50 text), populate #61, document #710.2.

## Fences (non-negotiable)

R/ src/ tests/ change ONLY where a CRAN check forces it (+ a test). Every OTHER code/correctness finding
(Julia xfam NULLs, `fixef.*` dispatch bypass, unrecoverable `cli_abort` messages) → **logged as a follow-up
issue + documented where user-visible, never fixed inline**. A real UBSAN defect = STOP. No compute (G5).
No remote platform matrix in-lane. Any capability/CLAIM change reopens the frozen manifest = a Shinichi
decision. **Mission Control** updated after each slice + at each stop (status file
`~/shinichi-brain/Shinichi/Dashboards/mission-control/live/status/drmTMB.json`, commit scoped to the vault;
rung discipline — never "ready").

## Resume command

```
Rehydrate from docs/dev-log/handover/2026-07-20-cran-rc-s3-to-g3-handover.md + the plan at
~/.claude/plans/hidden-soaring-fern.md. Workspace ~/worktrees/drmTMB-final @ claude/release-0.6.0-cran-rc
(pushed). S1+S2 done; land the carried-over R/ @seealso via devtools::document(), then run S3 (docs+pkgdown
careful check per the checklist above), then PAUSE at G3 before the version bump.
```
