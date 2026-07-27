# Lane B E2 phylo/spatial source-card notes

This is a no-compute, no-binding source classification for the frozen E0
cohort.  It neither selects a target nor changes capability, interval, or
campaign state.

## Frozen assignment

The input is the E0 manifest intersected with `structure_provider %in%
{phylo, spatial}`, after removing the 21 cell IDs already represented in the
checked partial binding table.  That leaves exactly 46 source cards.  The
provider/q label establishes the frozen stratum only; it was never used to
invent a component, DGP, truth scale, target, or information rung.

## Non-obvious classifications

- `q12` is a block dimension, not the distinct E0 `mc-0260m` K=12 negative
  control.  The q12 cards therefore retain unresolved multi-component targets.
- `mc-0214` and `mc-0215` are `source_found_not_direct`: the E0 exact-DGP
  probe explicitly reports unknown confidence-interval targets for their q4
  scale-side terms.  This is stronger than a generic missing-field label.
- `mc-0216`--`mc-0219` retain the primary committed test as found, but the
  cited dense-q4 ladder is uncommitted; it cannot supply a frozen DGP/version,
  truth, direct target, or rung.
- The remaining cards have a local ledger/test/fixture source but lack at
  least one required exact-binding field.  Formula hints are marked `present`
  only where the worklist itself recovered an explicit source formula; they are
  not treated as executable DGPs.

No row meets the all-fields-present plus one-target rule, so every tranche
disposition is `deferred` rather than `candidate_review`.
