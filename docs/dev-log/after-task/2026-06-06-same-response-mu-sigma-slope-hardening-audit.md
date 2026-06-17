# After Task: Same-Response Mu/Sigma Slope Hardening Audit

## Goal

Follow up the local 500-replicate formal audit for the same-response q2
`mu`/`sigma` slope covariance route by checking the weak replicates, trying a
stronger refit pass, deciding whether that changes the promotion decision, and
adding endpoint-profile evidence before any power-grid claim.

## Implemented

This was an evidence and status update, not a new likelihood surface. The audit
used the local artifact directory:

```text
inst/sim/results/actions/biv_gaussian_mu_sigma_slope_recovery
```

It wrote the follow-up CSVs under:

```text
inst/sim/results/actions/biv_gaussian_mu_sigma_slope_recovery/refit-audit-20260606
```

The follow-up reproducibility slice added
`inst/sim/run/sim_audit_biv_gaussian_mu_sigma_slope_hardening.R`, which reads
the formal recovery artifact, rebuilds the weak-replicate table, optionally
refits weak seeds with stronger optimizer controls, recomputes fixed-effect
Wald coverage after replacement, and optionally profiles clean direct q2
targets. Routine tests exercise the table-reading/no-refit path so package
checks do not rerun the expensive 130-refit audit.

The four follow-up checks were completed:

1. The weak-replicate table contains 130 rows: 72 from
   `biv_gaussian_mu_sigma_slope_001` and 58 from
   `biv_gaussian_mu_sigma_slope_002`.
2. The robust-refit table contains 130 rows, no refit errors, and zero rescued
   fits. All 130 retained `false convergence (8)` and `pdHess = FALSE`.
3. The route remains diagnostic-only. All-replicate fixed-effect Wald coverage
   stayed 0.796-0.850 because the weak fits still have no valid interval rows.
   Among interval-available converged fits, fixed-effect Wald coverage was
   0.9299-0.9720.
4. Endpoint profiles succeeded on two clean representative fits for `rho12`,
   both slope SDs, and `cor(mu1:x,sigma1:x | p | id)`. The eight profile rows
   all had `conf.status = "profile"` and no boundary flags.

## Mathematical Contract

The audited model remains the same same-response location-scale slope block:

```r
mu1 = y1 ~ x + (0 + x | p | id)
sigma1 = ~ x + (0 + x | p | id)
mu2 = y2 ~ x
sigma2 = ~ x
rho12 = ~ 1
```

The group-level `cor(mu1:x,sigma1:x | p | id)` row is distinct from residual
`rho12`. The profile-feasibility check covered the direct endpoint targets that
`profile_targets()` reports for this q2 route; it did not establish broad
profile or bootstrap coverage.

## Files Changed

Updated current status prose in `NEWS.md`, `README.md`, `ROADMAP.md`,
`docs/design/34-validation-debt-register.md`,
`docs/design/46-pre-simulation-readiness-matrix.md`,
`docs/design/67-sdstar-p8-poisson-q1.md`,
`docs/design/157-capability-completion-worklist.md`,
`docs/dev-log/known-limitations.md`, `inst/sim/README.md`, and
`docs/dev-log/check-log.md`. The reproducibility slice also added
`inst/sim/run/sim_audit_biv_gaussian_mu_sigma_slope_hardening.R` and extended
`tests/testthat/test-phase18-biv-gaussian-mu-sigma-slope-recovery.R`.

## Checks Run

- Artifact summary:
  `Rscript - <<'EOF' ... EOF`
  read `robust-refit-status.csv`, `robust-combined-fixed-wald-coverage.csv`,
  and `profile-feasibility-intervals.csv`. It reported 130 weak rows, zero
  refit errors, zero rescued fits, 130 `false convergence (8)` outcomes,
  all-replicate fixed-effect Wald coverage 0.796-0.850,
  interval-available fixed-effect Wald coverage 0.929906542056075-0.97196261682243,
  eight profile interval rows, `conf.status = "profile"`, and no profile
  boundary flags.
- `Rscript -e "devtools::test(filter = 'phase18-biv-gaussian-mu-sigma-slope-recovery')"`
  returned 27 passes, no failures, warnings, or skips.
- After the reproducibility script was added,
  `Rscript -e "devtools::test(filter = 'phase18-biv-gaussian-mu-sigma-slope-recovery')"`
  returned 36 passes, no failures, warnings, or skips.
- Real-artifact no-refit readback:
  `Rscript - <<'EOF' ... EOF`
  loaded the package and simulation helpers, then ran
  `phase18_audit_biv_gaussian_mu_sigma_slope_hardening(..., run_refits = FALSE, profile_replicates_per_cell = 0L)`
  against
  `inst/sim/results/actions/biv_gaussian_mu_sigma_slope_recovery`. It returned
  `weak=130`, `coverage_rows=16`, `refit_rows=0`, and `profile_rows=0`,
  confirming that the script can reconstruct the audit substrate from the
  saved artifact without rerunning refits or profiles.
- `Rscript tools/codex-checkpoint.R --goal "same-response q2 mu/sigma slope hardening audit reproducibility" --next "Review the hardening-audit script/docs diff, then choose whether to run full package checks or open/review the PR."`
  wrote
  `docs/dev-log/recovery-checkpoints/2026-06-06-074853-codex-checkpoint.md`.
