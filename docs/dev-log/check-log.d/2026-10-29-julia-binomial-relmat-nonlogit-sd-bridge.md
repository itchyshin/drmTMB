# Check log: Julia Binomial relmat SD bridge under probit and cloglog

- Date: 2026-10-29
- Sources: drmTMB candidate `425bee81572c625a634b2b083050c5c57c1dc1f1` and paired DRM.jl candidate `70dbf564eb670144c63c08f61ea099084d95add2`; exact tested source hashes are in the evidence manifest.
- Command: exact environment and filter are recorded in `docs/dev-log/general-sd-regression/evidence/julia-binomial-relmat-nonlogit-sd-bridge-live-20261029/receipt.md`.
- Result: live focused bridge test exited 0 on Julia 1.10.0; one test ran and 22 expectations passed across probit and cloglog.
- Documentation: `pkgdown::check_pkgdown()` found no problems; existing Pandoc `--mathml` deprecation warnings remain.
- Evidence: four rows added for native and Julia probit/cloglog relmat q1 intercepts. Reconciliation passed with 20,350 candidate rows, 199 linked, 20,151 unlinked, and 222 evidence records. Rows remain unreviewed.
- Boundary: point recovery and output agreement only; no interval calibration, coverage, or broad Julia parity claim.
- Detailed report: `docs/dev-log/after-task/2026-10-29-julia-binomial-relmat-nonlogit-sd-bridge.md`.
