# After Task: Provider Sigma One-Slope Fixture Parity

## 1. Goal

Move the deterministic same-target bridge fixture tier for Gaussian
sigma-only structured one-slope cells from one relmat row to the four provider
rows now opened at native point-fit and extractor level:

- `phylo(1 + x | species, tree = tree)` in `sigma`;
- fixed-covariance `spatial(1 + x | site, coords = coords)` in `sigma`;
- A-matrix `animal(1 + x | id, A = A)` in `sigma`;
- K-matrix `relmat(1 + x | id, K = K)` in `sigma`.

## 2. Implemented

- Generalized `phase18_structured_re_sigma_slope_payload_fixture()` from a
  relmat-only helper to a provider-specific helper for `phylo()`, `spatial()`,
  `animal()`, and `relmat()`.
- Expanded
  `phase18_structured_re_sigma_slope_parity_fixture_contract()` to four rows:
  `sigma_slope_phylo_same_target_ml`,
  `sigma_slope_spatial_same_target_ml`,
  `sigma_slope_animal_same_target_ml`, and
  `sigma_slope_relmat_same_target_ml`.
- Replaced the relmat-only dashboard sidecar with four provider-specific rows
  in `structured-re-sigma-slope-parity-fixture.tsv`.
- Moved the four sigma one-slope rows in
  `structured-re-q-series-support-cells.tsv` to
  `bridge_status = fixture_parity`, while leaving interval and coverage status
  planned.
- Updated bridge fixture tests, conversion/dashboard tests, mission-control
  validation, dashboard README, the q-series design map, and the check log.

## 3a. Decisions and Rejected Alternatives

This slice keeps the support-cell row as the unit of truth. The provider rows
move together because all four native sigma-only one-slope cells already have
point-fit and extractor evidence, and each now has a provider-specific
same-target fixture contract.

Rejected alternatives:

- Treating the old relmat-only fixture as broad sigma bridge evidence. That
  would overclaim `phylo()`, `spatial()`, and `animal()`.
- Treating relmat runtime K/Q parity as Q bridge marshalling. The bridge
  fixture remains a K-matrix contract.
- Treating sigma-only rows as matched `mu+sigma` slope covariance support.
  Those cells still need their own endpoint identity and runtime diagnostics.

## Mathematical Contract

Each deterministic fixture records the same coefficient order on the link and
structured-SD scale:

```text
sigma:(Intercept)
sigma:x
sd_sigma:structured(Intercept)
sd_sigma:structured(x)
```

The provider-specific matrix contracts are intentionally narrow: phylo uses
tree branch lengths, spatial uses a fixed covariance derived from coordinates,
animal uses an A matrix, and relmat uses a K matrix. The relmat runtime tests
also check K/Q same-target parity, but this bridge fixture is still the
K-matrix contract. None of these rows is a matched `mu+sigma` covariance block
or a labelled structured slope covariance block.

## 4. Files Touched

- `inst/sim/R/sim_structured_re_bridge_fixtures.R`
- `tests/testthat/test-structured-re-bridge-fixtures.R`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/structured-re-sigma-slope-parity-fixture.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `tools/validate-mission-control.py`
- `docs/dev-log/check-log.md`

## 5. Checks Run

```sh
air format inst/sim/R/sim_structured_re_bridge_fixtures.R tests/testthat/test-structured-re-bridge-fixtures.R tests/testthat/test-structured-re-conversion-contracts.R
python3 -m py_compile tools/validate-mission-control.py
Rscript --vanilla -e "devtools::test(filter = 'structured-re-bridge-fixtures')"
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
git diff --check
gh issue list --repo itchyshin/drmTMB --search "structured sigma slope q-series" --limit 20 --json number,title,state,url,labels
rg -n -e "relmat-only sigma" -e "other provider sigma fixtures remain planned" -e "No phylo, spatial, or animal sigma-slope fixture parity" -e "reported 1 structured RE sigma-slope parity-fixture row" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/dashboard R inst/sim tests tools docs/dev-log/check-log.md
rg -n -e "residual-scale structured slopes" -e "sigma.*structured.*slope" -e "sigma_slope_(phylo|spatial|animal|relmat)" -e "structured-re-sigma-slope-parity-fixture" README.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/design/16-phylo-spatial-common-math.md docs/design/218-structured-q-series-completion-map.md docs/design/34-validation-debt-register.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/59-structural-slope-and-non-gaussian-map.md docs/dev-log/dashboard tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py vignettes/formula-grammar.Rmd _pkgdown.yml
```

