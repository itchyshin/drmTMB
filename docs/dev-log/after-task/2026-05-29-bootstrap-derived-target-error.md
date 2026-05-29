# After Task: Bootstrap Derived-Target Error UX

## Goal

Make exact derived-target bootstrap requests fail with a useful direct-target
message instead of a generic unknown-target error.

## Implemented

`confint(..., method = "bootstrap")` now matches exact requested targets
against the full `profile_targets()` inventory before filtering to supported
bootstrap targets. If a requested target exists but is not bootstrap-supported,
the error says bootstrap currently supports direct fitted-object targets only
and reports the target type plus inventory note.

The focused tests cover q4 unstructured correlations, modelled `sd(group)`
surfaces, repeatability, and phylogenetic signal. Those rows remain unavailable
for bootstrap intervals; this slice only improves the user-facing boundary.

## Source Contract

Bootstrap intervals still use the direct-target set selected by
`bootstrap_supported_targets()`: fixed effects, direct fitted scale targets,
direct random-effect SDs, direct random-effect correlations, and constant
residual `rho12`. Derived targets keep their `profile_targets()` rows for
status and explanation, but the bootstrap route stops before simulate/refit
work when one is requested by exact name.

## Files Changed

- `R/profile.R`
- `tests/testthat/test-profile-targets.R`
- `NEWS.md`
- `docs/design/12-profile-likelihood-cis.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-29-bootstrap-derived-target-error.md`

## Checks Run

```sh
air format R/profile.R tests/testthat/test-profile-targets.R docs/design/12-profile-likelihood-cis.md NEWS.md
Rscript --vanilla -e "devtools::test(filter = 'profile-targets', reporter = 'summary')"
rg -n "direct-target-only|direct fitted-object targets only|derived.*unknown|unknown.*derived|bootstrap.*derived|derived.*bootstrap|bootstrap.*q4|q4.*bootstrap|bootstrap.*repeatability|repeatability.*bootstrap|bootstrap.*phylogenetic signal|phylogenetic signal.*bootstrap|bootstrap target" README.md NEWS.md ROADMAP.md docs/design R tests/testthat man --glob '!docs/dev-log/**'
gh issue list --repo itchyshin/drmTMB --state open --search 'bootstrap derived target error confint unknown repeatability q4' --limit 20 --json number,title,state,url,labels
git diff --check
```

Result: the final `test-profile-targets.R` run passed, `git diff --check` was
clean, and the GitHub issue search returned `[]`.

## Tests Of The Tests

The first targeted test run failed because the initial `cli` message used
pluralization shorthand incorrectly and produced "Multiple quantities for
pluralization" instead of the intended direct-target message. After replacing
that with plain `target(s)` wording, the same tests passed. This confirms the
new tests check the actual error text rather than only checking that an error
exists.

## Consistency Audit

The stale-wording scan found the new NEWS entry and the intended code/test
phrasing. README, ROADMAP, validation-debt, and profile-CI design docs still
describe bootstrap as a direct `confint()` route and keep derived q4,
repeatability, phylogenetic signal, prediction-table, `summary()`, and
`corpairs()` bootstrap intervals outside the current support boundary.

## GitHub Issue Maintenance

The issue search for bootstrap derived-target error wording, unknown targets,
repeatability, and q4 returned `[]`. No issue action was needed.

## What Did Not Go Smoothly

The initial `cli` pluralization syntax was too clever and broke the message.
Plain wording is safer for these error-boundary tests.

## Team Learning

Ada kept the slice to error UX rather than widening bootstrap support. Boole
checked that the error gives the user the next inspection command:
`profile_targets()`. Fisher and Noether kept derived targets out of the
bootstrap interval contract. Grace used the failing first run as the test of
the test. Rose recorded the stale-wording and issue-search evidence.

No spawned subagents were running.

## Known Limitations

This slice does not add derived bootstrap intervals, derived-profile
reparameterization, bootstrap coverage simulations, or bootstrap routes through
`summary()`, `corpairs()`, or prediction tables.

## Next Actions

After this PR lands, the next coding slice can move to a small direct-bootstrap
coverage simulation design or continue error UX for broad aliases such as
`parm = "correlations"` when derived rows are present.
