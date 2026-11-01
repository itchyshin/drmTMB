# 2026-10-25: Audit of drmTMB's own AGHQ (issue 934, step 1)

**Scope.** Step 1 only, as approved by the owner on 2026-10-11 (option a): a read-only audit that
says whether drmTMB's adaptive Gauss-Hermite quadrature (AGHQ) has been shown to be a correct
integrator, an established estimator, or both, and for which model classes. The node ladder,
the ridge check and the dimension ladder (asks 2 to 4 of the issue) stay parked behind this
result. No R, C++ or test file was changed. The one new artefact beyond this note is a
few-second fixed-parameter spot check, kept so the integrator figures can be reproduced
(`docs/dev-log/evidence/2026-10-25-aghq-integrator-spot-check/`).

**Tree read:** `origin/main` at `f03b0b24a`. Nothing was fitted or simulated for this note
except that spot check.

## Verdict in two sentences

- **Integrator: correct, for the two cases it implements.** At fixed parameters the quadrature
  converges to brute-force `integrate()` to machine precision as nodes increase, for a binomial
  and a cumulative-logit scalar random effect (reproduced today, table below).
- **Estimator: established for exactly one cell, not for the rest.** The fitting procedure
  (AGHQ plus Cox-Reid-style adjustment, called O3) has a planted-truth recovery and interval
  coverage campaign for one model class only: a cumulative-logit `mu` random slope. Binomial O3
  has deterministic checks and single-dataset ordering checks, but no recovery or coverage
  campaign. Nothing else has any AGHQ evidence, because nothing else is implemented.

## What drmTMB's AGHQ actually is

The baseline named in the issue is smaller than the issue's framing suggests.

1. **It is package-private and R-level.** `R/aghq-coxreid.R` (212 lines, pure R, no TMB/DLL)
   defines `drm_o3_fit()`, `drm_o3_marginal_ll()`, `drm_o3_profile_ci()`. It is not exported,
   not a `drmTMB()` argument (`estimator` admits `"ml"` and `"mspl"` only), and not what
   `REML = TRUE` runs. Its only callers in the tree are `tests/testthat/test-aghq-coxreid.R`,
   one optimizer-control test in `test-dinnage-audit-a3-misc.R`, and the campaign driver
   `tools/run-o3-cumlogit-coverage.R`. The capability ledger row reads `planned`
   (`docs/design/capability-status.md`), which matches.
2. **It integrates one scalar random effect per cluster.** The leaf is
   `drm_o3_cluster_ll(u, ...)` with `u` a single number. A random intercept (`z == 1`) or one
   independent numeric slope (`z == x`) in `mu`.
3. **Two families only:** `binomial` (Bernoulli or trials) and `cumulative_logit`.
4. **Outside it, with no AGHQ code at all:** random effects in `sigma`, correlated
   intercept-slope pairs, more than one latent effect per cluster, structured effects
   (phylogenetic, spatial, animal), Poisson, NB2, Gamma, Beta, every other family, missing-response
   and `mi()` routes, and the Julia engine. `R/julia-bridge.R` itself records that a same-target
   Julia comparison would need an AGHQ option in drmTMB.

