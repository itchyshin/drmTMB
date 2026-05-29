# After Task: Bootstrap Derived-Status Map

## Goal

Keep the new direct-target bootstrap route from drifting into derived interval
claims for q4 correlations, modelled SD surfaces, repeatability, phylogenetic
signal, covariance products, or non-`confint()` tables.

## Implemented

`R/profile.R` now has an explicit `bootstrap_supported_targets()` helper. It
currently mirrors the fast Wald direct-target gate, but it names the bootstrap
contract directly instead of making bootstrap dispatch borrow a Wald helper by
accident.

`tests/testthat/test-profile-targets.R` now checks that derived modelled
`sd(group)` surfaces, q4 unstructured-correlation rows, repeatability, and
phylogenetic signal stay outside the bootstrap target set. The profile-CI
design note now records that boundary in the same section that documents the
direct-target bootstrap route.

## Source Contract

Bootstrap target selection admits only direct targets already supported by the
fast direct interval gate: fixed effects, direct fitted scale targets, direct
random-effect SDs, direct random-effect correlations, and constant residual
`rho12`. Derived targets remain listed by `profile_targets()` for status and
reader guidance, but they are not bootstrap endpoints until a validated
derived-interval method exists.

## Files Changed

- `R/profile.R`
- `tests/testthat/test-profile-targets.R`
- `docs/design/12-profile-likelihood-cis.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-29-bootstrap-derived-status-map.md`

## Checks Run

```sh
air format R/profile.R tests/testthat/test-profile-targets.R docs/design/12-profile-likelihood-cis.md
Rscript --vanilla -e "devtools::test(filter = 'profile-targets', reporter = 'summary')"
rg -n "bootstrap.*derived|derived.*bootstrap|bootstrap.*q4|q4.*bootstrap|bootstrap.*repeatability|repeatability.*bootstrap|bootstrap.*phylogenetic signal|phylogenetic signal.*bootstrap|summary\\(\\).*bootstrap|corpairs\\(\\).*bootstrap|prediction tables.*bootstrap|direct-target gate|bootstrap target selection" README.md NEWS.md ROADMAP.md docs/design R tests/testthat man --glob '!docs/dev-log/**'
gh issue list --repo itchyshin/drmTMB --state open --search 'bootstrap derived q4 repeatability phylogenetic signal summary corpairs' --limit 20 --json number,title,state,url,labels
git diff --check
```

Result: `test-profile-targets.R` passed, `git diff --check` was clean, and the
GitHub issue search returned `[]`.

## Tests Of The Tests

The added expectations are boundary checks. They use existing fitted or
fitted-like target inventories and assert that known derived rows are not
selected by `bootstrap_supported_targets()`. A future accidental expansion of
bootstrap target selection to derived rows will now fail before any expensive
simulate/refit work starts.

## Consistency Audit

The stale-wording scan found the expected current wording: README, ROADMAP, the
profile-CI design note, and generated summary help all keep bootstrap as a
direct `confint()` route and leave `summary()`, `corpairs()`, prediction
tables, q4 derived rows, repeatability, and phylogenetic signal outside the
bootstrap route. One older NEWS entry records the historical pre-bootstrap
state where `confint()`, `summary()`, and `corpairs()` all rejected bootstrap;
the current top NEWS entry supersedes that historical note for `confint()`.

## GitHub Issue Maintenance

The issue search for bootstrap derived rows, q4, repeatability, phylogenetic
signal, `summary()`, and `corpairs()` returned `[]`. No issue action was
needed.

## What Did Not Go Smoothly

The first patch attempted to edit several contexts at once and missed the q4
test block. I split the edit into smaller hunks and kept the implementation
unchanged apart from the explicit helper name.

## Team Learning

Ada kept this as a boundary-map slice rather than a derived-bootstrap feature.
Fisher and Noether checked that direct bootstrap targets remain separate from
derived nonlinear summaries. Grace kept validation to `profile-targets`,
stale-wording scans, issue search, and `git diff --check`. Rose flagged the
old NEWS entry as historical rather than silently rewriting release history.

No spawned subagents were running.

## Known Limitations

This slice does not add bootstrap intervals to `summary()`, `corpairs()`,
prediction tables, q4 derived correlations, repeatability, phylogenetic signal,
covariance products, or modelled SD surfaces. It also does not evaluate derived
interval coverage.

## Next Actions

After this PR lands, the next interval slice can either improve the explicit
error message for a user who asks bootstrap for a derived target by name, or
move to a small simulation design for direct bootstrap coverage.
