🎯 GOAL
Solo platform: Codex
Deliverable: A reviewable implementation plan and Unlazy ledger for a Gaussian phylogenetic-stable-intercept plus independent-series OU model, with a separate future phylogeny-by-OU field and a ranked temporal-covariance roadmap.
HEADLINE: Estimate evolutionary baseline similarity, within-species persistence, and observation noise as three distinct variance sources.
IN PARALLEL: After native integration is stable, recovery/calibration preparation and reader documentation can proceed on disjoint paths.
DEFER: The separable phylogeny-by-OU field, Toeplitz/heterogeneous temporal structures, ARMA, trends, seasonality, Matérn, forecasts, temporal slopes, non-Gaussian families, and a gllvmTMB port.
DISCIPLINE: verify=independent dense covariance oracle plus retained failures · compute=local pilot then Totoro rehearsal and DRAC/Fir retained campaign only after approval · closure=all runnable gates reverified, independent math and reader review, rendered article, package check, after-task report, and a clean local commit.

# Plan status

This is a plan-only artifact. No implementation approval is asserted here. The
execution worktree must pin the completed OU source before it starts: the
planning source is clean at `73a440c3b` but is 67 commits ahead of
`origin/main` as measured on 2026-09-09. G0 requires an explicit source and
integration decision; no execution may silently assume the local OU branch has
already landed.

## Scientific contract and locked first slice

The first slice admits univariate Gaussian ML with fixed mean predictors,
offsets, `sigma ~ 1`, one phylogenetic stable intercept, and one within-species
OU process:

\[
y_{it}=x_{it}^{T}\beta+b_i+a_{it}+\epsilon_{it},
\qquad b\sim N(0,s_b^2 A),
\]
\[
\operatorname{Cov}(a_{it},a_{js})=\mathbb{1}_{i=j}s_a^2
\exp\{-\lambda|t-s|\},
\qquad \epsilon_{it}\sim N(0,\sigma^2).
\]

`A` is the phylogenetic covariance implied by the existing validated `phylo()`
tree path, with its current tip matching, scaling and precision construction.
The execution slice must document that exact normalization rather than invent a
second tree convention. The two latent components and residual noise are
independent. For observed rows `r` and `q`, the dense reference covariance is

\[
V_{rq}=s_b^2 A_{i_r i_q}+
\mathbb{1}_{i_r=i_q}s_a^2\exp\{-\lambda|t_r-t_q|\}+
\mathbb{1}_{r=q}\sigma^2.
\]

This is deliberately **not** the separable field
\(s_a^2 A_{ij}\exp\{-\lambda|t-s|\}\). That later model permits correlated
temporal departures among related species and changes both the likelihood and
the scientific estimand.

The native/dense agreement suite must retain four named reductions: (1) set
\(s_b=0\) to recover the completed independent-series OU covariance; (2) set
\(s_a=0\) to recover the existing phylogenetic stable-intercept covariance;
(3) set \(A=I\) to recover the ordinary same-ID intercept plus independent OU
covariance; and (4) on unit-spaced elapsed time set
\(\phi=\exp(-\lambda)\), so only the within-species component becomes
\(\mathbb{1}_{i=j}s_a^2\phi^{|t-s|}\), while the full covariance retains
\(s_b^2 A_{ij}\) and \(\mathbb{1}_{r=q}\sigma^2\). The fourth reduction is
not a pure AR1 model and must not drop phylogenetic stable variation.

The dense-oracle suite must also assert the decisive non-separable entry: for
species \(i\ne j\), nonzero \(A_{ij}\), nonzero elapsed-time gap, \(s_a>0\)
and finite \(\lambda>0\), the first-slice covariance is exactly
\(s_b^2 A_{ij}\). The deliberately wrong separable value
\(s_b^2 A_{ij}+s_a^2 A_{ij}\exp\{-\lambda|t-s|\}\) is a required mutation
failure. This makes the future field mechanically distinguishable from the
first slice.

### Interface and admissions

The first-slice grammar is the explicit paired form:

```r
fit <- drmTMB(
  bf(y ~ treatment + phylo(1 | species, tree = tree) +
       temporal(1 | species, time = elapsed_days, structure = "ou"),
     sigma ~ 1),
  data = dat, family = gaussian(), REML = FALSE
)
```

