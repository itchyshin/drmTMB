# After Task: Native Binomial phylogenetic-interaction SD

## 1. Goal

Add native Binomial predictor-dependent SDs for an existing q1
`phylo_interaction()` location field, with independent synthetic tests and
clear engine boundaries.

## 2. Implemented

The Binomial builder now extracts a q1 phylogenetic-interaction location
field. The existing Kronecker precision is reused, and
`sd(pair_id, level = "phylogenetic_interaction") ~ predictors` maps the SD
design to observed partner pairs. Each supplied pair ID must identify exactly
one pair, each observed pair must have one ID, and SD predictors must be
constant within pair. The parser, generated help, formula guide, likelihood
map, known-limitations page, roadmap, README, vignette, and NEWS now state the
syntax and current engine boundary.

## 3a. Decisions and Rejected Alternatives

The SD formula names a user-supplied pair identifier instead of treating the
internal `plant:pollinator` expression as a data column. Pair IDs are checked
against both partner columns and the fitted design uses the canonical
`partner1:partner2` labels. This keeps target prediction names aligned with the
latent field.

The covariance contract is `b ~ N(0, D K D)`, with `K = A2 ⊗ A1` and
`D = diag(exp(W alpha))` over observed partner pairs. The synthetic generator
draws `b = D chol(K) u`; the fit formula attaches the same pair-level `W` to
the q1 interaction field; recovery reads `coef(fit, "sd_phylo(pair)")` and
compares its SD slope with the generating value.

Assumption made without asking: the first deliverable is the native Binomial
engine. The current direct Julia fitter and R bridge have no interaction-field
route, so this slice records them as follow-up work rather than expanding the
same change into a new Julia sparse-field implementation.

## 4. Files Touched

- `R/drmTMB.R`
- `R/parse-formula.R`
- `R/random-effect-scale-formulas.R`
- `man/random_effect_scale_formulas.Rd`
- `tests/testthat/test-binomial-phylo-interaction-sd.R`
- `README.md`
- `NEWS.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/03-likelihoods.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/internal-roadmap.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/after-task/2026-10-27-binomial-phylo-interaction-sd.md`
- `vignettes/formula-grammar.Rmd`
- `LOOP/lanes/general-sd-regression/checkpoint.md`
- `LOOP/lanes/general-sd-regression/arcs.md`

## 5. Checks Run

- Before the implementation, the new test failed at formula parsing because
  `phylogenetic_interaction` was not an accepted SD level.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e
  'devtools::test(filter =
  "^(binomial-phylo-interaction-sd|binomial-phylo-sd-regression|sd-level-grammar)$")'`:
  74 expectations passed, 0 failed, 1 existing deprecation warning from the
  legacy `sd_phylo()` grammar test.
- `devtools::document()` completed and regenerated the random-effect-scale
  help page.
- `pkgdown::check_pkgdown()` passed with no problems; Pandoc emitted existing
  `--mathml` deprecation warnings.
- `pkgdown::build_site()` completed successfully and rendered the updated
  formula guide. Existing Pandoc `--mathml` and `--mathjax` deprecation
  warnings appeared during the full site build.
- Broader adjacent filter
  `devtools::test(filter =
  "^(binomial-phylo-interaction-sd|phylo-interaction|binomial-phylo-sd-regression)$")`
  reached 145 passes and one unrelated failure at
  `test-phylo-interaction.R:841`: the current NB2 validator error text no
  longer matches that fixture's expected stale refusal message. No NB2 code or
  assertion was changed.
- `gh issue list --state open --search 'phylo_interaction binomial' --json
  number,title,url` returned no matching open issue.

## 6. Tests of the Tests

The new test failed before implementation on the unsupported SD-level parser
gate. After the change it checks a seeded Bernoulli DGP, convergence, positive
and bounded recovery error for the SD-predictor slope, pair-ordered SD
predictions, canonical formula parsing, rejection of a pair ID that maps
inconsistently, and rejection of a predictor that varies within a pair.
Existing Binomial phylogenetic SD tests passed alongside the new test.

## 7a. Issue Ledger

No matching open GitHub issue was found. No issue was opened or changed.

## 8. Consistency Audit

Searched `README.md`, `docs/dev-log/internal-roadmap.md`,
`docs/dev-log/known-limitations.md`, both likelihood/formula design documents,
`vignettes/formula-grammar.Rmd`, and `R/random-effect-scale-formulas.R` for
`phylogenetic_interaction` and the stale claims that Binomial interaction
models were still planned. Updated the user-facing locations and confirmed no
remaining stale “binary incidence needs a Bernoulli/binomial family gate”
claim. The formula uses a pair ID column and keeps SD predictors at the pair level.

## 9. What Did Not Go Smoothly

The first test run confirmed that the public level selector and pair grouping
needed an explicit contract. The first negative predictor test expected a
generic wording that the validator does not use; it was corrected to assert
the actual pair-level error. The broader neighboring suite exposed the stale
NB2 error-message expectation recorded above. A report-generation helper
targeted the brain repository instead of this worktree; its accidental blank
template was removed, and this report was created in the package repository.

## 10. Known Residuals

This evidence is native TMB only and uses a logit Bernoulli synthetic fixture.
Direct Julia interaction fitting, the R-to-Julia bridge, same-data engine
parity, marginal-simulation and refit workflows for this exact interaction,
other Binomial links for this provider, and interval calibration remain open.
The overall general SD-regression goal remains active.

## 11. Team Learning

Pair-level structured SDs need a public pair identifier with an explicit
one-to-one mapping check. Internal latent labels can then remain canonical for
prediction and extraction. The repository route lookup returned no LOAD-FIRST
manifest for this worktree. Golden Set checks were not run; no known-mistake
class from that set was targeted.

## 12. Cross-Product Coverage

Covers: native TMB Binomial q1 `phylo_interaction()` location intercept with
pair-constant predictor-dependent SD, parser, pair ordering, SD prediction,
and invalid-input checks.

Does NOT cover: Julia direct fitting, R-to-Julia bridge or parity, non-logit
link recovery for this provider, additive partner main effects, interaction
slopes, bivariate responses, marginal simulation or bootstrap for this exact
route, and calibrated uncertainty.

## Prose Review

Style: 2/10, medium confidence. Genre and coverage: this short technical
after-task report and the related formula/status entries. Evidence and repair:
the report names the fitted provider, formula, pair-ID rule, test totals, and
engine boundary; no further wording change was needed. Gates: science = pass
for the stated `D K D` contract and tested q1 route; facts = pass against the
current source and logs; references = not applicable because the report cites
no external source. Provenance: self-review, version 1, 2026-10-27; related
after-task and formula-guide examples were seen.
