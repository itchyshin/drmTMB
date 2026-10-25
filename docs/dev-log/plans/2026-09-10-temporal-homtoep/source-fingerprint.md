# P2 homogeneous Toeplitz child receipt — source fingerprint

- Parent direct temporal OU close: `0d66e62f31b49a2b471a213805bc7123787c26ed`
- Calibrated direct-OU campaign source: `e57ed8c10ea7a715e58b4513ae17484d01b049a8`
- Parent direct-OU ledger: `docs/dev-log/plans/2026-09-08-temporal-ou/unlazy/GATES.md`, G0--G16 all passed.
- Original child planning commit: `518280195c9ee27254d5ab8dbce37f241eaac8f2`.
- S0 execution lane base: `c6ff7c47e`, which contains the full direct-OU closeout `73a440c3b` and its executable gate runner. The planning receipts were replayed as `0f842ea61`, `27fb46848`, and `a6cd24617` after a first child lane was found not to descend from the direct-OU provider.
- Fresh-parent replay on 2026-09-10: `G1` through `G11` and `G16` each emitted its `TEMPORAL_OU_G*_PASS` receipt on the corrected lane. The commands were `Rscript --vanilla tools/temporal-ou-gates.R G<number>`; the S0 check-log entry records the complete receipt set.

The phylogenetic-stable plus OU composition is an optional extension. Its pending profile-calibration gates do not weaken or block the direct temporal OU parent evidence used for this P2 child.
