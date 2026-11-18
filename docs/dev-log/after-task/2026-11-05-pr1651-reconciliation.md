# After task: reconcile PR 1651 with main

## Goal and implementation

Preserve the historical documentation-pin correction while reconciling its branch with main `9fea3036791e9bd836e080d9297cd04b1b29c2f8`. The merge retains both branches' historical check records and supplies a new compatibility receipt for the combined candidate. It changes no fitted-model equations, formula syntax or user examples.

## Checks and limits

The candidate's focused documentation test passed on Totoro. The three compatibility cells each passed four attempts; a same-host baseline and candidate produced identical summaries. The new receipt identifies package-source subsets, not full-tree commits, and did not record the loaded DLL hash. It also records a difference of at most 3.23e-11 from the previous Mac summary. The separate C14 receipt-equivalence check and capability-ledger check passed after reconciliation.

An exported candidate package passed a Linux `R CMD check --no-manual` with `NOT_CRAN=true`, reporting one spelling-output NOTE and testthat 0 failures, 117 warnings, 696 skips and 41,887 passes. The output reported difficulty terminating parallel workers; 138 live Julia bridge tests were skipped. The later receipt and this report were added after that check, so the check does not certify the final whole tree. The changed documentation test includes explicit source-pin assertions; broader cross-platform and live bridge checks remain outstanding.

## Consistency and follow-up

The historical source pin is a receipt identifier, not a claim of current R–Julia parity or calibrated intervals. The existing NEWS and generated help text carry the same pin. This task does not change model scope, mathematical documentation, or pkgdown navigation. The overlapping PR 1657 and its ledger conflict remain open; no issue was closed. The PR remains subject to exact-head CI and independent review before any separately authorized merge.
