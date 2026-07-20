# Handover (2026-07-20): drmTMB 0.6.0 CRAN RC gate — S1–S5 DONE (through G3), resume at S6

> **⏩ UPDATE (this handover superseded its own S3→G3 scope — read this block first).**
> **S1, S2, S3, S4, S5 are all DONE and pushed** to `origin/claude/release-0.6.0-cran-rc` (9 commits ahead
> of `origin/main`). **G3 was approved by Shinichi and the version is bumped to `0.6.0`** (commit
> `091d0a13`: DESCRIPTION `0.6.0.9000`→`0.6.0`, NEWS heading, `_pkgdown` banner, README preview-status).
> **S3 is complete**: doc-edits (`@seealso`, `\examples` verified), `check_pkgdown` clean, `urlcheck`
> (1 confirmed-false-positive DOI), **`build_site` clean**, and a **4-lens rendered inspection** (report:
> `docs/dev-log/figure-audits/2026-07-20-0.6.0-rc/rc-inspection-report.md`) that found **NO CRAN blocker**.
> Shinichi's decision was "small fixes now, rest → issues": **DONE** — the adequacy vignette got a
> colour-blind-safe viridis centile palette, a hedged worm-plot alt-text (honesty), and `fig.width` 6.4→7.4
> (re-rendered + PNG-verified: viridis correct, centile subtitle now wraps; the worm/qq single-line subtitle
> still clips at the tail — cosmetic, → the function-level follow-up issue).
> **S6 DONE (2026-07-20, CLEAN).** `--as-cran` on `drmTMB_0.6.0.tar.gz` = **0 errors / 0 warnings / 1 NOTE**
> (new-submission only; + a 27.8 Mb installed-size INFO — mostly `libs` 13.4 Mb compiled TMB, `doc` 9.4 Mb,
> `sim` 1.7 Mb; explained in cran-comments). **CRAN lane PROVEN**: `drmTMB.Rcheck/tests/testthat.Rout` ran the
> `phase18|structured-re-conversion-contracts` filter (invert) → **`FAIL 0 | WARN 52 | SKIP 122 | PASS 12011`**,
> well below the 39,466 full-run baseline (heavy tests excluded). Examples OK; vignettes rebuilt 78s (no timing
> risk). **Local clang-UBSAN probe CLEAN**: **0 runtime errors, 0 on `drmTMB.cpp`** — the six `(int)asDouble()`
> casts (1197/1301/1648/3241/3784/3856) do NOT trigger the NaN→int UB that blocked 0.5.0, across MI/ordinal/
> count/beta-binomial tests. (One testthat `E` under the *instrumented* build only; the same tests pass FAIL-0
> in the normal `--as-cran` run → sanitizer-build artifact, not a defect.)
> **FROZEN CANDIDATE TARBALL:** `drmTMB_0.6.0.tar.gz` · SHA-256
> `afd4600a86830451ea87971012929c7219b19fa9577c07c59485efc6c0a921f7` · 6,979,868 bytes · 825 entries ·
> forbidden-path scan CLEAN (no .git/scratchpad/docs/dev-log). Check log: `~/worktrees/drmTMB-rc-check.log`;
> UBSAN log: `~/worktrees/drmTMB-rc-ubsan.log`; build/tarball in `~/worktrees/drmTMB-final/`.
> **RESUME AT S7:** copy the tarball to an immutable hash-dir; author the ledger JSON (template at
> `~/shinichi-brain/protocols/cran-release-ledger.template.json`; set profile compiled_code=true,
> system_or_external_services=true [JuliaCall], first_submission; status_claim="tarball-clean"; the platform
> matrix stays NOT_APPLICABLE/next-gate); run `python3 ~/shinichi-brain/tools/cran_release_gate.py <ledger>`;
> temp-lib install smoke. Then S8 D-43 panel (Grace/Rose/Pat on the frozen artifact) → S9 rung report +
> manifest 7-field self-check + after-task → S10 RC PR (PAUSE at G4). The S3→G3 checklist below is HISTORY.
>
> **G2 follow-up issues to file (Shinichi APPROVED the "→ issues" disposition; file at the GitHub-edit gate):**
> (1) function-level figure-accessibility defaults (viridis in `centile_chart()`, subtitle wrapping in
> `worm_plot()`/`qq_plot()`) — the root cause of F1/F4; (2) `coef.drmTMB` documentation/reference page;
> (3) `animal-models` vignette heritability h² + table-after-example; (4) the **Julia xfam** extractor gap —
> **draft ready at `scratchpad/xfam-extractor-issue-draft.md`**; (5) the README "Stable-core matrix"
> plain-language trim (the top reader-quality finding, deferred by decision). Plus the pre-existing G2 items:
> the `phase18-simulation-grid.yaml` D-50 workflow, #59 body edit, #61 populate, #710.2 documentation.

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

