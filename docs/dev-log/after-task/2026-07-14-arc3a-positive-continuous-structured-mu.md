# Arc 3a: positive-continuous structured `mu`

## 1. Goal

Deliver the native-TMB univariate-ML pure-`mu` q1 structured random-intercept
slice for Gamma-phylo, lognormal-phylo, and lognormal-relmat, retain
Gamma-relmat as a comparator, and promote only cells with independent
point-fit recovery evidence. This task does not claim slopes, structured
`sigma`, labels/q2+, other providers, bivariate responses, REML, intervals,
coverage, or general support.

## 2. Implemented

Gamma now admits `phylo(1 | id, tree = tree)` in `mu`; lognormal admits that
route plus `relmat(1 | id, K = K)` and the precision form `Q = Q`. The native
fit, `ranef()`, `structured_effects()`, prediction decomposition, simulation,
K/Q parity, and malformed-neighbour contracts are tested. A Gamma-relmat
conditional-prediction decomposition defect discovered by the comparator was
also repaired without widening Gamma-relmat's pre-existing capability.

The capability ledger now contains 671 model-surface rows: 301 implemented,
330 rejected, and 40 not implemented. `mc-0251`, `mc-0386`, and `mc-0388` are
`verified` at `point_fit_recovery`; representative q2 neighbours `mc-0669` to
`mc-0671` remain rejected/deferred.

## 3. Mathematical Contract

The admitted models retain each family's established response likelihood and
add only a structured location effect,

\[
g(\mu_i)=x_i^\top\beta+u_i,\qquad
u\sim N(0, s^2K),
\]

where `g` is the log link for Gamma and the identity link for lognormal's
log-response location, while `K` is the normalized phylogenetic or supplied
relatedness covariance. The extracted structured scale is the covariance
multiplier `s`, not a blanket marginal response SD. The direct family scale
parameters remain fixed-effect-only in this arc.

## 3a. Decisions and Rejected Alternatives

The accepted decision was three exact q1 intercept cells with independent
recovery evidence. A blanket positive-continuous provider gate was rejected,
as were promotions based on convergence alone, retrospective relaxation of the
primary RMSE gate, and combining Beta structured `mu` with a direct-`sd()`
likelihood in the next arc. Arc 1b-S1 is recommended next because it starts
from an existing ML cell and has an exact restricted-likelihood oracle.

## 4. Files Touched

- Native admission, extraction, prediction, and tests landed in the earlier
  Arc 3a implementation commits on this branch.
- The final evidence import updates the capability ledger, generator, schema,
  tests, generated Markdown/HTML/census surfaces, design notes, NEWS, README,
  ROADMAP, limitations, and five reader-facing vignettes.
- Compact primary and addendum evidence lives under
  `docs/dev-log/simulation-artifacts/2026-07-14-arc3a-*`.
- The banked `sd()` candidate and the unapproved Arc 1b-S1 ultra-plan are
  planning artifacts only.

## 5. Checks Run

- Focused Arc 3a tests: 201 expectations, 0 failures.
- Final `devtools::test()`: 38,676 passes, 0 failures, 62 known warnings, and
  24 expected optional-Julia skips in 1,662.1 seconds.
- Genuine preliminary `devtools::check(args = "--as-cran")`: normalized
  0 errors, 0 warnings, 0 notes in 13m40s on the implementation tree. The
  closeout rerun rebuilt and passed installation, code, Rd, examples, and
  static checks; its duplicate full-test leg was stopped after the independent
  final full suite above had passed. This distinction is intentional and is
  not reported as a second completed check.
- `devtools::document()`: passed; generated documentation stayed synchronized.
- `pkgdown::check_pkgdown()`: no problems. `pkgdown::build_site()`: completed,
  including articles, navigation, sitemap, and search index.
- Capability ledger write/check/summary: passed for all generated outputs.
- Ledger unit tests: 34 passed. Runtime route check: 18/18 passed.
- `tools/validate-mission-control.py`: `mission_control_ok`.
- `git diff --check`: passed.

