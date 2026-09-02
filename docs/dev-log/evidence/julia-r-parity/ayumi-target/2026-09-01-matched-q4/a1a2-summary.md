# A1 / A2 summary — Hopper, drmTMB↔DRM.jl parity lane

Repo: `/private/tmp/drmtmb-control-audit` (branch `codex/rebase-julia-optimizer-controls`, not switched, not committed).

## A1 — alias repair confirmation

Command:
```
Rscript -e 'devtools::load_all("/private/tmp/drmtmb-control-audit", quiet=TRUE); testthat::test_file("/private/tmp/drmtmb-control-audit/tests/testthat/test-julia-bridge.R", reporter="summary")'
```

Verbatim output (see `a1-run.log`):
```
julia-bridge: .............................................................................................................................

══ DONE ════════════════════════════════════════════════════════════════════════
```

Counted 125 result markers, all `.` (pass) — no `F`/`W`/`S` characters present in the reporter line.

**Result: 125 PASS, 0 FAIL, 0 WARN, 0 SKIP.**

## A2 — matched-control fixture v2

Script: `q4-fixture-bridge-parity-v2.R` (this scratchpad dir). Changes from v1
(`/private/tmp/q4-fixture-bridge-parity.R`, untouched):
1. TMB fit dropped `control = drm_control(optimizer_preset = 'robust')` — uses `drm_control()` default.
2. Added an untimed warm-up `engine = 'julia'` fit on the first 60 rows of the same fixture/formula before the timed Julia fit.
3. Result line also written to `q4-fixture-v2-result.txt`, tagged `Q4_FIXTURE_BRIDGE_PARITY_V2`, with `tmb_conv_msg` appended (from `ft$optimizer_message`).
4. Fixture path, `bf()` formula, `REML = TRUE`, and coef/logLik comparison unchanged from v1.

Command:
```
Rscript q4-fixture-bridge-parity-v2.R 2>&1 | tee q4-fixture-v2-run.log
```

Result line (verbatim, also in `q4-fixture-v2-result.txt`):
```
Q4_FIXTURE_BRIDGE_PARITY_V2 conv_tmb=TRUE conv_julia=TRUE ll_delta=0.0162448722 max_coef_delta=0.0150611075 tmb_s=0.990 julia_s=5.727 n_common=7 tmb_conv_msg=NA
```

- `tmb_conv_msg=NA` — `ft$optimizer_message` was NULL/empty for this fit (field exists in drmTMB.R but wasn't populated here); no error raised, just no message to report.
- Wall time: script completed well under the 10-minute expectation (Julia session start + warm-up + timed fit all included in one run); TMB fit itself 0.990 s, Julia (warm, timed) fit 5.727 s.
- One warning emitted by the Julia engine during the fit (not an error):
  ```
  ┌ Warning: aic on a REML fit: REML log-likelihoods are only comparable across models with the SAME fixed-effect (mean) structure...
  └ @ DRM ~/Dropbox/Github Local/DRM.jl/src/gaussian_core.jl:1878
  ```
  (Benign — triggered by an internal AIC computation path, not by the fit itself; both `conv_tmb` and `conv_julia` report TRUE.)

No numbers here are claims of parity or speed — reported as measured only.
