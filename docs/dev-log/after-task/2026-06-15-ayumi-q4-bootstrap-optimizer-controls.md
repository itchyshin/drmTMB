# After Task: Ayumi q4 Bootstrap Optimizer Controls

Date: 2026-06-15

## Purpose

Native TMB ML bootstrap was returning `bootstrap_unavailable` for Ayumi's q4
phylogenetic SD targets because the bootstrap refits did not converge. This
slice makes the Ayumi harness expose the existing optimizer-preset controls so
the next benchmark can distinguish unsupported targets from unstable refits.

## What Changed

`tools/ayumi-q4-status-harness.R` now accepts two native-TMB-specific controls:

- `DRMTMB_AYUMI_Q4_TMB_OPTIMIZER_PRESET=default|careful|robust`
- `DRMTMB_AYUMI_Q4_TMB_BOOTSTRAP_REFIT_OPTIMIZER_PRESET=default|careful|robust`

The source-fit preset is passed to native `engine = "tmb"` fits through
`drm_control(optimizer_preset = ...)`. The bootstrap-refit preset is passed to
`confint(..., method = "bootstrap")` through the existing `refit_control`
surface with `se = FALSE` and `keep_tmb_object = FALSE`.

The harness records both presets in `metadata.md` and records the native
bootstrap-refit preset in `intervals.csv`.

These controls are native-TMB-only. They are not passed to `engine = "julia"`,
because the Julia bridge intentionally accepts only default R-side control in
the current contract.

## Evidence

The harness still parses:

```sh
Rscript --vanilla -e 'invisible(parse("tools/ayumi-q4-status-harness.R")); cat("parse ok\n")'
```

The 30-tip native TMB careful smoke:

```sh
DRMTMB_AYUMI_Q4_RDS=/tmp/ayumi-ls-ecogeo/for_test/birds_tarsus_beak_10440.rds \
DRMTMB_AYUMI_Q4_SIZES=30 \
DRMTMB_AYUMI_Q4_ENGINES=tmb \
DRMTMB_AYUMI_Q4_REML=false \
DRMTMB_AYUMI_Q4_PROFILE=none \
DRMTMB_AYUMI_Q4_BOOTSTRAP=2 \
DRMTMB_AYUMI_Q4_BOOTSTRAP_TARGETS=all_q4 \
DRMTMB_AYUMI_Q4_BOOTSTRAP_SEED=20260615 \
DRMTMB_AYUMI_Q4_TMB_OPTIMIZER_PRESET=careful \
DRMTMB_AYUMI_Q4_TMB_BOOTSTRAP_REFIT_OPTIMIZER_PRESET=careful \
DRMTMB_AYUMI_Q4_TIME_LIMIT=300 \
DRMTMB_AYUMI_Q4_OUT=/tmp/drmtmb-ayumi-evidence/native-tmb-30-ml-bootstrap-allq4-careful-abe8288a \
Rscript --vanilla tools/ayumi-q4-status-harness.R
```

The point fit returned in 1.21 s with `convergence = 0`, `pdHess = FALSE`,
and `fit_diagnostic_status = "fit_returned_converged_pdhess_false"`. The
bootstrap phase returned four q4 SD rows in 4.33 s with
`conf.status = "bootstrap"`, `bootstrap.n = 2`, `bootstrap.failed = 0`,
`profile.message = "2/2 successful refits"`, and
`bootstrap.refit_optimizer_preset = "careful"`.

The 100-tip native TMB careful smoke used the same settings with
`DRMTMB_AYUMI_Q4_SIZES=100` and wrote
`/tmp/drmtmb-ayumi-evidence/native-tmb-100-ml-bootstrap-allq4-careful-abe8288a`.
The point fit took 156.82 s and still returned `convergence = 1`,
`pdHess = FALSE`, and
`fit_diagnostic_status = "fit_returned_nonconverged_pdhess_false"`. The
bootstrap phase took 134.24 s and again returned
`conf.status = "bootstrap_unavailable"`, `bootstrap.n = 0`, and
`bootstrap.failed = 2` for all four q4 SD rows.

The 100-tip native TMB robust smoke used `optimizer_preset = "robust"` for both
the source fit and bootstrap refits, writing
`/tmp/drmtmb-ayumi-evidence/native-tmb-100-ml-bootstrap-allq4-robust-8ba6d9b6`.
The point fit took 162.53 s and still returned `convergence = 1`,
`pdHess = FALSE`, and
`fit_diagnostic_status = "fit_returned_nonconverged_pdhess_false"`. The
bootstrap rows again returned `conf.status = "bootstrap_unavailable"`,
`bootstrap.n = 0`, and `bootstrap.failed = 2`; recorded warnings included
`NA/NaN function evaluation` and a non-positive/NA diagonal covariance warning.

The internal issue ledger was updated at
`drmTMB#555`: https://github.com/itchyshin/drmTMB/issues/555#issuecomment-4711696348

## Interpretation

The 30-tip result shows that native TMB q4 bootstrap targets are reachable when
the refits converge. The 100-tip careful and robust results show that simply
raising the optimizer budget is not enough to make native ML bootstrap an
Ayumi-scale fallback.

The next useful R-side slice is not a speed claim. It is a bootstrap-refit
diagnostic/rescue slice: record per-refit convergence, messages, and target
availability, then decide whether retry-on-convergence-failure or a stronger
native optimizer preset belongs in the public `confint()` path.

## Boundaries

- This does not implement native TMB REML for bivariate q4 models.
- This does not make native bootstrap calibrated or practical at 10,440 tips.
- `B = 2` remains a plumbing/refit-stability smoke only.
- Julia-side optimizer/speed work is separate.
