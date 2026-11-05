# After Task: Bernoulli Relatedness-Matrix SD Regression

## 1. Goal

Add and check one native Bernoulli relatedness-matrix intercept whose latent
standard deviation depends on a group-level predictor.

## 2. Implemented

The native TMB route now fits `relmat(1 | id, K = K)` with
`sd(id, level = "relmat") ~ z`. Extraction now scales the q1 structured latent
field for every family that admits a structured SD, so `ranef()` and the
conditional prediction path use the same fitted effect that entered the
likelihood. The marginal draw uses the fitted group SDs in the fresh structured
effect. Help, the design note, two vignettes, NEWS, and known limitations now
describe this exact cell and its boundaries.

## 3a. Decisions and Rejected Alternatives

The model uses `log(sd_g) = W_g alpha`, `u ~ Normal(0, K)`, and `b = D u`, so
`Cov(b) = D K D`. The supplied kernel keeps its existing scaling. The change
reuses the `level = "relmat"` formula selector and does not create a parallel
SD function or imply support for other providers, families, or Julia.

## 4. Files Touched

- `R/drmTMB.R`
- `R/methods.R`
- `R/random-effect-scale-formulas.R`
- `tests/testthat/test-binomial-relmat-sd.R`
- `man/random_effect_scale_formulas.Rd`
- `docs/design/18-random-effect-scale-models.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/formula-grammar.Rmd`
- `vignettes/predictor-dependent-random-sd.Rmd`
- `NEWS.md`
- `docs/dev-log/check-log.md`
- `tests/testthat/test-poisson-phylo-sd-regression.R`

## 5. Checks Run

- `devtools::document()` exited 0 and regenerated `simulate.drmTMB.Rd` and
  `random_effect_scale_formulas.Rd`.
- Both changed vignettes rendered from `devtools::load_all()` with exit 0.
  Pandoc printed its existing `--mathjax` deprecation warning.
- `pkgdown::check_pkgdown()` exited 0 with “No problems found.” Pandoc printed
  its existing `--mathml` deprecation warnings.
- The final `devtools::test(filter = "binomial-relmat-sd",
  reporter = "summary")` run passed 22 expectations with no failures,
  warnings, or skips. The Julia bridge reported that it did not run a live
  engine test.
- A follow-up Poisson q1 phylogenetic modeled-SD smoke test passed 4
  expectations. It checked convergence, finite SD coefficients, the public
  prediction length, node-mapped model-scale extraction, and the conditional
  link. It is not a Poisson coefficient-recovery result.

## 6. Tests of the Tests

Before the extraction fix, the new assertion failed because `ranef()` returned
the unscaled latent values instead of `D u`. The final test checks recovery of
both SD coefficients and the fitted group-SD surface, the model-scale random
effects, the exact seeded fresh-draw contribution against a Cholesky solve,
public group-SD prediction, and Bernoulli simulation output. Its DGP now
reverses the kernel labels relative to the factor order and still recovers the
fitted SD surface. It also confirms that a constant relmat SD formula matches
the existing constant-SD model in log likelihood and location coefficients.
The independent review confirmed the original fixture
generated `D K D`; it did not review the permutation change or run an additional
fit. The Poisson follow-up initially exposed a bad test oracle: tip-level SD
names do not align directly with the full internal-node vector, so the oracle
now applies the model's explicit node-to-SD row map. Its attempted single-fit
slope recovery assertion was removed because this smoke test does not have a
predeclared recovery design.

## 7a. Issue Ledger

`gh issue list --state open --search 'Bernoulli relmat random-effect SD'
--limit 20` returned no matching open issue. No issue was opened, commented on,
or closed.

## 8. Consistency Audit

The formula, `D K D` covariance, TMB scaling, fitted random-effect extraction,
and fresh marginal draw now use consistent group-to-node mappings. The exact
status scan used was:

```sh
rg -n -i 'relmat.*(SD|scale)|((SD|scale).*relmat)|relatedness.*(SD|scale)|Bernoulli.*(structured|phylogenetic)' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd vignettes/predictor-dependent-random-sd.Rmd _pkgdown.yml
```

The Bernoulli grammar table, scale vignette, reference help, design note, NEWS,
and limitation note now name the relmat intercept as one native candidate
slice. They retain the limits on Julia parity, other structured combinations,
and interval calibration. No navigation change was needed.

## 9. What Did Not Go Smoothly

The first relatedness-matrix run checked fit and public SD outputs but did not
check the conditional random-effect scale. The independent review identified
that omission; the new failing assertion exposed the extraction defect. The
path-specific lane preflight for the shared check log and gate ledger produced
no final verdict during the wait and was stopped. Those shared files were not
edited; this report retains the slice evidence.

## 10. Known Residuals

The fitted capability is one native Bernoulli q1 relmat intercept cell. A
separate Poisson q1 phylogenetic smoke test checks the generic extraction
path, but does not claim coefficient recovery. These checks do NOT cover Julia
relmat fitting, Poisson relmat regression or coefficient recovery, other
providers and families beyond the two listed cells, correlated or bivariate
structured blocks, general structured simulation, interval calibration, or
the remaining programme gates. The overall goal
remains active.

## 11. Team Learning

Structured likelihoods may scale latent parameters inside the TMB objective
while public extraction still sees the unscaled optimizer parameters. Tests
for a new scale route must check the extracted model-scale random effect as
well as coefficients, predictions, and simulation shape.

## 12. Cross-Product Coverage

| Product cell | Evidence | Remaining work |
|---|---|---|
| Native TMB, Bernoulli q1 relmat intercept | Seeded coefficient and SD-surface recovery, scaled `ranef()` values, exact fresh-draw contribution, public SD prediction, response simulation | Broader group-order tests and family/provider combinations |
| Native TMB, Poisson q1 phylogenetic modeled SD | One smoke fit checks node-mapped extracted values and conditional link | Independent coefficient-recovery design and other structured providers |
| Julia engine, Bernoulli q1 relmat intercept | No live Julia route or test | Requires implementation and paired-lane ownership coordination |
| Inference | Point-recovery and workflow checks only | Interval calibration is deferred; no coverage claim |

This slice does NOT cover Julia relmat fitting, other families or providers,
correlated structured blocks, or interval calibration.

The next concrete action is to resolve paired-lane ownership before editing
the Julia relmat route.

## Prose Review

Style: 2/10, medium confidence. Genre and coverage: concise internal
implementation report, read in full. Evidence and repair: “The model uses
`log(sd_g) = W_g alpha`” is specific and paired with its covariance; no change
is needed. Gates: science = pass for the stated tested cell; facts = pass
against the test output and edited source; references = not applicable because
the report cites local code and tests only. Provenance: self-review of this
2026-10-20 report; no style-control examples were consulted.
