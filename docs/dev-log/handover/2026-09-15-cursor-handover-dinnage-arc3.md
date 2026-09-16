# Session Handoff: Dinnage audit, third arc (38 open issues), for Cursor

Meta: 2026-09-15 · from Claude (Fable, planning session) · to Cursor · TARGET = cursor · AUTHOR = claude.
Plan approved by Shinichi at G0 on 2026-09-15 with four decisions (section "Key Decisions").

You are Cursor, picking up the third fix arc for Russell Dinnage's independent evaluation of drmTMB
0.7.0. You inherit no chat. This file, `AGENTS.md`, and the current git state are your whole context.

## Critical Context

1. **38 issues remain open** under the label `audit-dinnage` (#1315 to #1360 minus the sixteen closed on
   2026-09-15 and minus #1351 Mi-13, closed the same day as A4 record). Every open issue carries "What
   Russell found", "Where", "Since-audit status on main", and "Proposed fix". A read-only inventory at
   `6ccdd737c` (Appendix A) listed 39 at G0; re-check with `gh issue list --label audit-dinnage --state
   open` before editing. Re-find each locus with `grep -n` before editing.
2. **An audit fix never merges on its own builder's tests** (D-263 corollary, learned in waves 1 to 3:
   a fresh-context reviewer overturned three of four builder verdicts). Each wave PR needs a review by
   a fresh chat on a pinned Claude or GPT model, or by Claude, before Shinichi merges it.
3. **Shinichi merges every wave PR himself.** You push branches and open PRs; you do not merge, tag,
   release, or message Russell.
4. **`R/methods.R` and `R/drmTMB.R` are pinned by the C17 capability-ledger validator** (CI step
   "Validate generated capability ledger"). Any branch that edits either file runs
   `tools/recertify-c17.py` LAST, after all other commits, or the four release shards go red with
   "stale, not wrong".
5. Two Codex lanes own the Julia bridge and its docs (`R/julia-bridge.R`, Julia help and vignettes).
   Do not touch them; #1328 Md-K is theirs (its "halted bridge" premise is stale: `engine = "julia"`
   is live and documented on main).

## What Was Accomplished (before this handover)

