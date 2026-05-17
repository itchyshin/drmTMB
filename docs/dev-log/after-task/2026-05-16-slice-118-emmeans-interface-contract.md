# After Task: Slice 118 emmeans interface contract

## Goal

Record the future `emmeans` interface contract before implementing any S3
method, dependency, or user-facing estimated marginal mean workflow.

## Implemented

Added `docs/design/40-emmeans-interface-contract.md`, a design-only note that
maps the official `emmeans` extension API to `drmTMB`. The note says that the
first public method should be a narrow fixed-effect univariate `mu` path and
that bivariate, structured-effect, random-effect, zero-inflated, hurdle,
ordinal expected-score, contrast, slope, and interval-aware targets remain
blocked until their algebra and tests are explicit.

## Mathematical Contract

No model equation changed. The design contract preserves the Slice 117
link-versus-response rule:

```text
eta = X_mu beta_mu
```

For any future first method, link-scale EMMs should stay on `eta`, while
response-scale EMMs should use the inverse link recorded in
`docs/design/19-family-link-contract.md`. The method must not silently translate
native distributional-parameter EMMs into `fitted()` response means.

## Files Changed

- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/design/40-emmeans-interface-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-118-emmeans-interface-contract.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-184715-codex-checkpoint.md`

## Checks Run

- `air format ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md`: passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rebuilt `pkgdown-site/ROADMAP.html`.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with "No problems found."
- `git diff --check`: passed.
- `rg -n 'Slice 118|40-emmeans-interface-contract|recover_data\\(\\)|emm_basis\\(\\)|first public method|bivariate.*blocked|zero-inflated.*blocked|random-effect.*blocked' ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md pkgdown-site/ROADMAP.html`: confirmed source and rendered roadmap wording.
- `rg -n 'exported `emmeans` method|implemented `emmeans`|emmeans support is implemented|emmeans.*Imports|emmeans.*Suggests|contrast API.*implemented|slope.*implemented' DESCRIPTION NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md pkgdown-site --glob '!pkgdown-site/search.json' --glob '!pkgdown-site/deps/**'`: found only intentional future-boundary wording and unrelated existing slope-status text.
- `Rscript tools/codex-checkpoint.R --goal "Slice 118 emmeans interface contract" --next "stage, commit, push branch, open PR after Slice 117 merge"`: passed and wrote `docs/dev-log/recovery-checkpoints/2026-05-16-184715-codex-checkpoint.md`.

## Tests Of The Tests

This is a design-only slice. The relevant validation is that Slice 117 already
tests the current `prediction_grid()` and `predict_parameters()` link-response
contract across implemented fixed-effect family paths. Slice 118 turns that
evidence into implementation gates for future `emmeans` work.

## Consistency Audit

ROADMAP and `docs/design/39-visualization-grammar.md` now point to the new
interface contract. NEWS and DESCRIPTION were intentionally left unchanged
because no dependency, S3 method, function, argument, or example workflow was
added.

## What Did Not Go Smoothly

Slice 118 started while Slice 117 CI was still running, so the branch was
rebased after PR #82 merged. Git skipped the already-applied Slice 117 commit
cleanly, and the Slice 118 docs reapplied without conflicts.

## Team Learning

Ada kept the slice as a contract rather than implementation. Boole owned the S3
method boundary and the `dpar`/`type` vocabulary. Fisher owned the distinction
between EMMs of native distributional parameters and fitted response means.
Pat owned the unsupported-call guidance. Grace owned pkgdown and dependency
checks. Rose owned stale-claim scans. Gauss, Noether, Curie, Emmy, Darwin, and
Jason stayed watch-only because no likelihood, equation, test code, object
structure, biological example, or landscape claim changed beyond the official
`emmeans` API citation.

## Known Limitations

No `emmeans` method is implemented. The first implementation still needs
targeted tests comparing `emmeans::ref_grid()` output against
`prediction_grid()` and `predict_parameters()` for the exact supported target
set.

## Next Actions

Implement or prototype only the fixed-effect univariate `mu` path after deciding
whether `emmeans` belongs in `Suggests` for public support or remains an
internal adapter experiment.
