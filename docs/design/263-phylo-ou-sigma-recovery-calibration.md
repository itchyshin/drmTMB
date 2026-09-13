# R1 Local Calibration Contract: Independent Phylogenetic OU Fields in Location and Scale

## Purpose and status

S1 is a **predeclared, no-claim calibration design** for the first joint phylogenetic-OU model: an independent stationary OU intercept field in Gaussian location (`mu`) and another in residual log-scale (`sigma`). Its reader is the method developer who will implement or assess the recovery runner. This file fixes the data-generating process, ordinary cells, starts, retained artifacts, and timing stop before a fit is run. It is not evidence that either decay is recoverable, that an interval is calibrated, or that the joint surface is ready for public use.

The fitted model is univariate Gaussian **ML** only, with complete data and unit weights:

```r
bf(
  mu    = y ~ 1 + phylo(1 | species, tree = tree, model = "ou"),
  sigma =   ~ 1 + phylo(1 | species, tree = tree, model = "ou")
)
```

There is no `x` covariate, no slope, and no ordinary random effect. The intercept-only core intentionally replaces G13's rank-deficient one-level-`x` control: its fixed-effect matrix is exactly one full-rank intercept column. The fields are unlabelled, share the same observed species and tree layout, and are independent; no phylogenetic `mu`--`sigma` correlation is fitted or generated.

## Frozen tree and stationary OU convention

For each `n_species` value, make one rooted, strictly bifurcating, ultrametric tree before generating any response data. Use `ape::rcoal()` with the fixed tree seeds below, retain the root, and rescale every branch by the same positive constant so each tip has root distance exactly one. Thus `alpha` is a decay per root-to-tip tree height, not per an arbitrary original tree scale. Do not regenerate a tree for a replicate or alpha pair.

| `n_species` | `tree_id` | tree seed |
| ---: | --- | ---: |
| 12 | `tree_n12_v1` | 2026091203 |
| 32 | `tree_n32_v1` | 2026091201 |
| 64 | `tree_n64_v1` | 2026091202 |

The root for a field with stationary SD `s` has distribution \(z_{root}\sim N(0,s^2)\). For every child reached by an edge of scaled length \(\ell\), generate

\[
z_{child}\mid z_{parent}\sim N\{e^{-\alpha\ell}z_{parent},\,
s^2(1-e^{-2\alpha\ell})\}.
\]

This root-plus-edge construction implies the tip covariance \(s^2\exp(-\alpha d_{ij})\), where \(d_{ij}\) is the scaled patristic distance. In the later retained campaign, the saved Newick tree and its SHA-256 are authoritative; its `tree_id`, scaling rule, seed, root convention, tip order, and checksum must appear in the campaign manifest and provenance receipt. R1's reduced local-readiness receipt records the tree ID and seed per task, but does not claim to be that retained tree archive.

## Data-generating process

For species \(i\) and within-species observation \(j\), independently draw

\[
u\sim OU(\alpha_\mu,0.45),\qquad
v\sim OU(\alpha_\sigma,0.25),\qquad
y_{ij}=0+u_i+\varepsilon_{ij},\quad
\varepsilon_{ij}\sim N\{0,\exp[-1+v_i]^2\}.
\]

The two fields use independent random-number streams conditional on the fixed tree. Their stationary SDs are therefore `sd_u = 0.45` and `sd_v = 0.25`; the fixed residual log-scale intercept is `-1`; and the fixed `mu` intercept is zero. Preserve the generated tip fields and response data, not only their seeds, so an assessment can distinguish a generator change from a fitting change.

## Exact S1 cells

The ordinary design has exactly sixteen cells:

| factor | values |
| --- | --- |
| `n_species` | 32, 64 |
| `n_each` | 6, 12 observations per species |
| `(alpha_mu, alpha_sigma)` | `(0.7, 1.3)`, `(1.3, 0.7)` |
| replicate seed | 2026091211, 2026091212 |

The Cartesian product is `2 x 2 x 2 x 2 = 16` ordinary cells. Name each as `S1_n<n_species>_m<n_each>_amu<alpha_mu>_asigma<alpha_sigma>_seed<seed>`; write decimal rates in that identifier as `0p7` and `1p3`. Each ordinary cell uses the one tree for its `n_species` value and the stated seed to initialize the field and observation streams.

