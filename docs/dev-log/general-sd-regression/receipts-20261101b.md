# Evidence receipts, batch 2026-11-01b

Branch codex/general-sd-regression, HEAD 7309d3cd8 (dirty shared tree). Each slice was run once with `devtools::test(filter = "^<stem>$", reporter = "summary", stop_on_failure = TRUE)` plus a final count line, under OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 NOT_CRAN=true. New evidence directories have the suffix 20261101b and hold test-console.log, source-manifest.json and receipt.json, all with one uniform schema (including evidence_grade, tolerances taken verbatim from the test header, and a not_covered list). The ledger direct-sd-evidence.tsv gained 17 rows, all unreviewed. Backup: scratchpad direct-sd-evidence.tsv.bak4-20261101.

Reconciler: EVIDENCE_RECONCILIATION_PASS candidate_rows=20350 linked_rows=265 evidence_records=320 (before: 262 and 303). Tool unit tests: 38 OK. Receipts link and seal; they do not review, calibrate or promote any row.

| Slice | Expectations | Grade | Rows linked |
|---|---|---|---|
| test-nbinom2-spatial-slope-sd-regression.R | 23 | focused_test | NB2 spatial_coordinate_slope, coordinates |
| test-nbinom2-structured-slope-marginal-simulate.R | 42 | workflow | NB2 relmat_numeric_slope K_covariance, phylo_numeric_slope tree (marginal simulation only) |
| test-nbinom2-gamma-same-group-sd-oracle.R | 10 | focused_test | NB2 and Gamma iid_numeric_slope |
| test-structured-sd-asymmetric-alignment.R | 52 | focused_test | Poisson spatial, NB2 relmat K, NB2 spatial, Gaussian relmat K, Gaussian spatial (intercepts) |
| test-structured-sd-nonunit-k-and-missing.R | 53 | focused_test | NB2 and Gaussian relmat K and Q; Binomial logit animal A, Ainv, pedigree |
| test-zi-poisson-plain-slope.R | 12 | focused_test | none (receipt only) |
| test-gamma-iid-structured-sd-regression.R | not receipted | | none |

Unmatched or not receipted.
- ZIP plain slope: only a constant SD (sd ~ 1) is fitted, so it is not predictor-dependent SD evidence; the zi_poisson mu iid_numeric_slope row already has its own receipt. Receipt written with an empty row list.
- Gamma iid plus structured: the test errors at the current tree (three blocks, "must name objects", an inline A = fx$K in the refusal check) after a concurrent edit at 16:03. No receipt, no ledger rows. Intended rows when it passes: gamma simultaneous_iid_structured, mu, A_covariance, Ainv_precision and phylo tree (the spatial pairing has no required row). Details in scratchpad batch7-evidence-receipts.patch.
- Missing-response refusals and drop-policy equality (nonunit-k file) and the NB2 slope-only structured rows: not linked, since they are refusals or complete-case equality, not likelihood checks.
- The marginal-simulate test has no likelihood oracle; the workflow grade says so. The two rows it names have other evidence.
- Weak points: the spatial, asymmetric and pedigree oracles use a helper under test for part of the construction (disclosed in each test header); recovery bounds are loose; one fixed-seed design per route; native engine only; no Julia parity.
