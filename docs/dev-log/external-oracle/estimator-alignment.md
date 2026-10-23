# Fisher review: is the drmTMB-vs-lme4 sleepstudy profile-CI comparison a valid pairing?

> ## ⚠ PARTIALLY SUPERSEDED — read this first
>
> **The ML-provenance conclusion in Section 1 and in the ML half of the Verdict is
> WITHDRAWN.** It is preserved verbatim below as the record of how the inference
> failed, not as a finding to cite.
>
> This review concluded that `fm1P`/`fm1B` are ML-derived because an ML refit
> reproduced `fm1P` to `4.36e-5` against a REML refit at `5.64e-4`. The audit in
> [`rose-audit.md`](rose-audit.md) refuted that as established: the within-estimator
> noise floor was never measured independently — it was read off the ML-vs-`fm1P`
> residual, which is circular. Varying only the optimizer, a **converged
> REML/`bobyqa`** refit reproduces `fm1P` to **`5.63e-5`, better than two of three
> ML reconstructions**. Within-REML optimizer spread (`5.63e-4`) is the same size
> as the ML-vs-REML separation (`6.08e-4`), so signal-to-noise is about 1.1 and the
> "13x" ratio is an optimizer artifact.
>
> **Current position:** `fm1P`'s estimator is **not recoverable** — it is a bare
> matrix with no estimator metadata and lme4 ships no generating script. The test
> suite does not depend on it: agreement is asserted to within lme4's own
> optimizer-to-optimizer reproducibility for this model, not as a matched-estimator
> proof.
>
> **What in this document still stands:** Evidence #2, the measured REML-vs-REML
> profile-CI gap on three of four targets, is untouched and still underwrites the
> boundary that **no REML interval-parity claim is made**. The tolerance figure
> (`5e-4`) also survives, but note it is now applied as an **absolute** bound via
> `expect_lt()`, not the relative `expect_equal(tolerance = )` this review assumed.

Reviewer: Fisher (`inference_reviewer`). Worktree:
`/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/external-oracle`. `lme4` 2.0.1,
R 4.6 (arm64), `drmTMB` `DESCRIPTION` version `0.7.0` (compiled from this worktree's
`R/`/`src/` for the empirical checks below).

## Question

The measurement under review compares `drmTMB` profile confidence intervals on
`sleepstudy` (`Reaction ~ Days + (Days | Subject)`) against `lme4`'s own shipped
reference matrix `fm1P` in
`file.path(find.package("lme4"), "testdata", "confint_ex.rda")`. `drmTMB`'s point
estimates match `lme4` fit with `REML = FALSE`, but `lme4::lmer`'s default is
`REML = TRUE`. Is `fm1P` ML- or REML-derived, is the comparison a valid same-estimator
pairing, and at what tolerance should such a claim be asserted (if at all)?

## Method

1. **Provenance search.** Listed `lme4`'s shipped `testdata/` for a generating script.
   `lme-tst-fits.R` exists but only builds unrelated objects
   (`fit_sleepstudy_0..3`, `fit_cbpp_*`, `fit_Pix.*`); it does not reference `fm1B`/`fm1P`
   or `confint_ex.rda`. No generating script for `confint_ex.rda` ships with the
   installed package. Two `WebFetch` attempts at plausible GitHub test-file paths
   (`tests/testthat/test-profile.R`, `tests/testthat/test-confint.R`,
   `tests/test-profConfint.R` on the confirmed default branch `master`) all 404'd, and
   unauthenticated GitHub code search is blocked behind sign-in. Provenance is
   therefore settled empirically (below), not by reading the original generating code.
2. **Reconstruction.** Fit `sleepstudy` with `lme4::lmer(Reaction ~ Days + (Days |
   Subject), REML = TRUE)` and `REML = FALSE`, ran `confint(..., method = "profile")`
   on both, and compared against the shipped `fm1P`. Also ran a small
   `confint(..., method = "boot", nsim = 200)` on both as a secondary (weaker, RNG-mismatched)
   check against `fm1B`.
