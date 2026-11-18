# Current-source receipt recertification

The prior-only change made the whole-file capability receipt stale. CI stopped at receipt validation before running its package checks. The model-15 fingerprint still matched.

The Totoro run at source5d0f1596 passed the cell criteria but differed from the stored summary by at most3.23e-11. The exact-match recertifier rejected it. Its raw output is retained in rejected-totoro/. No tolerance was raised and no historical receipt was replaced.

The committed receipt identifies the Mac as its reference host. Running the unchanged compatibility runner there on source90aa17a4 reproduced all three stored summary values exactly, with12/12 attempts passing. The new receipt is under docs/dev-log/implementation-recovery/2026-11-06-gaussian-ri-priors-c17c2-c14-final-source-compatibility/. The current pointer now refers to that fresh run. The model-15 fingerprint, old raw attempts, old provenance and old summary files retain their previous bytes.

The capability ledger and current-source equivalence checks passed;97 capability-ledger and recertification tests passed. This check certifies the existing unpenalized model-15 cells, without widening their scope to Gaussian priors or calibrated inference.

The current pointer file also appears in PR1651. This update is confined to the isolated prior branch. PR1651 remains open at its protected head; its branch and historical evidence were not changed. Reconciliation remains a review task, with no merge or release.
