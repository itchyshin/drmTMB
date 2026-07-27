# Arc 6 F4R: high-information alpha Wald validation design

## Purpose and boundary

F4 validly failed its all-valid-protocol alpha-Wald coverage screen in five
lower-information cells. F4R is a prospective, documentation-only design for
testing whether the same private alpha Godambe-Wald candidate is calibrated in
a higher-information domain. It does not change the estimator, numerics,
extractor, DGP family, availability definitions, or pass criteria; it does not
authorize a runner change, DRAC connection, simulation, F5, or a public API.

The reader is the statistical-method developer who must decide whether a
narrower public claim is defensible. F4's eight `n = 480` cells motivate this
question, but are not recycled as validation evidence: F4R uses fresh, frozen
seeds and a new source receipt.

## Candidate future scope

The only candidate remains fixed-effect ML, complete-pair literal Bernoulli x
ordinary-NB2, `associate_pairs(..., association = ~ 1)`, on the link-scale
association coefficient `alpha`. It excludes association slopes, eta
intervals, other family pairs, random or structured effects, missingness,
weights, offsets, REML, `rho12`, profiles, bootstrap exposure, and every
unreviewed association object.

F4R does **not** itself set a public sample-size rule. A future F5 panel may
consider an eligibility gate only if F4R passes and only for the tested
high-information design range. In particular, the existing `n = 480` F4
results do not justify a post-hoc unrestricted `n >= 480` public method.

## Frozen prospective grid

The 16 cells cross

| Factor | Values |
| --- | --- |
| paired rows `n` | 480, 960 |
| Bernoulli logit intercept `b0` | -1.4, -0.2 |
| ordinary-NB2 log-scale parameter `sigma` | 0.25, 0.65 |
| true association link coefficient `alpha` | 0, 0.22 |

Each cell retains exactly 1,000 assigned outer datasets: 16,000 attempts in
total. Cell IDs use lexicographic order `f4r-c01` through `f4r-c16` over the
table above. For cell number `c` and replicate `r`, the frozen seed is
`2026480000 + 1000 * c + r`, for `c = 1,...,16` and `r = 1,...,1000`.

The DGP, margin fits, association fit, private alpha extraction, sandwich
path, and terminal-status precedence are exactly those in the F4 contract.
Execution must name a new full source SHA and verify the private-engine and
fixture blobs before any attempt; a source, blob, DGP, seed, or schema
mismatch quarantines the full campaign.

## Denominators and decision rule

For every cell, retain all 1,000 rows. Bias and empirical SD use the explicit
point-available denominator; mean alpha Godambe SE and its empirical-SD ratio
use the common alpha-Godambe-available denominator. Availability is reported
over all valid-protocol datasets. Primary coverage is

\[
  \frac{\#\{\text{valid-protocol attempts whose alpha interval covers alpha}\}}
       {\#\{\text{valid-protocol attempts}\}},
\]

so unavailable intervals are retained non-coverage. Conditional coverage among
available intervals is diagnostic only. Report binomial MCSE for availability
and both coverage summaries; report the 1,000-resample outer-dataset bootstrap
uncertainty for the SE/empirical-SD ratio with a frozen post-processing seed.

Every cell must meet all of the unchanged F4 thresholds:

| Quantity | Requirement |
| --- | --- |
| absolute alpha bias | <= 0.10 |
| alpha-Godambe availability | >= 0.95 |
| alpha-interval availability | >= 0.95 |
| mean alpha Godambe SE / empirical alpha SD | [0.90, 1.10] |
| primary 95% alpha-Wald coverage | [0.925, 0.975] |

There is no early stop, adaptive cell addition, retry, changed tolerance,
changed start, dropped unavailable estimate, changed coverage denominator, or
post-hoc sample-size threshold. A failure in one cell fails F4R.

## Cost and approvals

F4R is a 16,000-outer-refit DRAC campaign, not an 8,000-attempt shortcut.
Including both `n = 480` and `n = 960` is necessary to investigate a
high-information domain prospectively rather than turn the previously observed
`n = 480` success into an untested monotonicity assumption. Runtime remains
unbenchmarked; no DRAC allocation, source snapshot, output root, or submission
is authorized by this document.

The next approval, if desired, must separately name the exact source SHA,
runbook, cluster/account/resources, source snapshot, and output root, and may
authorize only the fixed F4R runner and one 16-shard / 16,000-attempt DRAC
campaign. A F4R PASS would still require a separate F5 approval before any
public S3 exposure.

## Fail-closed disposition

Until F4R passes and F5 is separately approved, the current public boundary
remains point association only. `vcov.drm_pair_association()` and
`confint.drm_pair_association()` must continue to fail informatively.
