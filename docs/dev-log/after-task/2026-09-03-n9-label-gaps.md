
# N9 (#1127): the three coef_labels gaps N7 skipped, plus a fourth found closing them

**Reader**: anyone touching `drm_julia_bridge_payload_coef_labels()`
(`R/julia-bridge.R`), `tests/testthat/test-julia-sigma-phylo-reml.R`,
`tests/testthat/test-julia-tmb-parity.R`, or
`tests/testthat/test-julia-slope-nongaussian.R`; anyone reading design 258's
S7.7/S7.8; anyone wondering why a phylo term on `sigma`, a random-slope
phylo term, or a q2 (not q4) bivariate phylo formula used to abort
`engine = "julia"` with `coef_labels is missing an entry for dpar "..."`.

## What N7 left visibly broken

N7 (`docs/dev-log/after-task/2026-09-03-n7-skip-swallow.md`) removed
skip-swallowing everywhere in the live Julia test suite, which turned three
previously-silent DRM.jl echo aborts into four visible `testthat::skip()`
calls (two land in the same test file) naming the exact DRM.jl error text:

1. `test-julia-sigma-phylo-reml.R:538` -- `sigma ~ phylo(1 | species, tree =
   tree)` REML fit: `coef_labels is missing an entry for dpar "resd_sigma"`.
2. `test-julia-tmb-parity.R:353` -- a q2 bivariate `phylo()` residual-
   correlation formula (`mu1`/`mu2` sharing one `phylo()` term, ML):
   `coef_labels is missing an entry for dpar "phylocov"`.
3. `test-julia-tmb-parity.R:1337` -- the SAME `resd_sigma` construct as (1),
   but fit via `drm_julia_bridge_payload(method = "ML")` directly.
4. `test-julia-slope-nongaussian.R:66` -- `y ~ phylo(1 + x | species, tree =
   tree)` (Gamma): `coef_labels lacks 'resd' for a random-slope phylo block`.

## Method