Retain, but do not pool with, two negative controls. They have `n_species = 12`, `n_each = 1`, and the same fixed tree/root/scaling and DGP except for their alpha pair and seed:

| control | `(alpha_mu, alpha_sigma)` | seed | required interpretation |
| --- | --- | ---: | --- |
| `S1_NEG_n12_m1_amu0p7_asigma1p3_seed2026091213` | `(0.7, 1.3)` | 2026091213 | one residual per scale-field tip: expected weak or failed identification |
| `S1_NEG_n12_m1_amu1p3_asigma0p7_seed2026091214` | `(1.3, 0.7)` | 2026091214 | swapped-rate counterpart; expected weak or failed identification |

The negative controls must remain in the all-attempt denominator and report; their failure is not an ordinary-cell failure, and their apparent success is not evidence that one observation per species identifies the scale field.

## Starts, fitting, selection, and diagnostics

Fit every task from these three **fixed natural-scale starts**, transformed to the package's unconstrained coordinates only at the fitting boundary. They are the same in every ordinary and negative-control cell; none is a truth-dependent warm start.

| `start_id` | `alpha_mu` | `alpha_sigma` | `sd_u` | `sd_v` |
| --- | ---: | ---: | ---: | ---: |
| `low` | 0.40 | 0.40 | 0.25 | 0.15 |
| `middle` | 1.00 | 1.00 | 0.45 | 0.25 |
| `high` | 2.00 | 2.00 | 0.70 | 0.40 |

The fixed `mu` intercept start is `0` and the fixed log-scale intercept start is `-1` for all three starts. Run all three starts even when an earlier start is satisfactory. Select the finite, converged, positive-definite-Hessian attempt with the smallest objective; if none qualify, set the selected-fit status to `NO_QUALIFIED_START` and retain every attempt. Never replace a failed attempt, warning, boundary result, or non-positive-definite Hessian with a rerun under the same logical task ID.

For each start record at least: elapsed wall and CPU time; convergence code and message; objective; `pdHess`; maximum absolute gradient; all warnings; function/gradient evaluations; selected/not-selected status; the two fixed intercept estimates; `alpha_mu`, `alpha_sigma`, `sd_u`, and `sd_v` estimates on natural and internal scales; whether either estimate is at a reported boundary; and the unmodified start values. If a fixed-parameter covariance eigenvalue is recorded, label it as such: it is not a Hessian eigenvalue. Diagnostics are reported by ordinary cell and separately for negative controls. S1 does not predeclare pass thresholds for recovery, bias, coverage, profile availability, or model-selection performance: this calibration determines whether a later campaign is scientifically and operationally defensible.

## Required retained-campaign artifact schema

The later retained campaign, if separately approved, must write one immutable S1 directory. Its `README.md` must state that it is an ML point-recovery calibration and carries no interval or public-capability claim. The following files are required; a missing row, duplicated key, changed checksum, or unrecognised column is a fail-closed artifact error. R1's local smoke and timing preflight deliberately write only `conditions.csv`, attempt tables, a run manifest, and the timing receipt: they validate the current fitting mechanism and price the campaign, but do not masquerade as campaign evidence.

