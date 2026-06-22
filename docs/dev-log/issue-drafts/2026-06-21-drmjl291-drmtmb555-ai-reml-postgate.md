# Local Issue Comment Draft: DRM.jl#291 / drmTMB#555

Do not post without maintainer approval. Ayumi-facing communication remains
parked.

Draft:

The HSquared transfer work has now advanced one more local exact-Gaussian slice,
but it remains internal developer evidence only.

Banked in a clean DRM.jl worktree
(`/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot`,
`codex/ai-reml-gaussian-mme-pilot`):

- location-only Gaussian phylogenetic mean supplied-variance REML helper;
- dense same-estimand GLS oracle for the restricted objective;
- Takahashi selected-inverse trace diagnostic;
- Takahashi selected-inverse posterior-variance/PEV diagnostic;
- AI-vs-observed information diagnostic;
- finite-difference LBFGS optimizer experiment with
  `ai_reml_ready = false`;
- validation/status tuple and bridge payload draft with
  `r_bridge_status = planned` and `claim_status = internal_diagnostic`;
- machine-readable simulation-status rows with a schema validator, TSV writer,
  optional medium stress row, optional large-stress skipped row behind a runtime
  budget guard, and row provenance mapping;
- focused test: 370/370 assertions.

Claim boundary: this is exact-Gaussian location-only evidence. It does not
implement or advertise AI-REML, does not promote a drmTMB R bridge field, does
not apply to bivariate q4, Laplace, or non-Gaussian routes, and does not change
the 10k sigma-phylo interval blockers (`drmTMB#570`, `DRM.jl#293`,
`drmTMB#555`, `DRM.jl#291`).
