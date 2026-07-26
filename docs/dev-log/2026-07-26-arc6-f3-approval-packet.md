# Arc 6 F3R — one-cell provenance smoke approval packet

**DRAFT ONLY — NOT F3 EXECUTION AUTHORIZATION.** This is a provenance-only
contract for one local attempt, usable only after the owner supplies fresh
written approval naming the full post-F3R runner SHA. It does not authorize a
refit now or any inference claim.

## Authorized action if separately approved

Run exactly one local-only full-refit provenance smoke for fixed-effect,
complete-pair Bernoulli × ordinary-NB2 `association = ~1`. Its only possible
claim is: **“one full-refit provenance smoke completed under the frozen F3R
contract.”** It cannot support a claim about empirical SD, SE validity,
interval validity, recovery, coverage, calibration, or public readiness. Outer
empirical-SD calibration is F4-only.

## Frozen source, invocation, and RNG contract

The approved SHA must be the full 40-character Git object ID. Before invoking
R, the operator must verify that `git rev-parse HEAD` equals that SHA and that
the two F1M critical blobs remain:

| Path | Required blob |
| --- | --- |
| `R/associate-pairs-sandwich.R` | `d090f67b74bf5dfee6baa4396a8f45a3c977d6fd` |
| `tests/testthat/test-associate-pairs-staged-sandwich.R` | `d36b02b2ad470e641843d4f751ee1c998e6922bf` |

These are the validated blobs at F1M SHA
`e0af91fc610a751880dba22a1b342cfb50cb757b`. Any mismatch is a preflight
failure, not a permitted source substitution.

The only permitted invocation is, with both placeholders replaced literally
from the written approval:

```sh
Rscript --vanilla tools/run-arc6-bernoulli-nbinom2-f3-provenance-smoke.R --expected-sha=<approved-full-SHA> --out-dir=docs/dev-log/smoke/2026-07-26-arc6-f3-<first-12-of-approved-full-SHA>/attempt-001
```

No other argument, environment override, wrapper, seed override, start value,
or output directory is permitted. The runner must reject a nonempty output
directory. A relative `--out-dir` is interpreted from the drmTMB package root
before it is compared to the frozen SHA-specific `attempt-001` path. It must
set `RNGkind("Mersenne-Twister", "Inversion", "Rejection")`
before `set.seed(2026072603L)` and record both the resulting `RNGkind()` and
the generated `.Random.seed`; its frozen DGP is therefore not configurable.

SHA-256 capture is an external command-line preflight, not an R package
dependency. The runner must use either `shasum -a 256` or `sha256sum` to hash
the generated dataset and every immutable artifact listed below, except the
self-referential `metadata/artifact-sha256.tsv` manifest itself; record which
command was used, and fail closed before fitting if neither command is
available or a digest command fails. Do not add `digest` to package
dependencies to satisfy this contract.

## Frozen DGP and fitting protocol

- `n = 120`; `x = seq(-1, 1, length.out = n)`.
- Bernoulli logit: `-0.15 + 0.25*x`.
- Ordinary-NB2 log mean: `0.35 + 0.15*x`; NB2 `sigma = 0.6`.
- True staged `alpha = 0.22`, with `eta = 0.999999 * tanh(alpha)`.
- Generate complete paired responses through the existing private
  ordinary-NB2 normal-quantile route.
- Fit fresh margins `binary ~ x` and `count ~ x, sigma ~ 1`; then fit
  `associate_pairs(..., association = ~1)`.
- Call only the private sandwich helper. Do not call `vcov()`, `confint()`, a
  profile, bootstrap, or any public inference method.

## Immutable artifact layout

`<out-dir>` is exactly the CLI value above. The runner writes each listed path
once; it must neither overwrite an existing path nor replace a failed attempt
with a repaired artifact. The required layout is:

