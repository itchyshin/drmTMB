# After Task: Structured REML Status

## 1. Goal

Bank SR051-SR060 for native REML status in the structured random-effect balance
arc.

## 2. Implemented

SR051-SR060 are banked in
`docs/dev-log/dashboard/structured-re-balance-100-slices.tsv`.

`docs/design/211-structured-reml-status.md` records the native REML boundary:
exact-Gaussian univariate mean-side `phylo()` is supported and tested; scale-side
phylo, matched `mu`/`sigma`, q2/q4 phylo, coordinate `spatial()`, `animal()`,
and `relmat()` REML remain rejected or unvalidated.

## 3. Decisions and Rejected Alternatives

I did not broaden REML wording from the ML structured surface. ML fit evidence
does not imply REML support. Direct DRM.jl REML evidence remains direct Julia
evidence only unless R-to-Julia bridge parity is proven for the exact row.

## 4. Files Created or Changed

- `docs/design/211-structured-reml-status.md`
- `docs/dev-log/dashboard/structured-re-balance-100-slices.tsv`
- `docs/dev-log/after-task/2026-06-22-structured-reml-status.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

```sh
NOT_CRAN=true Rscript -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-reml-phylo-location.R")'
```

Outcome: `test-reml-phylo-location.R` passed with 8 assertions, zero failures,
zero warnings, and zero skips.

A direct smoke on 2026-06-22 checked `REML = TRUE` with `spatial()`,
`animal()`, and `relmat()` mean-side structured effects. All three rejected
with the current message that REML supports only phylogenetic mean-side
structured effects and that spatial, animal, and relatedness structured effects
under REML are not validated yet.

Mission-control validation and `git diff --check` are rerun in the closing gate
for this combined structured-balance update.

## 6. Tests of the Tests

The supported phylo REML test compares against a hand-computed restricted
likelihood reference and checks ML versus REML variance-component bias. The
same file checks scale-side and matched `mu`/`sigma` phylo rejection. The direct
spatial/animal/relmat smoke used actual `drmTMB()` calls with named structured
inputs.

## 7. Issue Ledger

No GitHub issue was touched. This is local evidence banking.

## 8. Consistency Audit

SR051-SR060 keep REML exact-Gaussian and native-TMB specific. They do not
promote q2/q4 REML, non-Gaussian REML, HSquared AI-REML, R-to-Julia bridge
support, public optimizer controls, or interval coverage.

## 9. What Did Not Go Smoothly

The important risk was semantic: "REML" can be too easily borrowed from the
DRM.jl q4 lane or from ML support. The tranche explicitly separates native TMB,
direct DRM.jl, and R-to-Julia bridge rows.

## 10. Known Limitations and Next Actions

SR061 starts the inference tranche. REML derivations for scale-side,
matched-location-scale, q2, q4, spatial, animal, and `relmat()` structured
routes remain future work.

## 11. Team Learning

For REML, absence of support must be visible as a first-class row. Otherwise
users will infer support from nearby ML cells or from direct Julia experiments.
