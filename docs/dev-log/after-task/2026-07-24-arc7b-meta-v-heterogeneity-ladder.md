# After Task: Arc 7B known-`V` meta-analytic heterogeneity ladder

## Goal

Build the local evidence contract for Gaussian `meta_V(V = V)` location,
location-scale, direct-SD, nested direct-SD, and sigma-side random-scale
models without promoting any capability or merging B0 PR #828.

## Implemented

Added deterministic L/LS/LSS/LSSS/DH DGPs, a nested-effect representation, an
independent marginal Gaussian oracle for LS/LSS/LSSS, a diagonal ML `metafor`
comparator, an all-attempt profile reducer, and a six-cell local sentinel. The
DH extractor records a sigma-side random-effect SD separately from direct-SD
coefficients.

## Mathematical Contract

`meta_V(V = V)` supplies known sampling covariance; residual `sigma`,
`sd(study)`, and `sd(effect)` are separate additive variance layers in the
Gaussian oracle. The DH model instead randomizes log residual SD and is a scale
mixture, so it is intentionally excluded from that Gaussian-oracle claim.
`metafor` scale coefficients are log variance and equal twice the `drmTMB`
log-SD coefficients.

## Files Changed

The new contract is `docs/design/241-arc7b-meta-v-heterogeneity-ladder-contract.md`.
The DGP/oracle/summariser/runner live under `inst/sim/`; the independent oracle,
comparator, DGP, and all-attempt tests live under `tests/testthat/`. Local
sentinel and comparator receipts are in `docs/dev-log/evidence/`.

## Checks Run

- `git diff --check`: passed.
- Focused oracle/comparator/DGP test command: passed.
- Focused runner test command: passed, including the retained dense-LSS
  incomplete-profile fixture.
- Source-pinned local serial sentinel at `f86fed0188ca14356bc098d962e2675e22c39593`:
  six scheduled fits retained; all converged with `pdHess = TRUE`; dense LSS
  returned two non-finite direct-SD profile intervals.

## Tests Of The Tests

The oracle tests compare fitted ML log likelihoods to an independently built
Gaussian covariance for diagonal LS, dense LSS, and nested LSSS. The comparator
test checks `metafor` likelihood and the factor-of-two scale conversion. The
runner tests inject an outer failure and preserve it in the denominator; the
dense fixture asserts both non-finite direct-SD profile states remain present.

## Consistency Audit

The status inventory and stale-syntax scans recorded in `check-log.md` found no
reason to widen user-facing `meta_V()` documentation. The existing
meta-analysis and location-scale-scale articles remain conditional examples;
they are not rewritten to imply calibrated layered inference.

## GitHub Issue Maintenance

Inspected open #59 (Phase 18 framework) and #60 (comparator benchmark). No
issue comment or new issue was appropriate: the result is a local NO-GO, not a
new public feature or an issue resolution.

## What Did Not Go Smoothly

The first DGP draft gave every effect a unique label. Review caught that it
could not identify an effect-level SD; it was corrected to nested effect IDs
with two rows per effect. The dense LSS profile returns `nonfinite_interval`
for both direct-SD coefficients despite a clean Hessian. This is retained as
negative feasibility evidence.

## Team Learning

Fisher separated the DH scale-mixture model from the additive Gaussian oracle.
Rose required immutable source/session provenance, explicit all-attempt failure
statuses, and a no-go rather than a premature DRAC label. The resulting runner
now makes failed outer profiles count as failures in any future campaign.

## Known Limitations

No recovery, calibrated interval, coverage, bootstrap-completion, dense-LSS
profile-engine cross-check, remote-compute, or capability-tier claim is made.
DH has fitting/extraction smoke evidence only; it has no direct-oracle or
inference validation. `brms` and `blsmeta` were not installed locally.

## Next Actions

Do not submit DRAC work. A later, separately approved arc must repair or narrow
the dense direct-SD profile target, add the promised profile-engine and
bootstrap checks, rerun the source-pinned sentinel, and obtain fresh Fisher and
Rose approval before any remote calibration denominator is launched.
