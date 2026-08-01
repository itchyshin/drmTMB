# C17-B current-source zero-one-beta zoi-slope recovery

Status: **COMPLETE — PASS_POINT_RECOVERY_LOCAL; fresh D-43 review pending**.

This directory is reserved for the authenticated current-source rerun of
`mc-0577`, using
`tools/run-lane-c-c17b-zob-zoi-slope-current-source-recovery.R`. The runner
keeps the frozen July DGP, seeds `2026073801:2026073804`, `tau = 0.45`, 32 groups
by 50 observations, exact formula, recovery gates, and zero-SD diagnostic.

The run used source commit `5e1b8d2b5406a3a29821d2007bb28769b7d6ce40`
and runner SHA-256
`36e109d0cddbe74cb8791c57410b0f9b027eb6bcdbcb1f0efad8282b6cdc166d`.
All four frozen attempts passed: convergence was zero, `pdHess` was true,
maximum gradient was at most `0.003039`, the estimated SD stayed away from the
declared boundaries, mode correlations ranged from `0.667` to `0.838`, every
group retained zero, one, and interior support, and mean relative `tau` error
was `0.134522` against the `0.40` gate. The zero-SD run is retained only as a
boundary diagnostic.

The directory
`docs/dev-log/implementation-recovery/2026-07-30-lane-c-z6-zob-zoi-slope-local-run-1/`
is quarantined historical evidence. Its README and raw files record inconsistent
July source SHAs, so it is preserved for audit history but is non-load-bearing
for C17-B. It must not be rewritten to look like current-source evidence. This directory holds the
current rerun's per-fit streamed attempts, summary, diagnostic, provenance,
dirty-state listing, and progress log.

The recovery pass is positive scoped evidence, but it is not by itself D-43 GO
or a ledger promotion. Do not interpret it as profile, interval, coverage,
calibration, inference-ready, supported, or broader atom-effect evidence.
