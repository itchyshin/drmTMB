# REML support census for the DRM.jl bridge

**PINNED DRM.jl REF: `77513aa0663209b96e53a649d232558515f687fa`**
(clone used: a local checkout of DRM.jl at that ref, pointed at by `DRM_JL_PATH`)

**STATUS: PARTIAL AND SUPERSEDED. Batch 1 of 3 only. Do NOT use this table to set
`drm_julia_reml_supported()`.** The owner decided on 2026-09-03, while this census
was running, to re-pin our DRM.jl clone away from `77513aa0`. A support gate built
on these numbers would be wrong for the version we ship. The remaining batches were
not run. This file is kept as a record of what users of the *current* pin get, and
because the census re-runs cheaply at the new pin.

Arc f4, gate f4-G1. Reader: whoever re-runs this after the re-pin.

## Why a census at all

`drm_julia_reml_supported()` in `R/julia-bridge.R` encodes drmTMB's *belief* about
which cells DRM.jl fits by restricted maximum likelihood. That belief is not
measured anywhere. It gates a real consequence: today an unsupported cell warns and
is then fitted by maximum likelihood, so a user who asked for REML silently receives
ML. Widening or narrowing that gate without measuring it first would replace one
unmeasured belief with another.

## The oracle, and why the tolerance is 1e-3

`census_classify()` in `census.R` holds the entire classification, and the oracle
sits behind a flag.

**`oracle = "two-fit"` (what runs today).** Fit each cell twice through the bridge,
once with `REML = TRUE` and once with `REML = FALSE`, and compare the two reported
log-likelihoods:

- the engine throws in either arm -> **REFUSED**
- the bridge route never sends `method = "REML"` -> **REFUSED** (see below)
- both fit, `abs(ll_reml - ll_ml) >= 1e-3` -> **RESTRICTED**
- both fit, `abs(ll_reml - ll_ml) < 1e-3` -> **UNDETERMINED**, with the value recorded

The two arms are **independent optimiser runs**, so their difference carries
convergence noise. Measured locally: `nlminb` moved 1.05e-5 under a tightened
tolerance (arc f3), and the #1130 cross-engine gap was 1.086e-5. A tolerance of
1e-6 would therefore sit *below* the noise floor, and a genuinely
silently-downgrading cell would have cleared it on noise alone and been recorded
RESTRICTED - the census would have certified "zero silent ML" with the bug intact.
A genuine restriction is orders of magnitude larger: the DRM.jl lane's worked case
is -172.747 against -164.009, about 8.7 log-likelihood units. 1e-3 sits safely
between the two.

