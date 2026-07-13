# After Task: Arc 4a closeout and marginal-Gauss-Kronrod probe

## 1. Goal

Repair sigma-scale prediction for lognormal and Gamma models, replace the
invalid Arc 4a population-SD coverage evidence, promote `mc-0382` and
`mc-0061` only if corrected evidence passes fresh D-43 review, refresh the
ledger-derived capability surface, and test TMB 1.9.21 adaptive marginal
Gauss-Kronrod against `glmer(nAGQ=25)` without wiring a new package engine.

## 2. Implemented

`has_sigma_random_effects()` now recognizes lognormal and Gamma fits, so
`predict(..., dpar = "sigma")` includes the fitted sigma random-effect BLUP on
the link and response scales. The existing `sigma()`, print, and emmeans
preflight paths now use the same capability decision.

The Arc 4a generator now simulates iid uncentered random effects, records raw
and summary denominators, and reports coverage MCSE plus exact binomial
intervals. Totoro ran all three specifications at `M={8,16,32,64}` with 1,200
replicates per cell: 14,400 fits, 14,400 finite profiles, and zero fit,
convergence, Hessian, or profile failures. Fresh Noether, Fisher, and Pat D-43
reviews returned DONE for two narrow promotions:

- `mc-0382`: lognormal sigma random intercept, true SD 0.4, `n_each=12`, and
  exactly `M={16,32,64}`; coverage 0.9325, 0.9242, and 0.9408;
- `mc-0061`: independent binomial mu random slope, true SD 0.6, 12
  observations per group, 12 trials per observation, and exactly `M={32,64}`;
  coverage 0.9492 and 0.9525.

Both cells are `inference_ready_with_caveats`, never `interval_feasible` or
`supported`. Their claims say mildly anti-conservative rather than nominal and
do not extrapolate beyond the tested designs.

The capability generator now derives family summaries from the live ledger,
keeps fixed, ordinary, and structured effects separate by distributional
parameter, derives REML only from REML cells, and distinguishes absent routes
from explicit rejection. The tracked HTML is regenerated from that contract.

The standalone Task B probe compiled a TMBad binomial random-intercept template
and compared ordinary Laplace, TMB adaptive marginal Gauss-Kronrod,
`glmer(nAGQ=1)`, `glmer(nAGQ=25)`, and a direct sum of 40 independent adaptive
integrals. The approved gate returned a negative/inconclusive result. The TMB
normalized objective differed from the direct oracle by about `1.068e-9`,
versus a propagated normalized numerical-error estimate of about `2.984e-10`.
The fixture was boundary-singular, so parameter agreement at an identified
interior optimum was not assessable. No drmTMB integration path was added.

## 3. Mathematical Contract

For a log-link sigma predictor, a fitted row uses

\[
\eta_{\sigma,i}=x_{\sigma,i}^{\mathsf T}\beta_\sigma+b_{\sigma,g[i]},
\qquad \sigma_i=\exp(\eta_{\sigma,i}).
\]

Population-level `newdata` prediction excludes the fitted BLUP. The regression
tests assert both contracts for lognormal and Gamma.

The corrected campaign draws (b_g\overset{\mathrm{iid}}{\sim}N(0,\tau^2))
without subtracting the realised mean, and scores the profile interval against
the same population SD \(\tau\). Coverage uses all 1,200 eligible replicates in
every cell; directional misses and failures remain separate counts.

For Task B, each group's direct marginal likelihood is

\[
L_g(\theta)=\int
\prod_{i\in g}p_i(z)^{y_i}\{1-p_i(z)\}^{1-y_i}\phi(z)\,dz,
\qquad
p_i(z)=\operatorname{logit}^{-1}(x_i^{\mathsf T}\beta+\sigma_b z).
\]

The direct objective is \(-\sum_g\log L_g\). Each
`stats::integrate()` absolute-error estimate is propagated through `-log()`,
then the evaluated-point and truth-reference estimates are added for the
normalized-objective comparison.

## 3a. Decisions and Rejected Alternatives

- The centered v1 campaign remains in the repository for provenance but is
  rejected as population-SD promotion evidence. Reinterpreting its target after
  the fact would hide the estimand mismatch.
- `interval_feasible` is rejected for both promotions because it denotes a
  computable interval without coverage evidence. The corrected campaign
  supports the higher but explicitly caveated
  `inference_ready_with_caveats` tier over discrete tested domains.
- A nominal-coverage or `supported` claim is rejected: lognormal coverage is
  mildly anti-conservative, and binomial directional misses do not justify a
  nominal label even though the promoted cells straddle 0.95.
- Task B package wiring is rejected by the approved gate. The mechanism is
  structurally active, but its normalized objective lies outside the recorded
  direct-oracle error envelope and the fixture has no identified interior SD
  optimum. Task C and merge remain deferred by plan.

## 4. Files Touched

- Prediction repair and tests: `R/methods.R`,
  `tests/testthat/test-arc2c-sigma-random-intercept.R`, and `NEWS.md`.