## 6. Tests of the Tests

The admission tests failed against the pre-implementation rejection gate.
Independent family likelihood calculations, provider covariance/precision
orientation, optimum and displaced-vector checks, conditional-prediction
identities, K/Q parity, and malformed q2/slope/scale neighbours prevent a mere
convergence-only pass. Campaign summarizers reconstruct the immutable schedule,
seeds, source hashes, raw denominators, and failure stages before evaluating
recovery.

## 7a. Issue Ledger

Open issues #776, #747, #570, and #33 were inspected as the closest random-
effect/structured matches. None owns this exact positive-continuous q1
intercept slice, so no issue was closed or rewritten. PR #781 is unrelated and
was deliberately left untouched. Arc 3a will use its own focused PR.

## 8. Consistency Audit

README, NEWS, ROADMAP, formula grammar, family registry, likelihood notes,
known limitations, model/implementation maps, phylogenetic-spatial guidance,
ledger, generated census, and rendered pkgdown pages now state the same narrow
three-cell capability. Exact scans used were:

```sh
rg -n "Arc 3a.*pending|recovery certification.*pending|implementation-only Gamma|implementation-only.*lognormal" README.md NEWS.md ROADMAP.md docs vignettes
rg -n "668 model-surface|668-cell census|Scope:</strong> 668|of 668 cells|Generated 668" README.md NEWS.md ROADMAP.md docs vignettes pkgdown-site
```

Remaining `668-cell` hits are provenance text in the immutable 2026-07-11
import/transitions and archived dated dashboard, not current reader surfaces.
Rendered-page readback confirmed the Arc 3a statement and its exclusions.

## 9. What Did Not Go Smoothly

The primary 6,000-fit campaign passed lognormal-relmat and its Gamma-relmat
comparator but held both phylogenetic cells under a universal absolute
intercept-RMSE cap. That cap did not account for balanced-tree realization
geometry. The primary result remains unchanged. A fresh, predeclared 2,400-fit
phylo-only addendum used exact design-conditioned GLS and structured-field
projection oracles and passed both cells. The closeout `--as-cran` rerun also
duplicated the already completed 27-minute final suite; that duplicate test leg
was stopped rather than represented as a completed second check.

## 10. Known Residuals

All three promotions stop at `point_fit_recovery`. No interval, coverage,
`inference_ready_with_caveats`, or `supported` claim follows. No structured
positive-continuous slope, `sigma` random effect, labelled/q2 block, additional
provider, bivariate model, REML, or bridge capability is implied. The primary
phylogenetic HOLD is still part of the evidence record; the independent
addendum is the promotion authority.

## 11. Team Learning

Structured recovery gates must identify whether absolute truth-centred error
or estimator agreement conditional on the realized design answers the claim.
When geometry matters, predeclare both. Never retrofit the primary verdict:
addenda remain separately planned, hashed, and interpreted. This rule is now
recorded in `docs/dev-log/team-improvements.md`.

## 12. Cross-Product Coverage

The R/native-TMB product is covered for the exact Gamma-phylo,
lognormal-phylo, and lognormal-relmat cells. K and Q relatedness forms are
covered. DRM.jl remains optional and was not expanded; the 24 Julia skips are
the repository's expected unavailable-engine boundary. No bivariate,
non-native, CI/coverage, or direct-`sd()` product surface is covered.
This arc **does NOT cover** spatial or animal providers, structured slopes,
structured `sigma`, REML, missing-response combinations, aggregation changes,
or any Julia-engine implementation.

## Next Actions

Open the focused Arc 3a PR, wait for current-head CI, and do not merge without
Shinichi's authorization. After an authorized merge, refresh `main` and ask for
approval of the separate copy-paste GOAL in
`docs/dev-log/2026-07-14-next-arc1b-spatial-q2-reml-ultra-plan.md`. The banked
distribution-wide `sd()` candidate should not be next as currently phrased; it
must first be split into Beta structured-`mu`, Gaussian canonical-`sd()`
parser/extractor, and combined Beta location-scale-scale slices.
