# After Task: Q-Series v1 q2 Scale-Only Point-Fit Recovery

## Goal

Move the cheapest honest Q-Series v1.0 rows needed to cross 90% by recovering
the exact q2 scale-only Gaussian `sigma1`/`sigma2` native point-fit route, while
keeping interval, coverage, bridge, and support claims closed.

## Implemented

The bivariate structured-effect detector now admits exact scale-only
intercept-only q2 blocks when both `sigma1` and `sigma2` use the same supported
structured provider, group, covariance source, and explicit label, and neither
`mu1` nor `mu2` contains a structured term.

The TMB contribution path now routes q2 bivariate structured endpoints through
the endpoint metadata instead of hardcoding `mu1` and `mu2`. The SD/correlation
summary helper now reads scale-endpoint structured SDs from `sdpars$sigma1` and
`sdpars$sigma2` when those endpoint-specific summaries exist.

Mission Control moves the three rows
`qseries_spatial_q2_plus_q2_sigma_rejected`,
`qseries_animal_q2_plus_q2_sigma_rejected`, and
`qseries_relmat_q2_plus_q2_sigma_rejected` to `point_fit` /
`extractor_ready` / `planned` / `planned`. The previous q2-plus-q2 sigma
rejection sidecar is now header-only.

## Mathematical Contract

The admitted model is still narrow:

```text
biv_gaussian()
sigma1 = ~ ... + provider(1 | ps | group, source)
sigma2 = ~ ... + provider(1 | ps | group, source)
```

It is a labelled scalar q2 covariance block on the scale endpoints only. This
slice checks deterministic point fitting, structured SD visibility, and
scale-scale `corpairs()` extraction. It does not validate Wald/profile
intervals, retained denominators, calibrated coverage, bridge payloads, q4/q8
inheritance, REML, AI-REML, or public support.

## Files Changed

- `R/drmTMB.R`
- `R/methods.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-structured-re-q2-rejections.R`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `tools/qseries_v1_release_check.py`
- `tools/qseries_v1_release_ledger.py` outputs and release-audit TSVs
- Q-Series dashboard sidecars, README, completion map, check-log, and this
  after-task report

## Checks Run

- Python compile checks for Mission Control and v1 release tools: passed.
- Dashboard JavaScript extraction plus bundled `node --check`: passed.
- `tools/qseries_v1_release_ledger.py --check --check-status --summary`:
  passed.
- `tools/validate-mission-control.py`: passed with `mission_control_ok`.
- `tools/qseries_v1_release_check.py --summary --write-report
  --write-candidates`: passed with `94/104 (90.4%)`, `rows_to_90=0`, and
  Mission Control included.
- `devtools::test(filter = "structured-re-q2-rejections", reporter =
  "summary")`: passed.
- `devtools::test(filter = "structured-re-conversion-contracts", reporter =
  "summary")`: passed.
- Stale-wording scan for old 87.5% and q2 scale-only rejection wording: no
  active-path hits.
- `git diff --check`: passed.

## Tests Of The Tests

The q2 scale-only test fits deterministic spatial, animal, and relmat
scale-side fixtures and asserts convergence, q2 scalar covariance metadata,
endpoint-specific `sdpars`, finite structured SD/correlation summaries,
scale-scale `corpairs()`, and summary target names for `sigma1` and `sigma2`.
It also keeps one-sided, unlabelled, and intercept-plus-slope scale-only
neighbours rejected.

The conversion-contract test caught two stale closure-triage expectations and
the old bridge-boundary status wording before the final pass. That was useful
evidence that the dashboard contracts are guarding the row-count and claim
surfaces rather than just the implementation.

## Consistency Audit

Rose audit: active docs, release reports, dashboard rows, and tests now say the
same thing: the three q2 scale-only rows are point-fit/extractor evidence only.
The stale active wording scan found no remaining `91/104`, `87.5%`, `rows_to_90=3`,
or current q2 scale-only rejection claims in the checked active paths.

Fisher audit: no coverage job is authorized. The three recovered rows keep
`interval_status = planned`, `coverage_status = planned`, and
`denominator_policy = fixture_not_coverage`.

Gauss audit: the implementation routes endpoint contributions through metadata
and the fixture test checks finite structured SD/correlation extraction for all
three providers.

Noether audit: the admitted formula class is exact and narrow: same label, same
group/source/object, same structured provider, `sigma1` plus `sigma2`, and no
structured location endpoints.

Grace audit: Mission Control validates 104 Q-Series cells, 8 exact
`inference_ready` rows, 0 structured `supported` rows, 23 Gaussian low-q
row-selection rows, and 0 q2-plus-q2 sigma rejection rows.

## GitHub Issue Maintenance

No GitHub issue was opened, commented on, or closed in this slice. This work is
being banked on the current Q-Series v1 feature branch before PR/GHA follow-up.

## What Did Not Go Smoothly

The first conversion-contract rerun exposed stale closure-triage counts. During
the stale-wording cleanup, one structured TSV rewrite used the wrong header and
partially rewrote `structured-re-executable-evidence.tsv`; it was restored from
`HEAD` content and then the intended q2 scale-only wording change was applied.

## Team Learning

For TSV sidecars with long historical rows, inspect the header before doing a
structured rewrite. If a row is being retired from rejection to point-fit, update
both the statistical support-cell surface and older bridge/closeout labels so
Rose does not have to rediscover a split truth later.

## Known Limitations

- The recovered rows are not `inference_ready`.
- The recovered rows are not `supported`.
- No q2 scale-scale profile route, retained denominator, coverage grid, bridge
  payload, q4/q8 inheritance, REML, AI-REML, or public support was added.
- Remaining practical-v1 post-v1 rows are still 10/104.

## Next Actions

Commit and push this clean checkpoint. The next technical work should choose
between a small remaining v1 design row or PR/GitHub Actions cleanup, not q2
scale-only coverage.
