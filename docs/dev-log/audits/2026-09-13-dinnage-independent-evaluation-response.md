# Response map: Russell Dinnage's independent evaluation of drmTMB 0.7.0

Pinned report: <https://github.com/rdinnager/drmTMB_eval/blob/main/REPORT.md> at commit `945da24f`.
Repo state audited against: `main` at `4bfb9d721` (2026-09-13), from worktree
`claude/audit-dinnage-wave1-20260913`.

## Purpose

This document cross-matches every finding in Russell Dinnage's independent evaluation of drmTMB 0.7.0
against the current state of `main`, so that Shinichi can decide what to post as GitHub issues (and in
what order) without re-deriving the audit himself, and so that Russell can see, finding by finding,
what the maintainers did with his report. Every row below was re-verified against the actual source at
the pin commit or against the current worktree — line numbers, `grep` hits, and (where practical) direct
reproduction in R — rather than taken on the report's word alone. Where an existing open issue already
covers a finding, we say so and file a comment instead of a duplicate issue; everything else gets a
standalone draft under `docs/dev-log/issue-drafts/2026-09-13-dinnage-audit/`.

## Method summary

- Four parallel, independent Claude Opus 5 evaluation runs (plus doc-only sub-runs) produced the source
  report; this response was assembled by a separate Rose (systems-auditor) pass reading only the frozen
  report text and the current repository.
- The evaluation's own design was pre-registered before the repository was cloned, and one reader group
  worked doc-only (no `R/`, `src/`, `tests/`, `docs/dev-log/`) to measure genuine first-contact usability
  separately from source-informed findings.
- Every claim in this response was re-derived against the pinned commit or current `main`: by `grep`/line
  read of the cited function, by `git log <pin>..HEAD -- <file>` for drift, and in several cases (Mi-2,
  Mi-14) by direct execution in R.
- Comparators (`glmmTMB`, `gamlss`, `metafor`, `lme4`) were run on identical data/seeds throughout the
  original evaluation; this response does not re-run those comparisons, only the drmTMB-side code state.
- All findings are tagged PRESENT / FIXED / MOVED / UNCLEAR against `main` as of this audit; severity and
  one-line summaries are drawn from the report's own Appendix A table, independently checked against the
  cited code.

## All findings