| file | one row per | required key and fields |
| --- | --- | --- |
| `trees.csv` and `trees/` | fixed tree | `tree_id`, `n_species`, `tree_seed`, `root_to_tip_height`, `root_retained`, `tip_order_sha256`, `newick_sha256`, `scaling_rule`, `root_distribution` |
| `manifest.csv` | task | `task_id`, `design_class`, `cell_id`, `replicate_seed`, `tree_id`, `n_species`, `n_each`, `alpha_mu_truth`, `alpha_sigma_truth`, `sd_u_truth`, `sd_v_truth`, `mu_intercept_truth`, `logsigma_intercept_truth`, `data_sha256`, `generator_sha256` |
| `starts.csv` | task-start | `task_id`, `start_id`, `alpha_mu_start`, `alpha_sigma_start`, `sd_u_start`, `sd_v_start`, `mu_intercept_start`, `logsigma_intercept_start`, `internal_start_sha256` |
| `attempts.csv` | task-start | `task_id`, `start_id`, `attempt_status`, `objective`, `convergence_code`, `convergence_message`, `pdHess`, `max_abs_gradient`, `elapsed_seconds`, `cpu_seconds`, `fn_evals`, `gr_evals`, `warning_text`, all four natural-scale and internal-scale estimates, and both boundary flags |
| `selected-fits.csv` | task | `task_id`, `selection_status`, `selected_start_id`, `selected_objective`, `selected_pdHess`, `selected_max_abs_gradient`, all selected natural-scale estimates, both fixed-intercept estimates, and `diagnostic_class` |
| `diagnostics.csv` | task | `task_id`, `design_class`, `finite_objective_any`, `converged_any`, `pdHess_any`, `qualified_start_count`, `warning_count`, `boundary_count`, `attempt_count`, `negative_control_interpretation` |
| `data/` and `fields/` | task | one response-data file plus separate `u` and `v` tip-field files; each file is named by `task_id` and listed with SHA-256 in `DATA-SHA256SUMS` |
| `SOURCE-PROVENANCE.tsv` | run | source commit and dirty state, package/DLL versions and hashes, R/platform, runner/helper/generator hashes, command line, time stamp, thread settings, and SHA-256 values for every schema file |
| `RESULTS.md` | run | exact cell inventory (16 ordinary, 2 negative), all-attempt and selected-fit denominators, ordinary and negative-control summaries kept separate, diagnostic counts, and this contract's no-claim boundary |

`task_id` must be unique in `manifest.csv`; `(task_id, start_id)` must be unique in `starts.csv` and `attempts.csv`; and every task must have exactly three start rows and one selected-fit plus one diagnostic row. `design_class` is exactly `ordinary` or `negative_control`. A reader must be able to reconstruct every selected result from the frozen tree, generated data, start, and source receipt without drawing a new tree or using an unstated seed.

## R1 local-readiness receipt schema

R1 is not the retained campaign above. Its smoke and timing preflight write a deliberately smaller receipt that exercises the current fitting route and prices the frozen design. `conditions.csv` has all eighteen `task_id` values, `design_class`, seeds, tree IDs, dimensions, and truth values. Each attempt table has exactly one row per executed `(task_id, start_id)` and records its fixed start, elapsed and CPU times, objective, convergence message/code, `pdHess`, gradient, fixed-covariance diagnostic, natural estimates, working-parameter string, warnings, and separate rate-boundary flags. `*-manifest.csv` records the source commit and dirty state, runner/contract MD5 values, command, UTC start time, R/platform/package versions, and loaded `drmTMB` DLL MD5. These reduced receipts are checked as a complete local-readiness schema; they are not a substitute for the tree/data/checksum campaign schema above.

## Timing gate and exclusions

Before the sixteen ordinary fits, run a source-current local timing calibration on the four largest ordinary tasks (`n_species = 64`, `n_each = 12`): both ordered alpha pairs at both fixed replicate seeds, with all three starts. This is twelve actual fits. Use its measured elapsed times to make a conservative wall-time estimate for all fifty-four predeclared attempts (sixteen ordinary plus two negative-control tasks, each with three starts). Run the complete ordinary calibration locally only when that estimate is at most 25 minutes; otherwise retain the timing receipt and stop before the full local run.

Any expanded replicated recovery campaign is a new decision. If its estimate exceeds 30 minutes, stop after a pre-run test and present the measured estimate, resource request, artifact plan, and failure partition for explicit approval before submitting or continuing it. The S1 contract itself authorizes neither that campaign nor an interval/coverage calculation.

If approved later, the retained campaign uses exactly one fixed seed per task; its manifest is the resumption authority, so a task is never replaced with an unrecorded rerun. The campaign is not launched by this calibration runner.

S1 explicitly defers phylogenetic `mu`--`sigma` correlation, temporal terms, REML, fixed slopes, direct-SD formulae, bivariate responses, missing data, weights, non-Gaussian families, `newdata`/forecasting, and every interval, coverage, model-selection, or general phylogenetic-OU claim.
