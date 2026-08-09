# After Task: Restore the function map and deduplicate the model map

## Goal

Restore the quick function/workflow route under Get started, keep the
implemented-versus-planned status map under Model Guides, and prove that no
article or asset disappeared.

## Implemented

The Get started menu now pairs **Function map and cheat sheet** with
`articles/function-map-cheatsheet.html`. Model Guides retains **What can I fit
today?** paired with `articles/model-map.html`. The introductory learning-path
table uses the same reader order, and the canonical design inventory now lists
all 37 vignettes.

The regression test checks exact labels and hrefs together, verifies that each
article belongs to its intended index group exactly once, checks the opening
learning-path order, and ties the design heading and row count to the current
vignette inventory.

## Mathematical Contract

Not applicable. This task changes navigation, documentation, and regression
guards only. It does not change a likelihood, formula grammar, estimator,
parameter definition, fit permission, or inference claim.

## Files Changed

- `_pkgdown.yml`: restore the function-map route and remove the duplicate
  model-map route from Get started.
- `vignettes/drmTMB.Rmd`: align the opening learning path with the navbar and
  add the function/workflow router explicitly.
- `docs/design/226-reader-learning-path.md`: record the current five-item Get
  started contract and the complete 37-vignette inventory.
- `tools/tests/test_capability_ledger.py`: guard exact route pairs, index
  membership, learning-path order, and inventory freshness.
- `docs/dev-log/check-log.md`: record verification.
- This report.

## Checks Run

- `python3 -m unittest tools/tests/test_capability_ledger.py`: 64 tests passed.
- `python3 tools/capability_ledger.py --check`: all 31 generated outputs current.
- `pkgdown::check_pkgdown()`: no problems found.
- Focused pkgdown renders: `model-map`, `drmTMB`, and
  `function-map-cheatsheet` completed.
- Rendered HTML contains one Get started function-map link and one Model Guides
  model-map link, with both target pages present.
- `rg -n "Model map|Function map and cheat sheet|function-map-cheatsheet|model-map" _pkgdown.yml vignettes/drmTMB.Rmd docs/design/226-reader-learning-path.md` confirmed the intended neighbouring routes.
- `rg -n "across 35 vignettes|contains 35 vignettes|35 rows|Total: 35 placed" docs/design/226-reader-learning-path.md` returned no stale current-inventory wording.
- `git diff --check`: passed.

A full local `pkgdown::build_site()` progressed through the home, reference,
and early article stages, then stopped in the unrelated `cross-family.Rmd`
example because the locally loaded installed package intentionally rejects
`vcov()` for frozen-margin association estimates. The affected pages were
therefore rebuilt directly. The pull-request and post-merge pkgdown workflows
remain the authoritative complete-site checks.

## Tests Of The Tests

The exact-pair regression check was evaluated against `origin/main`: it found
no function-map pair and found the old fourth pair, `Model map` →
`articles/model-map.html`. Thus the new test detects the reported regression
rather than merely passing on both configurations.

## Consistency Audit

Pat confirmed that the two pages now have distinct user roles: function and
workflow routing versus implemented/planned model status. Rose found the stale
35-vignette inventory and introductory-table contradiction; both were repaired.
Ada required exact label-to-href assertions and article-group assertions; both
were added.

Repository and rendered-source sweeps confirmed that
`vignettes/function-map-cheatsheet.Rmd`, its PNG asset, and
`vignettes/model-map.Rmd` remain present. No package code, public API,
DESCRIPTION, release ledger, or CRAN material changed.

## GitHub Issue Maintenance

`gh issue list --repo itchyshin/drmTMB --state open --limit 100 --search
"navbar function map model map pkgdown"` returned no overlapping open issue.
No new issue is needed for this bounded regression; the focused pull request
will carry the public discussion and CI evidence.

## What Did Not Go Smoothly

The first navigation edit fixed the visible duplicate but did not initially
update the introductory learning path or its stale inventory. Independent
package-aware reviews caught both. The in-app browser could reach a stale
localhost server rather than the fresh shell render, so local visual evidence
was not used for the completion claim; the final visual gate is the deployed
site at the merged commit.

## Team Learning

Navbar labels and hrefs must be tested as pairs. Checking label order and href
presence separately allows swapped destinations to pass. Navigation review
must also include the introductory learning path and article-index grouping,
because all three surfaces teach the same route.

## Known Limitations

This fix does NOT remove intentional cross-menu reuse of the overview,
family-choice, or fitted-model workflow pages. It addresses only the accidental
duplicate placement of `model-map` and the missing top-menu route to the
function map. It does not advance the release rung beyond `tarball-clean`.

## Next Actions

Merge only after focused PR checks pass, wait for the pkgdown deployment from
`main`, and verify both menus at desktop and mobile widths on the live site.
