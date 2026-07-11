# After Task: missing-data non-Gaussian arc — P3 completion, P4b, P5 close-out

## 1. Goal

Complete the **missing-data non-Gaussian arc (P0–P5)** so the first CRAN release
(**0.5.0**, not 1.0) ships full likelihood-based missing-data handling for
non-Gaussian responses, not just Gaussian. Two modes per family: FIML
missing-**response** masking (`response = "include"`) and missing-**predictor**
`mi()` modelling (`predictor = "model"` + `impute`). This session (continued
after context compaction) finished the arc: **P3** for a `beta()` response,
**P4b** capability-matrix docs, and **P5** close-out. Branch:
`drmtmb/missing-data-nongaussian`.

## 2. Implemented

Whole-arc summary (earlier slices landed in prior sessions; this session added
beta-P3, P4b, and this close-out):

- **P0 — symbolic-alignment gate** (`docs/design/223-...-symbolic-alignment.md`,
  signed + 3-reviewer sign-off). The masking = marginalisation identity and the
  per-family density/dispersion algebra written before code.
- **P1 — FIML missing-response masking** for `poisson()`, `nbinom2()`,
  `binomial()`, `beta()` (model_types 6/7/18/10): a plain C++ `observed_y` data
  guard around each family's density (never `CondExp`, so the masked-row
  placeholder is never taped).
- **P2 — pluggable response-density leaf** `drm_response_log_density`
  (`src/drm_response_kernels.h`). The Gaussian extraction is a **byte-identical**
  refactor (golden capture on logLik + gradient + objective, `identical()` not
  tolerance).
- **P3 — missing-predictor `mi()` for non-Gaussian responses**: one binary
  (Bernoulli/logit) missing predictor marginalised by an exact 2-point sum inside
  the joint likelihood, for `poisson()` (rewired MD9a through the leaf),
  `binomial()`, `nbinom2()`, and — **this session** — `beta()` (model_type 10).
- **P4a — family-specific guardrails + anti-drift reject test** and the SSOT
  helpers `drm_missing_response_families()` / `drm_missing_predictor_families()`.
- **P4b (this session) — capability matrix** in `vignette("missing-data")` +
  a headline NEWS section.
- **P5 (this session) — full-suite close-out.** The full `test_dir` run surfaced
  **27 pre-existing regressions the arc branch had carried undetected** (green on
  `main`, red on the branch; prior "green" claims were against the `missing`
  filter, not the whole suite). All 27 were diagnosed to root cause, confirmed
  against the `main` baseline, and fixed (see §2b).

**This session's beta-P3 (model_type 10), the keystone remaining slice:**

- **Engine.** Filled leaf `case 10` (beta density in the exact inline
  parameterization: `eps 1e-12` mean nudge, `1e-8` shape floor,
  `phi = exp(-2*log_sigma)`). Inserted the beta `mi()` 2-point sum inside
  `model_type == 10`, placed **before** `mu = plogis(eta)` so the observed-x
  `eta` adjustment flows into the precomputed `mu` vector the beta density loop
  reads (beta differs from nbinom2, which recomputes `mu` from `eta` in-loop).
  Extended the density-loop guard to skip missing-predictor rows.
- **R.** `drm_build_beta_ls_spec()` mi-setup (impute threading; bernoulli /
  response-both / fixed-effect-only gates; impute vars; keep-exclusion; na.pass;
  missing-predictor model build + `mu_col`; `missing_predictor`, `start$beta_mi`,
  `MD-beta-mi` metadata, `nobs`). `drm_finalize_missing_data()` beta branch
  (`dbeta` with the same nudge/floor/phi). `split_tmb_parameters()` registers
  `beta_mi` for the beta model_type. `beta` added to the predictor-families SSOT.
- **Tests / drift.** New `test-missing-predictor-beta-response.R` (FIML
  manual-loglik identity + recovery of mean, dispersion `phi`, predictor model).
  `predictor_validated += "beta"`.

