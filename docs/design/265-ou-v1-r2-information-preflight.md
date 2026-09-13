# R2 information preflight for independent OU location and scale fields

## A — aim

R2 asks one decision-bearing question: under a strengthened, replicated
univariate Gaussian ML design, can the existing independent phylogenetic OU
intercept model estimate both `alpha_mu` and `alpha_sigma` closely enough to
justify designing—not launching—the later G15 campaign? This is an ADEMP
(Morris, White, and Crowther 2019) information preflight, not a coverage,
model-selection, or public-capability study.

## D — data-generating mechanism

For each of two ordered truths and five independent tree-plus-field seeds,
draw a rooted ultrametric tree with 128 tips and rescale it to root-to-tip
height one. For each field \(k\in\{\mu,\sigma\}\), draw the stationary
rooted OU process

\[
z_{k,c}\mid z_{k,p}\sim N\!\left(e^{-\alpha_k\ell}z_{k,p},
s_k^2\{1-e^{-2\alpha_k\ell}\}\right),
\]

with \((s_\mu,s_\sigma)=(0.45,0.25)\), zero fixed location intercept, and
fixed log-residual-scale intercept \(-1\). Each tip receives 12 observations,

\[
y_{ij}=u_i+\epsilon_{ij},\qquad
\epsilon_{ij}\sim N\{0,\exp(-1+v_i)^2\}.
\]

The two fields have independent random-number streams. The fixed factors are:

| factor | levels |
| --- | --- |
| `(alpha_mu, alpha_sigma)` | `(0.7, 1.3)`, `(1.3, 0.7)` |
| independent tree-plus-field seed | 5 per ordered pair |
| tips / observations per tip | 128 / 12 |
| natural-scale starts | `low`, `middle`, `high` |

This makes 10 logical datasets and 30 retained task-start attempts. It tests
only the stated field amplitudes and tree scale; it does not generalise over
amplitudes, tree distributions, families, response structures, correlation,
or temporal terms.

## E — estimands

The true targets are \(\alpha_\mu\) and \(\alpha_\sigma\). Fit the exact
intercept-only ML model

```r
bf(
  y ~ phylo(1 | species, tree = tree, model = "ou"),
  sigma ~ phylo(1 | species, tree = tree, model = "ou")
)
```

with the existing independent-field implementation. The alignment table is
the binding contract:

| Symbol | fitted term | DGP draw | extractor | truth |
| --- | --- | --- | --- | --- |
| \(u_i\) | `phylo(..., model = "ou")` in `mu` | stationary OU `s_mu` | `sdpars$mu` | 0.45 |
| \(v_i\) | `phylo(..., model = "ou")` in `sigma` | stationary OU `s_sigma` | `sdpars$sigma` | 0.25 |
| \(\alpha_\mu\) | `decay_phylo` | OU edge decay | `decaypars$phylo` | 0.7 or 1.3 |
| \(\alpha_\sigma\) | `decay_phylo:sigma` | OU edge decay | `decaypars$phylo` | 1.3 or 0.7 |
| \(-1\) | fixed sigma intercept | residual scale baseline | `par$sigma` | -1 |

## M — method

Every task is fit from the same three non-truth-dependent natural-scale
starts. Select the finite, convergence-zero, positive-definite-Hessian,
non-boundary attempt with minimum objective; otherwise record
`NO_QUALIFIED_START`. No attempt, warning, boundary, or error is replaced.

## P — performance and decision rule

For each rate separately report all-task numerical availability, median and
maximum absolute log-rate error \(|\log(\hat\alpha/\alpha)|\), and the
complete selected-fit denominator. Five logical replicates per rate pair are
too few for a general recovery or MCSE claim; they are deliberately a
mechanism screen. R2 supports no interval, coverage, selection, or OU-over-BM
claim. It permits a G15 design discussion only if both rates improve enough
that a larger multi-tree campaign is scientifically plausible.

Before the 30 attempts, run one largest-cell, three-start local timing smoke.
If a conservative projection of all 30 attempts exceeds 30 minutes, stop and
seek a separate compute decision; otherwise run locally. No R2 outcome
authorises G15 automatically.

## Reporting checklist

The runner retains trees, fields, response data, starts, all attempts,
selected fits, diagnostics, SHA-256 checksums, and source provenance. This
covers the relevant transparent-simulation reporting items of Williams et al.
(2024): aim, DGP, targets, method, performance measures, implementation,
seed-level retention, and an explicit limitation. References: Morris, White &
Crowther (2019), *Statistics in Medicine* 38:2074–2102; Williams et al.
(2024), *Methods in Ecology and Evolution* 15:1926–1939.
