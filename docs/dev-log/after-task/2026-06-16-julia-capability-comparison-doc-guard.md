# After Task: Julia Capability Comparison And Docs Drift Guard

## Goal

Keep `engine = "julia"` public claims aligned with the intentional bridge gate
registry by adding a direct DRM.jl/R-bridge/native-TMB capability comparison and
a public-docs drift guard, without promoting binomial bridge support.

## Implemented

Added `drm_julia_capability_comparison()` as an internal row-oriented registry
for current Julia-adjacent claims. The new generator writes
`docs/dev-log/dashboard/julia-capabilities.tsv` for the mission-control widget
and `inst/extdata/julia-capabilities.tsv` for installed-package checks. The
dashboard now renders a Julia capability comparison section beside the generated
gate table, and the validator checks schema, identifiers, statuses, GitHub
evidence links, issue labels, and nonempty claim boundaries.

The new public-docs guard scans README, NEWS, and Julia/cross-family vignettes
for broad bridge overclaims: user-facing `engine_control`, all-family Julia
bridge language, ordinary binomial bridge promotion, or unsupported Julia speed
headlines.

## Mathematical Contract

No likelihood, estimator, or formula grammar changed. The registry is a claim
boundary: it separates native TMB support, R-to-Julia bridge support, and direct
DRM.jl evidence. Ordinary `stats::binomial()` remains a native-TMB #569 route;
the Julia bridge row remains an intentional error until separate parity evidence
exists.

## Files Changed

- `R/julia-bridge.R`
- `tools/write-julia-capability-comparison.R`
- `tools/validate-mission-control.py`
- `tools/start-mission-control.sh`
- `tests/testthat/test-julia-gate-vs-engine.R`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/julia-capabilities.tsv`
- `inst/extdata/julia-capabilities.tsv`

## Checks Run

```sh
Rscript tools/write-julia-gate-registry.R
Rscript tools/write-julia-capability-comparison.R
air format R/julia-bridge.R tests/testthat/test-julia-gate-vs-engine.R tools/write-julia-capability-comparison.R
python3 -m json.tool docs/dev-log/dashboard/status.json >/tmp/status-json-544-docguard.out
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/tmp/sweep-json-544-docguard.out
python3 tools/validate-mission-control.py
Rscript --vanilla -e 'devtools::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-julia-gate-vs-engine.R", reporter = "summary")'
sh tools/start-mission-control.sh --background
npx playwright screenshot --wait-for-timeout=3000 --viewport-size=1440,1200 'http://127.0.0.1:8765/?v=544-docguard-1122b' /tmp/drmtmb-julia-capabilities-desktop.png
npx playwright screenshot --wait-for-timeout=3000 --viewport-size=390,1400 'http://127.0.0.1:8765/?v=544-docguard-1122b' /tmp/drmtmb-julia-capabilities-mobile.png
tmpdir=$(mktemp -d /tmp/drmtmb-build-check-XXXXXX); cd "$tmpdir" && R CMD build --no-manual --no-build-vignettes /private/tmp/drmtmb-julia-docs-drift >/tmp/drmtmb-build-check-capabilities.log 2>&1 && tarball=$(ls drmTMB_*.tar.gz | head -n 1) && tar -tzf "$tarball" | grep '^drmTMB/inst/extdata/julia-capabilities.tsv$'
Rscript --vanilla -e 'devtools::test()'
Rscript --vanilla -e 'pkgdown::check_pkgdown()'
Rscript --vanilla -e 'devtools::check(error_on = "never")'
git diff --check
rg -n "non-identified|nonidentified|impossible|flat/unbounded|Bayesian only reads back the prior|REML on scale|REML.*scale" README.md ROADMAP.md NEWS.md docs vignettes R tests || true
```

Results:

- The generator wrote 9 capability rows to both dashboard and installed
  artifacts.
- The mission-control validator passed:
  `mission_control_ok: 19/68 banked_or_verified, 4 active, 17 matrix rows, 10 finish rows, 15 Julia gate rows, 9 Julia capability rows`.
- Focused `test-julia-gate-vs-engine.R` passed.
- Browser DOM verification found the Julia capability section, gate section,
  #544 finish-board row, binomial bridge boundary row, and active worktree state
  with no reported errors. Screenshots were saved to
  `/tmp/drmtmb-julia-capabilities-desktop.png` and
  `/tmp/drmtmb-julia-capabilities-mobile.png`.
- The source tarball includes `drmTMB/inst/extdata/julia-capabilities.tsv`.
- Full `devtools::test()` passed with 0 failures, 8 known log-sigma-clamp
  warnings, 5 known Julia bridge/sigma-phylo skips, and 11061 passes.
- `pkgdown::check_pkgdown()` is blocked by a Claude-owned penalty/MAP docs
  issue: `_pkgdown.yml` is missing the exported `drm_phylo_penalty` topic.
- Before #585 merged, `devtools::check(error_on = "never")` completed with
  0 errors, 0 warnings, and 2 notes: future timestamp verification and the
  then-current `stats::ave` import note.

## Tests Of The Tests

The capability artifact test compares every generated TSV row with
`drm_julia_capability_comparison()`, including the installed `inst/extdata`
copy used inside R CMD check. The public-docs guard checks a malformed-input
style failure path for documentation claims: if public docs start claiming
ordinary binomial Julia bridge support or user-facing `engine_control`, the test
fails.

## Consistency Audit

The capability comparison keeps the framing conservative: weakly identified
scale-side structured effects stay prior-sensitive and evidence-gated; no
`REML`-on-scale missing row was added; `rho12 ~ predictors` remains the lead
novelty in the finish board; ordinary binomial remains native TMB only until a
separate bridge parity slice exists.

Stale-wording search:

```sh
rg -n "non-identified|nonidentified|impossible|flat/unbounded|Bayesian only reads back the prior|REML on scale|REML.*scale" README.md ROADMAP.md NEWS.md docs vignettes R tests || true
```

Historical hits remain in old check-log/after-task records and generic
"impossible" wording outside this slice. The new capability boundary avoids the
phantom "REML on scale is missing" row and uses restricted-likelihood boundary
language only to avoid overclaiming native TMB support.

## GitHub Issue Maintenance

This slice belongs to `drmTMB#544`. It also points the ordinary binomial bridge
boundary to `drmTMB#569` and keeps the gllvmTMB bridge-ledger lesson linked to
`gllvmTMB#488`.

## What Did Not Go Smoothly

The first screenshot pass looked stale because `sweep.json` overlays
`status.json` and still carried the previous 08:05 active-work note. Updating
the overlay fixed the visible timestamp and active-work text. The in-app
browser screenshot command timed out on this large static page, so DOM
verification used the in-app browser and image artifacts used local Playwright.

## Team Learning

Rose: dashboard truth needs overlay files in the same validation mental model as
`status.json`; stale `sweep.json` can make a good source ledger look stale in
the served page. Grace: installed-package tests need generated artifacts under
`inst/extdata` because `docs/` is absent inside R CMD check.

## Known Limitations

This does not relax any bridge gate, does not add `engine_control`, does not
modify DRM.jl, and does not promote ordinary binomial bridge support. The
capability comparison is a governance artifact, not new numerical evidence.

## Next Actions

Keep draft PR #587 green after the #585 rebase, then mark it ready and merge it
when the serial queue is clear.
