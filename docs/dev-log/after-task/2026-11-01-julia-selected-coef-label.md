# After task: match a sole selected SD target's labels to the returned `sd` block

Reader: a maintainer who needs to know why `sd(id, coef = "x") ~ w` failed on
the Julia engine after the #1551 fence was lifted, and what changed.

## Finding

For a sole selected ordinary SD target, the R payload labels the SD
coefficients under the hashed block `sdtarget_<hex>` (hex of
`group|level|dpar|member|block`). The DRM.jl checkout used here accepts that
key and then renames it to its stable `sd` block
(`_bridge_single_sd_coef_label_alias()` in `src/bridge.jl`), so the engine
returns `sd_(Intercept)` and `sd_w`. The R fail-closed check
`drm_julia_bridge_check_coef_labels()` compared the returned `sd` block to the
unaliased payload keys and reported "no payload label was built for
fixed-effect dpar(s): sd". The mismatch was inside the R check; the Julia side
is consistent, so no Julia change is needed. The post-fit side
(`drm_julia_sd_fit_block()`) already resolved a sole SD target to `sd`.

## Change

`R/julia-coefficient-labels.R`: new helper
`drm_julia_alias_single_sd_target_labels()`, called once in the check. When the
engine returned an `sd` block, the payload has no `sd` key, no returned block is
itself hashed, and exactly one `sdtarget_` payload key exists, that key is
renamed to `sd` for the comparison only. The label terms are not touched, so a
real term disagreement still aborts, and two hashed keys or a missing key are
not aliased. Nothing sent to Julia changed.

## Tests

New static file `tests/testthat/test-julia-selected-sd-coef-label.R`, no Julia:
10 passed. It pins the hash identity (`id|iid|mu|x|none`), the sole-key match,
an emulated-bug test (the helper mocked to identity reproduces the live error
message), and refusals for wrong terms, a missing key, two hashed keys, and an
engine that already returns the hashed block. An independent numerical oracle,
structured providers and constant-SD equivalence do not apply: this slice
changes a label comparison and fits nothing.

## Live check (Mac, Julia 1.10.0, DRM_JL_PATH = general-sd-julia)

`test-julia-poisson-sd.R` before the change: 2 failed, 8 passed. After: 30
passed, 0 failed, 0 skipped. The three live tests are the selected-intercept
SD fit, the native versus Julia independent-slope fit (existing tolerance 0.25,
unchanged) and the phylogenetic fit. These are single seeded fixtures; no
wider parity claim is made. JULIA_HOME had to be set to the Julia 1.10.0 bin
directory because `~/.juliaup/bin` has no `julia` shim.

## Neighbour counts (Mac, one R process at a time)

`test-coefficient-labels.R` 122 passed, 5 skipped; `test-julia-bridge-coef-labels.R`
36 passed; `test-julia-ordinary-sd-fence-exemption.R` 89 passed;
`test-julia-ordinary-mean-re-fence.R` 24 passed; `test-julia-gate-vs-engine.R`
166 passed. No failures, no loosened tolerance, no deleted assertion.

## Open items

The comment near line 3797 of `R/julia-bridge.R` says a selected coefficient
needs the hashed key or Julia rejects the payload. That remains true for the
payload keys and is why the fix is in the check, not the payload. Other live
SD files (Gamma, NB2, Beta, Binomial) were not re-run for selected spellings.
