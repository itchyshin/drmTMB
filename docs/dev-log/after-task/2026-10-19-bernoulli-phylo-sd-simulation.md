# After Task: Bernoulli Phylogenetic SD Marginal Simulation

## Goal

Allow native Bernoulli models with predictor-dependent phylogenetic-intercept
SDs to draw fresh marginal random effects using each tip's fitted scale.

## Implemented

Marginal simulation now resolves the fitted phylogenetic SD target, maps the
scale rows to the zero-based node registry, and scales the observed tip nodes
before mapping the draw to observations. The supplied kernel and its existing
normalization remain unchanged. The simulator still rejects other modeled
structured scales and multi-endpoint structured effects.

## Mathematical Contract

The latent draw retains the fitted precision factorization. For each tip, the
fresh effect is multiplied by the positive scale returned by the model's
existing SD prediction path, including its fitted log-SD clamp. The
likelihood-scale contribution is then looked up through the existing
observation-to-node indices. Internal tree
nodes without a direct SD-regression row remain unscaled because the response
contribution indexes the observed tip nodes. This matches the existing TMB
node-scale registry and does not normalize or otherwise change the kernel.

## Files Changed

- `R/methods.R`: allow the supported native Bernoulli phylogenetic route and
  apply tip-specific scales in fresh structured draws; clarify `simulate()`
  documentation.
- `tests/testthat/test-binomial-phylo-sd-simulation.R`: add a synthetic fit,
  deterministic node-mapping check, and binary marginal-output assertions.
- `man/simulate.drmTMB.Rd`: synchronize the generated help text.
- `NEWS.md`: record the bounded new simulation path and remaining limits.
- `docs/dev-log/check-log.md`: record the check result and documentation
  handoff.

## Checks Run

- RED: `Rscript -e 'devtools::test(filter = "binomial-phylo-sd-simulation", reporter = "summary")'` failed at the previous modeled-scale guard with the expected informative error.
- GREEN: the same focused command passed all five assertions.
- `Rscript -e 'devtools::test(filter = "binomial-phylo|simulate-re-form-phylo-interaction", reporter = "summary")'` passed all selected tests, including the existing phylogenetic fit and `re.form` simulation tests.
- `git diff --check -- R/methods.R man/simulate.drmTMB.Rd tests/testthat/test-binomial-phylo-sd-simulation.R` passed.
- No full package check, pkgdown render, compute campaign, or interval calibration was run.

## Tests Of The Tests

The new test was observed failing before the code change. Its deterministic
check reconstructs the expected fitted scale at each indexed tip and compares
the resulting observation-level random-effect contribution to the production
draw. Separate assertions verify nonconstant fitted scales and valid binary
simulated outcomes.

## Consistency Audit

The implementation preserves the existing formula and kernel semantics. The
generated `simulate()` help and development NEWS now describe this exact
Bernoulli phylogenetic case. The current predictor-dependent-SD vignette still
says phylogenetic SD prediction/extraction is unavailable through the R bridge
and that native marginal simulation does not handle modeled phylogenetic SDs.
That vignette is held under a live lease by another lane, so its text was not
edited here; reconcile it when that owner releases the path. The rest of the
large family-support inventory was not audited in this slice.

## GitHub Issue Maintenance

`gh issue list --state open --search 'phylogenetic SD marginal simulation' --limit 10`
returned issue #1463, “Test sweep 3 Oct 2026: what passed,” which is unrelated
to this feature. No issue was opened, changed, or closed.

## What Did Not Go Smoothly

The lane-lease registry timed out in the sandbox twice. The required scoped
leases were acquired after an approved escalation. The first implementation
attempt treated the SD vector as matching every latent tree node; the failing
test exposed that the registry maps SD rows only to tip nodes. The corrected
code uses the existing node-to-row map and converts its zero-based indices
before indexing R vectors.

## Team Learning

For structured effects, distinguish the latent precision dimension from the
number and order of predictor-dependent SD rows. Reuse the model's node-scale
registry rather than inferring an order from tree labels.

## Design-Doc Updates

No formula grammar, likelihood, or kernel parameterization changed, so the
formula and likelihood design documents were not modified. The lingering
vignette statements are recorded above as a cross-lane follow-up.

## pkgdown/Documentation Updates

Updated the `simulate()` roxygen text, its Rd page, and `NEWS.md`. Did not run
`devtools::document()` or a pkgdown build because package documentation files
are already modified by concurrent general-SD work, and the relevant vignette
is leased by another lane. The README, formula grammar guide, roadmap and known
limitations were not changed. Exact status scan:

```sh
rg -n -i "marginal simulation|modeled.*structured.*sd|modelled.*structured.*scale|phylogenetic SD" README.md NEWS.md docs/dev-log/internal-roadmap.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml vignettes/predictor-dependent-random-sd.Rmd
```

The scan identified the stale statements in the leased predictor-dependent-SD
vignette; no navigation update was needed.

## Known Limitations

This test establishes native Bernoulli phylogenetic-intercept simulation
plumbing, not interval calibration or full cross-engine parity. It does not
cover spatial, animal, relatedness-matrix, phylogenetic interaction, correlated
or multi-endpoint structured effects, or bridge-level Julia simulation. A
separate vignette update remains pending with the lane that owns that file.

## Next Actions

Ask the vignette owner to reconcile the two stale claims before that document
is treated as current. Continue the approved programme with calibrated
uncertainty and the remaining random-effect and engine combinations; this
bounded slice does not close the overall goal.

## Prose Assessment

Style: 2/10 (low AI-like style), medium confidence; genre/coverage: compact
engineering after-task report, whole draft reviewed. Evidence/repair: the
specific fitted path, test commands and outstanding leased-document handoff
replace broad completion claims. Gates: scientific = pass for the stated
simulation behavior based on the deterministic regression test; factual = pass
for file and check claims based on current worktree evidence; references = not
applicable because the report cites no external sources. Provenance: self-review
of this report on 2026-10-19; no held-out style controls were used.
