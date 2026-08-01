# C17-B current-source zero-one-beta zoi-slope recovery, run 2

Status: **COMPLETE — PASS_POINT_RECOVERY_LOCAL; fresh D-43 review pending**.

This directory is reserved for the authenticated rerun after the second D-43
repair. The runner preserves the frozen DGP, seeds `2026073801:2026073804`,
`tau = sd_zoi = 0.45`, 32 groups by 50 observations, exact formula, recovery
gates, and zero-SD diagnostic. It differs from run 1 only by binding the evidence
to the repaired source commit and by writing to this new directory so every
earlier attempt remains retained.

The July evidence and C17-B run 1 remain historical, non-load-bearing records.
Neither is rewritten or used as proof for the repaired-source promotion.

Run 2 used source commit `eddc1412962f91342a78f33c66a3d454a0679d8d`
and runner SHA-256
`8f939dc6c3b95444354097bdf91061ec08eb1ca66ce139d13351f17829b256d6`.
All four attempts passed: convergence was zero, `pdHess` was true, maximum
gradient was at most `0.003039`, `sd_zoi` stayed away from the declared
boundaries, mode correlations ranged from `0.667` to `0.838`, each group kept
zero/one/interior support, and mean relative `sd_zoi` error was `0.134522`.
The zero-SD run remains diagnostic only.

This positive recovery result is not by itself D-43 GO or a ledger promotion.
Do not interpret it as profile, interval, coverage, calibration,
inference-ready, supported, or broader atom-effect evidence.