3. **`drmTMB` reproduction.** Compiled this worktree's `drmTMB` (`devtools::load_all`,
   ~83 s cold compile, then ~4-8 s per fit warm) and fit the identical formula with
   `REML = FALSE` and `REML = TRUE`, comparing point estimates, `logLik`, and
   `confint(..., method = "profile")` against both the shipped `fm1P` and my own fresh
   `lme4` reconstructions.
4. **Repo grep** for REML admission rules on ordinary correlated Gaussian random-slope
   blocks (`R/drmTMB.R`, `drm_validate_reml_spec`).
5. **Tolerance convention** read from `tests/testthat/test-comparators.R` and
   `docs/design/242-external-comparator-evidence-class.md`.

All runs were single-process, single-seed, single-dataset, and completed in well under
5 minutes each (profile pair: 27 s; bootstrap pair: 3 s; `drmTMB` compile: 83 s once,
then ~4-8 s per fit).

## Evidence

### 1. `fm1P` is ML-derived, not REML-derived

Reconstructed `confint(fit, method = "profile")`, reordered to `fm1P`'s row order and
diffed against the shipped matrix (`abs(reconstruction - fm1P)`):

| target | max abs diff, REML=TRUE reconstruction | max abs diff, REML=FALSE (ML) reconstruction |
|---|---|---|
| sd (Intercept)\|Subject | 5.643e-4 (upper) | 4.357e-5 (upper) |
| cor Days,(Intercept)\|Subject | 6.82e-8 | 3.48e-7 |
| sd Days\|Subject | 4.13e-6 | 3.21e-6 |
| sigma | 1.19e-8 | 7.53e-7 |
| (Intercept) | 6.42e-8 | 3.62e-8 |
| Days | 2.64e-8 | 2.02e-8 |
| **max over all 6 rows** | **5.643e-4** | **4.357e-5** |

The ML reconstruction is uniformly within 4.4e-5 of the shipped `fm1P` on every row.
The REML reconstruction is ~13x worse at its worst point, and that worst point is
exactly the row (`sd (Intercept)`) where REML and ML estimates genuinely diverge for
this model (REML point estimate 24.7407 vs ML 23.7798 -- see below). This is the
signature of a wrong-estimator reconstruction, not noise: the residual concentrates on
the one parameter with a real REML/ML gap. `isREML()` on both fitted objects confirmed
the two reconstructions used the estimators their names imply.

Point estimates make this unambiguous on their own: `lme4` REML gives
`sd(Intercept) = 24.7407`, `sigma = 25.5918`; `lme4` ML gives `sd(Intercept) = 23.7798`,
`sigma = 25.5919`. The task's own reported `drmTMB` point estimate (23.7805) sits 0.0007
from ML and 0.960 from REML.

**A second, independent confirmation**: I reproduced the exact `drmTMB` profile numbers
quoted in the task by fitting `drmTMB(bf(Reaction ~ Days + (Days | Subject)), data =
sleepstudy, REML = FALSE)` and calling `confint(..., method = "profile")` myself:

| target | quoted in task | my reproduction (`drmTMB`, `REML = FALSE`) |
|---|---|---|
| sd (Intercept) | 14.3814128 - 37.716258 | 14.38141 - 37.716258 |
| sd Days | 3.8011604 - 8.753395 | 3.80116 - 8.753395 |
| sigma | 22.8979555 - 28.858005 | 22.89796 - 28.858005 |
| cor | -0.4814922 - 0.685019 | -0.4814922 - 0.685019 |

Exact match. The `drmTMB` side of the original comparison is confirmed ML (`REML =
FALSE`), the same estimator my reconstruction shows `fm1P` to be.

**Bootstrap spot check (secondary, not decisive).** `confint(method = "boot", nsim =
200, seed = 1)` under REML and ML both land within roughly 0.1-2.5 units of the shipped
`fm1B` across the six targets, with no consistent pattern favoring one estimator over
the other (e.g. REML is closer on `sd(Intercept)` lower bound, ML is closer on
`(Intercept)` lower bound). This is expected: a parametric bootstrap depends on the RNG
stream, which almost certainly differs from whatever generated `fm1B`, so this check
cannot discriminate ML from REML the way the profile reconstruction does. It is
reported for completeness, not as evidence.

