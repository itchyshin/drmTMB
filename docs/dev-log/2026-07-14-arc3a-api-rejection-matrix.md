# Arc 3a API and rejection matrix

**Verdict: READY FOR ENGINE IMPLEMENTATION, with the boundaries below treated
as tests rather than suggestions.**

This note freezes the public formula surface for Arc 3a against base
`6b7c8f8345147577153194162cc74521d7801f1f`. The arc adds only three native-TMB,
univariate-ML, pure-`mu`, unlabelled q1 structured random-intercept cells:

1. `Gamma(link = "log")` × `phylo()`;
2. `lognormal()` × `phylo()`; and
3. `lognormal()` × `relmat()`.

The existing `Gamma(link = "log")` × `relmat()` route is the positive
comparator, not a fourth new capability. In particular, it already has an
independent intercept-plus-one-slope route and must not be narrowed by Arc 3a
(`tests/testthat/test-nongaussian-structured-mu-slope.R:1-41`).

## Accepted syntax

The canonical formulas below are the complete new user-facing surface. A
fixed-effect `sigma` formula may be omitted, in which case the existing family
default applies; writing it explicitly is preferred in tests and documentation.
`drm_formula()` and its `bf()` alias remain equivalent constructors
(`docs/design/01-formula-grammar.md:98-101`).

| Cell | Canonical accepted syntax | Structured coefficient and source |
| --- | --- | --- |
| Gamma × phylogeny | `bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ z)`, `family = Gamma(link = "log")` | One unlabelled `mu` intercept; one named tree object |
| Lognormal × phylogeny | `bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ z)`, `family = lognormal()` | One unlabelled `mu` intercept; one named tree object |
| Lognormal × relatedness covariance | `bf(y ~ x + relmat(1 | id, K = K), sigma ~ z)`, `family = lognormal()` | One unlabelled `mu` intercept; one named covariance/relatedness matrix |
| Lognormal × relatedness precision | `bf(y ~ x + relmat(1 | id, Q = Q), sigma ~ z)`, `family = lognormal()` | One unlabelled `mu` intercept; one named precision matrix |
| Existing comparator | `bf(y ~ x + relmat(1 | id, K = K), sigma ~ z)`, or the `Q = Q` form, `family = Gamma(link = "log")` | Existing q1 intercept route, unchanged |

The general formula parser also accepts the equivalent explicitly named
location entry, for example
`bf(mu = y ~ x + phylo(1 | species, tree = tree), sigma = ~ z)`. Arc 3a does
not introduce a second spelling or a family-specific marker.

### Marker contract

- `phylo()` requires exactly one structured bar term, exactly one named
  `tree =` argument, and a simple object name. The parser already enforces this
  and supplies an actionable canonical example
  (`R/parse-formula.R:562-582`, `R/parse-formula.R:612-635`).
- `relmat()` requires exactly one of `K =` and `Q =`, never both, and the matrix
  argument must be a simple object name (`R/parse-formula.R:669-692`). `K`
  means covariance/relatedness and `Q` means precision
  (`R/formula-markers.R:285-322`).
- The grouping expression must be a simple variable. The exact admitted left
  side is `1 | group`, which the parser records as `coef_names = "(Intercept)"`
  with no covariance label (`R/parse-formula.R:731-776`).
- `phylo()` requires an ultrametric tree with positive branch lengths, and all
  observed group labels must map to tree tips (`R/formula-markers.R:156-187`,
  `R/phylo-utils.R:247-269`).
- A `relmat()` matrix must have row/column labels covering every observed group
  level, be symmetric, and pass the existing covariance/precision validation
  (`R/phylo-utils.R:344-397`).

## Rejection matrix

Every row is a mandatory focused test for both new families where applicable.
“New cells” means Gamma–phylo, lognormal–phylo, and lognormal–relmat. The
Gamma–relmat exception is called out explicitly where existing behaviour is
broader.

