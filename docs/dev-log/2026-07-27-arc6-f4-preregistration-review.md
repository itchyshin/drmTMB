# Arc 6 F4 preregistration review — Bernoulli x ordinary-NB2 association

**Status:** frozen documentation-only review, approved 2026-07-27. This is
not authorization to implement a harness, run a simulation, contact Totoro or
DRAC, or make any inference or public-product claim.

## Scope and source boundary

The sole candidate is fixed-effect ML, complete paired observations, literal
Bernoulli x ordinary-NB2 margins, and `association = ~ 1`. The primary
estimand is the staged association-link coefficient `alpha`; `eta = 0.999999 *
tanh(alpha)` is derived only. The design excludes association slopes, other
pair classes, random or structured effects, missingness, weights, offsets,
REML, direct `biv_lognormal()` `rho12`, and all public API work.

F3 established only a provenance-correct full two-stage refit at source
`2418d847b45891b09f719932e75985101be50116`. It did not establish recovery,
SE calibration, interval validity, or coverage. F4 execution must name a new
full source SHA and verify that its private-engine and F1M-fixture blobs remain
respectively `d090f67b74bf5dfee6baa4396a8f45a3c977d6fd` and
`d36b02b2ad470e641843d4f751ee1c998e6922bf`; a mismatch quarantines the
campaign rather than becoming an eligibility exception.

The stopped `24 x 200 x 399` bootstrap shards are excluded permanently from
this review and may not be resumed, aggregated, or used as F4 evidence.

## Frozen DGP grid

Each cell uses `x = seq(-1.4, 1.4, length.out = n)`, complete paired
responses, a Bernoulli logit margin `b0 + 0.3*x`, and an ordinary-NB2 margin
`log(mu) = 0.7 + 0.2*x` with constant `sigma`. The staged association is
intercept-only. The factorial grid has 24 cells:

| Factor | Values |
| --- | --- |
| `n` | 120, 240, 480 |
| Bernoulli intercept `b0` | -1.4, -0.2 |
| NB2 `sigma` | 0.25, 0.65 |
| true `alpha` | 0, 0.22 |

Every cell has 1,000 attempted outer datasets: 24,000 attempts in total. Cell
IDs are lexicographic in the table order above (sample size, then Bernoulli
intercept, NB2 sigma, and alpha), and replicate `r` in cell `c` has frozen seed
`2026072000 + 100000*c + r`, for `c = 1,...,24` and `r = 1,...,1000`.
Each attempt refits `binary ~ x`, `count ~ x, sigma ~ 1`, then
`associate_pairs(..., association = ~ 1)` from the generated data. There are
no inner bootstrap refits: F4 evaluates the one explicitly named candidate
interval, the two-sided 95% link-scale Godambe Wald interval,
`alpha_hat +/- qnorm(0.975) * se_alpha`.

## Status, denominator, and analysis contract

Each outer attempt receives exactly one terminal status in this precedence:

`dgp_harness -> Bernoulli margin -> NB2 mean -> NB2 dispersion -> association
-> rectangle/integration -> sandwich -> delta -> interval`.

The retained all-attempt table must contain one row per attempted dataset,
including seed, source/fixture hashes, DGP cell, every stage status, point
estimate, alpha-SE availability, eta-delta availability, interval availability,
and failure reason. The denominators are nested and reported for every cell:

1. attempted outer datasets (always 1,000);
2. valid-protocol datasets (all source, fixture, DGP, and harness checks pass);
3. successful two-stage point fits;
4. alpha-Godambe and eta-delta availability, separately; and
5. alpha-Wald interval availability.

A DGP, harness, source, or fixture mismatch quarantines the entire campaign;
it is neither a failed fit nor a removable observation. The primary coverage
denominator is all valid-protocol datasets, so an unavailable interval counts
as non-coverage. Conditional coverage among interval-available fits is
secondary. No `retained` denominator is permitted.

## Pre-registered targets and uncertainty summaries

For each cell, report the mean alpha estimate and absolute bias, empirical SD
of alpha estimates, mean available Godambe alpha SE, their ratio, both coverage
denominators, and interval availability. The `eta` delta summaries are
descriptive only; no eta interval is assessed in F4.

The candidate passes its F4 calibration screen only if every cell has:

- absolute alpha bias no larger than 0.10;
- interval availability of at least 0.95 over valid-protocol datasets;
- mean Godambe alpha SE divided by empirical alpha SD in [0.90, 1.10]; and
- primary 95% alpha-Wald coverage in [0.925, 0.975].

Report binomial Monte Carlo SE `sqrt(p_hat * (1 - p_hat) / n_valid)` for
primary and conditional coverage and for availability. At the nominal 0.95
with 1,000 valid-protocol datasets this is about 0.0069; no campaign result may
be described without its cell-specific denominator and MCSE. The ratio's
uncertainty is reported with a 1,000-resample outer-dataset bootstrap; that
post-processing is part of a later execution harness, not authorized here.

F4 is an evidence screen, not an automatic exposure rule. Even a pass cannot
create a public method, claim, API, ledger movement, or F5 decision.

## Frozen stop and quarantine rules

Complete all 1,000 assigned attempts in every cell. Do not stop a cell early
for favourable or unfavourable recovery, SE, availability, or coverage results;
do not add a cell, change a seed, alter starts/tolerances, or rerun a terminal
attempt. An ordinary margin, association, rectangle, sandwich, delta, or
interval failure receives its terminal status and the next pre-assigned attempt
continues.

A source/fixture mismatch, DGP mismatch, seed-schedule mismatch, or malformed
status table quarantines the entire campaign: stop further work, retain all
rows already written, and return for a new owner decision. Infrastructure
interruption and resource exhaustion are execution-runbook matters; this review
does not authorize a retry or a scheduler resubmission.

## Compute recommendation and execution fence

The costed unit is 24 independent shards x 1,000 all-attempt full two-stage
fits = 24,000 outer refits, with no 399-refit inner bootstrap multiplier. DRAC
is the recommended future host because this is a replicated grid naturally
expressed as a 24-element job array with shard-level provenance. Totoro remains
an alternative only after a future capacity check and must stay within the
shared-use core cap; neither host has been contacted or benchmarked here.

No wall-clock allocation is predeclared because the F3 provenance smoke records
no elapsed-time benchmark. A later execution approval must name the frozen
source SHA, DRAC account/array resources (or a justified Totoro worker cap),
seed manifest, output root, and stop/quarantine procedure. It must not reuse
this documentation approval as permission to launch. GitHub Actions is
prohibited for F4 compute and artifacts.

## Approval chain

This review is the completed documentation-only approval. Before F4 execution,
Shinichi must separately approve the exact source SHA and compute runbook.
After F4, Fisher, Noether, and Rose must review the retained all-attempt
evidence before a separate F5 public-product decision; public inference remains
locked until then.