### 2. `drmTMB` DOES support REML for this exact model, and its REML point estimates/logLik match `lme4` closely -- but its REML *profile interval* does not, on this one spot check

`R/drmTMB.R:2433-2470` (`drm_validate_reml_spec`) admits ordinary ("q > 2 labelled
covariance blocks are admitted under REML (2026-07-08)") correlated
intercept-plus-slope Gaussian `mu`-side random effects under REML -- exactly
`sleepstudy`'s `(Days | Subject)` shape -- citing a recovery ladder
(`scratchpad/reml_parity_gaps_3A_ladder.R`, `n_id = 60`) showing REML less biased than
ML on every block SD. I fit it directly:

| quantity | `lme4` `REML = TRUE` | `drmTMB` `REML = TRUE` |
|---|---|---|
| sd(Intercept) | 24.7407 | 24.7405 |
| sd(Days) | 5.9221 | 5.9221 |
| cor | 0.0660 | 0.0656 |
| `logLik` | -871.8141 | -871.8141 |

Point estimates and `logLik` agree to the displayed precision. This is the correct
in-package evidence that `drmTMB`'s REML route is implemented for this model shape --
it is not vaporware.

But the **profile interval** is a different story. I ran
`confint(fit_drm_reml, method = "profile")` (`small_sample_df`/`bias_correct` have no
effect on `method = "profile"` -- confirmed empirically identical with `"none"` vs the
default `"location"`, consistent with `R/profile.R:248-250`: "`bias_correct` shifts only
the `method = "wald"` centre and never a profile endpoint") and compared it to a fresh
`lme4::lmer(..., REML = TRUE)` profile (not `fm1P`, which Evidence #1 shows is ML):

| target | `drmTMB` REML profile | `lme4` REML profile (my reconstruction) | abs diff (lower, upper) |
|---|---|---|---|
| sd(Intercept) | 15.032 - 39.516 | 14.381 - 37.717 | 0.650, 1.800 (~5%) |
| sd(Days) | 3.927 - 9.152 | 3.801 - 8.753 | 0.126, 0.399 (~5%) |
| cor | -0.498 - 0.666 | -0.482 - 0.685 | 0.017, 0.019 |
| sigma | 22.898 - 28.858 | 22.898 - 28.858 | ~3e-6, ~8e-6 |

`sigma`'s profile interval is REML/ML-invariant in *both* engines for this dataset (I
also found `lme4`'s own sd(Intercept) profile CI is nearly REML/ML-invariant, differing
by only ~6e-4 between my two `lme4` reconstructions -- a property of this specific
profile-likelihood/dataset combination, present in both engines, and not itself
alarming). But `sd(Intercept)`, `sd(Days)`, and `cor` show a real ~5% gap between
`drmTMB`'s REML profile and `lme4`'s REML profile that is **not** present in the
ML-vs-ML comparison (Evidence #1, sub-1e-4 there). This is a single-dataset,
single-seed spot check, not a campaign, and I have not diagnosed the mechanism (a
plausible candidate: `drmTMB`'s endpoint-search profile engine vs `lme4`'s
grid+spline `zeta` profile engine may not treat the REML nuisance-parameter
re-optimization identically -- this is a hypothesis, not verified). I report it because
it directly bears on what this class of evidence can license (Section below).

## Verdict: ML, and the valid pairing

**`fm1P`/`fm1B` are ML-derived (`REML = FALSE`)**, despite `lme4::lmer`'s `REML = TRUE`
default. The existing measurement (`drmTMB` `REML = FALSE` profile vs shipped `fm1P`)
is therefore **already a valid same-estimator pairing** between two independent
implementations -- contrary to the concern that motivated this review. There is no
REML-vs-ML mismatch hiding behind a coincidental numeric agreement.

**`drmTMB` does support REML for this model** (ordinary correlated Gaussian
intercept+slope random effect on `mu`; `R/drmTMB.R:2433-2470`), and its REML *point*
estimates and *logLik* match `lme4::lmer(REML = TRUE)` closely. A REML-vs-REML
comparison is the *conceptually* matched follow-on pairing once someone wants to claim
REML profile-interval parity -- but my one-dataset spot check of that pairing shows a
real ~5% gap on three of four targets, so that follow-on claim is **not yet supported**
and should not be asserted alongside the ML claim without further, dedicated
investigation (ideally more than one dataset/seed).

## Tolerances (per target, justified)

I saw the task's quoted diffs (2.6e-4, 1.4e-5, 3.1e-4, 3.3e-5) before setting these, so
I am not claiming a blind pre-registration; the justification below is deliberately
mechanism-based rather than fit to those four numbers.

**Recommend 5e-4 absolute, uniformly, for all four targets** (`sd(Intercept)`,
`sd(Days)`, `sigma`, `cor`):

- It matches the existing house tier for "different implementation, same
  likelihood-based estimator, correlated random-effect quantity" already used in
  `tests/testthat/test-comparators.R:231/236/241` (Poisson independent-random-slope
  comparator, `tolerance = 5e-4`) -- the closest existing precedent to a correlated
  Gaussian random-slope profile-CI target, since a profile endpoint (built by
  re-optimizing nuisance parameters along a monotone root-search) is a strictly more
  complex numerical object than a bare point estimate or `logLik`.
- It is **not arbitrarily loose**: my own lme4-to-lme4 profile reconstruction floor
  (Evidence #1) shows that even the *correct*-estimator reconstruction of the *same*
  package's *same* model differs from the shipped reference by up to 4.36e-5 purely
  from optimizer-path noise across separate BOBYQA fits, and the *wrong*-estimator
  reconstruction differs by up to 5.64e-4. 5e-4 sits just above that wrong-estimator
  floor, so it is tight enough to still catch a genuine estimator mismatch (as it would
  have caught the REML-reconstruction-vs-fm1P discrepancy here, 5.643e-4 vs 5e-4 -- a
  real, if narrow, fail) while not chasing engine-implementation noise below the
  1e-4-ish floor that even two same-package refits do not clear.
  Do not tighten to 1e-4 uniformly: two of the four targets (`sd(Intercept)` 2.6e-4,
  `sigma` 3.1e-4) would fail a 1e-4 gate on the ML pairing that is otherwise correctly
  matched, purely from independent-implementation profile-algorithm noise -- 1e-4 is
  appropriate for point estimates/`logLik` (as `test-comparators.R` already uses it for
  those) but too tight for a profile-CI *endpoint*, which is a numerically less stable
  quantity than a point estimate even within one package.
- It is tighter than the Laplace/AGHQ non-Gaussian comparator tier (1e-3,
  `test-comparators.R:282/287/292`) because this is an exact Gaussian profile
  likelihood on both sides, not an approximate marginal likelihood -- there is no
  Laplace/AGHQ-order approximation error to budget for here.
- It is **not** the 1e-6 "REML `logLik`-with-known-analytic-shift" tier
  (`test-comparators.R:1036`), because that tier is anchored to a closed-form external
  check (`gaussian_full_reml_loglik` / `gaussian_metafor_reml_shift`) computed
  independently of either fitted object; no such closed-form profile-CI-endpoint
  formula exists here to anchor a tighter bound.

At 5e-4, all four targets from the task's own table pass (2.6e-4, 1.4e-5, 3.1e-4,
3.3e-5, all < 5e-4). This is not fitting the tolerance to the result: the same 5e-4
figure is independently motivated by the reconstruction-noise floor above and would
also have flagged the wrong-estimator (REML) reconstruction as failing.

**Do not extend 5e-4, or any tolerance, to a REML-vs-REML profile-CI claim yet.**
Evidence #2 above shows `sd(Intercept)` and `sd(Days)` differing by ~5% (roughly two
orders of magnitude above 5e-4) between `drmTMB` REML and a fresh `lme4` REML profile
on the one dataset checked. If a REML pairing is added later, its tolerance needs its
own investigation, not an inherited number from the ML case.

## What this licenses / does not licenses

`docs/design/242-external-comparator-evidence-class.md:8-40` frames comparator
agreement as `evidence_class = "external_comparator"`, orthogonal to the ordered
`evidence_tier` scale, and states plainly: "**Not licensed.** Any interval, coverage,
bias, recovery or small-sample calibration claim. Every comparator test in the repo is
single-seed and single-dataset, and none asserts standard-error or confidence-interval
equality across packages." (`docs/design/242...md`, "What agreement licenses, and what
it does not" section). It also classifies `lme4` as **STRONG** independence (separate
engine) versus `glmmTMB`'s **WEAK** (same TMB/AD stack) -- relevant here because `lme4`
is a genuinely independent numerical implementation of the same restricted/unrestricted
Gaussian likelihood, which is what makes this comparison worth making at all.

**Licensed by the evidence above:**
- That `drmTMB`'s ML profile-likelihood machinery on this exact correlated
  Gaussian random-slope model reaches numerically close (within 5e-4 on every one of
  four checked targets, one dataset, one seed) endpoints to `lme4`'s own ML profile
  likelihood -- an implementation-correctness signal for the profile engine, on this
  model shape, at this sample size, under ML.
- That `drmTMB`'s REML *point estimates and logLik* for this same model shape agree
  closely with `lme4`'s REML point estimates and logLik (a separate, already-licensed
  claim, orthogonal to the profile-CI question).

