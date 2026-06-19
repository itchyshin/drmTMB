# Student-t `nu` Profile Failure Decision Audit

## Task Goal

Turn the post-#633 Student-t profile/bootstrap calibration artifact into a
target-level interval decision. The reader is the contributor deciding whether
to run a larger profile grid, repair the profile route, or keep bootstrap
evidence diagnostic.

## Files Changed

- `docs/design/176-numerical-guard-simulation-audit.md`
- `docs/design/157-capability-completion-worklist.md`
- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-19-student-nu-profile-failure-decision-audit.md`
- `docs/dev-log/simulation-artifacts/2026-06-19-student-nu-profile-failure-decision-audit/`

## What Changed

The new artifact reads back the 100-fit Student-t profile/bootstrap calibration
diagnostic without refitting models. It summarizes the 107 focused `nu` profile
failures, records that 86 of those failures occurred in fits with
`converged = TRUE` and `pdHess = TRUE`, retains two degenerate low-boundary
profile rows, and writes a target-level decision table.

The design docs, finish worklist, R-Julia matrix, and dashboard now record the
same decision: all current Student-t profile targets stay `blocked_by_method`.
Bootstrap intervals remain diagnostic or larger-grid candidates depending on
the target, and a bootstrap grid should wait until the target and refit budget
answer a user-facing question.

## Checks Run

```sh
air format docs/dev-log/simulation-artifacts/2026-06-19-student-nu-profile-failure-decision-audit/run-audit.R
/usr/local/bin/Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-19-student-nu-profile-failure-decision-audit/run-audit.R
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
tools/validate-mission-control.py
git diff --check
RSTUDIO_PANDOC=/opt/homebrew/bin /usr/local/bin/Rscript --vanilla -e "pkgdown::check_pkgdown()"
```

## Results

The artifact runner reported
`student_nu_profile_failure_decision_ok: profile_failures=107 degenerate_ok=2 decisions=4`.
Its internal assertions require 107 focused profile failures, two degenerate
profile rows, four decision rows, profile decisions of `blocked_by_method` for
all four targets, 107 target-level failed profiles, and 86 profile failures
among converged positive-Hessian fits.

Both dashboard JSON files parsed cleanly, mission control validated, and
`git diff --check` passed. `pkgdown::check_pkgdown()` found no problems.

## Consistency Audit

This is a readback and decision artifact only. It does not change likelihoods,
formula grammar, starts, clamps, floors, optimizer presets, profile budgets,
bootstrap refit budgets, tests, package exports, or examples. The wording keeps
Student-t profile/bootstrap intervals unpromoted and keeps direct Julia,
Julia-via-R, release, CRAN, and non-Gaussian REML/AI-REML claims out of scope.

## GitHub Issue Maintenance

A `drmTMB#59` breadcrumb was posted after the local validation pass, naming the
artifact and the target-level decision boundary:
https://github.com/itchyshin/drmTMB/issues/59#issuecomment-4751372241.

## Known Limitations

The audit does not repair profile target construction or interval algorithms.
It also does not choose a bootstrap target or a larger bootstrap refit budget.
Those are separate follow-on decisions.

## Next Actions

Run one scale/correlation sensitivity slice next. The strongest candidate from
the decision ledger is the fixed-effect bivariate Gaussian `sigma1`/`sigma2`
clamp-sensitivity row, followed by ordinary q2 correlation depth only after the
scale-route decision is banked.