## S3 PROGRESS (this session — much is already DONE + committed)

Committed + pushed on the RC branch (4 commits ahead of `origin/main`, HEAD `52007f50`):
- **`@seealso`** from `confint()`/`summary()` → the capability-and-limits tier table (`document()` regenerated
  the 2 Rd; diff was exactly those two).
- **`\examples`** added to `imputed()`, `drm_phylo_penalty()`, `drm_phylo_penalty_sweep()` — the only three
  exports lacking them. **Verified running** (imputed 0.1s; penalty ~0s; sweep `\donttest` real-fits 0.2s,
  both `convergence=0`/`pdHess=TRUE`). `checkRd` = **0 problems** on all three.
- Package **reinstalled** (`0.6.0.9000`) so the built site reflects the new Rd.

Checks run this session:
- `pkgdown::check_pkgdown()` → **✔ No problems.**
- `urlchecker::url_check()` → 28/29 clean; ONE flag: `vignettes/figure-gallery.Rmd:382` DOI
  `10.1198/0003130032369` returns **403** — the standard doi.org bot-block false-positive (record it in the
  rung report as a known 403-DOI, not a broken link; a valid DOI is the canonical citation).
- The 22 `drmTMB_julia`/`_xfam` S3 methods with no Rd are **legal** (S3method-registered, not exported → no
  R CMD check NOTE); scope = report only, no action.
- **`docs/` plain-text refs** = 107 across 10 vignettes, but they are **contributor pointers in code spans**
  (`docs/design/…`, `docs/dev-log/…`) in developer vignettes, not clickable 404s — assessed **acceptable**,
  no blanket rewrite (a future cleanup could convert applied-user-facing ones to GitHub URLs).

**IN FLIGHT:** `pkgdown::build_site(install = FALSE, preview = FALSE)` is RUNNING →
`~/worktrees/drmTMB-rc-buildsite.log`. **REMAINING S3:** (1) READ that build log (never trust exit code);
(2) inspect the rendered pages/figures + rendered home (README) + the figure uncertainty/colour-blind/caption
checks + audience-readability + per-vignette timing (Windows multiplier) — best fanned out as a Workflow
(Florence/Emmy/Pat/Darwin); (3) save a dated RC figure-audit under
`docs/dev-log/figure-audits/2026-07-20-0.6.0-rc/`. Then S5 (G3).

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
Rehydrate from docs/dev-log/handover/2026-07-20-cran-rc-s3-to-g3-handover.md (READ the ⏩ UPDATE block at
the top) + the plan at ~/.claude/plans/hidden-soaring-fern.md. Workspace ~/worktrees/drmTMB-final @
claude/release-0.6.0-cran-rc (pushed, 9 commits ahead; version already bumped to 0.6.0). S1–S5 done
through G3. RESUME AT S6: R CMD INSTALL . (prove namespace==HEAD), then the --as-cran build with NOT_CRAN
unset/false + the lane-proof (exact invert-filter test count + heavy-test presence/absence) + cran-extrachecks
+ the LOCAL clang-UBSAN probe of the six src/drmTMB.cpp casts (see the S6 line below); then S7 freeze → S8
D-43 panel → S9 rung report → S10 RC PR. PAUSE at G4 before merging the PR.
```
