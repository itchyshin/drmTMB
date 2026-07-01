# After Task: Q-Series Gaussian Mu-Slope Top-Up Runner

## 1. Goal

Make the Gaussian q1 `mu` one-slope top-up lane executable for the current
hybrid-boundary routing decision, without changing any support-cell status or
dashboard claim.

## 2. Implemented

This promotes exactly no support cell. The linked Q-Series rows remain
`fit_status = point_fit`, `interval_status = planned`, and
`coverage_status = planned`.

I extended `tools/run-structured-re-gaussian-mu-slope-coverage-pregrid.R` with
provider selection, generated non-overlapping seed slices, a copied seed
manifest in each artifact directory, a `--write-dashboard=false` mode, and a
help path. The default SR150 behavior is unchanged: if the run starts at seed 1
and the existing 150-row manifest covers the requested slice, the runner uses
that manifest.

I also extended
`tools/run-structured-re-gaussian-mu-slope-boundary-profile-diagnostic.R` with
`--source-replicates=PATH` and a help path, so a future top-up pregrid artifact
can be passed through the same endpoint-profile boundary repair channel.

## 3a. Decisions and Rejected Alternatives

The top-up smoke excludes animal. Animal remains blocked by the hybrid SR150
hard negative and should not be topped up until the interval channel changes.

Rejected alternatives: I did not rerun or overwrite the dashboard SR150 sidecar,
and I did not describe the smoke as coverage evidence. A one-replicate smoke is
only an executable-contract check.

## 3b. Simulation Contract

Aims: the immediate aim is to top up only phylo, relmat, and spatial Gaussian q1
`mu` one-slope rows from SR150 to at least SR475 per direct-SD target under the
hybrid Wald plus endpoint-profile interval channel.

Data-generating mechanism: reuse the existing phase-18 Gaussian q1 `mu`
one-slope DGPs for the exact provider conditions already used in the SR150
pregrid. Top-up seeds start at replicate 151, so the top-up does not duplicate
the original 1-150 seed slice.

Estimands: direct structured location-axis SD targets,
`sd_mu_intercept` and `sd_mu_x`, for phylo, relmat, and spatial.

Methods: run default `confint()` first, then run the endpoint-profile diagnostic
on any `boundary_or_nonwald_status` rows from the top-up artifact. The final
top-up summary must combine the original SR150 hybrid denominator with the
top-up Wald and endpoint-profile rows.

Performance measures: retained-denominator coverage, MCSE, finite interval
fraction, convergence, `pdHess`, lower misses, upper misses, boundary/non-Wald
counts, and profile-failure counts. The coverage MCSE gate remains `<= 0.01`
per direct target before any `inference_ready` discussion. This follows the
ADEMP framing of Morris, White, and Crowther (2019) and the simulation
reporting emphasis of Williams et al. (2024).

## 4. Files Touched

- `tools/run-structured-re-gaussian-mu-slope-coverage-pregrid.R`
- `tools/run-structured-re-gaussian-mu-slope-boundary-profile-diagnostic.R`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-topup-smoke-local/`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-gaussian-mu-slope-topup-runner.md`

## 5. Checks Run

```sh
air format tools/run-structured-re-gaussian-mu-slope-coverage-pregrid.R
air format tools/run-structured-re-gaussian-mu-slope-boundary-profile-diagnostic.R
R_PROFILE_USER=/dev/null Rscript --no-init-file tools/run-structured-re-gaussian-mu-slope-coverage-pregrid.R --help
R_PROFILE_USER=/dev/null Rscript --no-init-file tools/run-structured-re-gaussian-mu-slope-boundary-profile-diagnostic.R --help
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'invisible(parse("tools/run-structured-re-gaussian-mu-slope-boundary-profile-diagnostic.R"))'
R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-gaussian-mu-slope-coverage-pregrid.R --n-rep=1 --seed-start=151 --providers=phylo,relmat,spatial --output-dir=docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-topup-smoke-local --write-dashboard=false --overwrite=true
R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-gaussian-mu-slope-boundary-profile-diagnostic.R --source-replicates=docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-coverage-pregrid-local/structured-re-gaussian-mu-slope-coverage-pregrid-replicates.tsv --max-rows=1 --output-dir=/tmp/drmtmb-gaussian-mu-slope-boundary-source-smoke --write-dashboard=false --overwrite=true
```

Results: the top-up smoke wrote one generated seed, three fit-status rows, six
retained target-replicate rows, six target summaries, three provider summaries,
`sessionInfo.txt`, `git-sha.txt`, and a run log. The run log records
`dashboard_results = not_written`. The boundary diagnostic source-override smoke
wrote one detail row and one summary row into `/tmp`.

## 6. Tests of the Tests

The top-up smoke used `--seed-start=151` and wrote a seed manifest with
`seed = 791151` and `seed_role = generated_gaussian_mu_slope_pregrid_topup`.
That confirms the top-up path does not silently reuse the original 1-150 seeds.

The smoke also confirmed that `--providers=phylo,relmat,spatial` excludes
animal, and that `--write-dashboard=false` leaves the dashboard result sidecar
unwritten from the smoke run.

## 7a. Issue Ledger

No GitHub issue action was taken. This is local runner and reproducibility work
inside the Q-Series evidence-completion arc.

## 8. Consistency Audit

The one-replicate smoke is not coverage evidence. Its target summaries are
useful only for checking the retained-output schema and denominator accounting:
phylo and relmat had two usable intervals each in the generated seed, while
spatial had one covered slope target and one lower miss on the intercept target.
Those values do not promote or block any row.

The support-cell TSV, hybrid-boundary audit TSV, and widget routing remain the
source of truth: animal is blocked, while phylo, relmat, and spatial are top-up
candidates only.

## 9. What Did Not Go Smoothly

The original pregrid runner had no help path, and `--help` initially attempted
to run the default artifact. Adding an explicit help branch now makes future
operator checks less error-prone.

## 10. Known Residuals

The final top-up summary combiner is still needed. After a full top-up run, the
operator must run the boundary-profile diagnostic on the top-up replicate TSV
and then combine original SR150 hybrid evidence with the top-up Wald/profile
evidence before any status discussion.

## Next Actions

Run the candidate SR475 top-up with:

```sh
R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-gaussian-mu-slope-coverage-pregrid.R --n-rep=325 --seed-start=151 --providers=phylo,relmat,spatial --output-dir=docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-topup-sr475-local --write-dashboard=false --overwrite=true
```

Then run the boundary-profile diagnostic on any top-up boundary/non-Wald rows
and build a combined hybrid SR475 summary. Do not edit the support-cell TSV
before Rose and Fisher review the combined denominator, MCSE, and miss balance.

## 11. Team Learning

A top-up lane needs its own seed and dashboard-writing controls. Otherwise a
smoke run can accidentally overwrite the visible board or duplicate the old
denominator.
