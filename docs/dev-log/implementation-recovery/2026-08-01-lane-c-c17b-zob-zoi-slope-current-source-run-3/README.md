# C17-B current-source zero-one-beta zoi-slope recovery, run 3

Status: **COMPLETE — PASS_POINT_RECOVERY_LOCAL; fresh D-43 review pending**.

This directory is reserved for the authenticated rerun after synchronizing the
remaining public status surfaces and adding an explicit missing-response test
for the exact same-raw-symbol slope hint. The frozen DGP, seeds
`2026073801:2026073804`, `tau = sd_zoi = 0.45`, 32 groups by 50 observations,
formula, gates, and zero-SD diagnostic are unchanged.

The July evidence, run 1, and run 2 remain retained, non-load-bearing history.
Run 3 writes separately so no earlier attempt is discarded or relabelled.

Run 3 used source commit `ff5db60616e7ca362aa5f0c6d5817ab04e2baad9`
and runner SHA-256
`c8fa117d29fabeaf17062204f06b6fa7a603b75cfcc8e3757ff1f996e9afcf87`.
All four attempts passed: convergence was zero, `pdHess` was true, maximum
gradient was at most `0.003039`, `sd_zoi` stayed away from the declared
boundaries, mode correlations ranged from `0.667` to `0.838`, each group kept
zero/one/interior support, and mean relative `sd_zoi` error was `0.134522`.
The zero-SD run remains diagnostic only.

This positive recovery result is not by itself D-43 GO or a ledger promotion.
Do not interpret it as profile, interval, coverage, calibration,
inference-ready, supported, or broader atom-effect evidence.
