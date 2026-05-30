# After Task: Bivariate Gaussian Slope Actions Pilot Audit

## Goal

Audit the small manual Phase 18 GitHub Actions pilot for the bivariate Gaussian
`mu1`/`mu2` slope-only lane before making any recovery claim.

## Implemented

Run `26689587073` completed the manual `biv_gaussian_mu_slope` workflow job on
2026-05-30. The selected job ran with `n_reps=1`, `backend=none`,
`bootstrap_nsim=0`, `render_report=false`, `require_complete=true`, and seed
`20260603`. The workflow uploaded
`phase18-biv_gaussian_mu_slope-shard-1-of-1-26689587073`, and the downloaded
artifact contained the expected `phase18-actions-result.rds`, aggregate CSV,
replicate CSV, manifest CSV, failure-ledger CSV, and one replicate RDS for each
of the two pilot cells.

The pilot is evidence that the manual Actions task dispatches and writes the
expected artifact set on Ubuntu. It is not recovery, coverage, CRAN, or
cross-platform evidence.

## Mathematical Contract

No model equations, likelihood parameterization, formula grammar, or estimator
definition changed in this audit. The artifact records the already-wired
bivariate Gaussian surface with separate `mu1` and `mu2` location formulas,
residual `sigma1`, residual `sigma2`, residual `rho12`, two random-slope SDs,
and the random-slope correlation.

## Files Changed

- `ROADMAP.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/143-phase-18-structured-workflow-registry.md`
- `inst/sim/README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-30-biv-gaussian-slope-actions-pilot-audit.md`

## Checks Run

```sh
gh run list --repo itchyshin/drmTMB --workflow 'Phase 18 simulation grid' --limit 20 --json databaseId,displayTitle,event,headBranch,headSha,status,conclusion,createdAt,updatedAt,url
gh run view 26689587073 --repo itchyshin/drmTMB --json databaseId,displayTitle,event,headBranch,headSha,status,conclusion,createdAt,updatedAt,url,jobs
gh run view 26689587073 --repo itchyshin/drmTMB --job 78663532348 --log
gh run download 26689587073 --repo itchyshin/drmTMB --dir /tmp/drmtmb-phase18-biv-gaussian-audit-26689587073
find /tmp/drmtmb-phase18-biv-gaussian-audit-26689587073 -maxdepth 6 -type f | sort
Rscript --vanilla -e "base <- '/tmp/drmtmb-phase18-biv-gaussian-audit-26689587073/phase18-biv_gaussian_mu_slope-shard-1-of-1-26689587073'; files <- file.path(base, 'tables', c('biv-gaussian-mu-slope-manifest.csv','biv-gaussian-mu-slope-replicates.csv','biv-gaussian-mu-slope-aggregate.csv','biv-gaussian-mu-slope-failures.csv')); for (f in files) { cat('\n##', basename(f), '\n'); x <- read.csv(f, stringsAsFactors = FALSE); print(dim(x)); print(names(x)); print(x); }; cat('\n## action result\n'); r <- readRDS(file.path(base, 'phase18-actions-result.rds')); str(r, max.level = 2);"
rg -n "small artifact pilot is audited|small artifact pilot|pilot is audited|biv_gaussian_mu_slope.*recovery|bivariate_gaussian_slope_only.*recovery|biv_gaussian_mu_slope.*coverage|bivariate Gaussian.*coverage claim" README.md NEWS.md ROADMAP.md docs/design inst/sim .github/workflows tests/testthat --glob '!docs/dev-log/**'
rg -n "until a small artifact pilot is audited|small artifact pilot is audited|pilot is audited" README.md NEWS.md ROADMAP.md docs/design inst/sim .github/workflows tests/testthat --glob '!docs/dev-log/**'
rg -n "biv_gaussian_mu_slope.*recovery|bivariate_gaussian_slope_only.*recovery|biv_gaussian_mu_slope.*coverage|bivariate Gaussian.*coverage claim" README.md NEWS.md ROADMAP.md docs/design inst/sim .github/workflows tests/testthat --glob '!docs/dev-log/**'
gh issue list --repo itchyshin/drmTMB --state open --search "biv gaussian slope actions pilot artifact" --limit 20 --json number,title,state,url,labels
gh issue list --repo itchyshin/drmTMB --state open --search "bivariate Gaussian slope Phase 18" --limit 20 --json number,title,state,url,labels
git diff --check
```

The run and artifact audit passed. The manifest had two rows, both
`status == "ok"`, `skipped == FALSE`, `warning_count == 0`, and no errors. The
replicate table had 20 rows: two cells, one replicate, and 10 parameters per
replicate. Every replicate row had `converged == TRUE`, `pdHess == TRUE`, and
`warning_count == 0`. The aggregate table had 20 rows with
`n_replicate == 1`; its MCSE fields were `NA`, which is expected for a
one-replicate pilot. The failures table existed and had zero rows.

## Tests Of The Tests

This slice did not add tests. The audit checked the uploaded CSV dimensions,
required columns, selected workflow inputs, result RDS structure, failure
ledger, and per-row convergence flags rather than relying only on a green
workflow badge.

## Consistency Audit

The first stale-wording scan found only the two expected pre-audit phrases
stating that a small pilot still needed to be audited. This slice replaces
those with the audited run ID and keeps the no-recovery boundary explicit. The
follow-up pre-audit scan is clean; the conservative recovery/coverage scan
finds only the intended ROADMAP no-claim sentence for Slice 1826.

No README, NEWS, formula grammar, likelihood, roxygen, or pkgdown navigation
updates were needed because this was a simulation-artifact audit rather than a
public API change.

## GitHub Issue Maintenance

The direct issue search for a bivariate Gaussian slope Actions pilot returned
no exact issue. The broader search found issue #33, "Phase 6c: remaining
structured and bivariate random slopes"; that issue was updated with the
pilot-audit evidence and the remaining no-recovery boundary.

## What Did Not Go Smoothly

The handoff note said to dispatch a small pilot, but the recent Actions history
showed that the pilot had already run successfully. The efficient path was to
audit run `26689587073` rather than spend another runner cycle on a duplicate
job.

## Team Learning

Ada kept the task on the narrow audit rather than opening a new simulation
grid. Fisher and Curie treated clean convergence as dispatch evidence only.
Grace checked the selected job, run inputs, artifact upload, and PR #428
non-blocker status. Rose found that the unrelated GLLVM.jl scouting note is
useful but stale as-is and should be handled in a separate cleanup slice.

No spawned subagents edited files.

## Known Limitations

The pilot is Ubuntu-only and uses one replicate per cell. It does not test
HTML report rendering, multicore execution, bootstrap layers, profile
intervals, coverage, CRAN platforms, or formal operating characteristics. The
artifact has 14-day GitHub retention, so the durable project record is the run
ID plus the check-log and after-task audit.

## Next Actions

1. Keep `biv_gaussian_mu_slope` opt-in and excluded from `task = "all"`.
2. Design a deliberately sized bivariate Gaussian slope grid, with thresholds
   and MCSE targets, before making recovery or coverage claims.
3. Handle `docs/dev-log/lessons-from-gllvmjl-for-drmtmb.md` as a separate
   provenance cleanup slice; do not commit it as-is.
