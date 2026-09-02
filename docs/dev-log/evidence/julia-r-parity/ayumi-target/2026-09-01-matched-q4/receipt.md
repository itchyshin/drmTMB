# Matched-control q4 bridge fixture — receipt (2026-09-01, Claude parity lane)

- A1: tests/testthat/test-julia-bridge.R on branch codex/rebase-julia-optimizer-controls: 125 PASS / 0 FAIL.
- A2 (matched: default TMB control, warm Julia, durable capture):
  Q4_FIXTURE_BRIDGE_PARITY_V2 conv_tmb=TRUE conv_julia=TRUE ll_delta=0.0162448722 max_coef_delta=0.0150611075 tmb_s=0.990 julia_s=5.727 n_common=7
- Diagnosis (a2-delta-diagnosis.md): TMB logLik -219.613986 vs Julia -219.630231 (route tol) and
  -219.632708 (g_tol=1e-10) — gap is g_tol-insensitive; TMB at the better optimum on this cell.
  Filed as DRM.jl#575. Execution + diagnosis evidence only; NOT a parity pass, NOT a speed claim
  (single fixture, single rep).
- Prior mismatched-control run (robust preset, cold Julia) retained at /private/tmp/q4-fixture-bridge-parity.log.
