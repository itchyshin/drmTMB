# Arc 1b-S2R admission matrix

## Positive predicate

The helper may return `TRUE` only when every condition below holds:

1. `spec$model_type == "biv_gaussian"` through the existing bivariate REML
   validator.
2. `spec$structured$phylo_mu$has` is true, its provider is `relmat`, and its
   representation is exactly `structure == "K"`.
3. `structured_mu_q()` is 2, endpoint dpars are exactly `c("mu1","mu2")`,
   and endpoint coefficient names are exactly two intercepts.
4. Both endpoints carry the same nonempty covariance label, one block ID, and
   one block label.
5. The existing relmat builder has already proved the same group, matrix
   symbol, representation, coefficient, and label in both formulas and has
   aligned named `K` to the observed factor levels.
6. `sigma1`, `sigma2`, and `rho12` each have an intercept-only fixed design.
7. There are no ordinary random effects or covariance blocks, no direct
   ordinary or structured scale models, and no corpair regression.
8. There is no `meta_V()`/known observation covariance; weights are all one;
   both responses are observed for every fitted pair.

This is a sibling exception to the spatial q2 predicate. Do not generalize the
spatial helper into a provider-wide gate unless tests prove the same fail-closed
conditions explicitly.

## Direct test matrix

| Case | Expected result |
| --- | --- |
| Exact matching labelled `K` intercepts | Admit and match oracle |
| Same formula under ML | Continue to fit unchanged |
| Term in only one endpoint | Reject in the existing matched-endpoint guard |
| Different groups, labels, matrix symbols, representations, or coefficients | Reject before REML admission |
| Same named `K` permuted identically in both formulas | Realign by names and fit to the canonical objective/parameters within `1e-6` |
| Missing matrix dimnames | Reject with the existing named-relatedness requirement |
| Duplicate row/column names | Reject with the existing uniqueness requirement |
| Matrix names differ from fitted group levels | Reject and name the unmatched levels |
| Different matrix symbols or representations across endpoints | Reject in the matching-matrix guard even if numeric values happen to agree |
| Unlabelled pair | Reject |
| Slope-only, intercept-plus-slope, multiple labels, q4/q6/q8/q12 | Reject |
| `Q=Q`, including a numerically equivalent `solve(K)` | Reject under REML; ML parity remains unchanged |
| `animal`, `spatial`, or `phylo` passed to the new helper | Return false; their existing routes decide admission |
| Structured term on `sigma1`/`sigma2`, q2-plus-q2, or scale-only | Reject |
| Predictor-dependent `sigma1`, `sigma2`, or `rho12` | Reject |
| Extra ordinary RE, direct-SD model, `corpair()`, or `meta_V()` | Reject |
| Missing response pair or non-unit weight | Reject |
| Non-Gaussian family or AI-REML | Reject at existing estimator/family gate |

## User-facing message

The bivariate REML error must name three admitted classes without implying
broad provider support: phylogenetic structured effects, the exact spatial q2
cell, and the exact supplied-`K` relmat q2 cell. Guidance must show the matching
labelled `relmat(1 | p | id, K = K)` syntax and state that `Q`, animal,
slopes/q4+, scale-side layers, known covariance, missing/weighted pairs, and
other shapes remain deferred for this exact **bivariate relmat REML** surface.
The message must not imply that existing univariate animal or relmat routes
are globally deferred.

## Test-of-test requirement

The exact target must be observed failing against base `d2104391` before the
code change. The independent dense objective must match at the optimum and two
displaced vectors under the tolerances in the symbolic note. The deliberately
wrong precision orientation must miss the first displaced objective difference
by more than `1e-3`. The negative matrix must run
through public `drmTMB()` calls, not source-string inspection alone.
