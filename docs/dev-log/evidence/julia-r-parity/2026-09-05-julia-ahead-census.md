# Julia-ahead census (2026-09-05)

Every capability `DRM.jl` fits natively that `drmTMB` does not, at the two
repos' `origin/main` on the date above: `drmTMB` `802522384` (`0.7.0`),
`DRM.jl` `d3efbad2f` (real GitHub `main`, verified with
`gh api repos/itchyshin/DRM.jl/commits/main`; a stale local Dropbox clone read
`f477896`, five commits behind, and is not used anywhere below).

This is a docs-only reconciliation per D-204: user-facing gaps get a port
recommendation in both directions' vocabulary; engine-internal gaps get a
written boundary sentence the matrix can carry as-is, no code change implied.

## Method and inputs

1. `docs/design/capability-status.md` from both repos (the model-level,
   43/48-row projection) — row-by-row status diff.
2. `tools/parity_ledger.py` (DRM.jl) run live against drmTMB `origin/main`
   (`python3 tools/parity_ledger.py --drmtmb <drmTMB clone> --ref origin/main`)
   — the raw exported-symbol diff, both directions.
3. The parity plan's own scout numbers
   (`docs/dev-log/loop/parity-joint-20260905/ultra-plan.md:36,55`).
4. DRM.jl `#563` (programme umbrella issue — read; it is a checklist of S-item
   *labels*, not a capability list, so no per-row evidence comes from it
   beyond what the capability-status.md prose already cites against `#563 S8`).
5. Today's bivariate census, PR #1192
   (`docs/dev-log/evidence/julia-r-parity/2026-09-05-bivariate-cells-census.md`)
   — its "Julia-native but R-refused" list is **cited, not re-derived**, per
   instruction.
6. Direct source reads in both repos to check two rows the capability-status
   files disagreed on with drmTMB, below (`R/drmTMB.R`,
   `tests/testthat/test-tweedie-location-scale.R`).

## Headline count

- `docs/design/capability-status.md` matches 43 rows by name, byte-for-byte
  (drmTMB's own row-match audit at the bottom of its file, re-verified
  above — still 43/43, 0 near-misses).
- Of those 43, **11 are genuine Julia-ahead gaps** (DRM.jl's status word
  ranks strictly above drmTMB's for the same named row).
- Live `DRM.jl` `origin/main` carries **48** capability-status rows, not
  drmTMB's recorded 46 (drmTMB's own row-count audit, dated 2026-09-01, is
  now stale — the plan already flagged this at
  `ultra-plan.md:55`, itself citing "46/3" where the true count that day was
  "47/4"; live today it is **48/5**). Of the 5 DRM.jl-only rows, **2 are
  drmTMB documentation gaps, not code gaps** — verified against live R source
  and a passing R test below — and the other 3 are engine-internal (one of
  which DRM.jl itself has already rejected).
- The raw export-symbol diff (`tools/parity_ledger.py`) finds 31 DRM.jl
  exports with no drmTMB twin; 29 are accounted for elsewhere in this census
  or are pure engine plumbing; **2 are a genuinely new user-facing capability
  with no row in either capability-status.md file at all**
  (`fit_coevolution*`, `bias_correct`).
- PR #1192 adds 2 more Julia-ahead bivariate cells (cited, not re-counted
  here): `biv_lognormal` + any structured marker (q2/q4, ML), and
  `biv_gaussian` + `relmat`/`animal`/`spatial` at q4 mean+scale (ML,
  UNMEASURED on the R side).

