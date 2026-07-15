```text
🎯 GOAL

Codex alone will deliver Arc 1b-S1: native-TMB REML for the exact
bivariate-Gaussian, location-only, fixed-covariance spatial q2 intercept cell
that already fits under ML:

  mu1 = y1 ~ x1 + spatial(1 | p | site, coords = coords)
  mu2 = y2 ~ x2 + spatial(1 | p | site, coords = coords)
  sigma1 = ~ 1
  sigma2 = ~ 1
  rho12 = ~ 1
  family = biv_gaussian()
  REML = TRUE

HEADLINE: replace the representative non-phylogenetic bivariate REML rejection
with one exact, oracle-backed spatial q2 admission before considering animal,
relmat, scale-side q2, or q4.

IN PARALLEL after the symbolic/API freeze: Noether derives the restricted
likelihood and target alignment; Gauss maps the smallest R/TMB gate change;
Curie builds the independent oracle, rejection tests, and recovery harness;
Grace predeclares the ledger split and generated-surface migration. Ada
integrates only after these artifacts agree.

DEFER: spatial slopes; range estimation; animal and relmat; all sigma-side,
q2-plus-q2, mean-scale, and q4/q8/q12 blocks; non-Gaussian REML; AI-REML;
bridge expansion; interval or coverage promotion; supported claims; the
banked distribution-wide sd() arc; and unrelated PR #781.

DISCIPLINE: rehydrate from updated main only after Arc 3a is merged; freeze the
equation -> syntax -> DGP -> TMB parameter -> extractor -> oracle alignment
before code; prove the present rejection with a test-of-test; keep sigma1,
sigma2, and rho12 fixed-effect-only; smoke locally; run retained-denominator
recovery on Totoro or DRAC, never GitHub Actions; require full tests,
--as-cran, pkgdown, ledger/Mission-Control read-back, and fresh
Fisher/Noether/Rose review. Open a focused PR but do not merge it without
Shinichi's authorization.
```

# Ultra-plan — Arc 1b-S1 spatial q2 bivariate-Gaussian REML

## Decision

**Recommended next, but not authorized for execution.** Arc 1b-S1 closes one
known Gaussian REML/ML parity gap with a linear-Gaussian target and an
independent dense restricted-likelihood oracle. Existing ML cells `mc-0107`
and `mc-0108` already establish the same fixed-covariance spatial q2 model;
`mc-0199` records the current representative REML rejection. This makes the
first slice smaller and more falsifiable than opening a new family and a new
direct-SD likelihood path together.

The proposed distribution-wide `sd()` arc remains important Phase 4 work, but
its Beta example currently combines two absent capabilities: Beta
phylogenetic `mu` and a non-Gaussian direct random-effect-SD submodel. That
candidate should remain banked until its three prerequisite slices are
separated.

## Prior-work sweep

- Native ML already fits and extracts the spatial q2 intercept block for
  `mu1`/`mu2`; fixture parity and recovery evidence exist at the present
  point-fit tier.
- Native bivariate REML already has a fixed-effect restricted-likelihood
  reference and admits phylogenetic structured paths, so the estimator engine
  is not new.
- The current bivariate REML validator rejects every mean-side spatial block
  before q-specific dispatch. The implementation target is therefore a narrow
  admission rule plus any genuinely necessary estimator plumbing, not a
  covariance-engine rewrite.
- Spatial q2 interval evidence is not strong enough for promotion. This arc
  stops at `point_fit_recovery`; it does not borrow the phylo/relmat interval
  tier.

## Symbolic and API freeze

For response pair \(y_i=(y_{1i},y_{2i})^\top\), freeze

\[
y = X\beta + Zu + \varepsilon,\qquad
u \sim N(0,\,G\otimes K_{sp}),\qquad
\varepsilon \sim N(0,\,R\otimes I),
\]

where `G` is the q2 spatial mean-side covariance, `K_sp` is the exact
fixed-covariance matrix constructed from `coords`, and `R` contains constant
`sigma1`, `sigma2`, and `rho12`. The independent oracle evaluates

\[
\ell_R(\theta)=-\tfrac12\{\log|V|+\log|X^\top V^{-1}X|+
y^\top P_Vy+(n-p)\log(2\pi)\},
\]

