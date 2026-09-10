# P2 homogeneous Toeplitz child receipt — source fingerprint

- Parent direct temporal OU close: `0d66e62f31b49a2b471a213805bc7123787c26ed`
- Calibrated direct-OU campaign source: `e57ed8c10ea7a715e58b4513ae17484d01b049a8`
- Parent direct-OU ledger: `docs/dev-log/plans/2026-09-08-temporal-ou/unlazy/GATES.md`, G0--G16 all passed.
- Child planning commit: `518280195c9ee27254d5ab8dbce37f241eaac8f2`.
- Before any P2 code edit, create a fresh execution lane from a source containing both parent commits and rerun `Rscript --vanilla tools/temporal-ou-gates.R G1` through `G11` and `G16`.

The phylogenetic-stable plus OU composition is an optional extension. Its pending profile-calibration gates do not weaken or block the direct temporal OU parent evidence used for this P2 child.
