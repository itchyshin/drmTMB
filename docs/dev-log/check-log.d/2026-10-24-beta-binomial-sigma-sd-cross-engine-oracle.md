# Check: BetaBinomial sigma-SD cross-engine oracle

- Date: 2026-10-24
- Branch: `codex/general-sd-regression`
- Test SHA-256: `fa803784011804c95df599e02a3410000e5372e2a2dc858d5f2fe78d333af1d2`

`devtools::test(filter = "julia-beta-binomial-sigma-sd-bridge", reporter = "summary", stop_on_failure = TRUE)` completed with exit code 0 and one live Julia bridge test. The fixture checks same-data SD coefficient and group-prediction agreement, then compares each fitted marginal log likelihood with independent one-dimensional integration. Julia’s 11-node adaptive Gauss–Hermite and TMB’s Laplace results are not required to be identical.

The report at `docs/dev-log/after-task/2026-10-24-beta-binomial-sigma-sd-cross-engine-oracle.md` records the mathematical contract, initial failed bound, exact command, scope limits, and open programme status. I repaired the deferred G5 marker syntax so the main ledger parses, without changing its status. The full after-task acceptance check still reports open programme and per-slice gates; a Tweedie sidecar has zero live gates for the standalone checker. This is one candidate point-parity cell and does not close a programme gate or establish interval calibration.
