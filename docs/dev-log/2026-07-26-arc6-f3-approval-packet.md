# Arc 6 F3 — one-cell provenance smoke approval packet

**DRAFT ONLY — NOT F3 AUTHORIZATION.** This packet may be used only after the owner supplies a fresh written approval that names the final post-F1M source SHA.  It does not create a runner and it does not authorize a refit now.

## Authorized action if separately approved

Run exactly one local-only full-refit provenance smoke for fixed-effect, complete-pair Bernoulli × ordinary-NB2 `association = ~1`.  The smoke's only possible claim is: **“one full-refit provenance smoke completed.”** It cannot support a claim about SE validity, interval validity, recovery, coverage, or public readiness.

## Frozen DGP and fitting protocol

- `n = 120`; seed `2026072603`; `x = seq(-1, 1, length.out = n)`.
- Bernoulli logit: `-0.15 + 0.25*x`.
- Ordinary-NB2 log mean: `0.35 + 0.15*x`; NB2 `sigma = 0.6`.
- True staged `alpha = 0.22`, with `eta = 0.999999 * tanh(alpha)`.
- Generate the complete paired responses from the latent-normal construction, using the package's existing private ordinary-NB2 normal-quantile route for the count margin.
- Fit fresh margins `binary ~ x` and `count ~ x, sigma ~ 1`; then fit `associate_pairs(..., association = ~1)`.
- Call only the private sandwich helper.  Do not call `vcov()`, `confint()`, a profile, bootstrap, or any public inference method.

## One-attempt outcome ledger

Record one mutually exclusive terminal status per attempted dataset, with this precedence:

`DGP/harness → Bernoulli margin → NB2 mean → NB2 dispersion → association → rectangle → sandwich → delta → interval`.

The interval status is always `not_attempted`.  Retain the source SHA, seed, dataset hash, package/runtime versions, both fresh-margin fit identities, association identity, every status, and private-result availability.  Cached or provenance-mismatched fits are a protocol failure, not a substitute for the specified fresh fits.

## Stop rule and exclusions

Stop after the one attempt.  Do not retry, change the seed, alter starts, tune tolerances, or repair in response to its result.  This authorization would exclude F4/F5, Totoro/DRAC, simulations or calibration, public APIs/docs, capability-ledger movement, Arc D/F5, other pair classes, association slopes, random effects, missingness, weights, offsets, REML, and direct `biv_lognormal()` `rho12` inference.

## Approval text required before execution

> I approve exactly one local F3 provenance smoke at source SHA `<final-post-F1M-SHA>` under `docs/dev-log/2026-07-26-arc6-f3-approval-packet.md`.  This approval does not authorize F4, public inference, or any retry.
