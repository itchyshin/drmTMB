# After Task: Ayumi q4 Bootstrap Evidence Refresh

Date: 2026-06-15

## Purpose

After the Julia q4 target-estimate repair merged in #565, Shinichi asked
whether bootstrap might be a useful next path. This refresh separates two
different statements:

- Julia all-q4 bootstrap plumbing can return rows on a tiny Ayumi subset.
- Native TMB ML bootstrap is not yet a working q4 sigma-phylo fallback.

## Evidence

Julia evidence was banked in
`docs/dev-log/after-task/2026-06-15-julia-q4-phylocov-target-estimates.md`.
On the 30-tip Ayumi subset, `engine = "julia"`, `REML = FALSE`, all-q4
bootstrap with `B = 2` returned four rows with `bootstrap.n = 2`,
`bootstrap.failed = 0`, and `profile.message = "2/2 successful refits"`.

Two native TMB ML bootstrap smokes were then run from clean `origin/main`
`abe8288a`.

```sh
DRMTMB_AYUMI_Q4_RDS=/tmp/ayumi-ls-ecogeo/for_test/birds_tarsus_beak_10440.rds \
DRMTMB_AYUMI_Q4_SIZES=30 \
DRMTMB_AYUMI_Q4_ENGINES=tmb \
DRMTMB_AYUMI_Q4_REML=false \
DRMTMB_AYUMI_Q4_PROFILE=none \
DRMTMB_AYUMI_Q4_BOOTSTRAP=2 \
DRMTMB_AYUMI_Q4_BOOTSTRAP_TARGETS=all_q4 \
DRMTMB_AYUMI_Q4_BOOTSTRAP_SEED=20260615 \
DRMTMB_AYUMI_Q4_TIME_LIMIT=300 \
DRMTMB_AYUMI_Q4_OUT=/tmp/drmtmb-ayumi-evidence/native-tmb-30-ml-bootstrap-allq4-abe8288a \
Rscript --vanilla tools/ayumi-q4-status-harness.R
```

```sh
DRMTMB_AYUMI_Q4_RDS=/tmp/ayumi-ls-ecogeo/for_test/birds_tarsus_beak_10440.rds \
DRMTMB_AYUMI_Q4_SIZES=100 \
DRMTMB_AYUMI_Q4_ENGINES=tmb \
DRMTMB_AYUMI_Q4_REML=false \
DRMTMB_AYUMI_Q4_PROFILE=none \
DRMTMB_AYUMI_Q4_BOOTSTRAP=2 \
DRMTMB_AYUMI_Q4_BOOTSTRAP_TARGETS=all_q4 \
DRMTMB_AYUMI_Q4_BOOTSTRAP_SEED=20260615 \
DRMTMB_AYUMI_Q4_TIME_LIMIT=300 \
DRMTMB_AYUMI_Q4_OUT=/tmp/drmtmb-ayumi-evidence/native-tmb-100-ml-bootstrap-allq4-abe8288a \
Rscript --vanilla tools/ayumi-q4-status-harness.R
```

The 30-tip native point fit returned in 1.17 s with `convergence = 1`,
`pdHess = FALSE`, and
`fit_diagnostic_status = "fit_returned_nonconverged_pdhess_false"`.
The bootstrap phase returned four rows with
`conf.status = "bootstrap_unavailable"`, `bootstrap.n = 0`,
`bootstrap.failed = 2`, and
`profile.message = "fewer than two successful bootstrap refits"`.

The 100-tip native point fit returned in 25.58 s with `convergence = 1`,
`pdHess = FALSE`, and the same fit diagnostic status. The bootstrap phase
again returned four rows with `conf.status = "bootstrap_unavailable"`,
`bootstrap.n = 0`, `bootstrap.failed = 2`, and the same message. The 100-tip
bootstrap phase took 76.10 s.

The internal issue ledger was updated at
`drmTMB#555`: https://github.com/itchyshin/drmTMB/issues/555#issuecomment-4711541040

## Interpretation

Profile failure and bootstrap failure are different failure modes, so testing
bootstrap was still worth doing. The current native TMB bootstrap result is
negative evidence: native ML bootstrap is not yet a cheap fallback for the q4
sigma-phylo uncertainty path, at least not through the current all-q4 refit
route.

The Julia bootstrap smoke remains useful but narrow. It proves row-shape and
refit plumbing on a 30-tip subset after #565; it does not prove 10,440-tip
runtime, coverage, or across-tree feasibility.

Jason also checked the HSquared lane before this note was written. In
`HSquared.jl/src/likelihood.jl`, `fit_ai_reml()` is documented as
average-information REML for the Phase 1 Gaussian animal model. The same block
states that the AI form is exact for the Gaussian linear mixed model and does
not transfer to Laplace-approximated or non-Gaussian models, where
observed-information Newton is required instead. The `HSquared.jl`
validation-status row `V1-AI-REML` repeats the same Gaussian-only boundary.

That lesson is useful, but it does not make AI-REML available for Ayumi's
bivariate q4 location-scale sigma-phylo route. For `drmTMB`, AI-REML language
should stay reserved for exact Gaussian LMM/MME cells after implementation and
validation. The Ayumi route should be described as q4 Gaussian
location-scale/structured-effect optimization with separate point-estimate,
profile, bootstrap, and speed evidence.

## Boundaries

- This refresh does not change model code.
- This refresh does not implement native TMB REML for bivariate q4 models.
- This refresh does not make AI-REML available for Ayumi's q4 route.
- `B = 2` remains a plumbing smoke only, not an interval-calibration result.

## Team Notes

Fisher keeps the inference statement method-specific: Julia tiny bootstrap
plumbing succeeded, native ML bootstrap refits failed. Rose blocks any public
wording that compresses those into "bootstrap works." Grace now has a
repeatable negative native-bootstrap command for future regression checks.