- Waves 1 to 3 (PR #1361, merged 8195b1215) fixed the Critical, nine Majors, five Moderates and one
  Minor. Records: `docs/dev-log/after-task/2026-09-13-dinnage-audit-wave1.md`,
  `docs/dev-log/after-task/2026-09-14-dinnage-audit-wave3.md`, reviews under `docs/dev-log/audits/`.
- 2026-09-15 close-out (PRs #1364, #1365): sixteen issues closed with evidence comments; the response
  map `docs/dev-log/audits/2026-09-13-dinnage-independent-evaluation-response.md` carries a "Closed on
  GitHub" section. Russell has the map (a private issue in his evaluation repo).
- This session: two read-only scouts sized the open-issue set and the carried-over items (Appendices A
  and B); Shinichi answered the four owner questions below. No code was changed in that planning session.
- 2026-09-15 evening: Wave A implementation landed on three **OPEN** PRs (not merged): #1368, #1369,
  #1367. D-263 independent reviews **ACCEPT**; CI green on current heads. Shinichi merge only.

## Current Working State

- Working: `origin/main` at `3fbb3d516` (board sync after coordinator rehydration). Wave A fixes live on
  PR branches only until Shinichi merges.
- In progress: Wave A merge gate — **MERGE-READY**, awaiting Shinichi (#1369 and #1367 unblock Wave B).
- Not working / blocked: Wave B/C **HOLD** until #1369 and #1367 are on `main`. The seven DEFER items
  below wait on a campaign or a design, not on you.

## Key Decisions & Rationale (Shinichi, 2026-09-15, at G0)

1. **Wave B's eleven defaults are accepted as written** (table in "Next Immediate Steps"). Run B straight
   after A.
2. **Wave C, both API changes go ahead:** rename `beta()` to `beta_family()` with `beta()` kept as a
   deprecated alias for one release (Mi-1, #1339); import and re-export nlme's `ranef`/`fixef` generics
   and register drmTMB's methods on them, as glmmTMB does (Mi-2, #1340).
3. **Merge authority:** Shinichi merges each wave PR after CI is green and the review file says ACCEPT.
4. **Mi-13 (#1351):** no tag. Close it with a comment saying "tag matches Version" is a CRAN
   release-gate checklist item, not a CI check, and add that line to
   `~/shinichi-brain/skills/cran-release-gate/SKILL.md` if it is not already there (Shinichi's vault; if
   you cannot write there, say so in the closing comment and leave the issue open).

Standing decisions that still bind: D-263 (attributed issues, independent review before merge), D-266
(S3 stays as documented), D-252 (repeatability vocabulary; design note 275), D-139 (state a time
estimate before any run over 30 minutes; none expected here), D-88 (no bleed-through into another
lane's files).

## Landing State

`tools/handoff_gate.sh` on the lane worktree at `958d7c560`: clean tree, nothing unpushed, before this
document was added. The primary checkout `/Users/z3437171/Dropbox/Github Local/drmTMB` carries prior
sessions' untracked files (`docs/dev-log/correspondence/`, `.ignore`, `drmjl-profile-diagnostic.R`, a
`.gitignore` graft line) and 38 stale `.unlazy/` ledgers from earlier lanes: PROTECTED, never stage or
clean them, and do not work there. Work in a fresh worktree off `origin/main`.

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `main` `3fbb3d516` (#1364, #1365, #1366 merged) | y | y | merged | LANDED |
| this handover + board row, `claude/dinnage-arc3-handover-20260915` | y | y | merged via #1366 | LANDED |
| Wave A1 docs `#1368` @ `822763660` | y | y | [#1368](https://github.com/itchyshin/drmTMB/pull/1368) OPEN | MERGE-READY (Shinichi) |
| Wave A2 check `#1369` @ `3805b8520` | y | y | [#1369](https://github.com/itchyshin/drmTMB/pull/1369) OPEN | MERGE-READY (Shinichi) |
| Wave A3 misc `#1367` @ `6a5200f39` | y | y | [#1367](https://github.com/itchyshin/drmTMB/pull/1367) OPEN | MERGE-READY (Shinichi) |
| Wave B/C branches | none on `main` | | | HOLD until #1369+#1367 merged |

FINDINGS-OF-RECORD: none. The inventories in the appendices are derived from the issues and the code;
nothing new was discovered.

## Next Immediate Steps

Run `~/shinichi-brain/tools/lane_preflight.sh .` first, classify every item here OWED / DONE /
RETRACTED / PROTECTED against the live issue states (`gh issue list --label audit-dinnage --state open`),
and execute only OWED.

### Wave A: 21 issues, no owner input, three parallel PRs (about 10 hours of lane time)

Scaffold each PR as its own bounded worktree:
`~/shinichi-brain/tools/lane_launch.sh "/Users/z3437171/Dropbox/Github Local/drmTMB" dinnage-arc3-A1`
(likewise A2, A3). The script names the branch `claude/lane-<name>`; that is its convention, the lane is
yours. Claim the lease on exactly the files the PR edits. Copy the fixture style of
`tests/testthat/test-dinnage-audit-wave1.R` (one `test_that` per finding, comment naming the finding and
the pre-fix failure, `set.seed`, small n).

| PR | issues | what to do | notes |
|---|---|---|---|
| A1 docs | #1317 S8, #1320 Md-C, #1323 Md-F, #1334 A-4, #1341 Mi-3, #1345 Mi-7, #1346 Mi-8, #1349 Mi-11, #1354 Mi-16, #1359 UX-4 | roxygen in `R/`, regenerate `man/` with `devtools::document()`; Md-F updates the `mi()` table in `vignettes/capability-and-limits.Rmd` (lognormal, gamma, student, beta_binomial all fit); Md-C is doc-only this arc (a Details paragraph naming the families where `type = "response"` is not E[Y]); Mi-3 adds a worked emmeans and DHARMa example | no tests beyond `R CMD check`; docs-only, no C17 |
| A2 check.R | #1338 A-8, #1343 Mi-5 | A-8: `check_dropped_rows` also reports groups that lost every row; Mi-5: `wald_boundary_targets` (`R/profile.R` about line 2545) and `check_rho12_boundary` stop recommending `method = "profile"` when the target is `rho12` at its own bound | red-first tests in `test-dinnage-audit-wave4a.R` |
| A3 misc code | #1324 Md-G, #1325 Md-H, #1326 Md-I, #1344 Mi-6, #1348 Mi-10, #1350 Mi-12, #1357 UX-2, #1358 UX-3 | Md-G: `run_oracle` in `tests/testthat/test-numeric-kernel-oracle.R` counts and asserts excluded non-finite grid points; Md-H: give `beta_binomial` the mu-epsilon nudge and shape floor `beta` has, in both `src/drm_response_kernels.h` (case 14) and `src/drmTMB.cpp`; Md-I: an `estimator_exact` field beside `spec$estimator` distinguishing exact REML from Cox-Reid; Mi-6: `validate_phylo_tree` emits a note when tips are pruned and `?phylo` states the branch-length convention; Mi-10: `on.exit` RNG restore around `set.seed()` in `simulate.drm_pair_association`; Mi-12: one `control`/`maxit` and a convergence check at both `optim()` sites in `R/aghq-coxreid.R`; UX-2: `summary()` returns `nobs`; UX-3: an empty `$derived` points to `$sdpars` | edits `R/methods.R`: run `tools/recertify-c17.py` last; Md-H needs a TMB recompile (`pkgload::load_all()`, about 30 s) |
| A4 record | #1351 Mi-13 | close with the release-gate comment (decision 4) | no code |

Per finding: red test on current code, fix, green, one commit
`fix(<area>): <what> (Dinnage audit <id>, #<issue>)`, and a `NEWS.md` bullet ending
"Credit: the independent evaluation by Russell Dinnage (rdinnager/drmTMB_eval), finding <id>."
Per PR: `NOT_CRAN=false R CMD check --as-cran --no-manual` on a `git archive` export (0 errors, 0
package warnings; the "new submission" NOTE is expected); push; open the PR with a test plan; write
`docs/dev-log/audits/2026-09-<dd>-dinnage-arc3-<pr>-review.md` from a fresh reviewer chat (ACCEPT /
ACCEPT-WITH-CHANGES / REJECT per finding); tell Shinichi it is ready. After he merges, close each issue
with a `Status (<date>)` comment naming the sha and the NEWS bullet (shape: any comment on #1306).

### Wave B: 11 issues, decided, two PRs (12 to 16 hours)

| PR | issue | decision (binding) |
|---|---|---|
| B1 check.R | #1319 Md-B | SE-inflation ratio uses the median over the non-flagged subset as its reference |
| B1 | #1356 UX-1 | `[.drm_check` keeps the class; `print` says "X of N checks shown" when subset |
| B1 | #1337 A-7 | new row: observations per estimated parameter; note (not warning) below 10 |
| B1 | #1342 Mi-4 | new row: pairwise abs(r) above 0.99 among fixed-effect design columns; note only |
| B1 | #1333 A-3 | `is_converged()` stays logical; add `convergence_status()` returning converged / boundary / degenerate and a `check_drm()` row; `multi_start` can no longer clear a degenerate fit |
| B1 | #1327 Md-J | add the `wald_bias_corrected` level to `conf.status`; the tip-count `g` question is written up as `docs/design/276-phylo-bias-correction-denominator.md` (question and options only, no answer) |
| B2 surfaces | #1332 A-2 | `miss_control(predictor = "fail")` errors on NA predictors, as the help page promises |
| B2 | #1360 UX-5 | `bf()`/`drm_formula()` accept a formula held in a variable (evaluate the symbol); keep the literal-expression error for anything else |
| B2 | #1353 Mi-15 | keep the 13-column frame; add `as.matrix.drm_confint()` returning `stats::confint()`'s 2-column matrix |
| B2 | #1355 Mi-bundle | fix items 2 to 7 of the bundle; backfill the `{.i}` hint to all 17 unsupported-parameter branches |
| B2 | #1316 S7 | document the joint sigma+zi local-optimum risk and `multi_start` advice in `?drm_control`; no default change |

Thresholds in B1 are notes, never warnings, until a simulation says otherwise. Same per-finding and
per-PR discipline as wave A; B1 edits `R/check.R` and possibly `R/methods.R` (C17 rule applies).

### Wave C: 2 issues, API (about 3 hours, after B)

- #1339 Mi-1: `beta_family()` exported; `beta()` kept as a deprecated alias (`lifecycle`-style message)
  for one release; every internal call and example moves to `beta_family()`.
- #1340 Mi-2: `importFrom(nlme, ranef, fixef)` and re-export; drop drmTMB's own generics; register the
  drmTMB methods on nlme's; a test loads glmmTMB then drmTMB and calls `ranef()` on a glmmTMB fit.

## Blockers / Open Questions

None for waves A to C. DEFER (not yours; named so nothing vanishes):
S6 bootstrap opt-in code plus its Totoro pre-run (design 274 §7, D-139 gate); A-5 and A-6 (each needs a
simulation to set a threshold; Fisher designs); Md-L 17-copy refactor (own arc); Md-K (Codex Julia
lanes); Eq-4 latent-scale support (design 275, feature decision); variance-ratio Wald undercoverage (needs
an interval design); S3 option B campaign; M3 sqrt(n) tolerance design; Gaussian latent `mi()`
missing-row weighting; the four raw-predictor sigma-clamp consumers (`R/profile.R` about 4504,
`R/julia-bridge.R` about 5549, `R/methods.R` about 5225, `R/drmTMB.R` about 3542).

## Gotchas & Failed Approaches (from waves 1 to 3)

- A capped testthat reporter hid 5 of 11 red-test failures once; run red proofs with an uncapped reporter.
- Clamping Wald endpoints to the clamp band gave zero-width intervals (coverage 0); the accepted repair
  was `NA` endpoints with `conf.status = "clamp_limited"`. Do not reintroduce endpoint clamping.
- The structured-sigma diagonal must be measured on the modelled rows (tips), not the whole augmented
  precision; otherwise `phylo()` on sigma is wrongly refused.
- Two agents editing one worktree back up and restore each other's files; one worktree per PR.
- The first as-cran run on a clean export found a test pinned to pre-fix behaviour; always run it before
  the push, not after.
- The `unlazy` checker matches `EXPECT` literally; regex gates never pass. Never make
  `check-after-task.R` a gate CHECK (it re-verifies the ledger that contains it).

## How to Resume

Working directory: `/Users/z3437171/Dropbox/Github Local/drmTMB` for launching; each PR in its own
worktree under `~/local-scratch/lanes/`. Toolchain: R 4.6 (arm64), TMB; `pkgload::load_all()` recompiles
`src/` in about 30 s; `devtools::document()` for `man/`; check of record
`NOT_CRAN=false R CMD check --as-cran --no-manual` on a `git archive` export. `gh` is authenticated for
itchyshin/drmTMB. Never stage `.unlazy/`, `LOOP/notes/`, scratch files, or the primary checkout's
untracked files. `git push` of a lane branch and `gh pr create` are allowed; `gh pr merge`, `git tag`,
`gh release` are not.

Read, in order: `AGENTS.md`, this file, `docs/dev-log/coordination-board.md` (Active Lane Split),
`docs/dev-log/audits/2026-09-13-dinnage-independent-evaluation-response.md`, then the issue bodies for
the PR you take. Then `/goal` with wave A1 to A3 as the first arcs.

```text
Read AGENTS.md and docs/dev-log/handover/2026-09-15-cursor-handover-dinnage-arc3.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

## Appendix A: inventory at G0 (39 open at scout time; #1351 closed same day → 38 open now; scout main `6ccdd737c`)

| # | id | sev | kind | locus (file:function) | fix in one line | size | needs a decision? | groups with |
|---|----|----|------|------|------|------|------|------|
| 1315 | S6 | major | design-decision | R/profile.R:2608 `drm_bootstrap_confint` | Document the bias-doubling / recommend Wald or profile, or ship a BCa bias-corrected bootstrap | L | document-only, or implement a BCa variant (needs coverage-simulation validation)? | none |
| 1316 | S7 | moderate | design-decision | R/control.R:182 `drm_control` (`multi_start`) | Raise the `multi_start` default for jointly-specified submodels, or document the joint-submodel local-optimum risk | M | raise the default or document the risk in `?drm_control`? | 1333 |
| 1317 | S8 | moderate | doc | R/drmTMB.R:185-186 `REML` arg doc | State that Wald/profile `confint()` on a REML-integrated mean coefficient returns `NA`; name bootstrap as the working alternative | S | no | 1326, 1327, 1353, 1359 |
| 1319 | Md-B | moderate | code-small | R/check.R:1151 `check_standard_errors_inflated` | Compute the inflation-ratio reference (median or max/min) over a non-flagged subset instead of all finite SEs | S | median-over-reference-subset vs. max/min ratio? | 1333,1335,1337,1338,1342,1356 |
| 1320 | Md-C | moderate | doc | R/methods.R:2862 `predict.drmTMB` (`type=="response"` branches ~3807+) | Add a Details paragraph naming families where `type="response"` != E[Y] | S | doc-only this arc, or also ship a `type="mean"` option (code-medium)? | 1349, 1354, 1346, 1355 |
| 1323 | Md-F | moderate | doc | vignettes/capability-and-limits.Rmd:590-593 | Update the `mi()` capability table: lognormal/gamma/student/beta_binomial all fit already | S | no | none |
| 1324 | Md-G | moderate | test | tests/testthat/test-numeric-kernel-oracle.R:84-108 `run_oracle` | Count and assert non-finite/excluded grid points instead of silently dropping them | S | no | 1325 |
| 1325 | Md-H | moderate | code-small | src/drm_response_kernels.h:128 (case 14) + src/drmTMB.cpp:~3539 | Add the same mu-epsilon nudge + alpha/beta_shape floor guard `beta` already has, to `beta_binomial` in both files | S | no | 1324 |
| 1326 | Md-I | moderate | code-small | R/drmTMB.R:1268 (`spec$estimator <- "REML"`) | Add an `estimator_exact` field distinguishing exact REML from Cox-Reid/Laplace-adjusted REML | S | no | 1317, 1327 |
| 1327 | Md-J | moderate | design-decision | R/profile.R:2228 (`conf.status`) / :2390 `structured_sd_group_count` | Add a `wald_bias_corrected` status level (easy); separately settle the `g` question | S | is tip-count `g` the right denominator for the phylogenetic bias correction, or an effective-sample-size measure? | 1317, 1326, 1343, 1353 |
| 1328 | Md-K | moderate | design-decision | R/julia-bridge.R (8,688 lines) / NAMESPACE | Decide the Julia bridge's public export status before CRAN submission | L | keep the bridge publicly exported, or mark it internal/experimental? | none |
| 1329 | Md-L | moderate | code-medium | R/drmTMB.R:20565 `make_tmb_data_core` | Replace the 17 hand-maintained `model_type` branches with one constructor | L | refactor now given regression risk, or defer to its own arc? | none |
| 1332 | A-2 | moderate | code-medium | R/missing-data.R:47 `miss_control` + ~9 `complete.cases()` sites in R/drmTMB.R | Make `predictor = "fail"` actually error on NA predictors, or fix the docs to match current complete-case behaviour | M | implement the error, or relabel the docs? | 1338 |
| 1333 | A-3 | moderate | design-decision | R/check.R:225 `is_converged.drmTMB` | Make `is_converged()` three-valued, or stop it reading TRUE more often as `multi_start` rises on a degenerate likelihood | M | three-valued `is_converged()`, or another mechanism to stop the unearned flag? | 1316,1319,1335,1337,1338,1342 |
| 1334 | A-4 | moderate | doc | man/meta_V.Rd (R/formula-markers.R:16) | State that `meta_V()`'s `V` is matched by row position, not dimnames, mirroring `?relmat` | S | no | none |
| 1335 | A-5 | moderate | campaign | R/check.R (no row exists; dispatch ~289) | Add a `check_drm()` row sensitive to response-distribution/residual-scale damage | L | what residual-magnitude/scale-attenuation heuristic and threshold? | 1319,1333,1336,1337,1338,1342 |
| 1336 | A-6 | moderate | campaign | R/check.R:1452 `check_skew_normal_nu` + man/skew_normal.Rd | Add a Wald-SE-reliability note near the skew-normal `nu=0` singular-geometry boundary | L | what nu-near-zero threshold, calibrated by type-I error simulation? | 1319,1333,1335,1337,1338,1342 |
| 1337 | A-7 | moderate | code-medium | R/check.R (no row; `check_fixed_effect_design_size` at 1593 is related but distinct) | Add an observations-per-estimated-parameter `check_drm()` row | M | what obs-per-parameter threshold triggers the note? | 1319,1333,1335,1338,1342 |
| 1338 | A-8 | moderate | code-small | R/check.R:1207 `check_dropped_rows` | Also count/report groups that lost every row, not just rows dropped | S | no | 1319,1332,1333,1335,1337,1342 |
| 1356 | UX-1 | moderate | code-small | R/check.R:345 `print.drm_check` | Give subsetting either a class-dropping `[.drm_check` method, or a preserved-total "X of N shown" report | S | drop the class on subset, or preserve class + report the original total? | 1319 (check.R board) |
| 1339 | Mi-1 | minor | design-decision | R/family.R:278 `beta()` + NAMESPACE | Rename the `beta()` family constructor so `base::beta()` is no longer masked | M | new name (e.g. `beta_family()`), and keep `beta()` as a deprecated alias or drop it outright? | 1340 |
| 1340 | Mi-2 | minor | design-decision | R/zzz.R:27 `register_foreign_s3_methods` | Register/re-export so `ranef()`/`fixef()` on `glmmTMB`/`lmerMod` fits keep working after `library(drmTMB)` | M | keep drmTMB's own `ranef`/`fixef` generics, or re-export `nlme`'s as the shared generic? | 1339 |
| 1341 | Mi-3 | minor | doc | man/summary.drmTMB.Rd / man/residuals.drmTMB.Rd | Add `\seealso`/section documenting `emmeans` and `DHARMa` support plus a worked example | S | no | 1346 |
| 1342 | Mi-4 | minor | code-medium | R/check.R (no row; near `check_fixed_effect_design_size:1593`) | Add a collinearity/condition-number `check_drm()` row | M | pairwise-r vs. VIF, and what threshold? | 1319,1333,1335,1337,1338 |
| 1343 | Mi-5 | minor | code-small | R/profile.R:2545 `wald_boundary_targets` (remedy text) + R/check.R:1367 `check_rho12_boundary` | Don't recommend `method = "profile"` when the boundary target is `rho12` near its own ±1 boundary | S | no | 1327 |
| 1344 | Mi-6 | minor | code-small | R/phylo-utils.R:1 `validate_phylo_tree` + man/phylo.Rd | Emit a note when extra tree tips are pruned; state the assumed branch-length convention | S | no | none |
| 1345 | Mi-7 | minor | doc | R/drmTMB.R:17997 `prepare_ordinal_response` / `?cumulative_logit` | State that integer-coded ordinal responses are accepted at face value with no semantic-order check | S | no | none |
| 1346 | Mi-8 | minor | doc | man/residuals.drmTMB.Rd | Add `student`/`skew_normal`/`beta` to the per-family Pearson-residual-scale enumeration | S | no | 1341, 1349, 1354 |
| 1348 | Mi-10 | minor | code-small | R/associate-pairs.R:692 `simulate.drm_pair_association` | Add `on.exit` RNG restore around the bare `set.seed()` | S | no | none |
| 1349 | Mi-11 | minor | doc | man/student.Rd | Remove/qualify the false "one implemented family" scale-vs-SD claim | S | no | 1346, 1354, 1320 |
| 1350 | Mi-12 | minor | code-small | R/aghq-coxreid.R:14 and :55 `drm_o3_cr_negll` + `aghq` branch | Unify `maxit`/`control` across both `optim()` calls; check convergence at both sites | S | no | none |
| 1351 | Mi-13 | minor | code-small | DESCRIPTION:3 (`Version`) / git tags | Tag `v0.7.1` to match DESCRIPTION; consider a CI check enforcing tag-matches-version | S | add the CI enforcement check now, or just tag and leave the recurring gap? (decided: neither; release-gate item) | none |
| 1353 | Mi-15 | minor | code-medium | R/profile.R:404 `confint.drmTMB` | Add `simplify = TRUE` or a `tidy()`/`as.matrix()` companion returning `stats::confint()`'s 2-column matrix shape | M | argument vs. separate method? (decided: `as.matrix()` method) | 1359, 1317, 1327 |
| 1354 | Mi-16 | minor | doc | R/methods.R:4100 `sigma.drmTMB` | State that `sigma()` returns an n-vector when the `sigma` submodel has covariates, and that `insight::get_sigma()` will summarize it | S | no | 1349, 1346, 1320 |
| 1355 | Mi-bundle | minor | code-small | R/methods.R:2649 (AIC/BIC guard), :2 (`print.drmTMB`); R/family-dpq.R:192 (Tweedie dpq); R/drmTMB.R (column access, param-branch hints, weight grammar ~17699) | Fix items 2 to 7: scope the AIC/BIC REML guard to the comparison, guard Tweedie dpq domain, print coefficients, `tryCatch` column lookup, consistent `{.i}` hints, weight-grammar singular | M | backfill the `{.i}` hint to all 17 unsupported-parameter branches now, or file separately? (decided: now) | 1320, 1326 |
| 1357 | UX-2 | minor | code-small | R/methods.R:4264 `summary.drmTMB` | Add `nobs = nobs(object)` to the return list | S | no | 1358 |
| 1358 | UX-3 | minor | code-small | R/methods.R:4612 `drm_derived_summary_rows` | Point the user to `$sdpars` when `$derived` is empty because `sigma ~ x` disqualifies the constant-sigma computation | S | no | 1357 |
| 1359 | UX-4 | minor | doc | man/confint.drmTMB.Rd (R/profile.R:404 `confint.drmTMB`) | State in the Value section that returned `parm` values are always fully-qualified regardless of the spelling supplied | S | no | 1353, 1317, 1327 |
| 1360 | UX-5 | minor | code-small | R/parse-formula.R:117 `is_formula_call` / :54 `parse_drm_formula_entry` | Evaluate `expr` and accept a genuine formula held in a variable, or reword the error to describe the literal-expression restriction | M | accept formula-in-variable (fix the NSE check), or just reword the error message? (decided: accept) | none |

Pure documentation: #1317, #1320, #1323, #1334, #1341, #1345, #1346, #1349, #1354, #1359.
Touch `R/check.R`: #1319, #1333, #1335, #1336, #1337, #1338, #1342, #1343, #1356.
Already moved on main: #1351 (the 0.7.0 gap is tagged; the same drift recurred at 0.7.1).

## Appendix B: carried-over items from the second arc (read-only scout)

| item | where (file:line) | what the fix is | size | needs compute? | needs Shinichi's decision? |
|---|---|---|---|---|---|
| Gaussian latent `mi()` weight invariance | `src/drmTMB.cpp:325` (`has_mi2`), `:1175`/`:1245`, `:4417` (`mi_family == 0` blocks) | Observed rows: one-line weight fix. Missing rows: need a design (exact Gaussian marginal, then weighted, not weighting inside a Laplace-integrated latent) | M | No | Yes |
| Tweedie imputation quadrature frozen support | `R/missing-data.R:3577-3578` (start value), `:3656` `drm_tweedie_mi_quadrature()` | Add a `cli_warn()` when the fitted scale outgrows the support fixed at start values (a detector, not a re-solve) | S | No | No (could join wave B2 if time allows) |
| 4 raw-predictor sigma-clamp consumers | `R/profile.R:4504-4512`; `R/julia-bridge.R:5549-5566`; `R/methods.R:5225-5238`; `R/drmTMB.R:3542` via `R/check.R:572` | Align all four with `sigma()`/`predict()`'s clamp-aware value | M to L | No | Yes (cross-cutting; touches the Julia lane's file) |
| `drm_variance_ratio()` Wald undercoverage (0.910/0.928 vs 0.95) | `R/heritability.R:280`, `:465-495` | Needs a better interval; profile is refused for this quantity today | L | Likely (coverage sim) | Yes |
| S6 bootstrap `basic`/`BC` intervals (opt-in) + pre-run | `R/profile.R:404`, `:2608`, `:2978` | Add `bootstrap_interval = c("percentile","basic","BC")`, same draws | code S; campaign L (about 199,000 refits, 24 to 27 h single-core; Totoro at most 150 cores, D-143) | Yes | Yes (design 274 §7 sign-off before the full run) |
| S3 option B (drop Jacobian) | design note per wave-3 addendum | Likelihood change; needs bias/coverage evidence | L | Yes | Yes (parked, not rejected) |
| Eq 4 latent-scale support, non-Gaussian families (D-252) | `docs/design/275` §5/§8 | Feature decision | L | Possibly | Yes |
| M3 `gradient_tolerance` sqrt(n) scaling | `R/check.R:264`, `:648-687` | Rescale the absolute tolerance by sqrt(n) or leave absolute | S to M | No | Yes |

Test fixtures from waves 1 to 3: `test-dinnage-audit-m1-families.R`, `test-dinnage-audit-m2.R`,
`test-dinnage-audit-s2.R`, `test-dinnage-audit-wave1.R`, `test-dinnage-audit-wave2a.R`,
`test-dinnage-audit-wave2b.R`.
