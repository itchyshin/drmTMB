# Independent review: Poisson scalar ordinary block label

**Verdict (2026-10-17):** The exact complete-data Poisson scalar-intercept
`sd(id, block = "p")` route is coherent and passes the focused checks. The
initial broader ordinary/spatial admission concern below was resolved by the
narrow validator repair recorded in the amendment. This is a review, not a
recovery or calibrated inference claim.

## Source and evidence checked

- Base commit `47262cd4501d2fd16b5af8252e4f30ad370436d6`; supplied frozen
  archive digest `2cab4d8f1ff25fd5d9ac6294dd0dae450e71143c90aa07c333a468f27d1204a4`.
  The sole R runtime diff in `R/drmTMB.R:10839-10846` admits a non-null
  covariance label only when `family_label == "Poisson"` and the parsed term
  type is `intercept`. No likelihood, parameter-map, or C++ change is in this
  slice.
- I reran `Rscript tools/general-sd-regression/run-source-tests.R
  tests/testthat/test-poisson-sd-assembly.R`: 36 expectations and
  `SOURCE_ASSEMBLY_PASS`. `git diff --check` found no whitespace errors.
- The retained isolated compiled log ends in `NATIVE_BINOMIAL_SD_PASS` after
  `poisson-sd-integration`, binomial selector integration, and Gaussian SD
  regression checks. Its source manifest pins `R/drmTMB.R` at SHA-256
  `9e66eed5fb72246872bfa9592c87c124e0e2090e4fcad5d00f54831e90d77bf7`,
  which matches my local readback. The two Poisson test-file hashes also match
  the retained manifest. This supports this capsule and these tests only.

## Contract and adjacent routes

`parse_random_mu_term()` retains the label; `build_random_mu_structure()`
uses it in the term name and descriptor but assigns `re_cor_id0 = -1` for a
scalar term. The Poisson spec builds `re_mu` and the selected SD design from
that descriptor (`R/drmTMB.R:8493-8496`). Thus a lone `(1 | p | id)` has the
same latent log-mean contribution and no new correlation parameter relative
to `(1 | id)`. The source test checks identical `X_sd_mu`, latent SD-row map,
and zero ordinary correlation slots. The compiled test compares likelihood,
coefficients, selected SD prediction, profile mapping, latent simulation,
save/reload, and constant-SD reduction.

NB2 remains rejected: the shared validator's new exception requires the exact
`"Poisson"` family label; the assembly negative checks `"NB2"`. Poisson with
an active `zi` formula remains rejected before the label exception by the
`has_zi` guard at `R/drmTMB.R:10808-10815`. Labelled ordinary slopes and
labelled correlated blocks remain rejected by the existing branches. Duplicate
same-group intercepts with different labels remain an overlap error because
`validate_random_mu_term_overlap()` keys on group and coefficient, not label
(`R/drmTMB.R:17724-17740`). These are source-level scope conclusions; the
compiled check exercises the exact ordinary route, not every negative branch.

## Initial boundary (superseded by the amendment)

The Poisson builder already permits an ordinary `mu` term with a spatial `mu`
field (`allow_structured_plus_ordinary = TRUE`, spatial only, at
`R/drmTMB.R:8250-8260`). The new condition admits `(1 | p | site)` in that
combination, including a spatial field that itself uses block label `p`.
`drm_build_poisson_spec()` stores ordinary and structured fields separately
(`R/drmTMB.R:8575-8595`) and does not build a cross-field covariance block.
Consequently identical `p` labels would not imply a fitted ordinary/spatial
correlation. This is an inference from the source path, not a demonstrated
compiled collision fit. A narrow prefit collision rejection, or an explicit
source/compiled test plus documentation that such labels are scoped to their
own field, would remove the ambiguity. Do not infer support for structured
`sd()` from this slice; that remains rejected at `R/drmTMB.R:8270-8277`.

The validator's error hint still says “labelled covariance blocks remain
planned” (`R/drmTMB.R:10850-10855`), though a scalar Poisson label now works.
It should say *labelled correlated blocks* remain planned. The broad
random-effect eligibility paragraph in `docs/design/01-formula-grammar.md`
still calls non-zero-inflated Poisson ordinary effects “unlabelled,” while
the focused Poisson and `sd(group)` rows describe the newly admitted scalar
label; align those before a public capability claim. Finally, one source test
for shorthand `sd(id) ~ w` with a unique labelled intercept would make the
approved unique-target rule explicit. None of these observations changes the
passing exact route.

