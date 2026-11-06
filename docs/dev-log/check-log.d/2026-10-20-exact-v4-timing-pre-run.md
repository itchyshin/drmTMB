| Date | Check | Command | Result | Host |
|---|---|---|---|---|
| 2026-10-20 | Exact-v4 Bernoulli timing-only pre-run | `python3 tools/general-sd-regression/native-calibration/run-095.py <timing-root> ...` | PASS for timing only: 45/45 completed in 27.548 s; all 45 profile intervals valid and independent Laplace-oracle checks passed; `calibration_claim=false`. | Totoro |
| 2026-10-20 | Timing receipt and result readback | Local Python audit of retained `capsule/` | PASS; manifest, source registry, supervisor, attempts, and summary hashes match recorded values; all fit rows checked. | Codex local |
| 2026-10-20 | Runtime projection | `9.757 * 188 + 180`, then multiplied by three batches | 2,014.316 s per batch; 6,042.948 s total (100.7 min), below 10,500 s. Projection only; source-bound GO is still required. | Codex local |
