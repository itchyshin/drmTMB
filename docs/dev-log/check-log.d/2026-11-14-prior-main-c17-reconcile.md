# Prior table and main reconciliation

The combined source commit `1b454db75b5e5a6d0dd47703bffbd216ef2f8735` incorporates prior-table source and main `3b8d9737b47d72b180d1a981e4e6a0166bc7e569`. The C17 compatibility runner reproduced all three main-branch reference summaries at zero tolerance; 12 of 12 attempts passed. Both historical receipts remain available. This result covers the existing model-15 compatibility cases only.

`python3 tools/capability_ledger.py --check` and the 92 ledger unit tests passed. `python3 tools/capability_ledger.py --check-c14-receipt-equivalence` passed. The focused prior and weight-row tests passed 1,401 assertions with nine skips and no warnings. The live Julia bridge was skipped in this run. Full CI on the updated pull-request head remains required.
