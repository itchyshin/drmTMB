# After Task: Overnight Finish-Plan Wave 1 (docs / claim / widget gaps)

## Goal

Acting as Ada in an autonomous overnight run, close the boundary-safe
documentation, claim, and widget gaps surfaced by the Wave 0 completion audit,
without crossing any critical claim boundary. Branch
`shannon/overnight-audit-gaps-20260619` off clean `origin/main` `bd1f3e46`;
pushes/PRs/merges held for owner review.

## Implemented

Wave 0 produced an adversarially-verified completion map (141 items;
18 wave-1 / 4 wave-2 / 2 wave-3 closable-now; 63 blocked), banked in
`docs/dev-log/2026-06-19-overnight-finish-orchestration.md`.

Wave 1 verified 14 read-only claim/widget boundaries (all PASS) and landed four
small edits:

1. README preview/install version drift `0.1.3` -> `0.1.4` (DESCRIPTION is
   already `0.1.4`; `v0.1.4` tag exists; only the version token changed, all
   pre-CRAN wording preserved).
2. A getting-started note that `bf()` is an exact alias of `drm_formula()`
   (`bf <- drm_formula`), so the spelling difference across articles is not read
   as a behavioural one.
3. Documentation for `coef.drmTMB` (folded into the `model-fit-extractors`
   topic, with the `dpar` argument documented) and an expanded `drmTMB()`
   `@return` describing the fit-object components.
4. An accelerator-vocabulary lint in `tools/validate-mission-control.py`
   (`GPU|CUDA|cuDNN|TPU|accelerator|compute-target|offload`, case-insensitive)
   that flags any public-file claim lacking a `planned`/`unsupported` guard,
   plus a matching Claim Guards bullet in design 168. The lint deliberately
   excludes the overloaded token `backend` (parallel-execution mode and the TMB
   precision backend).

## Mathematical Contract

No model, likelihood, parameterization, formula grammar, or numerical guard
changed. Public terms `sigma`, `rho12`, `meta_V(V = V)`, `phylo()`,
`spatial()`, `mu`, and `nu` are unchanged.

## Files Changed

- `README.md`, `vignettes/drmTMB.Rmd`
- `R/methods.R`, `R/drmTMB.R`, `man/model-fit-extractors.Rd`, `man/drmTMB.Rd`
- `tools/validate-mission-control.py`,
  `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/dev-log/2026-06-19-overnight-finish-orchestration.md`,
  `docs/dev-log/check-log.md`

## Checks Run

- `python3 tools/validate-mission-control.py` -> exit 0 (25/68, 17 matrix rows).
- `tools::checkRd()` on both hand-edited Rd files -> OK.
- Accelerator-lint logic unit check (fires on unguarded GPU/compute-target,
  exempts `planned`/`unsupported`, ignores bare `backend`).
- `git diff --check` -> clean.

## What Did Not Go Smoothly

`devtools::document()` could not be committed: the local roxygen2 is 7.3.2 while
the repository is generated with 8.0.0 (`Config/roxygen2/version: 8.0.0`).
Running `document()` here injected regressions (a conflicting `RoxygenNote`
field, deletion of the Authors block from `drmTMB-package.Rd`, and downgraded
`\link` targets), so those auto-generated changes were reverted and the two
target man pages were hand-synced in the 8.0.0 style instead. A matching-version
`document()` pass should be run when convenient to normalise cross-references.

## Consistency Audit

The Wave 1 verify sweep confirmed, before and after the edits, that q8 stays
diagnostic-only, q4 phylogenetic correlations stay derived-only, recovery stays
diagnostic-qualified, REML stays Gaussian-only, no release/CRAN or
`engine_control` language appears in public files, and the missing-data and
complete-case boundaries stay separate.

## Known Limitations

Documentation/claim/widget hygiene only. It promotes no capability and makes no
recovery/coverage/power, q4/q8 or binomial Julia bridge parity, release/CRAN,
non-Gaussian REML/AI-REML, or selectable `engine_control` claim. Native R/TMB,
direct DRM.jl, and Julia-via-R evidence remain separate lanes.

## Next Actions

Wave 2 (native R/TMB correctness, serialized on the shared TMB build):
`pdHess=FALSE` -> `non_pd_hessian` uncertainty status; single link registry;
known-V indefinite guard; and the Cholesky/logdet reformulation of the q>2
covariance density (strict equivalence-gated, held if it does not compile or
match). Then Wave 3 (figure axis fix; Gaussian-baseline article authored but
held for Florence/Darwin/Fisher review).
