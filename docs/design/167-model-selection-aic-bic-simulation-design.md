# Model Selection AIC/BIC Simulation Design

This sheet records the first model-selection simulation lane for `drmTMB`.
It is a small article-support design, not a formal proof that AIC or BIC is
best for every distributional-regression question. The reader is an applied
user deciding whether two fitted candidate models are stable enough to compare.

The design follows the ADEMP structure of Morris, White, and Crowther (2019)
and the transparent-reporting checklist of Williams et al. (2024). AIC follows
Akaike's expected-prediction-risk criterion, and BIC follows Schwarz's
large-sample approximation with a stronger `log(n)` parameter penalty.

## A - Aims

Primary aim: show how often AIC and BIC select the generating candidate in
small paired `drmTMB` examples where the candidate set is known in advance.

Secondary aims: keep convergence, Hessian status, warnings, and failed
candidate fits beside the selection result; teach users that AIC/BIC should be
read after diagnostics and not as a substitute for candidate-model design.

This lane supports the model-selection article. It does not claim calibrated
power, coverage, or general operating characteristics until a larger grid is
designed and run.

## D - Data-Generating Mechanism

The article-support surface uses six paired cells. Each cell has two fitted
candidates and one named selection target.

| Scenario | Candidate set | Selection target | DGP |
| --- | --- | --- | --- |
| `normal_tail` | Gaussian versus Student-t | Gaussian | `y ~ Normal(mu, sigma)` with `mu ~ x`, constant `sigma` |
| `heavy_tail` | Gaussian versus Student-t | Student-t | `y = mu + sigma * t_nu`, with `nu = 5` |
| `nb2_counts` | NB2 versus ZINB2 | NB2 | NB2 count response with `mu ~ x`, constant public `sigma` |
| `extra_zeros` | NB2 versus ZINB2 | ZINB2 | NB2 count response plus structural zeros with constant `zi` |
| `constant_sigma` | Gaussian `sigma ~ 1` versus `sigma ~ x` | `sigma ~ 1` | Gaussian response with constant public `sigma` |
| `sigma_signal` | Gaussian `sigma ~ 1` versus `sigma ~ x` | `sigma ~ x` | Gaussian response with `log(sigma) = gamma0 + gamma1 * x` |

The count cells use the public NB2 scale convention
`Var(Y_i) = mu_i + sigma_i^2 * mu_i^2`, so the native NB2 size is
`1 / sigma_i^2`.

## E - Estimands

The estimand is a cell-level model-selection event:

```text
selected_by_AIC = candidate with minimum AIC among finite candidate fits
selected_by_BIC = candidate with minimum BIC among finite candidate fits
truth_selected_AIC = selected_by_AIC == selection_target
truth_selected_BIC = selected_by_BIC == selection_target
```

Candidate-level diagnostics are also estimands for the article because they
tell the reader whether the selection comparison was well behaved:
`converged`, `pdHess`, warning count, error message, log likelihood, degrees
of freedom, and elapsed time.

## M - Methods

The six article-support cells fit these candidate pairs:

```r
drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
drmTMB(bf(y ~ x, sigma ~ 1, nu ~ 1), family = student(), data = dat)

drmTMB(bf(count ~ x, sigma ~ 1), family = nbinom2(), data = dat)
drmTMB(bf(count ~ x, sigma ~ 1, zi ~ 1), family = nbinom2(), data = dat)

drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
drmTMB(bf(y ~ x, sigma ~ x), family = gaussian(), data = dat)
```

The runner writes one candidate row per replicate and candidate, plus a compact
summary with AIC/BIC truth-selection rates and binomial Monte Carlo standard
errors. It preserves nonconverged and warning-bearing candidates in the table
instead of dropping them before selection.

## P - Performance Measures

Report metrics by scenario:

| Measure | Rule |
| --- | --- |
| AIC target-selection rate | mean of `truth_selected_aic` over replicates for the target row |
| BIC target-selection rate | mean of `truth_selected_bic` over replicates for the target row |
| MCSE | `sqrt(p * (1 - p) / n_replicate)` |
| Mean delta at truth | mean `delta_aic` and `delta_bic` for the target candidate |
| Candidate convergence rate | mean candidate-level `converged` across both candidates |
| Candidate Hessian rate | mean candidate-level `pdHess` across both candidates |
| Candidate warning rate | mean candidate-level `warning_count > 0` across both candidates |
| Failure ledger | candidate-level warning and error CSVs beside the summary |

The current article-support run uses 200 replicates per cell and writes
artifacts under
`docs/dev-log/simulation-artifacts/2026-06-09-model-selection-n200/`. This
gives useful MCSEs for a documentation table, but it is still not a formal
selection-probability grid across sample sizes, effect sizes, tail strength,
zero-inflation strength, scale-slope strength, or candidate-set
misspecification.

## Williams-Style Self-Audit

| Item | Coverage in this sheet |
| --- | --- |
| 1. Aims | The article-support and diagnostic aims are stated above. |
| 2. DGP | Continuous-tail, count-zero, and scale-formula candidate pairs are specified. |
| 3. Estimands | AIC/BIC selection events and candidate diagnostics are named. |
| 4. Methods | The fitted `drmTMB` candidate formulas are stated. |
| 5. Performance measures | Selection rates, MCSEs, deltas, diagnostics, warnings, and failures are defined. |
| 6. Software/settings | Per-replicate RDS results carry session metadata through the Phase 18 runner. |
| 7. Code availability | DGP, fit, runner, writer, tests, and article summary live under `inst/sim/`. |
| 8. Replicability | Cells have stable ids and seeded replicate rows. |
| 9. Real-data motivation | The article connects tail choice, structural zeros, and scale formulas to applied model-selection questions. |
| 10. Complete results | Candidate rows, summaries, manifests, and failure ledgers are written as CSV artifacts. |
| 11. Monte Carlo uncertainty | The article table reports MCSE and explicitly refuses formal operating-characteristic claims. |
