# Lane B E2 animal, relmat, and phylo-interaction source-card notes

This is a source-card pass only.  It changes no canonical binding, schedule,
pregrid, compute state, capability evidence, package code, or public claim.

## Non-obvious decisions

- The frozen cohort is defined from the E0 inventory's
  `binding_status == "needs_exact_binding"`, not from null targets or from a
  provider-level search.  This produces 36 cards.
- A generic `profile_targets()` assertion for `phylo_interaction` is marked
  `not_direct`, not `present`: it proves an API parameter exists but neither
  selects a row-specific campaign target nor supplies that row's replayable
  DGP/truth/rung.
- The q6/q12 admission and recovery notes are kept as source evidence but do
  not fill cell-level truth, target, or rung fields.  Their provider-wide
  recovery summaries cannot be split into individual endpoint contracts.
- The animal/relmat matched `mu + sigma` receipts retain their useful negative
  geometry evidence.  They do not choose between split SD diagnostics and the
  matched correlation target, so their target cardinality remains multiple.
