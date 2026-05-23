# Large-Data Benchmarks

This directory contains optional development benchmarks. These scripts are not
part of the R package tarball and are not run by CRAN checks.

The first harness focuses on the scaling question that matters for large
phylogenetic data. It also has an explicit non-phylogenetic sparse fixed-effect
scenario for the first `sparse_fixed` implementation and a non-phylogenetic
repeated-cell scenario for the first `aggregate_gaussian` implementation:

```sh
Rscript bench/large-phylo-location.R --rows 100000 --species 1000 \
  --memory-light true --output bench/results/large-phylo-location.csv
```

Run it from the package root. The script loads the local development checkout
with `devtools::load_all()` when available; otherwise it uses an installed
`drmTMB`.

The scalar-profile harness compares the current `TMB::tmbprofile()` route with
the endpoint-only scalar profiler on the same fitted Gaussian phylogenetic
model. The primary target is the phylogenetic SD interval because that is the
expensive user-facing profile case:

```sh
Rscript bench/profile-scalar-endpoint.R --rows 10000 --species 1000 \
  --output docs/dev-log/benchmarks/profile-scalar-endpoint.csv
```

Use `--targets all` to add the constant `sigma` interval to the same run. The
script records elapsed seconds, returned bounds, engine identity, Git and R/TMB
versions, endpoint root errors, and endpoint-versus-`tmbprofile` differences.

If an existing output CSV was created by an older benchmark schema, choose a
new `--output` path or remove the old ignored CSV before appending new rows.
The benchmark schema can change as diagnostics improve; a fresh output path is
usually the safest choice for development evidence.

## Recommended Matrix

Start small, then scale only when the previous run converges and memory use is
reasonable.

| Step | Rows | Species | Options | Purpose |
| --- | ---: | ---: | --- | --- |
| Smoke | 10,000 | 100 | `--memory-light true` | Check the local toolchain and output file. |
| First large run | 100,000 | 1,000 | `--memory-light true` | Measure ordinary large-data behaviour. |
| Factor pressure | 100,000 | 1,000 | `--factor-heavy true --memory-light true` | Expose dense fixed-effect matrix cost. |
| Sparse fixed smoke | 100,000 | 1,000 | `--structured none --factor-heavy true --sparse-fixed true --memory-light true` | Measure the first sparse Gaussian `mu` fixed-effect path without phylogenetic structure. |
| Aggregation smoke | 100,000 | 1,000 | `--structured none --aggregate-gaussian true --aggregation-cells 100 --memory-light true` | Measure the first Gaussian sufficient-statistic aggregation path on repeated fixed-effect cells. |
| Scale predictor | 100,000 | 1,000 | `--sigma-x true --memory-light true` | Add a distributional scale predictor. |
| Species pressure | 100,000 | 5,000 | `--memory-light true` | Stress tree and species-index handling. |
| Row pressure | 500,000+ | 1,000+ | `--memory-light true` | Move toward million-row readiness. |

Use a smaller `--eval-max` and `--iter-max` when checking infrastructure. Use
larger values when the fit is intended as a real timing result.

For scalar profile timing evidence, use this development matrix:

| Step | Rows | Species | Target | Purpose |
| --- | ---: | ---: | --- | --- |
| Smoke | 10,000 | 1,000 | `sd:mu:phylo(1 | species)` | Check endpoint versus `tmbprofile` on a realistic phylogenetic SD interval. |
| Main | 100,000 | 1,000 | `sd:mu:phylo(1 | species)` | Measure row pressure for the primary interval target. |
| Species pressure | 100,000 | 5,000 | `sd:mu:phylo(1 | species)` | Required before claiming large-phylogeny profile speedup. |
| Stretch | 100,000 | 10,000 | `sd:mu:phylo(1 | species)` | Best-effort result only; do not block a merge on this laptop-scale run. |

Treat scalar-profile speed claims as valid only when the fit converged and both
engines returned finite intervals. If `tmbprofile` fails and the endpoint engine
succeeds, record the result as useful diagnostics but do not convert it into a
speedup ratio.

## Output Columns

