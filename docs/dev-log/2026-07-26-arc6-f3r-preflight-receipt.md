# Arc 6 F3R — private provenance-runner preflight receipt

**Disposition:** `F3R_REVIEWED_AWAITING_COMMIT`.  Fisher and Rose approved the final private contract for commit; this is not authorization to execute F3. This receipt records a developer-only runner and immutable one-attempt contract.  No dataset was generated, no margin was fitted, no association object was constructed, and no sandwich helper was called during F3R.

## Frozen route

- Candidate: fixed-effect, complete-pair Bernoulli × ordinary-NB2, `association = ~1`, intercept-only staged alpha.
- F1M validation source: `e0af91fc610a751880dba22a1b342cfb50cb757b`.
- F1M engine blob: `R/associate-pairs-sandwich.R` = `d090f67b74bf5dfee6baa4396a8f45a3c977d6fd`.
- F1M deterministic-fixture blob: `tests/testthat/test-associate-pairs-staged-sandwich.R` = `d36b02b2ad470e641843d4f751ee1c998e6922bf`.

The future runner accepts only the frozen equals-form `--expected-sha=<SHA>` and `--out-dir=<PATH>` arguments.  Before creating its output directory, it requires a clean worktree, matching `HEAD`, both F1M blobs, the two private helpers, and `shasum -a 256` or `sha256sum`.  It restores the caller RNG state after its fixed `Mersenne-Twister` / `Inversion` / `Rejection` setup.

## Retained contract

The runner has an immutable output layout, an RDS-based dataset SHA-256, one-row terminal `status.csv`, stage-specific status allowlists, no-clobber behavior, fresh-margin/association fingerprints, fit diagnostics, and private sandwich storage only on success.  The packet explicitly assigns empirical-SD calibration to F4; F3 is provenance and availability only.

## Verification

Passed without invoking `f3r_main()`:

```r
testthat::test_file("tests/testthat/test-arc6-f3-provenance-smoke-runner.R")
devtools::test(filter = "associate-pairs-(staged-sandwich|bernoulli-nb2)$")
```

The runner test supplied 47 expectations covering strict CLI parsing, status-schema and terminal-status rejection, source guard, rectangle gate, existing-output rejection, SHA preflight rejection, RNG restoration, RDS-hash contract, frozen output location, local-namespace identity, terminal-ledger propagation, forced receipt-finalization failure, and post-transition terminal-stage propagation.  `git diff --check` passed.

## Exact next fence

After this F3R work is committed, a fresh written approval must name that final commit SHA and authorize exactly one invocation of `tools/run-arc6-bernoulli-nbinom2-f3-provenance-smoke.R`.  It authorizes no retry, F4, remote compute, `vcov()`, `confint()`, profile, public API, coverage, calibration, or public readiness claim.