**Consequence for the VA/EVA comparison (#496, #932, #936).** The issue says "what we have, in
the regime that matters, is AGHQ". For random effects in `sigma`, and for any latent block of
dimension above 1, drmTMB has no AGHQ to serve as a baseline. Any VA-versus-AGHQ result there
would compare against something that does not exist yet, not against an unestablished
estimator. The 2026-08-03 decision's own scope note ("scoped to drmTMB's current model
classes", scalar random intercepts first) is the correct reading, but the repo currently has
the scalar case only.

## Evidence for "integrator correct"

Reproduced on 2026-10-25 on Totoro at `f03b0b24a`
(`docs/dev-log/evidence/2026-10-25-aghq-integrator-spot-check/`, R 4.6.1, a few seconds).
Fixed parameters, absolute error of the summed log marginal likelihood against
`integrate()` at `rel.tol = 1e-12`, using the same two datasets as `test-aghq-coxreid.R`
(binomial seed 11, 28 clusters of 6; ordinal seed 21, 28 clusters of 8, K = 4):

| nodes | binomial abs error | cumulative-logit abs error |
|--:|--:|--:|
| 1 (Laplace) | 1.9e-01 | 1.6e-01 |
| 3 | 6.0e-03 | 2.2e-03 |
| 5 | 2.0e-04 | 4.9e-05 |
| 9 | 7.3e-08 | 4.9e-08 |
| 15 | 1.1e-11 | 4.3e-12 |
| 25 | 1.4e-14 | 5.7e-14 |
| 41 | 7.1e-14 | 1.1e-13 |

The error falls by orders of magnitude per added node group and then sits at the floating
point floor, in both families. This is the node-order stability the issue asks about, but only
for the integral at fixed parameters, on two datasets, with the true parameters (not fitted
ones). It says nothing yet about the fitted estimate.

Other integrator evidence on file:

- `docs/design/224-aghq-coxreid-nongaussian-reml-alignment.md` section 7a reports the same
  checks (2.8e-14 binomial, 6.4e-9 ordinal at 15 nodes, `nodes = 1` equal to Laplace to 1e-13)
  and a full binomial AGHQ fit matching `lme4::glmer(nAGQ = 25)` on the RE-SD to 9.3e-6.
- `test-aghq-coxreid.R` checks the Golub-Welsch nodes against `statmod`, the binomial fit
  against `glmer(nAGQ = 25)` (tolerance 1e-3, one dataset), and orderings (Laplace < AGHQ <
  AGHQ + Cox-Reid) on one dataset per family.

**Gap in retained evidence.** Before today the `integrate()` comparison and the
`nodes = 1` equals Laplace identity existed only as numbers in the design doc. The test file
does not assert either: its `nq = 1` test only checks that 25 nodes give a larger SD than 1
node. The spot check closes the reproducibility gap but is not a regression test.

## Evidence for "estimator established"

"Established" here follows the issue: planted truth recovered with correct interval coverage,
not clean convergence flags.

| Model class | Integrator | Recovery vs planted truth | Interval coverage | Status |
|---|---|---|---|---|
| cumulative_logit, scalar `mu` random slope (iid, uncentred) | correct | yes, relative bias about 0% at every M | nominal at M of 40, 80, 160, 320 | **established for the tested design** |
| binomial, scalar `mu` random intercept or slope | correct | single datasets only | none | **not established** |
| cumulative_logit random intercept | correct (shared code) | one scoping run (see below) | none | **not established** |
| anything else | no code | none | none | **no AGHQ exists** |

### The one established cell: `mc-0227` (2026-07-18, commit `1ed90599b`)

`docs/dev-log/simulation-artifacts/2026-07-18-o3-cumlogit-slope-coverage/README.md`. O3 with
25 nodes, true sigma 0.5, K = 4, 15 observations per cluster, 1,200 replicates per cell,
profile interval on the natural SD scale. Coverage 0.9515, 0.9457, 0.9596, 0.9508 at M = 40,
80, 160, 320, each with an exact-binomial interval overlapping [0.925, 0.975]; relative bias
+0.0%, -0.1%, +0.1%, +0.1%. The recovery is measured against the planted truth, not against
flags, which meets the issue's ask 5 for this cell.

Limits to state with it:

- **One data-generating process**: one sigma, one cutpoint vector, one slope effect, one
  cluster size. It supports "recovers and covers on this design", not a regime map.
- **Only the RE-SD is scored.** Fixed effects and cutpoints are not scored for recovery.
- **Conditional coverage.** Replicates with no computable interval (n_fail 2, 4, 13, 21 at the
  four M) are excluded from the denominator.
- **Boundary behaviour at small M.** At M = 40, 15.5% of replicates had one-sided intervals
  (sigma-hat piled up at zero). The campaign itself named M = 80 the reporting floor and
  treated M = 40 as exploratory.
- **Nodes were fixed at 25.** No node sweep was run at the estimator level.
- **Per-replicate raw rows exist only for M = 320.** M = 40, 80, 160 survive as summary lines
  in `campaign-main-M40-M80-M160.log`.
- **The interval pivot is the plain chi-square(1)**, disclosed in the campaign, with no
  boundary mixture correction.
- **Public status is unchanged.** The 0.7 reconciliation
  (`docs/dev-log/plan-actual/2026-08-08-0.7-capability-truth-reconciliation.md`) records that
  this evidence grants no public estimator, interval or reporting permission, because the
  estimator is not callable from `drmTMB()`. The public `mc-0227` cell is ML-Laplace at
  `point_fit_recovery`.

### Binomial: integrator and ordering only

The binomial O3 route has: the `integrate()` and `glmer(nAGQ = 25)` agreement above, the
ordering test on one dataset, and `docs/dev-log/simulation-artifacts/2026-07-12-laplace-vs-aghq/`
(80 seeds per cell, true SD 0.8). That last study is the strongest binomial evidence but it is
about **glmer's AGHQ**, not drmTMB's code, and it scores point bias only (AGHQ relative bias
+2.0% at 2 observations per cluster against -23% for Laplace; -6.8% at 8 per cluster, the
remaining bias being the ML degrees-of-freedom effect that AGHQ does not remove). It supports
the claim that AGHQ is the right integrator for tiny binary clusters. It does not establish
that drmTMB's `drm_o3_fit()` recovers truth or covers. The binomial REML-scoping table
(`2026-07-18-cumlogit-laplace-vs-aghq/reml-scoping-binomial.tsv`) has no Cox-Reid column,
so the binomial Cox-Reid adjustment has no bias scoping at all beyond the one-dataset
ordering test.

### Cumulative-logit random intercept: scoping only

`reml-scoping-cumlogit-40seed.tsv` (40 seeds, M = 40 and 160) gives relative bias Laplace
-7.3%, exact ML (48-node AGHQ) -5.0%, Cox-Reid -0.9% at M = 40, but +2.1% at M = 160 for
Cox-Reid, which the design doc calls "scoping-grade, about 1e-2 reliable". The sibling file
`cumlogit-laplace-vs-aghq.tsv` has `n_ok_aghq = 0` in every row (three Laplace fits per cell,
no AGHQ fits succeeded), so it carries no AGHQ evidence and should not be cited for any.

## Asks 2 to 5 of the issue, status after this read

| Ask | State |
|---|---|
| 1. Which is it today? | Answered above. |
| 2. Node-order stability, per family | Integrator at fixed parameters: shown for both implemented families (table above). Estimator level: not shown; only 1, 5, 15, 25 and 48-node single runs exist. A real ladder is still needed, and only two families exist to run it on. |
| 3. The `aghq_ridge` claim | Nothing to confirm or refute in drmTMB. There is no ridge in `R/aghq-coxreid.R` (no match for "ridge"). The claim is gllvmTMB's (the 2026-08-03 decision and 2026-08-11 handover cite it as gllvmTMB's merged mitigation). On drmTMB it is untestable as stated. |
| 4. Dimension behaviour | Not measurable on current code: the implementation is one-dimensional by construction (cost is nodes times clusters, linear in M). The recorded wall clock for the mc-0227 cells (2,811 s at M = 40, 5,276 s at M = 80, 15,787 s at M = 160, 90 cores) is cost per M for a scalar effect. The exponential-in-dimension question, including random effects in `sigma`, needs a tensor-product AGHQ that does not exist. Building it is a design decision, not a measurement. |
| 5. Recovery, not flags | Met for the `mc-0227` cell. Not met for binomial. |

