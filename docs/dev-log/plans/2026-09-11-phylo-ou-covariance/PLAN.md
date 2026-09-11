🎯 GOAL

```text
Platform: Codex.
Deliverable: a Gaussian phylogenetic OU covariance option in `phylo()`, with Brownian motion retained as the default.
Headline: let an evolutionary random intercept decay with phylogenetic distance without confusing it with temporal OU, spatial kernels, or a phylogeny-by-time field.
Phases: lock the OU-tree contract -> parser/default -> native tree likelihood -> independent dense oracle -> methods and evidence -> separate scale-side child -> reader workflow and closure.
Agents: Ada/Terra medium owns integration; Boole/Terra high owns grammar; Gauss/Terra high owns the native tree prior; Curie/Terra medium owns the oracle and recovery; Noether/Astra high reviews the derivation; Pat/Terra medium checks the reader workflow.
Defer: phylogenetic-temporal interaction, temporal `sigma`, spatial OU, non-Gaussian routes, slopes, bivariate correlation blocks, and a gllvmTMB port.
Discipline: retain BM behaviour exactly; use `ape::corMartins` as an independent covariance reference; run only short local fixtures until a measured campaign is separately proposed; close with reviews, render, package check, report, and local commit.
```

## Why this is a new arc

The live `codex/phylo-ou-g12-prep-20260910` lane implements a different model: a Brownian phylogenetic intercept plus an independent **temporal** OU process. Its G13 profile-calibration verdict is currently unmet. This arc does not repair, continue, or inherit that model. It adds an evolutionary covariance choice to the existing phylogenetic marker:

```r
phylo(1 | species, tree = tree, model = "bm")  # existing default
phylo(1 | species, tree = tree, model = "ou")  # new evolutionary OU model
```

The code-bearing phase cannot claim the shared `phylo()` files until that live same-platform lane releases its overlapping ownership. This plan directory is the only scope claimed during orientation.

## Mathematical contract

For a phylogenetic random intercept `b`, BM retains the existing covariance `Var(b) = s_phylo^2 A_BM`. The initial OU option follows the Martins--Hansen stationary tree process used by `ape::corMartins`:

\[
\operatorname{Cov}(b_i,b_j)=s_{\mathrm{phylo}}^2 \exp\{-\alpha d_{ij}\},\qquad \alpha>0,
\]

where `d_ij` is patristic distance. Equivalently, root and branch transitions are

\[
u_{root}\sim N(0,1),\quad u_c\mid u_p\sim N\{e^{-\alpha\ell}u_p,1-e^{-2\alpha\ell}\},\quad b=s_{\mathrm{phylo}}u.
\]

The fixed intercept represents the common optimum. This gives an augmented-node sparse tree calculation rather than a dense inverse at every optimizer step. The new fitted parameter is `decay_phylo = alpha = exp(log_decay_phylo)`, evolutionary attraction per branch-length unit.

The stationary OU correlation approaches an all-ones matrix as `alpha` tends to zero and the identity as it grows. It is **not** a BM limit. BM stays an explicit default rather than an OU boundary. A dense `ape::corMartins` reference is the independent comparator.

## First admitted model and boundaries

Phase A is univariate Gaussian ML with one phylogenetic random intercept in `mu`, fixed predictors, offsets, and `sigma ~ 1`. It retains current tip matching and tree validation; it admits no ordinary random intercept or second structured term. Omitted `model` and `model = "bm"` must reproduce current behaviour. `model = "ou"` requires finite positive branch lengths and at least three observed species.

Point estimates, conditional modes, fitted values, residuals and seeded simulation are required. Fixed-mean profiles, coefficient covariance and all intervals remain unavailable until their own evidence qualifies them. The new decay parameter has no public interval in this phase. Diagnostics warn for a weak-correlation boundary or non-positive-definite Hessian.

The requested scale-side model is a second child: `sigma ~ phylo(1 | species, tree = tree, model = "ou")`. It has a separate scale-field decay parameter, identification study and simulation evidence. It cannot open merely because the location field fits.

## Evidence and acceptance order

| Phase | Owner and model | Result | Gate |
| --- | --- | --- | --- |
| A0 | Ada, Terra medium | source pin, ownership, exact OU-tree contract and failure-controlled gate runner | PO0--PO1 |
| A1 | Boole, Terra high | `model` grammar, default BM regression, invalid model/tree/branch errors | PO2 |
| A2 | Gauss, Terra high | stationary-root OU tree prior beside unchanged BM | PO3 |
| A3 | Curie, Terra medium | dense `ape::corMartins` likelihood, score/Hessian, root/edge transitions and mutations | PO4--PO5 |
| A4 | Emmy, Terra high | labelled decay extraction, diagnostics, modes, residuals and simulations | PO6 |
| A5 | Curie/Fisher, Terra medium | frozen local point-recovery fixtures and five-fixture measured pilot | PO7--PO8 |
| A6 | Pat, Terra medium | reference docs and reader workflow | PO9 |
| A7 | Noether, Astra high; Pat | independent math and reader reviews | PO10 |
| A8 | Ada/Rose, Terra high | reverify, package check, after-task report and local commit | PO11 |

The initial fixture set is 12 small Gaussian panels spanning low, moderate and high decay, balanced and unbalanced tree sampling, and shuffled rows. It retains every start and error. A fit-level feasibility result does not establish coverage. Any run estimated above three hours needs a measured plan and separate authorization; no remote campaign is proposed here.

## Deterministic reductions and mutations

The oracle checks dense covariance, marginal likelihood, score and two finite-difference Hessian step sizes. It must detect: BM covariance used under `model = "ou"`; missing root stationary density; use of temporal elapsed-time kernel; compressed branch lengths; a wrong `1-exp(-2 alpha l)` transition variance; shared states across independent trees; mismatched tip order; and a silent OU default.

Required limits are independent tips at large decay; positive off-diagonal correlation for finite decay; root/edge agreement with dense correlation; and unchanged BM output for omitted `model` and explicit `model = "bm"`. There is intentionally no BM-as-OU-boundary test.

## Sources and coordination

`ape::corMartins` documents `gamma * exp(-alpha * tij)` and cites Martins and Hansen (1997). The glmmTMB covariance vignette confirms OU as a positive continuous-decay correlation, but it is an observation-coordinate provider and is not copied into this phylogenetic path. Existing drmTMB tree code supplies the tip matching, Brownian validation and augmented-node conventions to preserve.

This is an approved orientation and documentation-only slice. Before A1, rerun lane preflight and claim the exact `phylo()` files. If the live phylo-temporal OU lane still owns them, wait or use an explicitly disjoint worktree; do not merge the two scientific models.