| Column | Meaning |
| --- | --- |
| `run_started_utc` | UTC timestamp when the benchmark run started. |
| `r_version`, `platform`, `os`, `machine` | R and platform metadata for interpreting local timing and memory results. |
| `drmTMB_version`, `TMB_version` | Package versions used by the benchmark. For a development checkout, `drmTMB_version` comes from the local `DESCRIPTION`. |
| `git_sha`, `git_dirty` | Local Git commit and whether the checkout had uncommitted changes when the row was generated. |
| `benchmark_command` | Reconstructed command with all benchmark settings needed to rerun the scenario from the package root. |
| `rows`, `species` | Requested observation rows and species count. |
| `structured` | Fitted structured-effect route: `phylo` for the default phylogenetic benchmark or `none` for fixed-effect sparse smoke runs. |
| `tree` | Synthetic tree shape: `balanced` or `star`. |
| `factor_heavy` | Whether the `mu` formula includes a 40-level factor. |
| `sigma_x` | Whether the scale model is `sigma ~ x1` instead of `sigma ~ 1`. |
| `sparse_fixed` | Whether `drm_control(sparse_fixed = TRUE)` was used. This currently requires `--structured none --sigma-x false`. |
| `aggregate_gaussian` | Whether `drm_control(aggregate_gaussian = TRUE)` was used. This currently requires `--structured none` and cannot be combined with `sparse_fixed`. |
| `aggregation_cells_requested`, `aggregation_cells_fitted`, `aggregation_compression_ratio`, `aggregation_largest_cell_n` | Requested repeated fixed-effect cells in the synthetic generator and the fitted aggregation diagnostics returned from the model. |
| `memory_light` | Whether `keep_data = FALSE`, `keep_model_frame = FALSE`, and `keep_tmb_object = FALSE` were used. |
| `convergence` | `stats::nlminb()` convergence code; `0` is the target. |
| `convergence_message` | Optimizer message from `stats::nlminb()`, when available. |
| `iterations` | Number of optimizer iterations reported by `stats::nlminb()`. |
| `function_evaluations`, `gradient_evaluations` | Optimizer evaluation counts reported by `stats::nlminb()`. |
| `nobs` | Number of modelled observations after filtering. |
| `data_build_sec` | Time to generate synthetic data and tree objects. |
| `fit_sec` | Elapsed model-fitting time. |
| `predict_mu_sec` | Time to compute full-row fitted `mu` predictions. |
| `residuals_sec` | Time to compute full-row residuals. |
| `data_object_mb`, `tree_object_mb` | Base R object sizes for generated inputs. |
| `fit_object_mb` | Base R object size for the fitted `drmTMB` object. |
| `model_matrix_mb` | Base R object size for stored fixed-effect model matrices. |
| `model_matrix_largest`, `model_matrix_largest_cols`, `model_matrix_largest_nonzero`, `model_matrix_largest_density` | The largest retained fixed-effect design block and its width, nonzero count, and density. A low density points to a future sparse fixed-effect matrix candidate. |
| `tmb_data_mb` | Base R object size for the TMB data list stored in the fit. |
| `gc_used_mb_before` | Approximate R heap use before data generation, calculated from `gc()` Ncells and Vcells counts. |
| `gc_used_mb_pre_fit` | Approximate R heap use after data generation, calculated from `gc()` Ncells and Vcells counts. |
| `gc_used_mb_post_fit` | Approximate R heap use after fitting, calculated from `gc()` Ncells and Vcells counts. |
| `mu_mean`, `residual_sd` | Simple output summaries used as sanity checks. |
| `sigma_hat`, `sd_phylo_hat` | Mean fitted residual `sigma` and fitted phylogenetic SD. |

Base R object sizes are not peak resident memory. For peak memory, wrap a run
with an operating-system tool. On macOS:

```sh
/usr/bin/time -l Rscript bench/large-phylo-location.R \
  --rows 100000 --species 1000 --memory-light true
```

On Linux, use `/usr/bin/time -v` when available.

## Comparing Default and Memory-Light Fits

Run the same scenario twice, changing only `--memory-light`:

```sh
Rscript bench/large-phylo-location.R --rows 100000 --species 1000 \
  --memory-light true --output bench/results/large-phylo-location.csv

Rscript bench/large-phylo-location.R --rows 100000 --species 1000 \
  --memory-light false --output bench/results/large-phylo-location.csv
```

Compare `fit_object_mb`, `gc_used_mb_post_fit`, and `convergence`. If the
memory-light fit converges but the default fit is too large to save or pass
around,
`drm_control(keep_data = FALSE, keep_model_frame = FALSE, keep_tmb_object = FALSE)`
is doing useful post-fit storage work. If both runs fail before optimization,
the next problem is probably model-frame construction or dense-model-matrix
memory.

## Summarising Results

Use the summary helper to turn a benchmark CSV into a small Markdown table:

```sh
Rscript bench/summarize-results.R \
  --input bench/results/large-phylo-location.csv
```

The helper labels non-converged rows as diagnostic only. It also flags older
CSV files that do not contain optimizer messages and evaluation counts; rerun
those scenarios with a fresh output path before treating them as timing
evidence.

## What Not To Claim

Do not claim million-row readiness from one small benchmark. A credible claim
needs repeated runs, the recorded `benchmark_command`, machine details, local
Git state, convergence code, optimizer message, object sizes, and peak-memory
evidence from the operating system.