## 2b. Full-suite regressions the arc had carried (P5 discovery + fix)

The whole-suite run (36k+ assertions) surfaced **27 failures in 4 files**, all
**pre-existing arc regressions** (verified GREEN on `main`, RED on the branch —
so introduced by prior-session arc commits, not this session). Baseline was
established forensically without recompiling (text/line and Python-guard checks
against `main` and against `9e371c1a`, the commit before this session).

- **Empty-complete-case message drift (2 failing tests; 3 builders fixed).**
  `test-{beta,nbinom2}-location-scale.R` assert that an all-`NA` response with
  default (complete-case) missingness aborts with "No complete observations
  remain…". P1 added the `observed_y` machinery to the `beta`/`nbinom2`/`binomial`
  builders but omitted the `if (length(y) == 0L)` guard that `poisson` and the
  Gaussian-family builders have, so the empty data-frame fell through to the
  `!any(observed_y)` guard with a different message ("At least one observed …
  response is required"). Fix: added the standard guard to all three builders
  (`binomial` had the same latent bug with no test asserting it — fixed for
  consistency per the Rose principle). Masking is unaffected (the guard fires
  only when zero rows survive complete-case; masked rows are kept).
- **Conformance-TSV line-citation drift (6 rows).**
  `test-estimator-surface-conformance.R` verifies each `evidence` `file:line`
  citation still contains its `detail` string (±3/+6 window). The arc's cumulative
  line additions (P1/P4a gates before line ~2000; this session's beta builder +
  guards after ~4500) drifted 6 REML-gate citations out of window. Fix: recomputed
  the current line of each cited detail string and updated the TSV
  (`docs/dev-log/dashboard/estimator-surface-conformance.tsv`) — exactly what the
  test's failure message instructs.
- **Q-Series v1 claim-guard false positive (≈19 assertions in one block).**
  `tools/qseries_v1_claim_guard.py` flags any line where "Q-Series" co-occurs with
  "complete"/"REML"/… The arc's 0.5.0-retarget NEWS preamble (absent on `main`)
  said `"v1.0" denotes the later complete-capability milestone` — a *disclaimer*
  that tripped the crude `Q-Series.*complete` regex. Fix: reworded to `"v1.0" is
  reserved for the later maturity milestone`, preserving the honest meaning; both
  the claim guard and `qseries_v1_release_check.py` now exit 0.

## 3a. Decisions and Rejected Alternatives

- **Ship the full arc in 0.5.0, autonomously to P5.** (Maintainer, this session:
  "let's go full … finish all the way to p five.") Rejected: staged release.
- **P3 approach A** — thin per-family 2-point-sum blocks calling the shared leaf,
  incremental and verifiable. (Maintainer.) Rejected: approach B (full shared-loop
  extraction across families) as higher-risk for one release.
- **beta `mi()` block placed before `mu = plogis(eta)`.** Necessary because the
  beta density loop consumes a precomputed `mu` vector; placing the adjustment
  after it (the nbinom2 position) would drop the observed-x correction. (Agent
  decision, verified by the FIML identity test.)
- **Fixed a pre-existing drift-test mismatch rather than leave it.** The
  predictor-axis regexp `"Missing-predictor models are currently validated only"`
  never matched the current message (which gained `` `mi()` `` formatting in the
  SSOT refactor); repointed to the stable `"models are currently validated only"`
  anchor and repointed the stale non-validated impute-reject loop to
  gamma/tweedie/lognormal (beta/nbinom2/binomial are now validated). Rose
  principle: the same staleness surfaced when nbinom2/binomial were validated.
- **NEWS section under the 0.4.0 dev line, not a new 0.5.0 heading.** The 0.4.0
  entry is explicitly "the development line toward … 0.5.0"; the version bump +
  release heading is a maintainer release-cut decision (see Known Residuals).
- **Fix the 27 pre-existing regressions rather than only flag them.** They are
  arc-introduced (green on `main`), directly caused by the missing-data code
  changes (P1 message drift, line-shift drift, the NEWS preamble), and the fixes
  are mechanical and low-risk. A red full suite is not a finished arc. Rejected:
  hand them to the maintainer as a residual — that would ship a knowingly-red
  branch. The claim-guard reword was checked to preserve, not weaken, the honest
  v1.0 disclaimer (not "gaming" the governance gate).

## 4. Files Touched (this session)

- Engine: `src/drm_response_kernels.h` (leaf `case 10`), `src/drmTMB.cpp`
  (`model_type == 10` mi block + guard).
- R: `R/drmTMB.R` (beta builder mi-setup, dispatch, `split_tmb_parameters`, gate
  messages), `R/missing-data.R` (`drm_finalize_missing_data` beta branch,
  predictor-families SSOT).
- Tests: `tests/testthat/test-missing-predictor-beta-response.R` (new),
  `tests/testthat/test-missing-data-capability-gate.R` (drift locks).
- Docs: `vignettes/missing-data.Rmd` (capability matrix + honest prose + two new
  worked examples), `NEWS.md` (missing-data arc section + preamble reword).
- P5 regression fixes: `R/drmTMB.R` (empty-data guard in the beta/nbinom2/binomial
  builders), `docs/dev-log/dashboard/estimator-surface-conformance.tsv` (6 citations).
- This report.

## 5. Checks Run

- **beta-P3 5-point gate.** (1) `load_all` compiles clean. (2) Slice tests green
  (beta predictor: FIML identity + recovery). (3) Neighbour regressions green
  (nbinom2/binomial predictor, all response masks). (4) **Byte-identical**: the
  two `drmTMB.cpp` hunks are confined to `model_type == 10`, and the guard reduces
  to the original `observed_y(i)==1` when `has_mi==0`, so every other family's
  kernel is literally unchanged and a plain beta fit is byte-identical. (5)
  **Recovery** at n=4000: `mu` (0.43, 0.48, 0.67 vs 0.4/0.5/0.7), `sigma`
  (−1.05 vs −1.04), `mi_x` (0.32, 0.78 vs 0.3/0.8).
- **Missing-data suite** (`filter="missing"`): **626 pass / 0 fail** (2
  pre-existing beta-binomial optimizer warnings; 2 Julia skips).
- **Full package suite** (`test_dir`): **36439 pass / 0 fail** (12 pre-existing optimizer warnings, 98 CRAN/Julia skips).
- **Vignette chunks**: the two new `missing-data.Rmd` fits (nbinom2 + beta binary
  predictor) execute cleanly.

## 6. Tests of the Tests

- The FIML manual-loglik oracle recomputes the beta 2-point sum independently in
  R (`dbeta` with the exact C++ nudge/floor/phi) and equals the fitted `logLik`
  to `1e-6` — a test that would fail if the engine and the documented density
  diverged.
- The capability-gate test asserts observed **behaviour** (does the fit reject?),
  not the gate's own allow-list constant, so loosening the gate without the
  implementation (or vice versa) breaks it. Positive controls confirm the gate
  does not over-reject validated families.
- Recovery tolerances (0.15) are wide enough for n=3000–4000 sampling noise and
  tight enough to catch a wrong parameterization (e.g. the reciprocal-size or
  precision trap would blow past them).

## 7a. Issue Ledger

- No GitHub issue drives this arc; it is the planned missing-data ultra-plan
  (`~/.claude/plans/crystalline-tinkering-fog.md`). No issues opened or closed.

## 8. Consistency Audit

- **Symbolic ↔ R ↔ TMB**: the beta density is written once in the design gate,
  once inline in `model_type == 10`, once in leaf `case 10`, and once in the R
  finalize/manual-loglik — all four use the same nudge (1e-12), floor (1e-8), and
  `phi = exp(-2*log_sigma)`. Verified equal by the FIML identity test.
- **SSOT ↔ gate ↔ test ↔ vignette**: `drm_missing_predictor_families()` now lists
  `beta`; the two capability gates read the SSOT; the drift test's
  `predictor_validated` matches; the vignette capability matrix matches.
- **Messages**: refreshed the predictor + impute gate enumerations (they omitted
  nbinom2 and now beta) so error text matches actual capability.

## 9. What Did Not Go Smoothly

- The predictor-axis drift regexp was silently stale (message gained `` `mi()` ``
  formatting in an earlier refactor without a test update). It only surfaced when
  beta moved into `predictor_validated`. Fixed with a stable anchor; the lesson is
  that regexps keyed on decorated text rot — anchor on the invariant clause.
- The "non-validated impute-reject" test listed beta/nbinom2/binomial, all now
  validated — a stale-rejection trap the P3 handoff had explicitly flagged.
  Repointed to families that remain non-validated.
- **The arc branch was carrying 27 full-suite failures undetected.** Prior slices
  were verified against the `missing` filter, not the whole suite, so P1's
  message-drift and the conformance/claim-guard drift accumulated silently across
  several commits. This is the same class of gap as the P4a broken-HEAD incident:
  a narrow verification scope hid a real regression. The P5 full-suite gate is
  exactly what caught it; the lesson is to run the whole suite (not a filter) at
  each arc close-out, and ideally once mid-arc.

## 10. Known Residuals

- **Release cut (maintainer).** NEWS documents the arc under the 0.4.0 dev line.
  The heading rename to `# drmTMB 0.5.0` and the `DESCRIPTION` `Version: 0.5.0`
  bump are deliberately **not** applied here — they are the maintainer's
  release-cut action, alongside push / PR / merge / tag (all maintainer-gated).
- **Scope of non-Gaussian `mi()`.** One **binary** (Bernoulli/logit) missing
  predictor per non-Gaussian response. The broad predictor-family catalogue
  (ordinal, categorical, count, beta, positive-continuous predictors) remains
  Gaussian-response-only. Zero inflation, random effects, and structured response
  terms with `mi()` are still rejected for these routes.
- **`R CMD check --as-cran` not re-run this session** (the full `test_dir` suite
  was the honesty check). Recommended before the release cut; the previous arc
  left it at 0E/0W/0N.
- **GAMLSS #747/#748** (per-family `{d,p,q}` object) is a separate workstream
  (scout note `d3e4fa3b` sits on this branch) — not part of this arc.

## 11. Team Learning

- **Byte-identity is best proven structurally, not just by tests.** Confining
  every kernel change to one `model_type` block and showing the guard degenerates
  to the original when the feature is off is a stronger guarantee than a golden
  file, and free to re-verify via `git diff`.
- **Per-family density must be written exactly once conceptually.** The beta
  boundary nudge + shape floor had to be replicated verbatim in four places; a
  single divergence would have been invisible except to the FIML identity test.
  The identity test is the safety net that makes the replication safe.
- **Drift tests keyed on decorated message text rot silently.** Anchor
  behavioural regexps on the stable clause, not on formatting that a later
  cosmetic edit will change.

## 12. Cross-Product Coverage

- **Response × mode.** Missing-response masking now: gaussian, biv-gaussian,
  binomial, poisson, nbinom2, beta. Missing-predictor `mi()` now: gaussian (broad
  catalogue), poisson, binomial, nbinom2, beta (binary predictor). Every family
  outside these is asserted to reject by the anti-drift test.
- **Predictor family × response family.** The binary-predictor route is now
  exercised on 5 response families (gaussian + 4 non-Gaussian); the broad
  predictor catalogue remains on the Gaussian response, unchanged.
- **The arc does NOT cover:** non-binary missing predictors on non-Gaussian
  responses; multiple missing predictors; `mi()` with RE/structured/zero-inflated
  response terms; boundary (0/1) beta responses with `mi()`; the broad predictor
  catalogue on non-Gaussian responses; EM/profile/REML missing-data engines. It
  also does NOT cover `--as-cran` (only the `devtools::test_dir` suite was run;
  see §10).