- `Rscript -e "devtools::test(filter = 'phase18-biv-gaussian-mu-sigma-slope')"`
  returned 86 passes, no failures, warnings, or skips across the same-response
  smoke and recovery/audit tests.
- `Rscript -e "pkgdown::build_site()"` completed and wrote `pkgdown-site`;
  it emitted the known local `glmmTMB`/`TMB` version mismatch warning.
- `Rscript -e "pkgdown::check_pkgdown()"` returned "No problems found."
- Source stale scan:
  `rg -n "same-response.*(source-tested only|source-tested and still|no formal Actions|formal Actions artifacts still needed|formal artifacts still needed|source-test level|source tests but no formal)|same-response location-scale slope covariance.*(planned|closed|blocked|unsupported)|same-response q2.*source-test|same-response q2.*source recovery|same-response slope covariance.*still needs formal|mu/sigma.*formal Actions artifacts still needed|same-response q2.*power-grid support|same-response q2.*power ready|same-response q2.*power readiness|q8.*fitted|p8.*fitted" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md inst/sim tests/testthat vignettes .github/workflows --glob '!docs/dev-log/after-task/**'`
  returned intended planning and hold-language matches only, including p8/q8
  planning rows and the same-response q2 power-readiness hold.
- Rendered stale scan:
  `rg -n "same-response.*(source-tested only|source-tested and still|no formal Actions|formal Actions artifacts still needed|formal artifacts still needed|source-test level|source tests but no formal)|same-response location-scale slope covariance.*(planned|closed|blocked|unsupported)|same-response q2.*source-test|same-response q2.*source recovery|same-response slope covariance.*still needs formal|mu/sigma.*formal Actions artifacts still needed|completed formal artifact audit still needed|still needs a completed formal artifact audit|still needs larger-grid evidence before power" pkgdown-site --glob '!search.json' --glob '!deps/**'`
  returned only the intended NEWS sentence that all-four p8/q8 slope endpoints
  remain closed.
- Rendered evidence scan:
  `rg -n "same-response q2.*(diagnostic audit|hardening audit|robust-refit|500-replicate)|0\\.930-0\\.972|130 weak|no rescue|power-grid use|endpoint profiles" pkgdown-site/index.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html pkgdown-site/articles/implementation-map.html pkgdown-site/articles/model-map.html pkgdown-site/articles/formula-grammar.html --glob '!search.json'`
  found the new hardening wording in rendered NEWS and the homepage.
- `git diff --check` passed before and after the status patch.

## Tests Of The Tests

The focused tests exercise the recovery-lane writer and summary expectations at
CRAN-safe size. The new hardening-audit test writes a tiny recovery artifact,
runs the audit script with `run_refits = FALSE` and
`profile_replicates_per_cell = 0`, checks that all expected CSVs are written,
and verifies the overwrite guard. A separate cheap readback ran the same script
against the real saved formal artifact, which checks the production artifact
schema without the cost of the 130 robust refits. The follow-up artifact summary
independently read the generated formal-audit CSVs and checked the failure mode
that matters for promotion: whether any weak replicate was rescued into a
converged positive-Hessian fit and whether profile intervals could be obtained
for direct q2 targets on clean fits.

## Consistency Audit

The repository now tells one story: the same-response q2 `mu`/`sigma` slope
route is fitted and artifact-routed, but its local formal and hardening audits
do not support power-grid use. The successful endpoint profiles show that
direct target intervals are feasible on clean fits, not that interval coverage
is calibrated across the weak-replicate set.

## GitHub Issue Maintenance

Issue #491 remains open. A GitHub connector attempt to post the follow-up
comment returned 403, so the local `gh` CLI was used instead. The issue comment
records the four checks and the hold decision:
<https://github.com/itchyshin/drmTMB/issues/491#issuecomment-4638712135>.

## What Did Not Go Smoothly

The first robust-refit attempt in the interactive audit did not source
`inst/sim/R/sim_runner.R`, so helper functions were missing. After sourcing the
runner helpers, the full robust-refit pass ran without refit errors. The first
profile-feasibility call also passed an incompatible `profile_precision`
argument to the endpoint profile engine; rerunning without that argument
produced the eight successful profile rows. The first version of the
reproducibility script also used a scalar `NA` when aligning a zero-row refit
table with the original artifact rows; the new focused test caught that
empty-table bug, and the helper now adds zero-length columns when needed.

## Team Learning

For weak-Hessian bivariate slope audits, keep three evidence layers separate:
manifest completion, convergence/Hessian rescue, and interval feasibility.
`status = "ok"` and plausible point estimates are not enough for promotion when
the Hessian and optimizer message fail. Endpoint profiles on clean fits are a
useful next diagnostic, but broad profile or bootstrap coverage should be
planned as a deliberately sharded lane because the two-fit profile check took
minutes rather than seconds.

## Known Limitations

This was a local audit of the two default recovery cells, not a GitHub Actions
artifact or a broad profile/bootstrap coverage grid. It did not add start-value
APIs, new optimizer workflows, or new interval methods. It also did not make
the all-four p8/q8 endpoint block fitted.

## Next Actions

Keep same-response q2 power claims gated. The next promotion attempt needs
either a real convergence-start improvement that rescues weak fits, or a
sharded profile/bootstrap interval-coverage lane that measures the direct q2
targets across more than two clean demonstration fits.
