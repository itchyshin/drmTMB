# Bernoulli stage-two timing pre-run

The reviewed Totoro runner completed 45/45 selected fits in 38.101 seconds. All
configured fit-health and independent Laplace-oracle checks passed. Projected
runtime for 9,000 fits is 98.28 minutes from summed fit service time plus
measured setup, and 127.00 minutes from observed batch wall time. Maximum
single-child RSS was 265,256 KiB; aggregate concurrent RSS remains unmeasured.
These are throughput results, not calibration evidence.

The source runner checked the preparation and qualification receipts, all three
batch registries, imported Python modules, package artifacts, Rscript launcher,
R version/home, worker, and selected seed/truth mappings before output creation.
Independent review approved the final source hashes. All 241 copied output
files match the remote SHA-256 manifest.

Attempt reconciliation checked all 9,000 frozen rows. V8 started indices
1–382: 366 completed, 16 were interrupted, and index 382 has no result file.
The timing pre-run repeated 1–15, which are excluded from unique attempt counts.
Its indices 3,001–3,015 and 6,001–6,015 were new relative to v8. The ledger
marks 412 unique seeds consumed and 8,588 eligible for future attempts at
383–3,000, 3,016–6,000, and 6,016–9,000. Full report:
`docs/dev-log/after-task/2026-10-19-bernoulli-timing-pre-run.md`.