The execution parser must recognize this pair as one named combined provider,
not as two unrelated structured terms. It must reject a different grouping ID,
an ordinary `(1 | species)` intercept, a second structured/temporal term,
REML, non-Gaussian families, weights other than one, temporal slopes,
`newdata`, and any tree/time metadata error before response omission. It must
require finite numeric elapsed time, unique species--time keys, a tree whose
tips match the observed species, at least three observed species, at least two
distinct times per observed species, and at least three distinct positive lags
across the data. Counts may differ among species; input order may not alter the
fit.

Report `sd_phylo_stable`, `sd_temporal`, `decay_temporal`, and `sigma` with
those meanings. Stable phylogenetic variation must never be labelled as an OU
process SD, and the OU SD must never be called an innovation SD.

### Inference, prediction and simulation boundary

The first public uncertainty target is a fixed-`mu` likelihood profile only,
provided deterministic dense profile agreement and a new calibration campaign
both pass. No Wald covariance claim transfers from the independent OU model.
Variance, decay, bootstrap, forecast and `newdata` intervals remain
unavailable. Fitted values, residuals, conditional modes and simulation are
required: fresh simulation draws `b` from `s_b^2 A` and independent OU paths
per species; conditional simulation retains both fitted latent components.

### Predeclared recovery and profile-calibration contract

Recovery retains 24 deterministic data sets: 12 balanced and 12 unbalanced
layouts spanning \(s_b=(0.3,0.6,1.0)\), \(s_a=0.8\),
\(\sigma=0.4\), and decay \(=(0.15,0.4,0.7)\), with two positive-decay
starts per fit. It preserves all 48 attempts, component labels, warnings and
source fingerprints. Before results are read, the selected-fit requirements are
at least 22 finite fits; mean absolute fixed-effect error at most 0.15; median
absolute log-SD error at most 0.25 across \(s_b,s_a,\sigma\); and median
absolute log-decay error at most 0.35. A failure is retained and diagnosed, not
removed by changing seeds or thresholds.

The 95% profile campaign uses the production two-start ML engine and profiles
all three fixed mean coefficients for \(\beta=(0,0.5,0.5)\). One centered,
balanced predictor varies among species and one is independently balanced
within species. Temporal effects are generated from independent dense Cholesky
factors and stable effects from the fixed deterministic phylogenetic covariance
used by each cell. The predeclared cells are:

| Cell | Species and occasions | \(s_b,s_a,\sigma\) | Decay | Role |
| --- | --- | --- | --- | --- |
| P1 | 80 species × 6 irregular occasions | 0.6, 0.8, 0.4 | 0.40 | Primary short series |
| P2 | 80 species × 12 irregular occasions | 1.0, 0.8, 0.4 | 0.15 | Primary strong phylogenetic and persistent signal |
| P3 | 80 species with 4–12 irregular occasions | 0.6, 0.8, 0.4 | 0.70 | Primary unbalanced series |
| P4 | 20 species × 6 irregular occasions | 1.0, 0.8, 0.4 | 0.15 | Stress only |

P1–P3 each have 1,000 generated data sets; P4 has 500. Every primary
coefficient-cell denominator is all 1,000 generated data sets. Missing or
non-finite endpoints count as unavailable and uncovered in that denominator.
The summary reports availability, all-attempt and conditional coverage, lower
and upper tail error separately, bias, empirical SD, mean profile width, all
warnings, failures and runtime. A primary row qualifies only if availability is
at least 0.99, coverage plus or minus one binomial Monte Carlo SE lies within
0.925–0.975, absolute bias is at most 0.10 empirical SD, and mean profile
width divided by \(3.92\) empirical SD lies in 0.90–1.10. P4 is reported as
stress evidence and never used to promote a nominal-coverage claim.

## Future phylogeny-by-OU field

A later, separately approved provider may estimate

\[
\operatorname{Cov}(a_{it},a_{js})=s_a^2 A_{ij}\exp\{-\lambda|t-s|\}.
\]

It must have a new formula marker, a different dense oracle, separable
precision/determinant design, its own simulation and profile calibration, and
its own reader example. It may not be added as an undocumented flag to the
paired first-slice grammar. No conclusion from the first slice validates this
field.

