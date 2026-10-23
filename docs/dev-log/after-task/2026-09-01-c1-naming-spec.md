# After-task: coefficient-naming contract specification (issue #258, slice C1)

Date: 2026-09-01
Author: Claude Code (Boole, formula/API reviewer)
Branch: `claude/rev-parity-c1-naming-spec`

## What was done

Wrote `docs/design/258-coefficient-naming-contract.md`, a specification-only
document addressing the DRM.jl bridge-formula parity suite's 1-pass/6-fail
coefficient-NAME mismatch (DRM.jl issue #467, comment 5501007899). No R code
was written or changed; this slice deliberately stops at the spec.

## What the document contains

- The measured problem, cited to its source, plus confirmation (by grep across
  DRM.jl's `src/`) that DRM.jl does not currently implement or emit the
  `bridge_formula_labels_v1` / `coef_label_contract` map at all — the R-side
  validator in `R/julia-coefficient-labels.R` is currently unreachable dead
  code with no producer.
- A ten-row construct table (the six DRM.jl parity failures plus the four
  later cases from prior evidence work), each row giving today's base-R name,
  today's `drm_bridge` name, and a proposed canonical name — all read from
  `test/parity/gen_bridge_formula_fixtures.R`'s committed `name_map` and from
  `public-004.json` on branch `origin/codex/rebase-julia-optimizer-controls`,
  not reconstructed from memory.
- The no-punctuation-guessing constraint, argued from a concrete case (row 7,
  reversed two-factor interaction) where a spelling-only translator would
  additionally miss a term-order disagreement between the two sides.
- Both candidate authorities (base-R spelling wins vs DRM.jl's translated map
  wins) argued fairly, with a recommendation for (a) on usability grounds,
  explicitly flagged as a cross-repo governance call this document does not
  settle.
- A per-construct breaking-change assessment: adopting candidate (a) changes
  nothing under the native TMB engine (verified by reading `R/methods.R`'s
  `coefficient_labels()` and its three callers); whether it changes anything
  under `engine = "julia"` today is flagged **cannot determine**, because no
  shipping producer of `object$bridge_public_coef_labels` was found — flagged
  rather than guessed.
- An explicit "NOT decided here" section covering authority choice, map
  schema, row 7's ordering question, timeline/ownership, and CI gating.

## Constraints honoured

- No R file changed; no code written.
- DRM.jl was read-only (capabilities.md, test/parity/, src/ grep for the
  contract keys); nothing in that repo was modified.
- `inst/extdata/julia-capabilities.tsv`, `docs/dev-log/coordination-board.md`,
  `.github/workflows/`, and `docs/design/35-*` were not touched.
- No version bump, no push, no merge, no release action.
- Test suite was not run.

## Follow-up (not actioned here)

- The authority decision (§4 of the spec) needs a maintainer/reviewer call
  spanning both drmTMB and DRM.jl.
- Row 7's interaction-term ordering disagreement (noted in §3 of the spec) may
  be a separate `drm_bridge` bug independent of naming.