Results:

- `structured-re-bridge-fixtures` passed with 343 assertions.
- `structured-re-conversion-contracts` passed with 1508 assertions.
- `python3 tools/validate-mission-control.py` passed and reported 4 structured
  RE sigma-slope parity-fixture rows.
- `git diff --check` passed.
- The GitHub issue search returned no direct duplicate tracker item for
  "structured sigma slope q-series".
- The stale relmat-only scan returned no current prose hits.

## 6. Tests of the Tests

The bridge-fixture test loops over all four providers, reconstructs native,
direct DRM.jl, and R-via-Julia fixture payloads, and checks zero
coefficient/log-likelihood deltas through
`phase18_structured_re_parity_status()`. It also checks endpoint identity,
coefficient order, matrix slot/source, provider-specific claim boundaries, and
the negative path for an unsupported `structured_type`.

The conversion test separately verifies that the dashboard sidecar has exactly
four rows, that each q-series sigma one-slope row points to the new sidecar,
and that interval and coverage states remain planned.

## 7a. Issue Ledger

No GitHub issue was opened or updated. The direct issue search for
`structured sigma slope q-series` returned `[]`, and this slice is an internal
evidence-tier promotion already represented by the q-series dashboard rows.

## 8. Consistency Audit

Reader: R package contributor maintaining the structured random-effect
support map.

The q-series support-cell sidecar, sigma fixture sidecar, mission-control
validator, dashboard README, and design map now agree on the same four exact
fixture rows. The first stale-wording scan checked for relmat-only wording and
returned no current prose hits. The second scan checked the status inventory:
README, ROADMAP, NEWS, known limitations, formula grammar, the shared
structured-effect math note, q-series map, validation debt register,
pre-simulation readiness matrix, structural-slope map, dashboard sidecars,
conversion tests, mission-control validator, `vignettes/formula-grammar.Rmd`,
and `_pkgdown.yml`.

The old relmat-only after-task report remains historically true for the earlier
slice. This report supersedes it by recording the four-provider fixture tier.

## 9. What Did Not Go Smoothly

The relmat-only helper made it easy to leave one-row assumptions in tests and
validator wording. The fix was small but required checking the fixture helper,
q-series sidecar, dashboard README, validator, and conversion test together.

One stale-wording scan was rerun because the first shell regex contained
zsh-sensitive punctuation. The report records the corrected `rg -e` commands.

## 10. Known Residuals

- No broad bridge support.
- No range-estimating spatial bridge support.
- No pedigree/Ainv bridge marshalling.
- No relmat Q bridge marshalling.
- No matched `mu+sigma` structured slope cells.
- No labelled structured slope covariance.
- No bivariate structured slope covariance.
- No structured q4/q6/q8 slope support.
- No interval reliability or coverage.
- No REML, AI-REML, DRAC execution, or SR150 evidence.

## 11. Team Learning

Provider completion should be table-first. When a provider row moves, the
fixture helper, q-series table, sidecar, validator, conversion tests, dashboard
README, and after-task note should move in the same slice.

The next repeated-risk pattern is endpoint pairing: a sigma-only fixture still
does not imply a matched `mu+sigma` structured slope cell. Keep that boundary
row-level rather than prose-only.

## Next Actions

1. Add endpoint/member/coefficient identity checks for matched `mu+sigma`
   slope diagnostics before opening runtime matched cells.
2. Design the first matched `mu+sigma` sigma-location diagnostic cell without
   borrowing q1 plus q1 or q4 intercept evidence.
3. Keep interval and coverage promotion blocked until denominator and
   MCSE-calibrated coverage evidence exist.