| Neighbour | Representative formula | Required result | Stable message concept |
| --- | --- | --- | --- |
| Pure structured slope | `y ~ x + phylo(0 + x | species, tree = tree)` or `relmat(0 + x | id, K = K)` | Reject for all three new cells | Family/provider `mu` gate supports only an unlabelled q1 intercept |
| Intercept plus one slope | `phylo(1 + x | species, tree = tree)` or `relmat(1 + x | id, K = K)` | Reject for all three new cells | “intercept-only” and show the accepted `1 | group` form |
| More than one slope | `phylo(1 + x + z | species, tree = tree)` or the `relmat()` equivalent | Reject at parser or family gate | Existing parser phrase “intercept and one-slope structured terms”; family gate must not widen it |
| Labelled q2 request | `phylo(1 | p | species, tree = tree)` or `relmat(1 | p | id, K = K)` | Reject | “only unlabelled q=1 intercepts”; show the unlabelled form |
| Structured `sigma` | `bf(y ~ x, sigma ~ z + phylo(1 | species, tree = tree))` or `relmat(...)` | Reject | Arc 3a admits structured effects only in `mu`; keep `sigma` fixed-effect |
| Joint structured `mu` and `sigma` | Structured term in both formulas | Reject | Joint location-scale structured effects are deferred; fit the `mu` route alone |
| Two terms from one provider | Two `phylo()` terms or two `relmat()` terms in `mu` | Reject | “Only one `<provider>` structured effect is implemented in `mu`” |
| Multiple structured providers | `y ~ x + phylo(...) + relmat(...)` | Reject before optimization | “Only one structured `mu` provider at a time”; fit one provider and name both detected providers |
| `spatial()` | `y ~ x + spatial(1 | site, coords = coords)` | Reject for Gamma and lognormal in this arc | Only `phylo()` and the family-specific `relmat()` route are admitted; spatial remains deferred |
| `animal()` | `y ~ x + animal(1 | id, A = A)` | Reject | Same provider-scoped message; recommend neither silently nor via a generic parser failure |
| `phylo_interaction()` | Pair-level structured marker in `mu` | Reject | Bipartite interaction is outside the positive-continuous Arc 3a gate |
| Ordinary plus structured `mu` | `y ~ x + (1 | site) + phylo(1 | species, tree = tree)` (or new lognormal `relmat`) | Reject for the three new cells | No ordinary-plus-structured mixture in this recovery gate; fit one random layer |
| `mu` structured plus ordinary `sigma` random effect | `y ~ x + phylo(...), sigma ~ z + (1 | site)` | Reject | Pure-`mu` Arc 3a requires fixed-effect `sigma`; fit one variance layer |
| REML | Any accepted Arc 3a formula with `REML = TRUE` | Reject | Existing exact message: REML is implemented only for univariate and bivariate Gaussian models |
| Bivariate Gamma/lognormal | `mvbind(y1, y2) ~ ...`, explicit `mu1`/`mu2`, or mixed composed families | Reject | Family currently supports one positive response; mixed-response bivariate families are not implemented |
| Julia engine as Arc 3a evidence | Accepted formula with `engine = "julia"` | Do not route or count as the new native cell | Arc 3a is native TMB only; existing Julia experiments remain separate |

### Existing Gamma–`relmat()` exception

The new shared validator must be parameterized by family and provider. It must
not accidentally reject the already fitted
`Gamma`–`relmat(1 + x | id, K/Q = ...)` route. The current Gamma validator
admits an unlabelled intercept or intercept-plus-one-slope and rejects labels
and multiple slopes (`R/drmTMB.R:8993-9022`); its behaviour is exercised at
`tests/testthat/test-nongaussian-structured-mu-slope.R:10-41` and its labelled
and multiple-slope boundary at
`tests/testthat/test-nongaussian-structured-mu-slope.R:105-122`.

The existing builder can also construct ordinary and structured `mu` blocks
concurrently because it builds `mu_re` and the relatedness structure separately
without a combination guard (`R/drmTMB.R:4249-4261`,
`R/drmTMB.R:4343-4368`). Arc 3a does **not** supply evidence for that combined
Gamma–relmat model and does not authorize promoting it. The implementation must
either preserve its current behaviour unchanged or raise a separate design
decision; it must not silently alter it as a side effect of adding the three
new cells.

## Error-message expectations

Messages should identify the family, distributional parameter, provider, and
unsupported coefficient or combination. Each should also tell the reader what
to try next. The following regex-level concepts are the stable test contract;
full CLI formatting need not be snapshotted.

| Condition | Required matching concepts | Reader guidance |
| --- | --- | --- |
| Slope or slope-only in a new cell | family name; provider; `mu`; `intercept-only` | Show `phylo(1 | species, tree = tree)` or `relmat(1 | id, K = K)` |
| Labelled term | family name; `unlabelled q=1`; offending label | Remove the middle block label |
| Multiple provider types | family name; `one structured mu provider`; both provider names | Fit one provider at a time |
| Unsupported provider | family name; requested provider; admitted providers | Use the admitted provider or remove the term |
| Structured `sigma` or ordinary sigma RE combined with structured `mu` | family name; `sigma`; `fixed-effect` or `pure-mu` | Keep `sigma ~ z` fixed-effect |
| Ordinary plus new structured `mu` | family name; `ordinary`; `structured`; `cannot be combined` | Fit one random layer |
| Missing tree/matrix object | object name; `Could not find` | Supply a named object in the formula environment |
| Invalid `K`/`Q` | `relmat`; matrix object; precise defect: labels, coverage, symmetry, covariance, or precision | Repair the matrix rather than switching silently between `K` and `Q` |
| Invalid tree | `phylo`; precise defect: class, tips, branch lengths, ultrametricity, or missing observed species | Repair the tree/group alignment |
| REML | `REML`; `only`; `Gaussian` | Set `REML = FALSE` |
| Bivariate request | family name; `one positive response` or `mixed-response bivariate` | Fit one response; do not suggest Gaussian unless it answers the same scientific model |

