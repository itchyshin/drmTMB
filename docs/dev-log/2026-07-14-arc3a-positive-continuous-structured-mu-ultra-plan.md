```text
🎯 GOAL

Codex alone will deliver Arc 3a: native-TMB, univariate-ML, pure-mu,
unlabelled q1 structured random intercepts for the three missing
positive-continuous cells Gamma × phylo(), lognormal × phylo(), and
lognormal × relmat(), using the existing Gamma × relmat() route as the
positive comparator.

HEADLINE: complete the bounded Gamma/lognormal × phylo/relmat q1 grid with
real engine support and recovery evidence, without widening any neighbouring
model route.

IN PARALLEL after the symbolic and API freeze: Gauss implements the R/TMB
engine; Curie develops isolated tests and the recovery harness; Grace prepares
the capability-ledger migration; Pat prepares family-specific documentation.
Ada integrates only after their outputs agree.

DEFER: structured slopes; sigma random or structured effects; joint mu+sigma
models; multiple simultaneous providers; labels and q2+ covariance blocks;
spatial() and animal(); bivariate models; REML; intervals; coverage promotions;
supported claims; Julia expansion; and unrelated PR #781 work.

DISCIPLINE: reverify refreshed main and explicitly disposition PR #781 before
branching; write the symbolic equation → syntax → DGP → extractor → truth
alignment before code; smoke locally before remote compute; run recovery on
Totoro with OPENBLAS_NUM_THREADS=1 and no more than 96 cores; retain all
attempted fits and denominators; never use GitHub Actions for simulations;
require full tests, R CMD check, pkgdown, ledger validation, rendered-surface
inspection, and fresh Fisher/Noether/Rose review. Open a focused PR, but do not
merge it without Shinichi's authorization.
```

# Arc 3a positive-continuous structured-`mu` ultra-plan

## Outcome

Arc 3a met its bounded goal. The native engine, focused positive and negative
contracts, generated ledger, and reader surfaces now admit exactly the three
new q1 intercept cells. The 6,000-fit primary campaign certified
lognormal–`relmat()` and retained its predeclared phylogenetic intercept HOLD.
A separate fresh 2,400-fit addendum passed design-conditioned GLS-oracle and
structured-projection gates for Gamma–`phylo()` and lognormal–`phylo()`.
All three cells finish at `point_fit_recovery`; every deferred neighbour and
all interval, coverage, REML, inference-ready, supported, and Julia claims
remain outside the arc.

## Status at authorization

PR #780 is merged. Local `HEAD`, local `main`, and `origin/main` were verified
at `6b7c8f8345147577153194162cc74521d7801f1f` before branching. PR #781 is an
unrelated, open trust-dossier lane and is explicitly parked: Arc 3a neither
modifies nor merges it. The execution branch is
`codex/arc3a-positive-continuous-structured-mu` from refreshed `origin/main`.

## Claim boundary

The only new model cells are Gamma × `phylo()`, lognormal × `phylo()`, and
lognormal × `relmat()` for native ML, one unlabelled structured intercept in
`mu`, and one provider per fit. Gamma × `relmat()` is the positive comparator.
The maximum capability tier is `point_fit_recovery` after known-DGP evidence.
No neighbouring REML, interval, coverage, or `supported` claim is implied.

## Prior-work sweep

- Gamma already has generic structured-effect machinery and Gamma × `relmat()`
  recovery evidence.
- Lognormal currently constructs an empty structured object and needs real
  R/TMB likelihood plumbing.
- `mc-0386` and `mc-0388` represent broader q domains and must be split rather
  than directly promoted.
- DRM.jl may supply secondary parity context only; the R repo defines the API
  and evidence standard.
- External search is not required because this is an internal parameterization,
  engine, and validation problem.

## Symbolic floor

For the three target cells,

\[
\eta_{\mu i} = \mathbf{x}_i^\top\boldsymbol\beta_\mu
               + \mathbf{z}_i^\top\mathbf{b},
\qquad
\mathbf{b}\sim N(\mathbf{0},\tau_\mu^2\mathbf{K}_h).
\]

For lognormal, the structured SD is on log-response location. For Gamma, it is
on the log-mean predictor. The existing family-specific `sigma`
parameterizations remain fixed and unstructured. The detailed syntax, DGP,
TMB-parameter, extractor, and truth alignment must be reviewed before code.

## Slices

| Slice | Member · model/effort · estimate | Output | Dependency |
| --- | --- | --- | --- |
| S0 truth freeze | Ada · Sol/high · 20–30 min | refreshed base, parked #781, branch, plan | none |
| S1a symbols | Noether · Sol/high · 30–45 min | symbolic alignment memo | S0 |
| S1b API | Boole · Terra/high · 30–45 min | accepted/rejected syntax matrix | S0 |
| S1c ledger | Grace · Terra/medium · 30 min | row-split migration plan | S0 |
| S2a engine | Gauss · Terra/ultra · 2–4 h | Gamma-phylo admission and lognormal R/TMB block | S1a+S1b |
| S2b tests/harness | Curie · Terra/high · 1–2 h | focused tests and recovery runner | S1a+S1b |
| S2c ledger | Grace · Terra/high · 45–75 min | explicit q1 rows and preserved rejections | S1c |
| S3 integration | Ada+Gauss · Sol/high · 45–90 min | compiled package and green toy smokes | S2a+S2b+S2c |
| S4 evidence | Curie · Terra/high · 1–3 h wall | all-attempted Totoro recovery evidence | S3 |
| S5 surfaces | Grace+Pat · Terra/high · 1–2 h | docs, ledger, generated site surfaces | S4 |
| S6 verification | Fisher+Noether+Rose · Sol/high · 1–2 h | independent D-43 verdicts | S5 |
| S7 closeout | Ada+Rose · Sol/high · 45–60 min | checks, after-task, handoff, unmerged PR | S6 |

Parallel batches are S1a/S1b/S1c, S2a/S2b/S2c after the freeze, S5 docs/site,
and the three final reviews. Shared engine files have one owner. Integration,
smoke, compute, and landing are sequential gates. Estimated total is 8–12
focused hours plus Totoro and GitHub CI wall time; a durable handoff is expected
if the run crosses sessions.

## Validation and recovery gates

Before Totoro, each target cell must compile, fit one tiny known-DGP dataset,
return finite fixed-effect and structured-SD extraction with the correct
component label, and write a non-empty result containing the seed, attempted
status, convergence, `pdHess`, truth, estimate, and error. The neighbour matrix
must prove that slopes, labels/q2+, structured `sigma`, multiple providers,
spatial/animal, bivariate, and REML routes remain rejected.

The Totoro campaign starts with one cell and one seed. The first output is read
before scaling. `OPENBLAS_NUM_THREADS=1`; parallelism is capped at 96. Every
attempt is retained. Raw campaign output remains local and is never uploaded as
a GitHub Actions artifact. Fisher freezes numerical promotion thresholds before
the full run. A failing cell stays rejected or diagnostic-only.

## Closure

Required closure evidence is `devtools::document()`, focused and full tests,
`devtools::check()`, genuine `R CMD check --as-cran` where the branch gate
requires it, `pkgdown::check_pkgdown()`, capability-ledger validation, rendered
surface and Mission Control read-back, stale-wording audit, fresh Fisher,
Noether, and Rose verdicts, the eleven-section after-task report, a durable
handoff, and a focused pushed PR. Merge remains a separate Shinichi decision.
