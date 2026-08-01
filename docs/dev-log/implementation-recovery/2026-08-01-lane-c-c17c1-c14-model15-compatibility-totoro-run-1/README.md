# C17-C1 current-source compatibility for C14 model-15 routes

## Verdict

`PASS_CURRENT_SOURCE_COMPATIBILITY` for all three C14 rows whose immutable
receipts were source-equivalent before the C17-C1 `coi` carrier was added:

- `mc-0568`: ordinary `sigma` random intercept, 4/4 pass;
- `mc-0569`: ordinary `zoi` random intercept, 4/4 pass;
- `mc-0576`: ordinary same-symbol `sigma` random slope, 4/4 pass.

Every attempt converged with `pdHess = TRUE`, maximum gradient at most `0.01`,
no SD boundary, mode correlation above `0.45`, and the route-specific support
gate satisfied. Mean relative latent-SD error was `0.0990`, `0.1661`, and
`0.0613`, respectively. Every fitted object reported `n_coi_re_terms = 0`,
confirming that the added C17-C1 carrier is inert for these routes.

## Authenticated source

- Source SHA: `19e5b045dfbaa1c5dea2453e255b717dda773c14`
- Runner SHA-256: `03e230c48539267d803a22e43ffcc68786b08236c4bd6bf9f11c1b1b37c9b1df`
- Host checkout: `/home/snakagaw/hsq_work/drmTMB-c17c1-compat-19e5b045`
- Pre-run worktree state: clean

The exact source blobs, namespace path, command, timestamps, all 12 attempts,
and summary are retained beside this note.

## Provenance boundary

This is a new current-source non-regression bridge. It does not rewrite,
replace, or rebaseline the ten immutable C14 receipts in
`c14-receipt-equivalence.tsv`. The seven source-different C14 receipts remain
ineligible, and this run does not promote any cell or widen any claim.