| ID | sev | finding | files at pin | since-audit | existing issue | draft path | wave |
|---|---|---|---|---|---|---|---|
| C1 | critical | log(sigma) clamp one-armed; check_drm() misreports 96%-wrong fit | R/drmTMB.R:2929-2937, R/profile.R:4197, test-clamp-active-guard.R:33 | PRESENT (draft); **caveat: HEAD now has an uncommitted-to-main fix, `328507d59`, in this same lane** | — | C1.md | wave 1 |
| M1 | major | weights() inside mi() mixture move the MLE at constant weight | src/drmTMB.cpp:3510-3519 | PRESENT | — | M1.md | wave 1 |
| M2 | major | sigma()/predict()/residuals() report the unclamped scale | R/drmTMB.R:22335, R/methods.R | PRESENT | — | M2.md | wave 2 |
| M3 | major | fixed_gradient absolute tolerance warns on ~all correct fits at n>=1000 | R/check.R:612 | PRESENT | — (rel. #1251, distinct check) | M3.md | wave 2 |
| M4 | major | simulate() leaks missing-response sentinel for 12/13 families | R/methods.R:3235-3241, R/missing-data.R:546-565 | PRESENT | — | M4.md | wave 2 |
| S1 | major | fitted_distribution()$p()/$d() return row 1 only for a scalar input | R/family-dpq.R:1167, man/exceedance.Rd | PRESENT | — | S1.md | wave 2 |
| S2 | major | summary()$derived repeatability divides by median sigma, not E[sigma^2]^0.5 | R/methods.R:4529, man/summary.drmTMB.Rd | PRESENT | #1231 (related family, distinct locus) | S2.comment.md | decision-gated (D-252, #1301) |
| S3 | major | drm_phylo_penalty() applies Gamma(2, rate), not the documented PC prior | R/penalty.R:54, man/drm_phylo_penalty.Rd | PRESENT | — | S3.md | wave 2 |
| S4 | major | vcov(type="robust") silently returns the model-based matrix | R/methods.R:2331 | PRESENT | — | S4.md | wave 2 |
| S5 | major | AIC(drm_fit, foreign_fit) silently returns a bare scalar | R/methods.R:2677 | PRESENT | — | S5.md | wave 2 |
| S6 | major | percentile bootstrap confint() doubles the ML bias; one-sided coverage | R/profile.R:2545, R/profile.R:501 | PRESENT | — | S6.md | wave 2 (+ design-note decision-gated) |
| S7 | moderate | default single start lands worse on 18.3% of joint sigma+zi fits at n=400 | R/drmTMB.R (drm_control default) | PRESENT | — (rel. #1248, distinct: perf vs default) | S7.md | later |
| S8 | moderate | REML=TRUE gives NA Wald intervals on mean coefficients, undocumented | man/drmTMB.Rd | PRESENT | — (rel. #1201, distinct: SE construction vs refusal) | S8.md | later |
| Md-A | moderate | drm_clamped_scale_families() omits biv_lognormal/biv_student | R/drmTMB.R:2895-2911, src/drmTMB.cpp:5166-5170 | PRESENT (draft); **caveat: HEAD now has an uncommitted-to-main fix, `0acc4a477`, in this same lane** | — | Md-A.md | wave 1 |
| Md-B | moderate | standard_errors_inflated loses sensitivity as its own median inflates | R/check.R:764-800 | PRESENT | — | Md-B.md | later |
| Md-C | moderate | predict(type="response") is not documented as returning E[Y] | man/predict.drmTMB.Rd | PRESENT | — | Md-C.md | later |
| Md-D | moderate | mi() silently discarded on every non-mu formula | R/drmTMB.R:9788 | PRESENT | — | Md-D.md | wave 1 |
| Md-E / A-1 | moderate | unused factor level: right estimates, every SE NA, remedy hint is a no-op | R/drmTMB.R (model-frame construction) | PRESENT | — | Md-E.md | wave 1 |
| Md-F | moderate | capability table says 4 families reject mi(); all 4 fit | vignettes/capability-and-limits.Rmd:587-591 | PRESENT (table moved/re-worded, defect unchanged) | — (rel. #962, #1230, distinct) | Md-F.md | later |
| Md-G | moderate | extreme-value kernel oracle silently drops non-finite grid points | tests/testthat/ (run_oracle) | PRESENT | — | Md-G.md | later |
| Md-H | moderate | beta_binomial missing both numerical guards its siblings carry | src/drmTMB.cpp:3532, src/drm_response_kernels.h:119 | PRESENT | — | Md-H.md | later |
| Md-I | moderate | "estimator: REML" labels two different objects (exact vs Cox-Reid) | R/drmTMB.R:1140 | PRESENT | — | Md-I.md | later |
| Md-J | moderate | bias-corrected confint() leaves no trace in conf.status | R/profile.R (bias-correct branch) | PRESENT | — | Md-J.md | later |
| Md-K | moderate | halted Julia bridge's NAMESPACE footprint needs a public-status decision | R/julia-bridge.R, NAMESPACE | PRESENT / UNCLEAR (a decision, not a code defect) | — | Md-K.md | later |
| Md-L | moderate | make_tmb_data_core is 17 hand-maintained copies of one data literal | R/drmTMB.R (make_tmb_data_core) | PRESENT | — (rel. #1048, the historical incident this risk cites) | Md-L.md | later |
| Md-M | moderate | skew_normal floors log-Phi with +1e-300 instead of the tail-safe helper | src/drm_numeric.h:76 | PRESENT | — | Md-M.md | wave 1 |
| Md-N | moderate | dropped_rows says "no rows dropped" after MSPL drops rows | R/mspl-estimator.R, R/drmTMB.R | PRESENT | — | Md-N.md | wave 1 |
| A-2 | moderate | miss_control(predictor="fail") does not fail; help page self-contradicts | R/missing-data.R, man/miss_control.Rd | PRESENT | — | A-2.md | later |
| A-3 | moderate | multi_start can clear is_converged() on a likelihood with no maximum | R/drmTMB.R (is_converged, multi-start loop) | PRESENT | — (rel. #1248, #1254, distinct: perf not flag semantics) | A-3.md | later |
| A-4 | moderate | meta_V() is positional, relmat() name-keyed; only the second says so | man/meta_V.Rd | PRESENT | — | A-4.md | later |
| A-5 | moderate | no check_drm() row is sensitive to response-distribution damage | R/check.R (no such row) | PRESENT | — | A-5.md | later |
| A-6 | moderate | skew_normal() nu~x prints unqualified Wald SE at singular info matrix | man/skew_normal.Rd, R/check.R | PRESENT | — (rel. #1230, distinct claim) | A-6.md | later |
| A-7 | moderate | nothing on the diagnostic board carries sample size | R/check.R | PRESENT | — | A-7.md | later |
| A-8 | moderate | dropped_rows counts rows lost to MCAR, not groups | R/check.R:826 | PRESENT | — | A-8.md | later |
| Mi-1 | minor | beta() masks base::beta() | R/families.R, NAMESPACE | PRESENT | — | Mi-1.md | later |
| Mi-2 | minor | ranef()/fixef() own generics break glmmTMB/lmerMod dispatch | R/zzz.R, NAMESPACE | PRESENT (reproduced live) | — | Mi-2.md | later |
| Mi-3 | minor | emmeans support is exact and DHARMa works; neither documented | man/summary.drmTMB.Rd, vignettes/ | PRESENT | — | Mi-3.md | later |
| Mi-4 | minor | near-collinearity to r=0.9999 fires no check and no warning | R/check.R | PRESENT | — (rel. #1251, opposite-direction case) | Mi-4.md | later |
| Mi-5 | minor | Wald rho12-boundary warning always recommends a profile that is a no-op there | R/check.R, R/profile.R | PRESENT | — | Mi-5.md | later |
| Mi-6 | minor | a tree with extra tips is pruned with no message in 25/25 fits | R/drmTMB.R (phylo prep), man/phylo.Rd | PRESENT | — | Mi-6.md | later |
| Mi-7 | minor | ordinal guard tests for ordered factor; integer coding bypasses it | R/drmTMB.R (ordinal validation) | PRESENT | — | Mi-7.md | later |
| Mi-8 | minor | ?residuals.drmTMB enumerates 15 families, omits student/skew_normal/beta | man/residuals.drmTMB.Rd | PRESENT | — | Mi-8.md | later |
| Mi-9 | minor | default: branch of drm_response_log_density() returns 1 for unhandled family | src/drm_response_kernels.h:138 | PRESENT | — | Mi-9.md | wave 1 |
| Mi-10 | minor | simulate.drm_pair_association() leaks the RNG seed | R/associate-pairs.R | PRESENT | — | Mi-10.md | later |
| Mi-11 | minor | ?student wrongly claims uniqueness for its scale-vs-SD[y] distinction | man/student.Rd | PRESENT | — | Mi-11.md | later |
| Mi-12 | minor | aghq-coxreid.R's two optim() branches diverge; convergence unchecked in both | R/aghq-coxreid.R | PRESENT | — (rel. #934, distinct: estimator validity vs code hygiene) | Mi-12.md | later |
| Mi-13 | minor | DESCRIPTION Version keeps running ahead of the newest immutable git tag | DESCRIPTION, git tags | MOVED (0.7.0/v0.5.0 gap closed; now 0.7.1/v0.7.0 gap) | — | Mi-13.md | later |
| Mi-14 | minor | AGENTS.md bloat, five competing "start here" blocks | AGENTS.md, CONTRIBUTING.md | **FIXED** (commit `743191f8b`, 2026-08-30, post-pin) | — | Mi-14.md | later |
| Mi-15 | minor | confint() returns a 13-column data frame, not stats::confint's 2-col matrix | R/profile.R (confint.drmTMB) | PRESENT | — | Mi-15.md | later |
| Mi-16 | minor | sigma() returns an n-vector, collapsing under insight::get_sigma() | R/methods.R (sigma.drmTMB) | PRESENT | — | Mi-16.md | later |
| Mi-bundle | minor | 6 more papercuts (anova/AIC-BIC-guard/Tweedie-guard/print/undef-cols/hint-count/grammar) | R/methods.R, R/family-dpq.R, R/drmTMB.R | PRESENT (6/7; anova sub-item tracked at #1240) | #1240 (anova sub-item only) | Mi-bundle.md + anova-note.comment.md | later |
| UX-1 | moderate | print() of a filtered drm_check prints "<drm_check: 0 checks>" | R/check.R (print.drm_check) | PRESENT | — | UX-1.md | later |
| UX-2 | minor | summary(fit)$nobs does not exist, returns NULL silently | R/methods.R (summary.drmTMB) | PRESENT | — | UX-2.md | later |
| UX-3 | minor | summary(fit)$derived is 0-row whenever a sigma submodel is present | R/methods.R (summary.drmTMB) | PRESENT | — | UX-3.md | later |
| UX-4 | minor | confint(parm="sigma:z") accepts compact label, returns fixef:sigma:z | R/profile.R (confint.drmTMB) | PRESENT | — | UX-4.md | later |
| UX-5 | minor | bf()/drm_formula() reject a formula held in a variable | R/parse-formula.R | PRESENT | — | UX-5.md | later |

## Counts

**By since-audit status** (57 files; Mi-bundle counted once as PRESENT for its 6 own items, its anova
sub-item separately tracked at #1240 and not double-counted):

| Status | Count | IDs |
|---|---|---|
| PRESENT | 54 | everything above except Mi-13, Mi-14, and Md-K's decision half |
| FIXED | 1 | Mi-14 |
| MOVED | 1 | Mi-13 |
| UNCLEAR (decision, not code) | 1 | Md-K |

**By severity** (58 rows counting Md-E/A-1 once and Mi-bundle once; S2's severity follows the report's
own major label even though it is decision-gated):

| Severity | Count |
|---|---|
| Critical | 1 (C1) |
| Major | 10 (M1-M4, S1-S6) |
| Moderate | 22 (Md-A..N = 14, A-2..A-8 = 7, UX-1 = 1) |
| Minor | 21 (Mi-1..16 = 16, Mi-bundle = 1, UX-2..5 = 4) |

**A caveat on the tally, stated plainly for Shinichi.** Two PRESENT rows above (C1, Md-A) reflect what the
standalone draft files say, per this task's instruction to source since-audit status from the draft
files. But this worktree's `git log` shows two commits already made in this same lane, *after* those
drafts were written, that fix exactly those two findings: `328507d59` (two-sided clamp detection, C1) and
`0acc4a477` (biv_lognormal/biv_student added to the clamped-family list, Md-A). Neither commit is on
`origin/main` yet. Treat C1 and Md-A as **effectively FIXED pending merge**, not PRESENT, when deciding
what to post — posting them as open bugs would misstate the true repository state. This response map does
not edit the underlying draft files (out of scope for this pass), so the inconsistency is flagged here
instead of silently corrected.

## What nobody looked at

Excluding the halted Julia bridge (5,193 deliberately-undocumented lines), **3,896 lines of live, shipped,
user-reachable R code were never read, skimmed, or grepped for a hazard by any of the evaluation's
runs** — 14.5% of `R/`. The largest named files are `prediction-grid.R` (500 lines), `mspl.R` (442),
`plot-corpairs.R` (392), `plot-parameter-surface.R` (372), `distributional-outputs.R` (340),
`gaussian-aggregation.R` (338), `penalty.R` (303), `adequacy.R` (303), `adequacy-plots.R` (268),
`mesh.R` (242), `marginal-parameters.R` (187), `meta-vcov.R` (150), and `sparse-fixed.R` (59). Three
consequences the report states plainly: (1) the promotion trigger for the M4 `simulate()` sentinel finding
sits entirely inside this unread code — `centile_chart()`, `worm_plot()`, `prediction_grid()`, and the
`adequacy` layer (1,411 of the 3,896 lines) were exercised behaviourally and found correct across all 17
families, but only on complete data, never with a missing-response mask; (2) four documented capabilities
have zero code-review coverage at all — known-sampling-variance meta-analysis (`meta-vcov.R`, a headline
capability), the MAP/penalty path (`penalty.R`), the SPDE/mesh spatial route (`mesh.R`), and the sparse
fixed-effect path (`sparse-fixed.R`); and (3) `prediction-grid.R` is one of the two routes the `emmeans`
preflight sends users to when it refuses a family — a refusal the evaluation itself praised as the
best-designed message in the package, while half of its destination went unread.

## How to post

1. Create the shared label once:
   ```
   gh label create audit-dinnage --repo itchyshin/drmTMB --color B60205 \
     --description "Finding from Russell Dinnage's independent evaluation (rdinnager/drmTMB_eval)"
   ```
2. Create one severity label per level actually used above:
   ```
   gh label create "severity: critical" --repo itchyshin/drmTMB --color B60205
   gh label create "severity: major"    --repo itchyshin/drmTMB --color D93F0B
   gh label create "severity: moderate" --repo itchyshin/drmTMB --color FBCA04
   gh label create "severity: minor"    --repo itchyshin/drmTMB --color 0E8A16
   ```
3. For each **standalone draft** (every row above except S2, which is comment-only, and Mi-bundle's
   anova sub-item, which is comment-only against #1240), post in ID order:
   ```
   gh issue create --repo itchyshin/drmTMB \
     --title "<TITLE from the draft's first header line>" \
     --body-file <(tail -n +4 <draft path>) \
     --label audit-dinnage \
     --label <bug|documentation|enhancement, from the draft's LABELS line> \
     --label "severity: <sev, from the draft's LABELS line>"
   ```
   `tail -n +4` drops the `TITLE:` line, the `LABELS:` line, and the `---` separator, so only the
   attribution header and body sections are posted.
   Recommend posting in this order: **wave 1** (C1, M1, Md-A, Md-D, Md-E, Md-N, Md-M, Mi-9) first, then
   **wave 2** (M2, M3, M4, S1, S3, S4, S5, S6), holding **S2** and **S6's design-note half** for the D-252
   decision gate (#1301), then **later** (everything else) in ID order.
4. For each **comment file** (`S2.comment.md`, `anova-note.comment.md`), post onto the named existing
   issue:
   ```
   gh issue comment 1301 --repo itchyshin/drmTMB --body-file S2.comment.md
   gh issue comment 1240 --repo itchyshin/drmTMB --body-file anova-note.comment.md
   ```

## Filed issues (posted 2026-09-13, Shinichi-authorised batch)

Every finding below is now a GitHub issue carrying the `audit-dinnage` label, a `severity:` label,
and the attribution header naming Russell Dinnage and the report row. Two findings went to existing
issues as comments instead: S2 → #1301 (repeatability scale, D-252) and the `anova.drmTMB()` papercut → #1240.

| ID | Issue |
|---|---|
| C1 | [#1306](https://github.com/itchyshin/drmTMB/issues/1306) |
| M1 | [#1307](https://github.com/itchyshin/drmTMB/issues/1307) |
| M2 | [#1308](https://github.com/itchyshin/drmTMB/issues/1308) |
| M3 | [#1309](https://github.com/itchyshin/drmTMB/issues/1309) |
| M4 | [#1310](https://github.com/itchyshin/drmTMB/issues/1310) |
| S1 | [#1311](https://github.com/itchyshin/drmTMB/issues/1311) |
| S3 | [#1312](https://github.com/itchyshin/drmTMB/issues/1312) |
| S4 | [#1313](https://github.com/itchyshin/drmTMB/issues/1313) |
| S5 | [#1314](https://github.com/itchyshin/drmTMB/issues/1314) |
| S6 | [#1315](https://github.com/itchyshin/drmTMB/issues/1315) |
| S7 | [#1316](https://github.com/itchyshin/drmTMB/issues/1316) |
| S8 | [#1317](https://github.com/itchyshin/drmTMB/issues/1317) |
| Md-A | [#1318](https://github.com/itchyshin/drmTMB/issues/1318) |
| Md-B | [#1319](https://github.com/itchyshin/drmTMB/issues/1319) |
| Md-C | [#1320](https://github.com/itchyshin/drmTMB/issues/1320) |
| Md-D | [#1321](https://github.com/itchyshin/drmTMB/issues/1321) |
| Md-E | [#1322](https://github.com/itchyshin/drmTMB/issues/1322) |
| Md-F | [#1323](https://github.com/itchyshin/drmTMB/issues/1323) |
| Md-G | [#1324](https://github.com/itchyshin/drmTMB/issues/1324) |
| Md-H | [#1325](https://github.com/itchyshin/drmTMB/issues/1325) |
| Md-I | [#1326](https://github.com/itchyshin/drmTMB/issues/1326) |
| Md-J | [#1327](https://github.com/itchyshin/drmTMB/issues/1327) |
| Md-K | [#1328](https://github.com/itchyshin/drmTMB/issues/1328) |
| Md-L | [#1329](https://github.com/itchyshin/drmTMB/issues/1329) |
| Md-M | [#1330](https://github.com/itchyshin/drmTMB/issues/1330) |
| Md-N | [#1331](https://github.com/itchyshin/drmTMB/issues/1331) |
| A-2 | [#1332](https://github.com/itchyshin/drmTMB/issues/1332) |
| A-3 | [#1333](https://github.com/itchyshin/drmTMB/issues/1333) |
| A-4 | [#1334](https://github.com/itchyshin/drmTMB/issues/1334) |
| A-5 | [#1335](https://github.com/itchyshin/drmTMB/issues/1335) |
| A-6 | [#1336](https://github.com/itchyshin/drmTMB/issues/1336) |
| A-7 | [#1337](https://github.com/itchyshin/drmTMB/issues/1337) |
| A-8 | [#1338](https://github.com/itchyshin/drmTMB/issues/1338) |
| Mi-1 | [#1339](https://github.com/itchyshin/drmTMB/issues/1339) |
| Mi-2 | [#1340](https://github.com/itchyshin/drmTMB/issues/1340) |
| Mi-3 | [#1341](https://github.com/itchyshin/drmTMB/issues/1341) |
| Mi-4 | [#1342](https://github.com/itchyshin/drmTMB/issues/1342) |
| Mi-5 | [#1343](https://github.com/itchyshin/drmTMB/issues/1343) |
| Mi-6 | [#1344](https://github.com/itchyshin/drmTMB/issues/1344) |
| Mi-7 | [#1345](https://github.com/itchyshin/drmTMB/issues/1345) |
| Mi-8 | [#1346](https://github.com/itchyshin/drmTMB/issues/1346) |
| Mi-9 | [#1347](https://github.com/itchyshin/drmTMB/issues/1347) |
| Mi-10 | [#1348](https://github.com/itchyshin/drmTMB/issues/1348) |
| Mi-11 | [#1349](https://github.com/itchyshin/drmTMB/issues/1349) |
| Mi-12 | [#1350](https://github.com/itchyshin/drmTMB/issues/1350) |
| Mi-13 | [#1351](https://github.com/itchyshin/drmTMB/issues/1351) |
| Mi-14 | [#1352](https://github.com/itchyshin/drmTMB/issues/1352) |
| Mi-15 | [#1353](https://github.com/itchyshin/drmTMB/issues/1353) |
| Mi-16 | [#1354](https://github.com/itchyshin/drmTMB/issues/1354) |
| Mi-bundle | [#1355](https://github.com/itchyshin/drmTMB/issues/1355) |
| UX-1 | [#1356](https://github.com/itchyshin/drmTMB/issues/1356) |
| UX-2 | [#1357](https://github.com/itchyshin/drmTMB/issues/1357) |
| UX-3 | [#1358](https://github.com/itchyshin/drmTMB/issues/1358) |
| UX-4 | [#1359](https://github.com/itchyshin/drmTMB/issues/1359) |
| UX-5 | [#1360](https://github.com/itchyshin/drmTMB/issues/1360) |