**Total enumerated Julia-ahead items in this census: 11 (Table A) + 2
genuinely-ahead-but-engine-internal-or-dead-end (Table B) + 2 new
user-facing (Table C) + 2 bivariate cells (cited from #1192) = 17 rows**,
against 2 drmTMB documentation gaps that are corrections, not ports (Table
B'), and a further ~29 raw export names that are already accounted for
(`sd`/`sd_phylo`, the `mi()` joint-fit family, engine plumbing — Table D).

---

## Table A — Matched capability-status.md rows: DRM.jl status ahead of drmTMB

All 11 rows below are **already fully evidenced and cited** inside
drmTMB's own `docs/design/capability-status.md` (the prose immediately under
each table names the exact `cells.tsv` rows and evidence tiers). This table
adds the DRM.jl-side citation and the classification/port call; it does not
re-litigate drmTMB's own evidence.

| # | Capability | drmTMB status (file:line) | DRM.jl status + evidence (file:line) | Class | Port size |
|---|---|---|---|---|---|
| A1 | Gaussian phylogenetic random intercept (mean) | scope-limited (`docs/design/capability-status.md:70`, mixed with `rejected` for student/binomial) | implemented — `src/sparse_laplace_glmm.jl`, `src/DRM.jl:*` export | USER-FACING | M — student/binomial families need the sparse-Laplace phylo path in `src/drmTMB.cpp` (currently only nbinom2/poisson/gamma/beta reach `has_phylo_mu`) |
| A2 | Non-Gaussian phylogenetic random intercept (mean) | scope-limited (`docs/design/capability-status.md:78`) | implemented for Poisson/NB2/Gamma/Binomial/Beta via `src/sparse_laplace_glmm.jl` (DRM.jl `docs/design/capability-status.md:78-83`) | USER-FACING | M — same family gap as A1, one shared TMB branch |
| A3 | Non-Gaussian phylogenetic location-scale (μ + log σ) | scope-limited (`docs/design/capability-status.md:79-83`, implemented only for nbinom2/zero_one_beta) | implemented (`closes #202`) via `src/locscale_*.jl`, NB2 recovery + Gamma smoke (DRM.jl file, "Non-Gaussian phylogenetic location-scale" section) | USER-FACING | L — per-family coupled `(1|p|species)` on mean+scale; drmTMB's own text records "no `nbinom2-locscale` R fixture in this closeout" even on the Julia side, so this is genuinely open work, not just a doc gap |
| A4 | REML (Gaussian fixed-effect location-scale) | point-fit-recovery (`docs/design/capability-status.md:96`) | implemented (evidence tier reaches full `implemented`, not just recovery) | USER-FACING (evidence tier, not new code) | S — this is a coverage-campaign gap, not an unimplemented route: `mc-0261`/`mc-0263` already fit and recover; the port is a same-target interval/coverage receipt, not a TMB change |
| A5 | REML with ordinary random effects (Gaussian mean) | point-fit-recovery (`docs/design/capability-status.md:97`) | implemented (DRM.jl `#439`, in default suite) | USER-FACING (evidence tier) | S — same shape as A4 |
| A6 | REML bivariate phylogenetic location-scale (q4, all axes) | scope-limited (`docs/design/capability-status.md:98`, mixed tiers across mu1/mu2/sigma1/sigma2) | implemented — `src/reml_q4.jl`, `test/test_reml_q4_allaxes.jl` asserts all 4 axes together | USER-FACING | M — the missing piece is specifically getting the `sigma1`/`sigma2` phylo REML cells from `point_fit_recovery` to `interval_feasible`, matching what `mu1`/`mu2` already have |
| A7 | AGHQ adaptive-quadrature marginal estimator | planned (`docs/design/capability-status.md:104`) | implemented (DRM.jl `#449`/`93c3db6b`), Poisson `(1\|g)` only | USER-FACING | M — Poisson-only AGHQ front end; TMB's own quadrature machinery (`RTMB`/manual GHQ over the random effect) would need a new estimator path parallel to the existing Laplace default |
| A8 | Chi-bar-square boundary LRT p-value | planned (`docs/design/capability-status.md:105`) | implemented — `src/chibar.jl`, exports `chibar_pvalue`/`lrt_boundary` | USER-FACING | S — drmTMB's `profile.R` already flags `conf.status = "wald_at_boundary"` (Self & Liang 1987 / Stram & Lee 1994 cited in the same file); the p-value front end is new R-side glue over an existing internal signal, no `.cpp` change |
| A9 | Model comparison suite (LRT/anova/AICc/weights/update) | planned (`docs/design/capability-status.md:106`) | implemented — named S3-style generics, all exported | USER-FACING | M — pure R-side (`anova.drmTMB`, `AICc.drmTMB`, `update.drmTMB`); DRM.jl's own file warns the `weights` member is a false-parity trap (StatsAPI prior weights, not Akaike weights) — see Table D-2, do not port that member as "model weights" |
| A10 | Heritability/repeatability/ICC accessors | point-fit-recovery (`docs/design/capability-status.md:107`) | implemented (fuller coverage evidence) | USER-FACING (evidence tier) | S — R already has `heritability()`/`icc()`/`repeatability()` (`R/heritability.R`); this is a coverage-campaign gap like A4/A5, not a missing route |
| A11 | Bivariate structured random effect on all four axes (q4 PLSM) | point-fit-recovery (`docs/design/capability-status.md:114`) | implemented — `src/sparse_phy.jl`, `src/takahashi_selinv.jl`, `src/sparse_aug_plsm.jl` | USER-FACING (evidence tier) | M/L — same coverage-campaign shape as A4/A5/A10, but across 4 structure providers (phylo/spatial/animal/relmat) x 4 axes |

Two matched rows go the other way (drmTMB ahead of DRM.jl) and are excluded
from this census by definition: `Missing-response handling` (R
`implemented`, DRM.jl `missing` — DRM.jl's own file calls FIML for missing
responses explicitly out of scope, `#49` parked) and `Missing-predictor
imputation (mi())` (R `implemented`, DRM.jl `experimental`, fenced by
D-181/D-209). One matched row is a tie at the bottom: `Cross-family
bivariate` is `planned` in R and `missing` in DRM.jl — parked permanently on
both sides (D-179 `#3`).

---

## Table B — DRM.jl-only capability-status.md rows: verified, not what they look like

drmTMB's file records only 3 DRM.jl-only rows (its 2026-09-01 row-match
audit, `docs/design/capability-status.md:180-190`) and calls them "Julia-side
algorithm choices ... no natural R counterpart." Live `DRM.jl` `origin/main`
now has **5** rows with no drmTMB name-match, not 3 — two new ones need
checking on their own terms rather than assumed to be more of the same kind.
Both turned out to be **documentation gaps in drmTMB's own file, not code
gaps**:

