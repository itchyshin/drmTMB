# After Task: Beta phylogenetic q1 PR 2 recovery HOLD

## 1. Goal

For R package contributors and statistical-method reviewers, this phase tested
whether one bounded Beta phylogenetic direct latent-SD regression could proceed
as the second pull request in the approved two-PR sequence. PR 1 first admitted
the constant latent phylogenetic location-effect SD. PR 2 was allowed to add
only

```r
sd(spp_id, level = "phylogenetic") ~ 1 + x
```

for the same unlabelled intercept-only `phylo()` effect on `mu`, under ML and
with fixed-effect family `sigma`. The maximum possible claim was
`point_fit_recovery`.

## 2. Implemented

PR 1 merged as #786 at
`0bdfda144c976824bed604be2cfae22b33bd8fe0`. Exact post-merge R-CMD-check
run 29524995333 passed its `os-matrix` and Ubuntu release jobs.

PR 2's implementation remains on branch
`codex/beta-phylo-q1-sd-regression`. Source commit
`2f1b602b88f0fcf1ce67ebd60412c6bcf2fbaa27` added the bounded parser,
TMB path, extractors, independent likelihood/gradient sentinels, rejection
matrix, runner tests, and recovery runner. Commit
`2f1399dda78253ea725f93e47a0e88da2ed5a8e6` repaired relative-path manifest
readback and is the exact source authenticated by all valid compute evidence.

The recovery result is **HOLD**. No PR 2 was opened, no capability ledger row
was promoted, and no public direct latent-`sd()` claim was added.

## 3a. Decisions and Rejected Alternatives

The frozen decision rule required both distinct and shared
`g = 1024, m = 4` arms to pass separately. The shared arm failed, so the arc
stopped. We rejected rerunning the failed seed, filtering the attempt,
substituting an interior draw, pooling the two predictor designs, weakening the
all-400-finite gate, or treating the 399 fitted datasets as the denominator.
Each alternative would change a prospective contract after seeing the result.

We also rejected opening a code-only PR. The approved sequence tied PR 2
admission to recovery, and branch-level tests cannot substitute for that gate.
A later interior-DGP redesign is scientifically reasonable, but it is a new
goal rather than a repair inside this stopped campaign.

## 3b. Mathematical Contract

For species-level latent location effects `a`, phylogenetic correlation `A`,
and species-constant predictor `x_s`, PR 2 implements

\[
\alpha_s = \alpha_0 + \alpha_1 x_s, \qquad
\tau_s = \exp(\alpha_s), \qquad
a \sim \mathcal N(0, D_\tau A D_\tau).
\]

The conditional mean is linked through `mu`, while Beta family variability is
parameterized separately by

\[
\phi_i = \sigma_i^{-2}.
\]

Thus family `sigma` is not the latent target `tau_s` represented by `sd()`.
The symbolic table, R syntax, C++ covariance construction, extractor scale,
and independent direct likelihood/gradient oracle match term by term.

## 4. Files Touched

The branch-only implementation touches `R/drmTMB.R`, `R/methods.R`,
`src/drmTMB.cpp`, focused Beta tests, the recovery runner, its frozen design,
and the symbolic alignment note. This closeout adds only compact evidence,
repository status prose, this report, and the handover. It does not edit the
capability ledger, user-facing reference pages, or pkgdown navigation because
the feature did not pass its admission gate.

## 5. Checks Run

The exact source passed 586 focused implementation expectations, including
independent likelihood and gradient comparisons and the rejected-neighbour
matrix. The hardened runner passed 81 expectations. Its source-authentication
chain binds the commit, tree, runner, frozen design, prior PR 1 manifest,
tracked seed audit, DLL, stage ordering, attempt schemas, output manifest, and
completion seal.

The closeout rerun passed 44/44 direct-SD test expectations and 81/81 runner
expectations with zero failures, warnings, or skips.

The authenticated local one-fit completed in 3.674 seconds with convergence
code zero, `pdHess = TRUE`, maximum gradient `3.948802e-05`, Hessian condition
`93.24146`, six finite estimates, and no warning or error. The exact-source
Totoro smoke retained all 12 cells: 12/12 convergence-code-zero, 12/12
`pdHess = TRUE`, 12/12 six-finite, no warning or error, maximum gradient
`0.002543139`, and maximum Hessian condition `2959.676`.

The Totoro certification ran from 2026-07-16 20:08:27 UTC to 21:08:38 UTC and
retained all 4,800 predeclared attempts. After import, the full 9,613-file
output passed local SHA-256 manifest authentication. The complete output
manifest hash was
`7e5532c61e0f97f107e54c0be43f438e2859421e8630129bbba529e91123459f`.

## 5a. Recovery Decision

The distinct `g = 1024, m = 4` arm passed. All 400 attempts were finite and
all six parameter gates passed; the latent-SD intercept bias was `-0.01672`
with Monte Carlo interval `[-0.03284, -0.00059]`, and the latent-SD slope bias
was `0.00284` with interval `[-0.00185, 0.00753]`.

The shared `g = 1024, m = 4` arm failed its prospective all-400-finite rule.
Replicate 373, seed `2099879627`, generated a response at Beta's forbidden
support boundary and failed before optimization with the package's strict
interior-support error. The arm therefore retained 400 attempts but only 399
successful, finite fits. The other 399 estimates were descriptively small-bias,
but the frozen denominator forbids filtering the failed draw or promoting from
the successful subset. The exact decision is `HOLD_NO_PR2_PROMOTION`.