The existing generic fallback “Structured-effect syntax is planned, not
implemented” (`R/drmTMB.R:8066-8080`) is insufficient after Arc 3a because it
would incorrectly describe admitted Gamma/lognormal cells. The three new paths
must remove their selected term before that fallback and use family-specific
guards for every remaining structured term.

## Required implementation trace

### Parser: reuse, do not widen

No grammar expansion is needed. Reuse:

- `collect_structured_effects()` and `structured_marker_names()` for additive
  marker collection (`R/parse-formula.R:511-543`);
- `parse_structured_marker_call()` for exact `tree` and `K`/`Q` arguments
  (`R/parse-formula.R:562-692`); and
- `parse_structured_bar_term()` for coefficient and label extraction
  (`R/parse-formula.R:731-850`).

The family validator, not a global parser change, must narrow the otherwise
generic one-slope grammar to intercept-only for the three new cells.

### Builders and validators

Affected functions/files:

1. `drm_build_lognormal_ls_spec()` in `R/drmTMB.R:3963-4184` must extract
   `phylo()` and `relmat()` from `mu`, choose exactly one, apply the Arc 3a
   validator, include structured variables in complete-case filtering, build
   the structured object, and pass it through starts/maps/random names.
2. `drm_build_gamma_ls_spec()` in `R/drmTMB.R:4186-4380` must extract `phylo()`
   in addition to the existing `relmat()` term and select exactly one without
   changing the comparator's existing slope behaviour.
3. A family/provider-aware selector and validator should replace or wrap
   `validate_gamma_relmat_mu_structured_term()` (`R/drmTMB.R:8993-9022`). The
   target policy is:
   - Gamma–phylo: intercept-only;
   - Gamma–relmat: preserve existing intercept/one-slope behaviour;
   - lognormal–phylo: intercept-only;
   - lognormal–relmat: intercept-only.
4. Reuse `extract_gaussian_mu_phylo_term()` and
   `extract_gaussian_mu_known_term()` for extraction
   (`R/drmTMB.R:9516-9556`, `R/drmTMB.R:9607-9647`) and
   `build_structured_mu_structure()` for tree/K/Q construction
   (`R/drmTMB.R:10959-10973`). Their broader coefficient grammar must be
   narrowed by the family validator.
5. `drm_validate_reml_spec()` already rejects every non-Gaussian model before
   any structured-provider exception (`R/drmTMB.R:2050-2057`). Do not add an
   Arc 3a REML bypass.
6. The positive-continuous builders already reject `mvbind()` and name the
   one-response boundary (`R/drmTMB.R:4010-4014`,
   `R/drmTMB.R:4233-4237`). Preserve those errors.

## Mandatory boundary tests

One focused test file should cover the four-cell grid. The minimum API suite is:

1. Gamma–phylo intercept fits.
2. Lognormal–phylo intercept fits.
3. Lognormal–relmat `K` and `Q` forms fit and report the same public naming.
4. Existing Gamma–relmat intercept and one-slope tests remain green.
5. Every rejection-matrix row above is exercised for each relevant new family.
6. Tree and matrix validation errors reuse the existing structured-input
   validators rather than family-specific copies.
7. Accepted fits expose exactly one structured `mu` SD and the matching
   `phylo_mu` or `relmat_mu` random-effect block; no `sigma` structured block or
   latent correlation is reported.
8. The new tests assert `REML = TRUE` rejection and the one-response boundary.

## Final API verdict

**READY.** The parser already expresses every admitted formula, and the shared
structured builder already handles tree, `K`, and `Q` inputs. Implementation
may begin once Gauss and Noether use this matrix to keep the engine and symbolic
alignment synchronized.

Two flags are load-bearing:

- the three new cells are intercept-only even though the generic parser accepts
  one-slope terms; and
- the existing Gamma–relmat one-slope comparator must not be regressed by a
  shared validator.

Any implementation that admits another provider, structured `sigma`, ordinary
plus structured effects in a new cell, labels/q2+, REML, or bivariate
positive-continuous structure is outside Arc 3a and is **NOT READY** under this
review.