- Corrected campaign: `generate-profile.R`, the superseded-v1 README, and the
  iid-v2 README, raw, summary, manifest, and campaign log under
  `docs/dev-log/simulation-artifacts/2026-07-12-dg3-re-sd-coverage/`.
- Ledger and surface: `cells.tsv`, `evidence.tsv`, `transitions.tsv`,
  `tools/capability_ledger.py`, its 13-test unit suite, 30 generated outputs,
  and `docs/dev-log/dashboard/capability-surface.{md,html}`.
- Task B: the complete standalone source, fixture, result tables, manifest, and
  README under
  `docs/dev-log/simulation-artifacts/2026-07-13-marginal-gk-probe/`.
- Current-facing status: `AGENTS.md`, `README.md`, `ROADMAP.md`, `NEWS.md`,
  family registry, formula grammar, readiness and evidence maps, worked-example
  inventory, known limitations, the distribution-family/model/source/
  implementation-map vignettes, the campaign plan, historical supersession
  notes, this report, and `docs/dev-log/team-improvements.md`.
- One unrelated but exposed metadata repair:
  `estimator-surface-conformance.tsv` now points to the current source line for
  the unchanged phylogenetic residual-scale rejection.

## 5. Checks Run

- `pkgload::load_all(".")` plus the Arc 2c file: 52 focused assertions passed.
- Campaign raw-table recomputation matched all 12 summaries; all denominators
  and miss identities passed. Totoro used 64 workers and
  `OPENBLAS_NUM_THREADS=1`.
- `python3 -m unittest tools.tests.test_capability_ledger`: 13 tests passed.
- `python3 tools/capability_ledger.py --write` and `--check`: all 30 generated
  outputs current.
- `tools/check-capability-runtime.R`: 18 routes, G0=G1=G2=0, verified=18.
- Task B reruns reproduced the fixture, fit, best-returned-candidate, and
  objective-grid hashes. Final Noether/Gauss review returned DONE after two
  numerical-accounting corrections.
- Full `devtools::test()`: exit 0, zero failures, 62 known warnings, and 24
  unavailable-Julia skips.
- `rcmdcheck::rcmdcheck(args = "--as-cran")`: 0 errors, 0 warnings, one
  expected development-version/new-submission NOTE; 8 minutes 33.5 seconds.
- Full `pkgdown::build_site(preview = FALSE)` and `check_pkgdown()`: no
  problems. A final post-Rose `pkgdown::build_articles()` and
  `check_pkgdown()` also found no problems after all current-facing repairs;
  rendered read-back confirmed the separate positive-continuous gates, the
  cannot-combine boundary, and binomial's ordinary random-effect first slices.
- HTML DOM read-back: 295 implemented, 333 rejected by design, 40 not
  implemented, and 18 `inference_ready_with_caveats`; both promoted rows and
  the lognormal/binomial family summaries are present.
- `git diff --check`: clean. Capability HTML SHA-256:
  `225272ea0abdc5eb89893c5f7462b59fcaae3ee1880b7af45d2cad02aa5d1f47`.
- Rose's final repaired-tree audit returned DONE after independently rerunning
  the ledger/generator/runtime gates, after-task validator, diff check, rendered
  five-article boundary read-back, and HTML hash. This authorizes commit, push,
  and PR refresh; it does not claim the external Claude artifact is refreshed.

## 6. Tests of the Tests

The fitted prediction assertions were run against clean pre-fix `HEAD` in a
temporary worktree and produced 10 expected failures: both families omitted
the sigma BLUP, the linked response value, and the emmeans preflight signal.
The temporary worktree was removed afterward.

The corrected campaign preserves the centered v1 TSV rather than overwriting
it. A smoke campaign and Noether's iid-DGP/estimand review preceded the Totoro
launch. Independent raw recomputation, rather than the generator's summary
alone, established the reported counts.

Task B's first adversarial review returned NOT-DONE because
`stats::integrate()` errors were still on the probability scale. The rerun
propagated them through `-log()` and combined point/reference estimates. A
second NOT-DONE corrected “bound” to “estimate”; only the third review returned
DONE. These corrections did not change the negative verdict.

## 7a. Issue Ledger

Open issues with overlapping profile/coverage/random-effect terms were
inspected. Issue #682 is the broad profile-likelihood methods issue. It was not
changed before branch landing because the focused branch PR is the coherent
place for the corrected evidence and exact two-cell boundaries; no duplicate
issue was opened.

## 8. Consistency Audit

The status inventory covered `README.md`, `ROADMAP.md`, `NEWS.md`, known
limitations, the family registry, formula grammar, Phase 18/readiness/evidence
maps, the worked-example inventory, all current family/model/source/
implementation-map vignettes, and `_pkgdown.yml`. Rose's first pass found that
several reader surfaces still called binomial fixed-only and lognormal/Gamma
sigma random effects planned. A second pass caught an overcorrection that
showed unsupported combined `mu`+`sigma` random effects. The final wording now
shows separate positive-continuous mean-side and scale-side gates, explicitly
rejects their combination, and limits caveated inference to the exact two
ledger domains. No formula syntax or likelihood parameterization changed.