This event is evidence of the realized simulation DGP meeting finite-precision
Beta support, not evidence of estimator, Laplace, or optimizer bias: no fit was
attempted for that replicate. Increasing `g` does not repair a DGP that can
produce an exact 0 or 1. Any interior-response redesign must be prospective and
must start under a separately approved goal.

Three non-promotional cells also retained adverse diagnostics. Distinct
`g = 256, m = 2` replicate 103 (seed `2099989897`) and shared
`g = 256, m = 2` replicate 153 (seed `2099929847`) each returned optimizer
code 1 with a singular-convergence warning. Shared `g = 512, m = 2` replicate
74 (seed `2099909926`) returned `pdHess = FALSE` with `NaNs produced`. The
runner kept all three and marked their cell-quality rows false. They do not
alter the separate two-arm promotion algebra, but they remain part of the
negative evidence and may not be omitted from future design review.

## 6. Tests of the Tests

The test suite compares the implementation against independent likelihood and
gradient calculations, checks covariance scaling directly, and exercises the
unsupported family, REML, q2/labels/slopes, family-`sigma` phylogeny,
within-species-varying predictor, ordinary-random-effect combination,
random-RHS, and missing-route boundaries. Runner tests tamper with manifests,
source identity, stage DLLs, shards, resume provenance, output seals, host and
thread guards, and frozen designs. The real certification supplied the final
failure-path test: its retained support-boundary attempt forced the conservative
HOLD branch.

Rose's pre-compute review noted that direct unit expectations for wrong stage
mode/count and failed-stage diagnostics would further harden the runner. Those
guards exist and fail closed, but this branch will not merge, so no post-
certification code descendant was created merely to expand a stopped runner.

## 7a. Issue Ledger

No new issue was opened. This is a failed branch-level admission gate rather
than a shipped regression, and opening a public capability issue would risk
turning a DGP redesign question into an implied implementation commitment. PR
#786 and post-merge run 29524995333 were verified read-only; PR 2 was not opened.

## 8. Consistency Audit

`AGENTS.md`, `ROADMAP.md`, and `docs/dev-log/known-limitations.md` now record
the same boundary: PR 1 is merged, PR 2 is branch-only and HOLD, direct Beta
latent-`sd()` regression is not admitted, and family `sigma` remains distinct.
The ledger and generated capability surface were deliberately not changed.
No pkgdown rebuild is required because no user-facing source or navigation was
edited.

The stale-surface search was:

```sh
rg -n -i 'beta.*phylo|phylo.*beta|direct latent|sd\(spp_id|sd\(species|HOLD_NO_PR2_PROMOTION|g *= *1024|family sigma|phi *= *sigma' README.md ROADMAP.md NEWS.md AGENTS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml docs/dev-log/dashboard/capability-ledger/cells.tsv docs/dev-log/dashboard/capability-ledger/evidence.tsv
```

## 9. What Did Not Go Smoothly

The first local one-fit exposed a relative-path output-manifest bug. Its output
was quarantined and never used as evidence. The runner was repaired before the
valid one-fit, smoke, or certification. The certification then exposed a second,
scientifically different problem: `rbeta()` can return an exact boundary value
under the frozen DGP at finite precision, while `drmTMB()` correctly requires
strictly interior Beta responses. The retained failure stopped promotion.

The first closeout test command called the fitted test file directly without
loading the package, so it failed with `drmTMB` not found. The corrected
`devtools::test()` invocation loaded the package and passed 44/44; the runner
file then passed 81/81. This was a harness invocation error, not a code failure.

## 10. Known Residuals

This branch does not support or claim REML, q2/q4, labels, phylogenetic slopes,
phylogeny in family `sigma`, ordinary random-effect combinations, random terms
on the `sd()` right-hand side, within-species-varying `sd()` predictors,
missing-response routes, `zero_one_beta()`, other non-Gaussian families,
intervals, or coverage. The surviving 399 shared-cell estimates are descriptive
only and cannot establish recovery.

The runner's negative stage tests can be expanded if a future approved goal
reuses it. The branch-only implementation and full sealed artifacts remain
carried over, not merged.

## 11. Team Learning

The N ladder did its job: it prevented a premature estimator-method arc and
showed that the distinct high-information cell can recover. It did not justify
ignoring a support-invalid simulated dataset in the shared design. Recovery
contracts should predeclare both statistical gates and an explicit
interior-support policy for continuous bounded DGPs before compute.

The full certification attempt-level output stays local and on Totoro, in line
with D-50. The
repository tracks the complete 4,800-row table and compact decision evidence,
not the certification's 9,600 atomic shard files or a GitHub Actions artifact.
The sealed local copy is under
`/Users/z3437171/Dropbox/Github Local/drmTMB-local-artifacts/2026-07-16-beta-phylo-q1-pr2/`.

## 12. Cross-Product Coverage

No claim or code was transferred to `DRM.jl`, `gllvmTMB`, or `GLLVM.jl`.
`drmTMB` remains the primary R/TMB implementation and Julia remains optional.
Mission Control now records the HOLD and exact no-PR boundary. No public site
or generated capability surface changed because the feature did not land.
This stopped arc does NOT cover REML, penalized/MAP estimation, another engine,
missing-response handling, aggregation, intervals, coverage, q2/q4 providers,
or any structured provider other than the exact univariate Beta `phylo()` cell.

## 13. Next Actions

Stop this arc with the implementation preserved branch-only. Do not open PR 2,
promote the ledger, rerun or filter the stopped campaign, replace seed
`2099879627`, or alter its gate. A future arc requires Shinichi's explicit goal
and a prospectively frozen interior-response DGP. The separate hierarchical-
`sd()` subarc remains later and must not be bundled into that decision.
