# Prior table and main compatibility reconciliation

The prior-table pull request and current main each changed the C17 source receipt. The combined source required a new receipt because its fitting file differed from both recorded versions. Source `1b454db75b5e5a6d0dd47703bffbd216ef2f8735` reproduced the three main-branch reference summaries at zero tolerance, with all 12 recorded attempts passing. The historical receipts are retained.

The ledger checks and 92 ledger tests passed. Focused prior and weight-row tests passed 1,401 assertions with nine skips; the live Julia bridge was not exercised. An independent review checked the receipt and source pins. Full CI for the updated pull-request head remains open, and the receipt does not widen the model-15 compatibility claim.
