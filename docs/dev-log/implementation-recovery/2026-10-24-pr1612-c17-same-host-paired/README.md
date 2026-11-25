# C17 current-source paired receipt for PR #1612

This receipt checks only the three retained model-15 C17/C14 compatibility routes (`mc-0568`, `mc-0569`, and `mc-0576`). It does not add a model claim or measure CMR recovery, interval availability, or interval coverage.

The candidate run used PR #1612 source `07bb3b0a734d393811d0d4623a2198b7a553c695` on Totoro, with the committed runner SHA-256 `03e230c48539267d803a22e43ffcc68786b08236c4bd6bf9f11c1b1b37c9b1df`. Its provenance records R 4.6.1, TMB 1.9.25, and one-thread BLAS/OpenMP settings. The baseline reran the ledger's then-recorded source `8825b8b3e4cb010ed853327681a225cdc672b4e2` on the same Totoro host using the same runner and thread settings.

All 12 paired raw attempts match in every recorded field except `source_sha`; the three summary values are exactly equal. `paired-comparison.tsv` records each comparison. This paired same-host check replaces neither the historical C14 target nor the separate cross-host Mac receipt. The earlier Mac-to-Totoro difference is retained as history and is not used to relax the zero-tolerance guard.

The full run directories preserve the raw attempts, summary, provenance, and dirty-state records from both runs. Candidate run ID: `2026-10-24-cmr-1612-totoro-retry1`; baseline run ID: `2026-10-24-cmr-1612-c17-ledger-baseline-8825`.
