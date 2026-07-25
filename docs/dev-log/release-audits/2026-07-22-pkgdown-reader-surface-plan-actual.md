# Plan-versus-actual: pkgdown reader-surface formal closeout

## Planned boundary

The audit programme was a reader-surface repair lane: 32 Codex-owned authored
articles, two legacy routes, homepage/navigation/search, 68 Rd topics covering
51 exports, and generated reference routes. It explicitly deferred model/API
work, capability promotion, simulation, CRAN, deployment, and platform gates.

## Actual delivery

The original 32 article closeouts and the two legacy-route dispositions were
already merged in PR #816 (`1a972b8e`). During the second pass,
`bivariate-coscale` transferred to Codex and its P1 certification wording was
repaired. The completed reader inventory is therefore 35 authored sources, 36
article HTML routes including the index, 68 Rd topics, 51 exports, 69 canonical
reference routes, and 98 generated reference HTML files when alias redirects
are included.

The formal closeout added the missing eight-batch reference ledger, reconciled
the old owner-held bivariate record with the second-pass repair, removed
trailing whitespace from the original audit records, and retained a fresh
clean-worktree validation receipt. The D-43 review is recorded separately.

## Reconciled deltas

| Plan item | Actual disposition |
| --- | --- |
| 32 Codex-owned articles | Completed in the first pass; no article was restarted. |
| Two legacy routes | Audited and retained with explicit dispositions. |
| Owner-held `bivariate-coscale` | Ownership transferred during the second pass; the false “certified” interval wording was repaired. |
| Eight reference batches | Audit evidence existed as an aggregate table; the formal closeout supplies the explicit 1+17+7+2+29+5+4+3 topic/route ledger. |
| 98 reference routes | Reconciled as 69 canonical sitemap routes plus 29 generated no-index alias redirects. |
| Final independent verdict | Required and recorded in the D-43 closeout record. |

## Negative space

This reconciliation closes documentation assurance. It does NOT declare drmTMB
ready for CRAN, deploy a site, validate a platform matrix, run a package check,
change a likelihood or formula grammar, promote a capability, or certify
coverage for either constant or predictor-dependent `rho12` intervals.
