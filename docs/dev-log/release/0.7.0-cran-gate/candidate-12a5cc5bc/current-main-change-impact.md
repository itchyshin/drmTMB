# Current-main change-impact and rights continuity — candidate `12a5cc5bc`

Date: 2026-08-18

The prior executable ledger covered candidate `302ac2579…`. A direct extracted-
tarball comparison against current candidate `e9c5556d…` is preserved in
`predecessor-tarball-diff.txt`. It identifies changes in package code, generated
documentation, vignettes, tests, NEWS/README, and
`inst/extdata/julia-capabilities.tsv`.

## Rights and component impact

- No new `data/` component, image, font, PDF, compiled binary, or third-party
  source asset was added.
- `inst/COPYRIGHTS` is present and unchanged between the two tarballs.
- The only changed installed evidence/data-like component is
  `inst/extdata/julia-capabilities.tsv`, an internally maintained capability table;
  no new external rights holder or licence is introduced.
- Existing installed CSV/TSV trust-dossier and simulation components are unchanged.
- Source additions are package-authored tests; modifications to R/C++ code,
  documentation, and generated HTML introduce no newly copied component.

Therefore the 2026-08-15 component ledger and rights review remains applicable to
the current candidate, with this document supplying the candidate-specific change-
impact bridge. Grace and Rose must independently verify this conclusion before any
submission-ready claim.

## Product-contract impact

The candidate includes substantive R/C++ and user-facing changes since the prior
ledger. Those changes are not certified by the predecessor platform evidence; they
are covered by the new candidate's local exact-byte check, current-source 3-OS and
R-hub checks, three-arm win-builder packet, rendered documentation check, and fresh
panel review. Capability expansion beyond the shipped current-main contract remains
out of scope for this release lane.

This document makes no claim above `platform-clean` and authorizes no submission.