```text
<out-dir>/
  status.csv
  stage-status.csv
  input/dgp.tsv
  input/dataset.csv
  input/dataset.rds
  input/dataset.sha256
  fit/bernoulli-margin.rds
  fit/nb2-mean-margin.rds
  fit/nb2-dispersion-margin.rds
  fit/association.rds
  fit/fit-diagnostics.csv
  fit/association-diagnostics.csv
  private/sandwich.rds
  metadata/provenance.tsv
  metadata/rng.tsv
  metadata/session-info.txt
  metadata/source-blobs.tsv
  metadata/sha256-command.txt
  metadata/artifact-sha256.tsv
  logs/stdout.txt
  logs/stderr.txt
```

`status.csv`, `stage-status.csv`, and the `metadata/` files are required after
every post-layout terminal outcome, including a DGP, serialization, hash, fit,
association, rectangle, sandwich, or delta failure. `input/dataset.sha256` is the SHA-256 of the serialized
`input/dataset.rds` object; `input/dataset.csv` is retained only for inspection.
A file downstream of the terminal stage must be absent, not an empty
placeholder. `private/sandwich.rds` is permitted only for terminal status
`success`; it is private evidence and cannot be attached to a fitted object or
used by a public method. `metadata/provenance.tsv` must record the source SHA,
F1M SHA, both required blobs, exact CLI, runner path, requested output path,
R and package versions, and fresh-margin and association fit identities.

## Status CSV: vocabulary and precedence

`status.csv` contains exactly one row, with columns `source_sha`, `seed`,
`dataset_sha256`, `terminal_stage`, `terminal_status`, `bernoulli_margin_id`,
`nb2_mean_margin_id`, `nb2_dispersion_margin_id`, `association_id`,
`private_result_available`, `alpha_godambe_available`, `eta_delta_available`,
and `interval_status`. The sole allowed
`terminal_status` values are:

| Terminal stage | Allowed terminal status |
| --- | --- |
| `dgp_harness` | `dgp_harness_failure`, `provenance_mismatch`, `sha256_preflight_failure` |
| `bernoulli_margin` | `bernoulli_margin_failure` |
| `nb2_mean` | `nb2_mean_failure` |
| `nb2_dispersion` | `nb2_dispersion_failure` |
| `association` | `association_unresolved`, `association_boundary`, `association_failure` |
| `rectangle` | `association_nonfinite_derivative`, `association_step_unstable`, `rectangle_failure` |
| `sandwich` | `bread_or_meat_unstable`, `bread_solve_failure`, `covariance_unstable`, `sandwich_failure` |
| `delta` | `eta_delta_unstable`, `delta_failure` |
| `interval` | `not_attempted` |
| `complete` | `success` |

Evaluate stages in this fixed precedence:

`dgp_harness → bernoulli_margin → nb2_mean → nb2_dispersion → association → rectangle → sandwich → delta → interval`.

`stage-status.csv` contains exactly nine rows, in the stated precedence order,
with columns `stage`, `status`, and `reason`. Its `status` is exactly `ok`,
`failed`, or `not_attempted`. The first failed stage supplies the terminal
values; every later row is `not_attempted`. `interval_status` is always
`not_attempted`; no F3R result may contain an interval. `alpha_godambe_available`
and `eta_delta_available` are recorded independently; neither is inferred from
the other. An alpha result is available only when it is actually retained in the
private result: an `eta_delta_unstable` outcome currently retains no partial
alpha object, so both availability fields are `FALSE`. `private_result_available` is `TRUE` only when the private result is
actually retained. A cached fit, stale source, source/blob mismatch, or missing
digest preflight is a protocol failure and never a substitute for a fresh fit.

## Stop rule and exclusions

Stop after the one attempt. Do not retry, change the seed, alter starts, tune
tolerances, or repair in response to its result. This authorization excludes
F4/F5, Totoro/DRAC, simulations or calibration, public APIs/docs,
capability-ledger movement, Arc D/F5, other pair classes, association slopes,
random effects, missingness, weights, offsets, REML, and direct
`biv_lognormal()` `rho12` inference.

## Approval text required before execution

> I approve exactly one local F3R provenance smoke at source SHA
> `<approved-full-SHA>` under
> `docs/dev-log/2026-07-26-arc6-f3-approval-packet.md`. This approval permits
> exactly the frozen CLI and `attempt-001` layout, and does not authorize F4,
> public inference, calibration, or any retry.
