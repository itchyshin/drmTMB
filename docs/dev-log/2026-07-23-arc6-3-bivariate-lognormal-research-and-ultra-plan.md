# Arc 6.3 exact bivariate-lognormal research and execution record

```text
PLATFORM: Codex. One bounded exact bivariate-lognormal model from clean origin/main.
HEADLINE: rho12 is log-response residual correlation, never eta or raw-scale correlation.
PARALLEL: prior-art curation, symbolic/API alignment, independent oracle and simulator.
DEFER: sigma/rho predictors, random or structured effects, incomplete pairs, weights,
offsets, meta_V, mi(), REML, Julia, intervals, coverage, capability claims, and CRAN.
DISCIPLINE: oracle and simulator before package likelihood; smoke before any campaign;
DRAC recovery only after separate approval; Rose closes.
```

## Sweep receipt

| Surface | Evidence run | Finding | Call |
| --- | --- | --- | --- |
| Repository state | `git status --short --branch`; `git log -1 origin/main`; `git worktree list` | Current checkout was dirty foreign AGHQ/REML work; `origin/main` is `44cf6271`. | Create clean `/private/tmp/drmtmb-arc6-3` worktree and do not touch the foreign lane. |
| Prior Arc 6 work | `docs/dev-log/handover/2026-07-23-codex-arc6-handover.md`; `docs/design/230-arc6-bivariate-series-overview.md` | 6.1--6.2 are frozen-margin `eta` models; 6.3 is explicitly an exact-special lognormal candidate. | Build the genuinely new direct likelihood, not another association wrapper. |
| Sister route | `rg -n "biv_gaussian|associate_pairs|lognormal" R src tests` | Existing bivariate Gaussian supplies formula/guard patterns only; univariate lognormal supplies response-scale semantics. | Separate `biv_lognormal()` type and explicit Jacobian. |
| Brain | `rg -n -i "Arc 6|bivariate lognormal" /Users/z3437171/.codex/memories/MEMORY.md` | Arc 6 preserves exact Gaussian `rho12` while staged pairs use frozen-margin `eta`. | Preserve estimand boundary. |
| External prior art | NotebookLM notebook `60264b87-22d6-4535-9baf-d283b87f0a37`; targeted source curation | The bivariate lognormal is established, and IFM is a distinct two-stage copula estimator. The limited corpus did not verify a direct drmTMB-equivalent comparator. | Make no novelty claim; use an independent density oracle rather than a false package comparator. |

## Curated sources and decision

- Ko and Hjort (2019), [Model robust inference with two-stage maximum likelihood estimation for copulas](https://doi.org/10.1016/j.jmva.2019.01.004), distinguishes IFM/two-stage estimation from full likelihood.
- Zhang, [Some measures on the standard bivariate lognormal distribution](https://www.math.unm.edu/~gzhang12/paper/correlation13.pdf), records the lognormal correlation transformation used here.
- Aitchison and Brown (1969), *The Lognormal Distribution*, is the classical source cited by the curated bivariate-lognormal material.

These sources establish neither priority nor a direct package comparator. The design decision is therefore pragmatic and transparent: expose the direct log-response residual correlation because it has an exact, stable model meaning for two positive lognormal responses; retain `associate_pairs()` separately for the frozen-margin question.

## Team review before implementation

- **Fisher:** require the two Jacobians, a transformed-scale independent oracle, exact joint simulator, and no inherited uncertainty or capability claim.
- **Gauss:** reuse only the guarded correlation and formula layout; use a new family/type, log-scale starts, and response means `exp(mu + sigma^2/2)`.
- **Rose:** use a clean `origin/main` lane; reject the Gaussian covariance, missingness, and `meta_V` machinery rather than accidentally inheriting it.

## Execution slices and gates

| Slice | Owner / tier | Output | Gate |
| --- | --- | --- | --- |
| Contract | Ada + Noether / Sol high | design 233 | equations, API, simulator, and oracle agree term-for-term |
| Family and builder | Terra high | R constructor and bounded spec | all deferred grammar fails before TMB |
| Likelihood | Terra high + Gauss review | dedicated C++ bivariate-lognormal branch | log transform only after positivity validation; two Jacobians |
| Methods | Terra high | prediction, `rho12()`, simulation | log-scale `rho12`; original-scale fitted means |
| Validation | Terra high + Fisher/Rose | focused source/integration tests | oracle, product, swap, input, and boundary tests |

No smoke or recovery campaign is authorized by this record. Any later recovery proposal needs its own immutable all-attempt ledger and explicit owner approval for Totoro or DRAC.