## What this means for the parked steps (for the owner)

1. The cheapest step that actually moves the baseline: a small binomial O3 recovery and
   coverage run at the `mc-0227` standard (same harness, `family = "binomial"`). Likely under
   3 hours at the same cell count per M on Totoro, but I have not estimated it from a pilot,
   so treat that as unmeasured. This would make the binomial class established or show it is
   not.
2. A fitted-estimator node ladder (asks 2) on the two implemented families is cheap in
   comparison and can reuse the fixed-parameter datasets above.
3. Ask 4 and the `sigma` side of the EVA argument (#936) cannot start until someone decides
   whether to build a multi-dimensional AGHQ. That decision is the owner's, and it determines
   whether "VA versus AGHQ" is a test at all for `sigma` random effects.
4. The two stale or misleading items found while reading (not fixed here, outside this
   issue): the `nq = 1` test does not assert the Laplace identity; and
   `docs/design/parity-fenced-capabilities.md` section 1 still says AGHQ "has no D-number",
   while `inst/extdata/julia-fences.tsv` now records an owner answer of 2026-09-24. I did not
   check which of the two is current beyond that one line.

## Provenance and limits of this audit

Read-only apart from the spot check. Evidence tiers follow the repo's own ledger words. I did
not re-run the `mc-0227` campaign, did not read the DRM.jl AGHQ (out of scope: the issue asks
about drmTMB's own), and did not audit the MSPL quadrature receipt
(`scratchpad/mspl-binomial-quadrature-spike.R`), which checks the experimental MSPL objective
against Gauss-Hermite and is a different object from O3. The existing test file was run
once on this tree; its result is in the check log entry.