**`oracle = "single-fit"` (unavailable until DRM.jl #625).** When #625 lands the
bridge returns `estim_method`, `ml_loglik`, `reml_loglik` and `infocrit_basis` from
ONE fit, so both log-likelihoods can be read at ONE optimum. That removes the
optimiser-noise term entirely and makes the tolerance question moot. The flag exists
so that swap is a small change to one function rather than a rewrite.

## UNDETERMINED should come back empty

The restricted and maximum-likelihood objectives differ by roughly the log-determinant
of the fixed-effect information matrix, which **grows** about as `p log n` rather than
shrinking. ML and REML converge in their *estimates*, not in their *objective values*.
So a genuine restricted fit never drifts toward the noise floor, and a populated
UNDETERMINED bucket is a finding to investigate rather than a shrug. When investigating
one, **suspect the harness before the engine**: the likeliest causes are that the two
arms were not actually fitted by different methods, or that the gate silently rewrote
`method = "REML"` to `"ML"` before the payload was built.

Nothing landed in UNDETERMINED in batch 1.

## The census forces the gate open

`census.R` overwrites `drm_julia_reml_supported()` with `function(...) TRUE` before
fitting anything. This is deliberate and load-bearing. With the shipped gate in place,
the bridge rewrites `method` to `"ML"` for every cell it already disbelieves, so the
census would read its own prior back and confirm it. Forcing the gate open makes each
arm reach DRM.jl as written, so what is measured is the **engine**, not our belief
about it.

Three bridge routes hard-code `effective_REML = FALSE` and never send
`method = "REML"` regardless of the gate: the cross-family route
(`drmTMB_julia_xfam_bridge`), the bivariate q2 known-covariance structured route
(`drmTMB_julia_biv_known_structured_bridge`, `R/julia-bridge.R:5541`) and the general
structured route (`drmTMB_julia_structured_bridge`, `R/julia-bridge.R:5778`). For those,
the two arms are the same fit by construction, so `census_classify()` settles the
verdict from the route and does **not** run the log-likelihood comparison at all -
comparing two identical fits would put a difference of exactly zero into UNDETERMINED
and make a known R-side fallback look like an engine finding.

## Batch 1 results, pin 77513aa0

| cell | formula | verdict | ll (REML requested) | ll (ML) | abs diff |
| --- | --- | --- | --- | --- | --- |
| `gaussian_fixed_locscale` | `bf(y ~ x, sigma ~ x)` | REFUSED (see caveat) | - | -253.531117232424 | - |
| `gaussian_random_intercept` | `bf(y ~ x + (1 \| g))` | RESTRICTED | -264.693905172301 | -262.596043145445 | 2.097862027 |
| `gaussian_mean_only_phylo_no_sd` | `bf(y ~ x + phylo(1 \| species), sigma ~ 1)` | REFUSED | - | -97.5630777153355 | - |
| `gaussian_sigma_phylo_locscale` | `bf(y ~ x + phylo(1 \| species), sigma ~ phylo(1 \| species))` | RESTRICTED | -102.686443156935 | -97.4324841075311 | 5.253959049 |

Full error strings, including Julia stack traces, are in `batch1-pin-77513aa0.csv`.

### `gaussian_mean_only_phylo_no_sd` - a clean confirmation

DRM.jl refuses this cell with an explicit `ArgumentError`:

> drm: method = :REML is currently implemented only for the fixed-effect Gaussian
> location-scale model and for a single Gaussian mean random intercept `(1 | g)`
> (no random slopes, no random effect on sigma, no structured / phylo / meta terms).

The current gate already calls this cell unsupported, and the census agrees. The
refusal message text is unchanged between our pin and the DRM.jl lane's tip, so greps
against it are safe today.

### `gaussian_random_intercept` - the gate is right for the wrong reason

The DRM.jl lane flagged Poisson `(1 | g)` and Poisson `phylo(1 | species)` as cells a
prior would most likely get wrong. Those are batch 3 and were not reached. The Gaussian
`(1 | g)` case measured here is genuinely restricted (2.10 units apart), consistent
with the DRM.jl refusal message above naming it explicitly.

### `gaussian_fixed_locscale` - a REFUSED verdict that must NOT be trusted

This is the most important thing in this partial run, and the reason the table cannot
be promoted to a gate as it stands.

The fixed-effect Gaussian location-scale model is the *canonical* supported REML cell -
DRM.jl's own refusal message names it first. It nevertheless threw here:

> DomainError with -1.0: log was called with a negative real argument

from `logdet` inside `_fit_fixed_gaussian_reml` (`src/gaussian_core.jl:1098`), reached
through `ForwardDiff` during the REML profiling step. This is a **numerical failure on
this particular simulated dataset**, not a categorical refusal. The same formula shape
fit without complaint in a smoke run earlier the same session, on 120 rows with a
different seed and no group structure in the response (log-likelihoods -196.7376399419
REML against -194.2233890841 ML, a difference of 2.514 - comfortably RESTRICTED).

Two consequences:

1. **A harness defect, recorded not fixed.** The two-fit oracle cannot distinguish
   "the engine will not fit this cell by REML" from "the engine failed to fit this
   *dataset*". A REFUSED verdict is only trustworthy when the error is a deliberate
   `ArgumentError` naming the limitation, as in `gaussian_mean_only_phylo_no_sd`. The
   re-run should classify a numerical error (`DomainError`, `PosDefException`,
   non-convergence) as a distinct **INCONCLUSIVE** verdict and retry on a second
   dataset before recording anything, rather than collapsing it into REFUSED.
2. **It is very likely the version gap.** One of the three fitting-behaviour changes
   between our pin and the DRM.jl lane's tip is a **resolvable-scale guard near the
   variance boundary**, absent at `77513aa0`. A `logdet` of a matrix that has gone
   indefinite near the variance boundary is exactly the failure such a guard exists to
   catch. This cell alone is a strong argument that the census belongs at the new pin.

## Pin-specific caveats for the re-run

Four facts about `77513aa0`, measured by the DRM.jl lane, that bound what any census
here can conclude:

1. **The sparse multi-component location-scale-scale route (their census row 9) landed
   after our pin and cannot exist here.** It is recorded as **EXPECTED-ABSENT**, not as
   a disagreement. The dense multi-component variant does exist here and is in batch 2.
2. **Defect #620 is live at our pin.** A structured marker with a non-intercept left
   side - `phylo(1 + x | g)` and the `relmat` / `animal` / `spatial` equivalents -
   **silently fits the intercept-only model** rather than throwing. Any such cell says
   nothing about REML support, because the model being fitted is not the model the
   formula names. Such cells are labelled **#620-affected** and excluded from the
   supported set in **both** directions. The complete #620 exposure on the Julia route
   is three test sites and zero committed receipts: two in
   `tests/testthat/test-julia-slope-nongaussian.R`, and
   `tests/testthat/test-julia-structured.R:238`
   (`bf(y ~ x + relmat(1 + x | id, K = K), sigma ~ 1)`), the last of which had not been
   flagged before 2026-09-03. Batch 3 of `census.R` carries `relmat_slope_620` and
   `gamma_phylo_slope_620` for exactly this reason. Those three test sites will start
   *raising* rather than silently fitting once the re-pin lands, and that is re-pin
   work, not census work.
3. **Three fitting-behaviour changes sit between our pin and their tip**, so a
   disagreement with their fourteen cells is not automatically a version artefact:
   the resolvable-scale guard near the variance boundary (absent here); the
   location-scale-scale outer iteration budget doubling from 1000 to 2000 (absent here,
   so some cells may report not-converged here that converge there); and the #620
   refusal. Any disagreement must name which of these could explain it, or state that
   none can.
4. **The REML refusal message text is unchanged** between our pin and their tip.

## What was not reached

Batches 2 and 3 did not run. Uncensused: `lss_sd_group_dense`, `lss_sd_phylo_dense`,
`lss_multi_component_dense`, `biv_q2_structured_phylo`, `biv_q4_phylo`,
`poisson_random_intercept`, `poisson_phylo_intercept`, `gaussian_random_slopes`,
`gaussian_meta_V`, `biv_residual_only`, `gamma_fixed_no_ranef`, `relmat_slope_620`,
`gamma_phylo_slope_620`, plus `lss_multi_component_SPARSE` (EXPECTED-ABSENT).

## Re-running

    OPENBLAS_NUM_THREADS=1 \
      CENSUS_OUT=<dir> \
      DRM_JL_PATH=<DRM.jl clone> \
      Rscript docs/dev-log/evidence/julia-r-parity/reml-support-census/census.R <batch>

with `<batch>` in 1, 2, 3. Julia boots once per process in about 35 s; each fit is
about 2 s thereafter, so a batch is a couple of minutes. Update the pinned ref at the
top of this file when re-running.