**Not licensed, per doc 242 and this review specifically:**
- Any interval-width, coverage, or calibration claim -- single dataset, single seed,
  as doc 242 requires stating.
- A REML profile-CI parity claim: Evidence #2 shows a real ~5% discrepancy on this one
  spot check, so this is actively **not** supported, not merely "unchecked."
- Generalization beyond this one model shape (one correlated q=2 mu-side block, no
  scale-side random effect, balanced design, n=180/18 groups) or beyond `sleepstudy`.
- Any claim that `drmTMB`'s bootstrap-CI machinery agrees with `lme4`'s -- the
  bootstrap spot check above is RNG-mismatched and inconclusive, not confirmatory.
- Any implication that this note is itself a repo test; it is a review artifact. If a
  comparator test asserting profile-CI agreement is later added to
  `tests/testthat/test-comparators.R`, it must carry its own `claim_boundary` per doc
  242's enforced convention (`docs/design/242...md`, closing sentence: "a test enforces
  that").

## Uncertainty

- **Provenance of `fm1P`/`fm1B` is settled empirically, not textually.** I could not
  retrieve `lme4`'s actual generating script (two `WebFetch` attempts 404'd; GitHub code
  search needs auth I don't have here). The ML verdict rests on reconstruction evidence
  (a 13x tighter residual, concentrated exactly where REML/ML diverge, plus an exact
  match of `drmTMB`'s own quoted numbers to my `REML = FALSE` reproduction), which I
  consider strong but not textually certain. A maintainer with `gh` auth could confirm
  directly by searching `lme4`'s GitHub history for `confint_ex.rda`.
- **The REML profile-CI gap (Evidence #2) is a single spot check**, not a designed
  study: one dataset, one seed, default `profile_engine = "auto"` on the `drmTMB` side
  vs `lme4`'s built-in grid+spline profile. I have a candidate mechanism (different
  profile algorithms handling the REML nuisance-parameter re-optimization differently)
  but did not verify it. This gap is worth a dedicated follow-up if a REML profile-CI
  claim is ever wanted; I flag it here rather than either ignoring it or over-claiming
  what one dataset shows.
- **The 5e-4 tolerance is a recommendation for a new comparator that does not exist
  yet** (no current `test-comparators.R` test asserts `drmTMB`-vs-`lme4` profile-CI
  agreement at any tolerance). If added, it should carry the single-dataset caveat
  explicitly, per doc 242's `claim_boundary` requirement, since no coverage or
  multi-seed evidence backs it.
- I did not attempt to fix or explain the REML profile-CI gap; that is implementation
  work outside this review's scope (statistical-inference review of an existing/
  proposed comparison, not engine debugging).
