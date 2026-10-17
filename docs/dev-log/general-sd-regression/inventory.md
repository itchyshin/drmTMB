# General random-effect SD inventory

Pinned drmTMB `d89db50975d96d9c2bcb13046453ae34c7fcf49b` and DRM.jl `b1832c7a686decf4e3d7a06ad8382bf164b9d8d4`.
The paired DRM.jl source was read through `git show` at its recorded commit; dirty or untracked checkout files were not read.

This is a reproducible source inventory, not a complete Cartesian product. Marginal family, endpoint, provider, effect, dimension, q, and estimator lists do not imply all combinations are supported.

The native capability ledger contains 751 rows (703 on `model_surface`) and 18 represented family routes. The native family dispatcher contains 17 builders.
The Julia family registry contains 17 rows; 0 native builder/ledger family names lack a Julia-registry mapping after aliases. This mapping count does not measure direct-SD support.
Native family-level direct-SD review status: 3 has at least one explicit route, 15 has an explicit family-builder refusal, and 2 remain unclassified.

## Direct SD routes found

| Engine | Family | Endpoint | Provider/effect | Block | Status | Evidence |
|---|---|---|---|---|---|---|
| tmb | gaussian | mu | iid / random_intercept | q1 | structural_reviewed | `R/drmTMB.R:4061` |
| tmb | gaussian | mu | phylo / structured_intercept | q1 | structural_reviewed | `R/random-effect-scale-formulas.R:14` |
| tmb | beta | mu | phylo / structured_intercept | q1 | structural_reviewed | `R/drmTMB.R:6306` |
| tmb | biv_gaussian | mu1/mu2 | iid or phylo / random_intercept | q1 per endpoint | structural_reviewed | `R/random-effect-scale-formulas.R:12` |
| julia | gaussian | mu | iid / random_intercept | q1 LSS; multiple iid components also route through LSS | structural_reviewed | `src/gaussian_lss.jl:25` |
| julia | gaussian | mu | phylo / structured_intercept | q1 LSS; may combine with iid components | structural_reviewed | `src/gaussian_lss.jl:9` |
| julia | gaussian | mu | multiple iid and/or phylo components / random_intercepts | multi-component LSS | structural_reviewed | `src/gaussian_lss.jl:43` |

## Status meanings

`structural_reviewed` means the pinned source path or explicit formula declaration was inspected. It does not mean simulation recovery, interval calibration, inference readiness, or all sibling cells passed.
`missing` means a pinned native family builder has an explicit SD-formula refusal (with route-specific exceptions retained in adjacent source context). `required` means the family route lacks a direct-SD classification or a Julia registry mapping; it remains unresolved rather than assumed unsupported.

## Known scope boundary

The generated output retains every ledger row and registry family list as source data. It does not turn the marginal axes into a full crossproduct. Endpoint-specific covariance blocks, random slopes, crossed/nested effects, temporal structures, provider interactions, and engine parity need explicit per-cell source review before a route can be marked supported or missing.

Native family builders with explicit SD-formula refusal text found: 13. See the JSON for each source line.
Current native checkout candidate: `unverified_worktree_changes`; its hashes are separate from both pinned baselines and do not alter capability counts.
