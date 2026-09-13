TITLE: [Dinnage audit Mi-6] A tree with extra tips is pruned with no message in 25/25 fits; `?phylo` states no branch-length convention
LABELS: audit-dinnage, documentation, minor
---
Reported by Russell Dinnage, independent evaluation of drmTMB 0.7.0 at 945da24f
(https://github.com/rdinnager/drmTMB_eval/blob/main/REPORT.md §4, Appendix A row Mi-6; severity minor).
Supporting working: 25 fits with a tree carrying tips absent from the data, compared against a pre-pruned
fit; the frozen design asked for "identical to a pre-pruned fit and says so."

## What Russell found
A tree carrying tips absent from the data is pruned with no message, warning or `check_drm()` note in
25/25 fits. Related: `?phylo` states neither branch-length convention (drmTMB does not silently rescale --
either convention is acceptable, ambiguity about which one is not).

## Where (at 945da24f)
`R/drmTMB.R` (phylo preparation), `man/phylo.Rd`.

## Since-audit status on main (4bfb9d721, 2026-09-13)
PRESENT. `validate_phylo_tree()` (`R/phylo-utils.R:1-155`) builds `species_index <- match(species_levels,
tip_label)` and validates only that every *observed* species is represented in the tree
(`validate_phylo_species()`, `R/phylo-utils.R:165-183`, which errors on species missing from the tree) --
it contains no check, message, or count for the reverse case: tree tips absent from the data. No pruning
message is emitted anywhere in the phylo build path. `man/phylo.Rd` (checked for "convention", "rescale",
"branch length"): only states `"Ultrametric phylogeny input with branch lengths"` in the `tree` argument
description and "uses the Hadfield and Nakagawa ..." parameterization in Details -- no statement of which
branch-length convention (unit height vs raw) is assumed. `git log --oneline 945da24f..HEAD --
R/phylo-utils.R man/phylo.Rd` shows no commit adding a pruning message or a convention statement. No
existing-issue match: `gh issue list --search "prune"` and `--search "extra tips"` return nothing on
point.

## Proposed fix (Russell's, if stated)
"Note + 1 sentence" -- a pruning note when extra tips are dropped, and a sentence in `?phylo` stating the
branch-length convention.

## Acceptance
- [ ] a test that fails on 945da24f-behaviour and passes after: fitting with a tree carrying tips absent
      from the data produces a note (message or `check_drm()` row) naming how many tips were pruned
- [ ] `?phylo` states its assumed branch-length convention
- [ ] NEWS.md entry crediting the report