Per construct: build the exact formula from the failing test, call
`drm_julia_bridge_payload()`/`drm_julia_call_bridge()` directly against the
pinned 77513aa0 clone with the offending block omitted from
`options$coef_labels`, and read DRM.jl's own abort text -- it names the
missing dpar, the column count, and the exact Julia-side names
(`"... Julia names: [...]"`). No label was ever guessed from punctuation
(design 258 S3's binding constraint); every rule below is read off that
text.

## Per-construct findings

### (a) `resd_sigma` -- a phylo random-intercept term on a non-`mu` dpar

`sigma ~ phylo(1 | species, tree = tree)` (mu plain): Julia names
`["resd_sigma_species:sd_sigma"]` (ONE column). Rule: block key
`"resd_<dpar>"`, one label, the COMPOUND term `"<group>:sd_<dpar>"` -- not
the bare group `mu`-side phylo uses. Generalised to any non-`mu` dpar
carrying a bare-intercept `phylo()` term (only `sigma` is reachable through
today's formula grammar, but the rule does not special-case the string
`"sigma"`).

### (b) `resd` for a random-slope phylo term on `mu`

`y ~ phylo(1 + x | species, tree = tree)` (Gamma, sparse-Laplace GLMM
route): Julia names `["resd_species"]` -- **exactly one column**, "1
fixed-effect columns" per the echo's own count. This surprised the original
brief, which expected an intercept/slope SD split; DRM.jl's route does not
split them. Rule: identical to the existing plain-intercept `resd` rule
(bare group, key `"resd"`) -- the producer's restriction to
`term$coef_names == "(Intercept)"` was simply too narrow and is now dropped
for the `mu`-side case.

### (c) `phylocov` on the q=2 bivariate phylo route

`mu1 = y1 ~ x + phylo(1 | p | species, tree = tree), mu2 = y2 ~ x +
phylo(1 | p | species, tree = tree), sigma1 = ~1, sigma2 = ~1, rho12 = ~1`
(ML): Julia names end in `["phylocov_Sigma_a:L11", "...L21", "...L22"]` --
the SAME lower-triangular column-major convention
`drm_julia_phylocov_block_labels(2L)` already generates for the
KNOWN-STRUCTURED (`relmat`/`animal`/`spatial`) q2 route (design 258 S7.6).
Only the ROUTE differs: `drm_julia_biv_phylo_dimension(formula) == "q2"`
(a direct `phylo()` marker on mu1/mu2), not
`drm_julia_collect_structured_terms()`. Fix: widen the existing
`if (... == "q4")` check to also branch on `"q2"`, reusing the same helper.

### (d) `recov` vs `resd_mu`/`resd_sigma` -- found while fixing (a), not in the brief

Fixing (a) alone did not make live test (3) above pass: that test's
`summarize()` fits BOTH a `sigma_only` construct (which (a) fixes) AND a
`mu_sigma` construct (`y ~ x + phylo(1 | species, tree = tree), sigma ~
phylo(1 | species, tree = tree)` -- the SAME group carrying a bare-intercept
phylo term on BOTH `mu` and `sigma`, DRM.jl's `phylo_locscale` mode). Fitting
that construct directly surfaced a NEW error, not (a)'s:
`coef_labels supplies names for unknown dpar "resd_sigma"; the model has
dpars: mu, sigma, recov` -- under `method = "ML"` (the default). Probing
`method = "REML"` on the identical formula gave a THIRD shape:
`coef_labels supplies names for unknown dpar "resd"; the model has dpars:
mu, sigma, resd_mu, resd_sigma`.

Reading both abort texts (with the conflicting block omitted, to get the
"missing an entry" form with the Julia names list) gave:

- `method = "ML"` (DRM.jl's coupled route, `phylo_coupled = TRUE` in
  `drm_julia_bridge_options()`): ONE 2x2 mu/sigma-axis residual-correlation
  block, `["recov_species:L11", "recov_species:L22", "recov_species:L21"]`
  -- **diag-then-offdiag order**, not `phylocov`'s lower-triangular
  column-major order. New dpar key `"recov"`.
- `method = "REML"` (coupled mean-sigma phylo REML is not implemented in
  DRM.jl, so REML falls back to the separate-block route): TWO
  dpar-qualified blocks, `"resd_mu"` (`"species:sd_mu"`) and `"resd_sigma"`
  (`"species:sd_sigma"`) -- note `mu` is ALSO qualified here, unlike the
  mu-only (no coupled sigma term) case, which keeps the bare `"resd"` key.

This is a genuinely different block PER ESTIMATOR on the IDENTICAL formula,
so `drm_julia_bridge_payload_coef_labels()` needed a `method = "ML"`
parameter (the only signature change in this repair), threaded from the
base bridge's own `method` argument. The structured/known-structured
payload builders never reach a `phylo()` term (they use
`relmat`/`animal`/`spatial`), so they pass no `method` and keep the
default -- confirmed this default cannot fire for them since their route
never sets up a `mu`+non-`mu` shared-group phylo pair.

I verified both shapes succeed through the actual producer
(`drm_julia_bridge_payload()` + `drm_julia_call_bridge()`, not a hand-built
payload) before writing the fix into the general block, and again after,
via a direct probe script (not committed -- ephemeral, in the scratchpad
directory).

## What is still not covered

- A non-`mu` random-SLOPE phylo term (e.g. `sigma ~ phylo(1 + x | g, tree =
  tree)`) was not measured; (b)'s fix only widens the `mu`-side rule.
- `recov`'s label helper (`drm_julia_recov_block_labels()`) is hard-coded to
  q=2 (this route can only ever pair exactly one `mu` axis with one other
  axis); it does not generalise the way `drm_julia_phylocov_block_labels(q)`
  does, and there is no evidence a q>2 shape of this route exists to
  generalise for.
- The REML mu+sigma coupled route's numerical parity (does the fit converge
  to the same answer as native TMB?) is not asserted anywhere by this
  repair -- only that the coef_labels round trip no longer aborts. The live
  tests unskipped here already carry their own numerical assertions
  (`expect_lt` on loglik/coef/SD deltas); those now run and pass, but this
  repair's OWN evidence is limited to the label contract.

## Files changed

- `R/julia-bridge.R` -- the only file changed under `R/` (scope fence
  N9-G6). `drm_julia_bridge_payload_coef_labels()` gained a `method = "ML"`
  parameter; its phylo-term detection loop was restructured to separate
  mu-only, non-mu-only, and coupled mu+other cases; two new helpers,
  `drm_julia_recov_block_labels()` and the widened `phylocov` branch reusing
  `drm_julia_phylocov_block_labels(2L)`.
- `tests/testthat/test-coefficient-labels.R` -- four new offline unit tests
  (`resd_sigma`, `resd_sigma coupled`, `random-slope`, `phylocov`), no live
  Julia.
- `tests/testthat/test-julia-sigma-phylo-reml.R`,
  `tests/testthat/test-julia-tmb-parity.R` (two sites),
  `tests/testthat/test-julia-slope-nongaussian.R` -- the four
  `testthat::skip("measured broken under DRM.jl 77513aa0: ...")` calls
  removed; each site's comment now says what was broken and what fixed it,
  reworded so it does not still match the "measured broken under DRM.jl
  77513aa0" grep the ledger's G2 gate scans for.
- `docs/design/258-coefficient-naming-contract.md` -- new S7.8 amendment
  documenting all four findings; S7.7's "NOT fixed" paragraph gets a
  forward pointer rather than being rewritten (history preserved).
- `docs/dev-log/evidence/julia-r-parity/lss-tip-identity/public-001.json`
  -- regenerated LAST (after every R/ edit, per the receipt tool's own
  discipline) via `tools/run-julia-phylo-labels-public.R`; unaffected in
  substance (that fixture's LSS route is explicitly excluded from every
  rule this repair adds, via the existing `lss_groups` exclusion), but
  regenerated to keep the receipt's own source-hash provenance current.

## Verification

- `tests/testthat/test-coefficient-labels.R`: 0 failed, 0 errors, offline
  (`env -u DRM_JL_PATH -u DRM_JL_PHYLO_PATH -u DRMTMB_JULIA_TESTS`).
- Live (`DRM_JL_PATH=<pinned 77513aa0 clone> DRMTMB_JULIA_TESTS=true`):
  `test-julia-sigma-phylo-reml.R` 0/0/0/74 (fail/error/skip/pass),
  `test-julia-tmb-parity.R` 0/0/0/126, `test-julia-slope-nongaussian.R`
  0/0/0/3.
- Regression, live: `test-coefficient-labels.R` 0/0/0/131,
  `test-julia-bridge.R` 0/0/0/133, `test-julia-phylo-labels.R` 0/0/0/14,
  `test-julia-structured.R` 0/0/0/68.
- `python3 -m unittest tools/tests/test_capability_ledger.py`: OK (80
  tests).
- `Rscript tools/check-julia-phylo-labels-receipt.R
  docs/dev-log/evidence/julia-r-parity/lss-tip-identity/public-001.json
  --current --self-test`: `PHYLO_LABEL_RECEIPT_PASS labels=12 rows=72
  checks=8`, all 12 self-test rejection cases firing correctly.
- `git diff --name-only <base> -- R`: `R/julia-bridge.R` only.