Exact searches included:

```sh
rg "has_sigma_random_effects|predict\\(.*dpar.*sigma|sigma random (intercept|effect)|lognormal.*Gamma|Gamma.*lognormal" README.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md docs/design vignettes _pkgdown.yml R tests/testthat
rg "HALF done|0\\.917|0\\.943|M≥|M >=|interval_feasible promotion|AGHQ Slice 0|approximately unbiased SD|mechanism reproduced" AGENTS.md README.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md docs/design vignettes docs/dev-log/2026-07-13-next-arcs-codex-campaign-plan.md docs/dev-log/handover/2026-07-13-codex-handover.md
rg "binomial random effects|fixed-effect.*binomial.*event|outside .*ordinary NB2 intercept gate|lognormal.*sigma random effects.*planned|Gamma.*sigma random effects.*planned|Student-t, lognormal, Gamma.*fixed-effect" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes
```

Historical reports remain intact but carry supersession notices where they are
still likely entry points. The live generator, ledger, tracked HTML, canonical
design maps, README/NEWS/ROADMAP, known limitations, and rendered pkgdown site
now tell the same bounded story.

## 9. What Did Not Go Smoothly

The original 7,200-fit campaign was invalid for its claimed estimand because
the generator mean-centered every realised random-effect vector. That result
is preserved for provenance but withdrawn from promotion evidence.

The first Task B memo compared numerical errors on unlike scales. Noether also
caught that `stats::integrate()` reports an estimate rather than a guaranteed
bound, and that boundary parameter differences cannot be compared
dimensionally with an objective-error envelope.

The first final-tree package run exposed a stale source-line citation in the
estimator conformance table. The unchanged guard had moved from line 11479 to
11673. The row was repaired, the focused file passed, and the full suite was
rerun from the beginning.

## 10. Known Residuals

The two promoted routes are mildly anti-conservative and apply only to the
discrete tested domains. They are not nominal, `supported`, general
`M>=` claims, or evidence for neighboring SDs, replication, trials, correlated
effects, labelled blocks, REML, or structured effects. Gamma sigma random
intercepts retain point-recovery evidence only.

Task B does not establish unbiasedness, a usable interior optimum, or package
support for marginal Gauss-Kronrod. It cannot support `mc-0061`, which is a
random slope rather than the random-intercept fixture. AGHQ package wiring,
broader bias/recovery work, Task C, DRAC, GitHub Actions compute, and any merge
remain deferred.

Claude's external artifact `a1bf21a1` is not refreshed by this local work. The
tracked HTML, generator command, final branch commit, and SHA-256 must be handed
to Claude for mirroring; until Claude imports it, the mirror remains pending.

## 11. Team Learning

Two durable rules were added to `docs/dev-log/team-improvements.md`: coverage
DGPs must declare and match their estimand, and numerical error estimates must
be transformed onto the same objective scale—including the normalization
reference—before they support a gate.

The capability surface must be generated from the live ledger rather than a
frozen family table. Missing routes, explicit rejections, REML support, and
evidence tiers are separate axes and must remain separate in aggregation.

## 12. Cross-Product Coverage

The A0 repair covers fitted link/response sigma prediction, population-level
same-row `newdata`, `sigma()`, printed sigma random-effect counts, and emmeans
preflight for lognormal and Gamma independent sigma random intercepts. It does
NOT cover sigma slopes, labelled covariance, combined mu-plus-sigma random
effects, structured sigma effects, REML, or other non-Gaussian families.

The Arc 4a promotion covers exactly one lognormal sigma-intercept cell and one
binomial independent mu-slope cell over their recorded discrete designs. It
does NOT cover Gamma intervals, `M>=` extrapolation, untested SDs/replication/
trials, nominal coverage, correlated or structured effects, `supported`, or
any package-wide inference promise.

The surface-generator repair covers live-ledger family aggregation, separate
dpar/effect/provider status, REML provenance, evidence-tier ordering, and
preservation of the missing-response and `mi()` boards. It does NOT convert an
absent route into a rejection, infer REML from ML, or promote neighboring cells.

Task B covers only the standalone 40-group binomial random-intercept fixture
and objective-mechanism comparison. It does NOT cover a drmTMB engine path,
AGHQ, unbiasedness, multiple fixtures, random slopes, `mc-0061`, Task C, or a
greenlight for package integration.

## 13. Next Actions

1. Obtain Rose's final systems audit and repair every blocking discrepancy.
2. Commit and push `feature/arc4a-profile-coverage`; update or open its PR, but
   do not merge.
3. Run the handoff gate and write the Claude handoff with the canonical HTML
   path, generator command, commit SHA, and HTML SHA-256.
4. Ask Claude to mirror the tracked HTML into `a1bf21a1`; report that external
   refresh as pending until confirmed by Claude.