## Amendment after the narrow admission repair (2026-10-17)

The earlier ordinary/spatial collision concern is **resolved at admission**
for the reviewed slice. `validate_poisson_mu_random_terms()` now defaults
`allow_labelled_intercepts = FALSE`, and only `drm_build_poisson_spec()` passes
`TRUE` when there is no selected structured `mu` term and missing-response
integration is off (`R/drmTMB.R:8225-8232,10803-10851`). The flag remains
conditional on exact `family_label == "Poisson"` and scalar intercept type.
The Poisson `zi` guard still executes first; NB2 calls retain the false
default. This does not alter the ordinary or structured kernels or imply a
cross-field covariance. It intentionally leaves labels unavailable in
Poisson missing-response models and ordinary-plus-structured models, even
where an unlabelled base effect is admitted.

The new source negatives assemble a same-labelled ordinary/spatial formula
and a labelled ordinary formula with `miss_control(response = "include")`;
both reject at the validator. I independently reran the source assembly test:
38 expectations, `SOURCE_ASSEMBLY_PASS`, with `R/drmTMB.R` SHA-256
`54b24c5574ff5695d103c71d6a332a1e57455c90919f1a77a1bdc5c80d5f9859`
and assembly-test SHA-256
`23a83f09f3a76cefbf5743a872d78d4fd1b2ed4ea8a8d0afbdbf0b8712777201`.
`git diff --check` passed. The previous compiled capsule is tied to the
earlier R hash, so it cannot validate this repair; the new compiled capsule
must be checked separately. The source-level repair is a **GO for that
compiled check**, not a new recovery or inference claim.

Two wording limits remain. The error hint now says “Other labelled count
effects remain planned,” which is too broad because exact labelled
structured count effects already exist; “labelled ordinary slopes and
correlated blocks” would describe this validator's boundary. The focused
Poisson row in `docs/design/01-formula-grammar.md:188` now acknowledges the
scalar label, but its later random-effect eligibility paragraph near line
1096 still calls Poisson ordinary effects “unlabelled.” These are documentation
corrections before a public claim, not reasons to change the passing scalar
likelihood. The unique-labelled shorthand `sd(id) ~ w` still lacks a focused
Poisson assertion.

## Final repaired-capsule readback (2026-10-17)

The final hint now names **labelled ordinary NB2 intercepts and labelled
ordinary count slopes** as pending, leaving implemented structured count
labels out of that refusal (`R/drmTMB.R:10860`). The broad eligibility row
in `docs/design/01-formula-grammar.md:1096` now states the unique labelled
ordinary Poisson exception. The source assembly test includes `sd(id) ~ w`
against a unique labelled `(1 | p | id)` term and preserves its `block = "p"`
identity. I independently reran that file: 39 expectations,
`SOURCE_ASSEMBLY_PASS`.

I read back the repaired isolated compiled capsule identified by archive
SHA-256 `6ad295b3bed294db34bc32fd3dc59028942e5b38c1cb202576be55e994aa58d6`.
Its source manifest is based on commit `47262cd4501d2fd16b5af8252e4f30ad370436d6`;
local SHA-256 values match all four reviewed manifest entries:
`R/drmTMB.R` `d88ff6046bffa9f57aa258c0e19e1adf4ee46c7c8e05cfcf297420a27d7efe46`,
`src/drmTMB.cpp` `b46f05dea0b44f94be76db03851ae49b41a7cdef125aa13f3864ac7219d83846`,
Poisson assembly test `e1f4afa35077a875646bfd0aa1f17e6dea0febe34f04cf3b0d0e2a6ca9312c64`,
and Poisson integration test `08121b2d0efaffbe7ba32f9cb6b5344ae973a98f95dda93b6f2b947a929077af`.
The installed-source receipt repeats the reviewed R and C++ hashes. Its
retained test log reports Poisson integration (43 expectations), binomial
selector integration (22), and Gaussian random-effect-scale (89), each
`DONE`, followed by `NATIVE_BINOMIAL_SD_PASS`; no failure section appears.
The 154 compiled assertions and current source checks support the exact
labelled scalar Poisson route and its stated fences. They do not establish
recovery, interval calibration, new structured combinations, or slope-SD
admission. The prior source-only and older-capsule caveats above are
superseded by this exact readback, while the mathematical scope remains the
same.
