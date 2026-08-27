# GOAL — S6 A7 family gate (IMMUTABLE — re-read at the top of EVERY arc)

## Mission

Ship drmTMB item 1 (#962) **one family at a time**: C++ `has_mi`
marginalisation for a response family that currently has none, plus an
R-side spec wire, a known-DGP recovery test, and one honest
`missing_predictor` ledger row. This is **not** a whitelist-only edit.

## Headline

**First family = Gamma response × one Bernoulli `mi()` predictor.**
Poisson is already wired (binary predictor only). #962's first unwired
row is Gamma (`model_type` 5).

## Invariants

- ONE lane: `cursor/lane-s6-family-gate` at
  `~/local-scratch/lanes/drmTMB-s6-family-gate` from `origin/main`.
  Do **not** edit the dirty drmTMB primary checkout. Do **not** touch
  MAG-completeness, MAG-wire, S3-grouping, or `drmTMB-s6-multi-mi`.
- C++ `has_mi` + `drm_response_log_density` leaf **before** adding
  `"gamma"` to `drm_missing_predictor_families()`.
- One family only this slice. Not lognormal, student, beta_binomial,
  or zi-*.
- One binary predictor only (sibling of poisson/binomial/nbinom2/beta).
- Not FIML across a SEM. Not `impute_joint`. Not k ≥ 2 on Gamma.
- Never claim capability-status `"covered"`.
- Explicit paths on every `git add`. NEVER `git add -A`.

## Authoritative WHAT

`LOOP/ultra-plan.md`. Charter:
drmSEM `docs/memory/2026-08-26-next-arc-s6-imputation.md` A7.
Issue: itchyshin/drmTMB#962.

## Definition of done

- Gamma response accepts one `mi()` + Bernoulli `impute_model()`.
- Manual 2-point-sum logLik identity (G2) and MCAR + MAR recovery
  smoke (G3, honest tier).
- Ledger row `mp-gamma-bernoulli` on the existing `missing_predictor`
  axis.
- Gate test `predictor_validated` updated in the same commit.
- drmSEM consumer **not** this slice unless the engine is already
  merged and the lift is trivial.

## Out of scope

- FIML / `impute_joint` / k ≥ 2 on a non-Gaussian response
- Continuous missing predictor under Gamma
- Lognormal / student / beta_binomial / zi-* (next families)
- drmSEM capability `"covered"`
- MAG / S3 grouping / dirty primary checkout