## Prior-work receipt

| Surface | Evidence inspected | Verdict |
| --- | --- | --- |
| Current drmTMB lane | `git status -sb`; `git rev-list --left-right --count origin/main...HEAD`; all-branch log; completed OU plan/ledger; `R/` and `src/drmTMB.cpp` provider map | Reuse the completed OU state process and existing phylogenetic precision provider. Build only their unimplemented paired interaction and the dense marginal oracle. |
| Existing issue | [#1302](https://github.com/itchyshin/drmTMB/issues/1302) | Resume its exact first-slice decision: stable phylogenetic intercept plus independent OU, not the separable field. |
| gllvmTMB | `rg --files` plus `rg -n -i 'temporal|ornstein|autocorr|ar1|ou' R src tests docs vignettes` | No reusable temporal provider was found. Its phylogenetic latent infrastructure is conceptually relevant but is not an observation-level OU implementation. |
| glmmTMB | Official [covariance vignette](https://glmmtmb.github.io/glmmTMB/articles/covstruct.html), official [reference](https://glmmtmb.github.io/glmmTMB/reference/glmmTMB.html), and current-source enumeration | Learn covariance parameterizations and boundary warnings; do not copy its factor-level time interface or extend scope merely because it has more structures. |
| Brain | `basic-memory tool search-notes 'drmTMB phylogenetic temporal OU separable covariance' --hybrid`; deterministic searches over `memory/AGENT_LOG.md`, `memory/DECISIONS.md`, `memory/OPEN_QUESTIONS.md`, and `projects/deep-research/README.md` | Reuse the standing separation of structured variance sources and the rule that calibration does not transfer between estimands. No completed phylogenetic OU implementation was located. |

## What glmmTMB has, and the roadmap it suggests

glmmTMB's documented covariance menu includes AR1, OU, heterogeneous AR1,
heterogeneous and homogeneous Toeplitz, diagonal, compound-symmetric,
unstructured, exponential, Gaussian and Matérn structures. Its current source
also enumerates proportional and equal-correlation structures. Several of its
structured-covariance options are marked experimental in the reference manual.
That is a source map, not an implementation order for drmTMB.

| Priority after the phylogenetic-OU programme | Structure | Scientific use | Admission boundary |
| --- | --- | --- | --- |
| 1 | Homogeneous Toeplitz | Correlation at each discrete lag when decay is not plausibly AR1 | Equal, discrete occasions; enough repeated series to estimate one correlation per lag. |
| 2 | Heterogeneous AR1 | AR1 persistence with occasion-specific process SDs | Strong reason for changing temporal variability and replication at each occasion. |
| 3 | Heterogeneous Toeplitz | Both lag correlations and occasion SDs vary | Large balanced panel; high parameter count makes it unsuitable as a default. |
| 4 | Seasonal, trend/random-walk, ARMA, temporal Matérn | Cycles, nonstationarity, oscillation or different smoothness | A named scientific mechanism and a separate design/validation programme. |

Spatial exponential/Gaussian/Matérn are distance kernels, not replacements for
the discrete-time structures above. Existing drmTMB phylogenetic and spatial
providers remain separate covariance axes; this plan does not create a generic
spatiotemporal provider.

## Slices, dependencies and planned routing

No sub-agent is dispatched in this planning task. The table is the execution
route after G0. S1--S4 are sequential because they share the parsed provider
contract. S5 and S6 may overlap after S4 because their files are disjoint.

| Slice | Member/lens | Model and dispatch | Files/decision | Depends on | Estimate |
| --- | --- | --- | --- | --- | --- |
| S0: freeze and interfaces | Ada | Terra medium, native/explicit | Pin source; write formula grammar, covariance labels, source-map and runner contract | G0 | 2–3 h |
| S0a: prior-art source map | Ranga | Terra medium, native/explicit | Bounded NotebookLM corpus and cited distillation: distinguish phylogenetic stable effects, independent temporal effects and separable fields | G0 | 2–4 h |
| S1: parser/layout | Boole | Terra high, native/explicit | `R/` parser/layout plus malformed-input tests | S0 | 4–6 h |
| S2: native provider | Gauss | Terra high, native/explicit | `src/drmTMB.cpp`; paired phylo-stable and independent OU likelihood | S1 | 6–9 h |
| S3: independent oracle | Curie | Terra medium, native/explicit | dense covariance, score/Hessian/profile/mode/simulation references and mutations | S2 | 6–8 h |
| S4: public methods | Emmy | Terra high, native/explicit | extractors, diagnostics, profile target boundary, simulation and S3 parity | S2–S3 | 4–6 h |
| S5: recovery/calibration | Fisher and Curie | Terra medium, native/explicit | retained recovery, timed pilot, campaign specification and fail-closed assessment | S4 | 5–8 h plus compute |
| S6: article and reference docs | Pat | Terra medium, native/explicit | phylogenetic-temporal article, reference/design docs, render inspection | S4 | 3–5 h |
| S7: independent plan and math review | Noether | Astra high, native/explicit | bounded adversarial check of covariance reductions, oracle and profile target | S0, before S1 | 1–2 h |
| S8: integration | Ada, Rose | Terra high, native/explicit | reverify gates, package check, after-task and plan-vs-actual reconciliation | S5–S7 | 3–5 h |

S0a supplies literature context for the reader article and covariance roadmap;
it does not decide the native likelihood or establish a novelty claim. The Astra
use is bounded to S7 because a wrong covariance decomposition could produce a
plausible but incorrect model; Terra is sufficient for the remaining
implementation and testing slices. Expected implementation effort is roughly
35–53 agent-hours in four sequential batches, plus campaign compute. The
campaign size and target are deliberately unestimated: G10 measures a five-seed
pilot first. A campaign exceeding 30 minutes needs G12's measured plan and
explicit authorization. Use Totoro for bounded rehearsal and durable storage;
use a DRAC/Fir array for retained claim-bearing calibration, never a login node
or GitHub Actions.

## Execution order and pre-authorisation envelope

1. G0 pins the source, the ownership lease and this plan revision.
2. S0–S4 establish the parser, native likelihood, independent oracle and public
   profile boundary. No uncertainty claim is made yet.
3. S0a and S5/S6 may overlap after their dependencies resolve. S0a supplies a
   cited source map; S5 stops after its announced pilot budget and writes a
   campaign proposal from measured resources; S6 renders the article.
4. G12 is the only campaign authorization gate. G13 recomputes immutable
   results and never launches a second campaign.
5. S8 rechecks every runnable gate, obtains Noether and Pat reviews, runs
   package checks and writes the after-task and plan-vs-actual reports.

After G0, the authorized reversible envelope is scoped edits, routine local
commands, tests/builds, local rendering, checkpoints and local commits. Remote
campaign submission, push/merge, release, deployment and external messages
remain separately authorized. A campaign is never implied by a passing pilot.

## Plan review before execution

Rose must verify that the prior-work receipt is evidence-cited and that each
public claim has a matching gate. Noether must review the covariance formula,
all four reductions, and the dense-oracle independence before S1 begins. Pat
must confirm the article explains which variation is evolutionary, temporal and
residual, and never turns the qualified profile campaign into a general
inference claim.

## Questions still open for S0, not for silent implementation

- Confirm the exact existing `phylo()` covariance normalization used in the
  first-slice dense oracle and report it verbatim.
- Confirm whether the current temporal layout permits a species with only one
  retained response after omission; the planned first slice rejects it unless a
  mathematically justified alternative preserves the stated decomposition.
- Derive campaign cells after the timed pilot; they must vary phylogenetic
  signal, OU decay and sampling imbalance rather than repeat the independent
  OU grid.

## Plan-review receipt

- **Noether mathematical review:** initially found that the AR1 reduction could
  drop the stable phylogenetic covariance, that the non-separable boundary was
  not falsified, and that calibration was under-specified. The plan now fixes
  the entire unit-spaced covariance, adds an explicit wrong-separable-field
  mutation, and predeclares P1--P4, all-attempt denominators, tails, MCSE and
  qualification criteria. Re-review: `REPAIRS_ACCEPTED`.
- **Pat/Rose reader review:** initially found the same G5 ambiguity and asked
  that the dense-profile oracle be named independently. The revised G5/G8 make
  both points explicit. Re-review: `REPAIRS_ACCEPTED`.