| Row (DRM.jl-only) | DRM.jl status | Verification | Verdict |
|---|---|---|---|
| `Tweedie random intercept (mean)` | implemented (`#563 S8`) | **drmTMB already fits this natively.** `tests/testthat/test-tweedie-location-scale.R:456` — `test_that("tweedie mu supports an ordinary random intercept", ...)` calls `drmTMB(bf(y ~ x + (1 \| id), nu ~ 1), family = tweedie(), data = sim$data)` and asserts convergence, recovered SD and recovered fixed effects. `R/drmTMB.R:11640-11662` (`validate_tweedie_mu_random_terms`) explicitly permits independent intercepts/slopes on `mu` (only labelled-covariance / correlated slopes are refused). | **Not Julia-ahead.** drmTMB's `docs/design/capability-status.md` Random-effect-structure table is simply missing this row. Add it, status `implemented`, citing the test above. |
| `Gaussian phylogenetic random intercept + slope, two SDs (mean)` | implemented (`#620`) | **drmTMB already fits this natively for Gaussian.** `R/drmTMB.R:20063-20067` sets `has_phylo_mu_q2_covariance` to 1 **only** when `spec$model_type %in% c("nbinom2", "poisson")` — for every other family, including Gaussian, `phylo(1 + x \| species, tree = tree)` (`R/drmTMB.R:10819`) always fits the **independent** two-SD model (`has_phylo_mu_q2_covariance = 0`), which is exactly the model DRM.jl's own file says it replicates ("the same five free parameters drmTMB optimizes", DRM.jl `docs/design/capability-status.md`, `#620` prose). | **Not Julia-ahead** for Gaussian. drmTMB's own file is missing this row too. Add it, status `implemented`, citing `R/drmTMB.R:20063-20067` and `R/drmTMB.R:10819`. (drmTMB's separate written boundary about Poisson/NegBinomial2 fitting a *correlated* model under the same formula — `has_phylo_mu_q2_covariance = 1` — is a genuinely different, already-known asymmetry, not part of this row.) |

Port recommendation for both: **S, docs-only** — add the two rows to
drmTMB's `docs/design/capability-status.md` Random-effect-structure table
(status `implemented`, citations as above). No TMB or R code changes; the
capability already exists. This is a correction to carry back into the
matrix, not a build item.

The remaining 3 DRM.jl-only rows are genuinely engine-internal, matching
drmTMB's original characterization:

- **`Conjugate-EM Gaussian phylo-mean (algorithm = :em)`** — ENGINE-INTERNAL.
  An alternative block-coordinate optimizer for a route (`q4`/phylo-mean
  Gaussian) TMB already reaches by its own AD-gradient Newton solve. No
  distinct model or output for a user to ask for; boundary sentence: *"DRM.jl
  offers a second optimization algorithm for a model drmTMB already fits by
  a different (TMB-native) route; the fitted model and its outputs are
  identical, only the numerical path differs."*
- **`Natural-gradient EM (algorithm = :natgrad)`** — ENGINE-INTERNAL, and DRM.jl
  itself has rejected it (`docs/design/capability-status.md`, DRM.jl file:
  "stalls at logLik ~ -259.80 ... vs ... -256.51", 2026-08-01 decision gate).
  Boundary sentence: *"A DRM.jl-internal optimizer experiment that DRM.jl's
  own measured evidence rejected as inferior; nothing to port."*
- **`Fisher / observed-info metric (lc_metric)`** — ENGINE-INTERNAL. Per
  DRM.jl's own file: "infrastructure for AI-REML / `#11`/`#165`, **not** a
  public solver." Boundary sentence: *"An alternative curvature metric used
  internally by DRM.jl's own in-progress REML research; TMB already exposes
  its own observed/expected information machinery for the models drmTMB
  fits, so there is no user-facing gap this closes."*

---

## Table C — New user-facing capabilities with no capability-status.md row at all

Found via the raw export diff (`tools/parity_ledger.py`, "DRM.jl EXPORTS WITH
NO drmTMB TWIN" section, run live 2026-09-05 against drmTMB `802522384`):
31 raw names, of which 29 are either already accounted for under an existing
capability-status.md row (the `mi()` joint-fit family: `JointDrmFit`,
`JointTwoDrmFit`, `JointFiniteDrmFit`, `JointImputeModel`,
`JointMissingControl`, `CategoricalLogit`, `prepared_joint_*`,
`PreparedJointFit`/`PreparedJointModel`/`PreparedFiniteJointFit`/`PreparedFiniteJointModel`
— all under the existing `Missing-predictor imputation (mi())` row, D-181/
D-209 fenced) or pure engine plumbing (`bootstrap_ci`/`bootstrap_result`/
`bootstrap_sigma_a`/`profile_sigma_a`/`cutpoints`/`sd`/`sd_phylo` — see Table
D) — and 2 are a genuinely new, un-censused capability:

| Capability | What it is | DRM.jl evidence | drmTMB status | Class | Port size, files, receipt |
|---|---|---|---|---|---|
| General-*q* multivariate-Brownian coevolution on a tree | `bf`-free API: fit a *q*-trait (q >= 2, tested to q=6/q=8) Brownian-motion coevolution model on a phylogeny, sharing one *q*x*q* among-trait covariance Lambda, with diagonal residual variance per trait. Generalizes the verified *q*=4 bivariate location-scale PLSM to arbitrary trait count. | `src/coevolution_q.jl:1-30` (design doc header, explicitly states "generalises to arbitrary q"); exports `fit_coevolution`, `fit_coevolution_q2_residual`, `fit_coevolution_q2_reml` (`src/DRM.jl:160`); tests `test/test_coevo_q6.jl`, `test/test_coevo_accessors.jl`, `test/test_bootstrap_sigma_a.jl`, plus `#188` (issue cited in the module header) | **absent** — drmTMB's `Bivariate structured random effect on all four axes (q4 PLSM)` row is fixed at exactly 2 traits (`biv_gaussian`, `mu1`/`mu2`/`sigma1`/`sigma2`); there is no *q* > 2 trait row anywhere in `docs/design/capability-status.md` or `cells.tsv` | USER-FACING — a phylogenetic comparative biologist asking "does N traits coevolve together across this tree" is exactly the census's target reader; this is not a q4-PLSM rename, it drops the location-scale (mu+logsigma pairing) structure for a flat q-trait Brownian model | **L**. Files touched: `src/drmTMB.cpp` (a new model branch — the existing `model_type == 1`/`q4` sparse-augmented-state machinery in `src/drmTMB.cpp` around `has_phylo_mu_q2_covariance` is q=4-specific and would need generalizing to a `q`-parametrized log-Cholesky block, not a small patch); `R/drmTMB.R` (new formula grammar — drmTMB has no `cbind(y1,...,yq) ~` q>2 front end at all); `R/coevolution-accessors.R` exists already but is scoped to q=4 output shapes and would need a general-q rewrite. Receipt: same-target fit against DRM.jl `test/test_coevo_q6.jl`'s fixture (q=6 traits) — recovered Lambda entries and beta within FD tolerance, mirroring how A6/A11 above cite same-target checks. |
| Generalized-delta (epsilon-method) bias correction for arbitrary derived quantities | `bias_correct(fit, g)`: for ANY smooth scalar function `g` of the fitted parameters (a back-transformed mean, a correlation, a variance), computes the TMB-`sdreport(bias.correct=TRUE)`-style second-order correction `g(theta_hat) + 1/2 tr(H_g * V)` and a delta-method SE, using `ForwardDiff` for exact gradient+Hessian of the user's own `g`. This is Thorson & Kristensen (2016, *Fisheries Research* 175:66-74)'s epsilon method, applied generically. | `src/bias_correct.jl:1-40` (full derivation + scope caveats in the file header, explicitly named after the TMB feature); `test/test_bias_correct.jl`; exported at `src/DRM.jl` | **Named but not this.** drmTMB has its own `bias_correct` (`R/profile.R:137,423,2106` — a `match.arg`-style `c("location","none","group")` small-sample point-estimate shift for structured-RE variance-component bootstrap CIs, `docs/design/219-structured-re-small-sample-bias-correction.md`). Same word, unrelated mechanism and scope: R's version is bootstrap-only and variance-component-specific; DRM.jl's is AD-exact, works on any user-supplied `g`, and needs no bootstrap. **Naming collision — flag this explicitly so nobody reads "R has `bias_correct` too" as parity.** | USER-FACING — TMB users specifically ask for `sdreport(..., bias.correct = TRUE)` on arbitrary derived quantities; drmTMB currently has no generic answer, only the narrow bootstrap-shift version. | **M**. TMB already computes the Hessian and covariance `drmTMB` needs (`fit$sdr`); a generic epsilon-method wrapper is closer to R-side glue over `TMB::sdreport`'s existing AD machinery (which TMB itself supports for arbitrary `ADreport`-registered quantities) than new `.cpp` work — `R/methods.R` or a new `R/bias-correct-generic.R`. Receipt: same-target vs DRM.jl `test/test_bias_correct.jl`'s fixture — point estimate and SE for a chosen derived quantity (e.g. `exp(mu)` or a variance ratio) within FD tolerance. **Recommend renaming the R front end** (e.g. `bias_correct_generic()` or extending the existing argument) rather than overloading `bias_correct` a second time. |

---

## Table D — Accounted for, not ports (raw export names, for completeness)

Named because the export diff surfaces them, resolved without a code
recommendation:

- **D-1. `sd`, `sd_phylo`** — false positive of the raw-symbol diff. These are
  DRM.jl's formula-grammar markers for the "location-scale-scale" capability
  (`sd(group) ~ z`, heteroscedastic random-effect SD; `sd_phylo(species) ~
  x`, phylogenetic version — `src/gaussian_lss.jl:1-113`). drmTMB already has
  the same capability under different exported-symbol shape: `sd_phylo(...)`
  appears throughout `R/drmTMB.R`, `R/check.R`, `R/control.R`,
  `R/coevolution-accessors.R` as **formula syntax**, not a standalone R
  function export, and `location_scale_scale` is the capability-status.md
  row (`covered` in the bridge ledger, promoted by this branch's own most
  recent commit, `79e8f0951`, "widen Julia REML support for LSS models &
  promote Capability Row 12 to covered"). **Already at parity; the diff tool
  cannot see it because R's grammar is parsed inline, not exported as a
  function named `sd`.**
- **D-2. `weights` member of the Model comparison suite** — see A9 above;
  DRM.jl's own file flags this as a false-parity trap (`StatsAPI.weights`,
  prior weights, not Akaike weights). Not a port target; note it in the
  matrix's own text if/when A9 is ported, so the "weights" member is not
  read as model-averaging weights.
- **D-3. `JointDrmFit`/`JointTwoDrmFit`/`JointFiniteDrmFit`/`JointImputeModel`/
  `JointMissingControl`/`CategoricalLogit`/`prepared_joint_*`/
  `PreparedJointFit`/`PreparedJointModel`/`PreparedFiniteJointFit`/
  `PreparedFiniteJointModel`** — all under the existing `Missing-predictor
  imputation (mi())` capability-status.md row, `experimental` on the DRM.jl
  side, D-181/D-209-fenced for v1.0 on both sides. Not separately Julia-ahead.
- **D-4. `bootstrap_ci`/`bootstrap_result`/`bootstrap_sigma_a`/
  `profile_sigma_a`/`cutpoints`/`drm_bridge_objective_at`/
  `reml_objective_at`** — engine/accessor plumbing already covered by the
  `Parametric bootstrap CIs`/`Profile-likelihood CIs` capability-status.md
  rows (both `implemented` in drmTMB already) or by
  `tools/parity_ledger.py`'s own `DELIBERATELY_NOT_PORTED` entry for
  `objective_at` (`tools/parity_ledger.py:47-51`, citing drmTMB `#1114` and
  DRM.jl `#589`/`#590`). No independent capability.

---

## Bivariate cells (cited from PR #1192, not re-derived)

PR #1192
(`docs/dev-log/evidence/julia-r-parity/2026-09-05-bivariate-cells-census.md`)
already measured and recorded these Julia-ahead bivariate cells; listed here
only so this census's "every Julia-ahead capability" claim is complete, with
no new evidence added:

- **`biv_lognormal` + `phylo`/`relmat`/`animal`/`spatial`, q2 and q4, ML** —
  DRM.jl-native fits every one of these by delegating to its verified
  bivariate Gaussian engine on `log(y)`; drmTMB's `biv_lognormal()` refuses
  every random/structured effect. USER-FACING. Sizing and TMB files are
  PR #1192's call to make (it names this as "the concrete answer to the
  LogNormal half of `#471`"); not re-sized here to avoid contradicting that
  PR's own scope.
- **`biv_gaussian` + `relmat`/`animal`/`spatial` at q4 (mean+scale), ML** —
  DRM.jl-native admits this uniformly; the R side was explicitly left
  **UNMEASURED** by PR #1192 (not asserted as a gap). Not sized here for the
  same reason — this needs the R-side measurement PR #1192 deferred before a
  port size can be assigned.

---

## Ranked: ports worth opening next

Ranked by (a) user-facing pull, (b) how much of the receipt already exists as
evidence-tier work rather than new engine code, (c) size.

1. **A8 — Chi-bar-square boundary LRT p-value (S).** The internal signal
   (`wald_at_boundary`) already exists in `R/profile.R`; this is the
   cheapest real capability close in the whole census.
2. **A4/A5/A10/A11 — REML and heritability/ICC coverage receipts (S/S/S/M-L,
   bundle-able).** All four are "the route already fits and recovers,
   promote the evidence tier" work, not new code — the cheapest *class* of
   port even though A11 alone is larger in scope (4 structure providers x 4
   axes).
3. **A9 — Model comparison suite (M).** Pure R-side glue
   (`anova`/`AICc`/`update` S3 methods); watch the `weights` naming trap
   (D-2) when writing it.
4. **A6 — REML bivariate phylogenetic location-scale, sigma-axis cells (M).**
   Half of this row (mu1/mu2) is already `interval_feasible`; the remaining
   work is specifically the sigma1/sigma2 phylo REML cells.
5. **C-2 — Generic epsilon-method bias correction (M).** R-side wrapper over
   `TMB::sdreport`'s existing AD machinery; needs a naming decision (D-181-style
   fence is not needed here, just a distinct function name from the existing
   `bias_correct` argument) before it is opened as an issue.
6. **A1/A2 — Phylogenetic random intercept for student/binomial (M).** One
   shared TMB branch (`has_phylo_mu` extended to the two currently-`rejected`
   families) closes both rows at once.
7. **A7 — AGHQ, Poisson `(1|g)` only (M).** Scoped exactly as narrow as
   DRM.jl's own version; do not over-scope to other families on the first
   pass.
8. **A3 — Non-Gaussian phylogenetic location-scale, remaining families (L).**
   Even DRM.jl's own closeout admits no `nbinom2-locscale` R fixture exists
   yet on either side; open only after A1/A2 land, since it shares the
   sparse-Laplace phylo machinery.
9. **C-1 — General-*q* coevolution (L).** Real, tested, cited capability, but
   the largest lift in this census: new TMB model branch, new formula
   grammar, and a rewrite of the q=4-shaped accessor file. Sequence after
   the cheaper items above; do not treat q4 PLSM code as a drop-in base — DRM.jl's
   own module header is explicit that this is a *new* general-q file, not a
   parametrization of the existing q4 engine.

## Do-not-port list

- **Natural-gradient EM (`:natgrad`)** — DRM.jl's own measured evidence
  rejected it (Table B). Porting a rejected optimizer serves nobody.
- **Conjugate-EM Gaussian phylo-mean (`:em`)** — engine-internal alternate
  optimizer for a route TMB already reaches; no distinct user-facing output.
- **Fisher / observed-info metric (`lc_metric`)** — DRM.jl's own file calls
  this "not a public solver," internal to its own in-progress REML research.
- **Cross-family bivariate** — parked permanently on both sides (D-179 `#3`);
  neither engine implements it, so it is not a Julia-ahead item at all
  despite showing up as a matched-but-unequal-status row.
- **`mi()` joint-imputation family (all `Joint*`/`Prepared*` exports,
  `CategoricalLogit`)** — real code on the Julia side, but D-181 (reaffirmed
  D-209 §3) fences it out of the v1.0 twin claim on BOTH sides; not owed
  until that fence is explicitly revisited by the same decision process that
  set it.
- **`sd`/`sd_phylo` raw export names** — false positive; already at parity
  (D-1). Do not open a port issue against these names.
- **Missing-response native masked likelihood beyond the q4 engine** — this
  is drmTMB *ahead* of DRM.jl (excluded from this census by definition), and
  DRM.jl's own file states FIML for missing responses is explicitly out of
  scope (`#49` parked). Nothing for drmTMB to chase here.
- **The two Table-B documentation-gap rows as "ports"** — they are correct
  as-is in drmTMB's engine; the only action is adding the two missing rows to
  `docs/design/capability-status.md` (S, docs-only, listed under Table B, not
  repeated here as a build item).

---

## Sources read

- `docs/design/capability-status.md` (drmTMB `origin/main` `802522384`, this
  worktree — a fresh worktree at that ref, not the working checkout).
- `docs/design/capability-status.md` (DRM.jl `origin/main` `d3efbad2f`, fresh
  clone via `git clone https://github.com/itchyshin/DRM.jl.git`, verified
  against `gh api repos/itchyshin/DRM.jl/commits/main`).
- `tools/parity_ledger.py` (DRM.jl), run live:
  `python3 tools/parity_ledger.py --drmtmb <drmTMB worktree> --ref origin/main`.
- `docs/dev-log/loop/parity-joint-20260905/ultra-plan.md:32-70`.
- DRM.jl `#563` (`gh issue view 563 --repo itchyshin/DRM.jl`) — programme
  umbrella, S-item labels only.
- PR #1192 (`gh pr view 1192 --repo itchyshin/drmTMB --json body,files`) —
  cited, not re-derived.
- `src/coevolution_q.jl`, `src/bias_correct.jl`, `src/gaussian_lss.jl`,
  `src/joint_missing_frontend.jl` (DRM.jl) and matching `test/*.jl` files, for
  Table C/D verification.
- `R/drmTMB.R:10819,11640-11662,20063-20067`,
  `tests/testthat/test-tweedie-location-scale.R:456-483`, `R/profile.R:137,
  423,2106`, `R/heritability.R` (drmTMB) for Table A/B verification.

## Not covered by this census

- The Table C-1 (general-*q* coevolution) and Table C-2 (generic bias
  correction) *sizes* are estimates from reading the source, not a scoped
  design doc — a design pass would be needed before either is actually
  opened as a build issue.
- PR #1192's two bivariate cells are cited, not independently re-measured or
  re-sized, per this task's own instruction not to redo that census.
- The 5 "maintenance-only" bridge rows named in the ultra-plan
  (`ultra-plan.md:52`) are `r_bridge_status` axis items (interval status on
  the `engine="julia"` bridge), a different axis from this native-capability
  census; not enumerated here.
- No Julia runtime was invoked for this census (no ledger `CHECK` needed
  a live fit); all claims are file:line source/test citations or `gh`
  command output.
