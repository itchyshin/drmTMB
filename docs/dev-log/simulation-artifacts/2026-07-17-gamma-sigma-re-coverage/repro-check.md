# mc-0242 Gamma σ-RE coverage — local↔Totoro reproducibility check

**Gate (gate-spec rev 2 §6):** a shared-seed cell must agree across platforms to ~1e-4, so the
Totoro campaign evidence is numerically consistent with a local build.

**Method:** `SEED_BASE = 20260900`, so the first replicate at every M is **seed 20260901**. The
local Mac-ARM gating smoke (`coverage-results-smoke-raw.tsv`, `pkgload::load_all`, Apple clang) and
the Totoro x86 campaign (`coverage-results-iid-raw.tsv`, `pkgload::load_all`, gcc/OpenBLAS,
`OPENBLAS_NUM_THREADS=1`) both fit the identical seed-20260901 data at each M. Compare `sd_hat`,
`profile_lower`, `profile_upper`.

| M | sd̂ (local / Totoro) | profile_lower (local / Totoro) | profile_upper (local / Totoro) |
|---|---|---|---|
| 16 | 0.30063 / 0.30063 | 0.18112 / 0.18112 | 0.48837 / 0.48837 |
| 32 | 0.43326 / 0.43326 | 0.32355 / 0.32355 | 0.58966 / 0.58966 |
| 64 | 0.46504 / 0.46504 | 0.38061 / 0.38061 | 0.57412 / 0.57412 |

**Max |local − Totoro| ≤ 5e-5** across all reported endpoints for M ∈ {16, 32, 64} — within the
~1e-4 gate. Cross-checked independently by the S4 math-consistency reviewer (Noether), who extracted
the Totoro seed-20260901 rows (raw rows 1202 / 2402 / 3602) and matched them to the local smoke to
every reported digit. The agreement confirms the fit is platform-stable and the coverage evidence is
numerically consistent across the two builds (both drmTMB 0.6.0.9000 @ a9b2633c).

**Scope:** M=8 was not among the local smoke's recorded rows, so the cross-platform check covers the
promoted range M ∈ {16,32,64}; M=8 is excluded from promotion regardless. Re-derivable at any time:
`raw[raw$seed==20260901, c("M","sd_hat","profile_lower","profile_upper")]` on each host.