with \(V=Z(G\otimes K_{sp})Z^\top+R\otimes I\) and
\(P_V=V^{-1}-V^{-1}X(X^\top V^{-1}X)^{-1}X^\top V^{-1}\).
The alignment table must name the two spatial SDs, their correlation, fixed
effects, residual parameters, coefficient order, covariance normalization,
and extractor names term by term.

## Slices and dependencies

| Slice | Member · model/effort · estimate | Output | Dependency |
| --- | --- | --- | --- |
| S0 truth refresh | Ada · Sol/high · 20–30 min | merged-main SHA, live ledger rows, parked unrelated PRs | Arc 3a merge + explicit GOAL approval |
| S1a symbolic oracle | Noether · Sol/high · 45–75 min | equation/syntax/DGP/oracle/extractor alignment | S0 |
| S1b admission matrix | Boole · Terra/high · 30–45 min | exact accepted cell plus direct rejected neighbours | S0 |
| S1c ledger plan | Grace · Terra/medium · 30–45 min | stable-ID split, evidence and transition plan | S0 |
| S2a test-of-test | Curie · Terra/high · 30–60 min | current-head rejection proof and frozen fixtures | S1a+S1b |
| S2b implementation | Gauss · Terra/ultra · 2–4 h | minimal validator/engine change | S1a+S1b |
| S2c oracle harness | Curie · Terra/high · 1–2 h | optimum and displaced-vector restricted-likelihood parity | S1a |
| S3 integration | Ada+Gauss · Sol/high · 45–90 min | compiled local fits, extractors, malformed-neighbour guards | S2a+S2b+S2c |
| S4 recovery evidence | Curie · Terra/high · 1–3 h wall | predeclared retained-denominator Totoro/DRAC ladder | S3 |
| S5 surfaces | Grace+Pat · Terra/high · 1–2 h | ledger, docs, pkgdown, Mission Control | S4 |
| S6 independent review | Fisher+Noether+Rose · Sol/high · 1–2 h | inference, math, and systems verdicts | S5 |
| S7 closeout | Ada+Rose · Sol/high · 45–75 min | full checks, after-task, handoff, unmerged PR | S6 |

Parallel batches are S1a/S1b/S1c and, after their freeze, S2a/S2b/S2c.
Integration, compute, promotion, and landing are sequential. Shared engine
files have one owner.

## Direct negative boundary

The accepted formula is intercept-only, matched, labelled, location-only,
fixed-covariance spatial q2. Direct tests must retain rejection of unmatched
endpoints, slope-only/intercept-plus-slope, multiple labels, q4 all-four,
scale-only q2, q2-plus-q2, range-estimating spatial forms, ordinary-plus-
structured mixtures outside the existing contract, non-Gaussian families,
and any `rho12` random effect. Animal/relmat remain separate candidates even
if the internal machinery looks reusable.

## Evidence and promotion gate

Local deterministic evidence must match the dense oracle at the optimum and
at displaced common parameter vectors, not merely return convergence zero.
The recovery design then varies the number of sites and replication per site,
retains every attempt, reports convergence, `pdHess`, boundary frequency,
bias, RMSE, MCSE, and information response for both SDs and their correlation,
and authenticates source and raw hashes. The maximum Arc 1b-S1 tier is
`point_fit_recovery`. Intervals, coverage, `inference_ready_with_caveats`, and
`supported` require a later approved campaign.

## Candidate comparison at Arc 3a closeout

| Candidate | Bounded first slice | Independent oracle/comparator | Main risk | Decision |
| --- | --- | --- | --- | --- |
| Arc 1b-S1 spatial q2 REML | One existing ML cell under REML | Exact dense restricted likelihood + current ML route | bivariate parameter ordering and REML gate scope | **Next** |
| Distribution-wide `sd()` | Beta example currently needs two new gates | Fixed Beta control only | parser + family likelihood + identifiability open together | Bank and split |
| Arc 4b coverage | Broad by default | Existing profile machinery | compute breadth and target-specific interval defects | Later bounded target |
| Arc 5 `mi()` | Can be bounded by family | Existing missing-data gates | lower current priority by maintainer decision | Later |
| Arc 6 mixed-family bivariate | Not yet | No common joint-likelihood oracle | combinatorial flagship | Post-0.6.0 |

## Stop gate

This document is planning only. Do not create the branch, change code, launch
compute, edit the ledger, commit, push, or open a PR until Shinichi approves
the copy-paste GOAL above after Arc 3a is merged and `main` is refreshed.
