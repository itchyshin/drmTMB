# After Task: NB2 Phylogenetic q1 Formal Audit Slices 541-555

## Goal

Run the next NB2 phylogenetic q1 evidence lane after Slices 526-540:

```r
drmTMB(
  bf(count ~ x + phylo(1 | species, tree = tree), sigma ~ z),
  family = nbinom2(),
  data = dat
)
```

The target was not a new likelihood or grammar change. The target was to use
the formal-grid artifact machinery, audit the direct `log_sd_phylo` profile
target and grouped species-intercept comparator, and decide whether the route
can move beyond formal-admission evidence.

## Implemented

- Added `docs/design/75-phase-18-nbinom2-phylo-q1-formal-audit.md`.
- Ran the default formal-grid preflight and recorded that the full gate expands
  to 288 condition cells x 500 replicates, or 144,000 target/comparator
  replicate fits before direct profile work.
- Ran an ignored all-cell local sentinel at
  `inst/sim/results/actions/nbinom2_phylo_q1_formal_541_555_sentinel`.
- Ran an ignored representative 24-cell x 5-replicate audit at
  `inst/sim/results/actions/nbinom2_phylo_q1_formal_541_555_replicate_audit`.
- Updated ROADMAP, NEWS, validation debt, readiness, simulation programme,
  simulation README, ADEMP cross-reference, and source map.

## Mathematical Contract

The model remains the ordinary non-zero-inflated NB2 q=1 phylogenetic `mu`
route. The DGP has a phylogenetic species effect in the log-mean predictor,
fixed-effect log-`sigma` overdispersion, and the NB2 variance
`Var(y) = mu + sigma^2 * mu^2`. The formal audit keeps the ordinary grouped
species-intercept comparator in the artifact schema because unstructured
species heterogeneity can mimic structured phylogenetic SD in small samples.

## Files Changed

- `docs/design/75-phase-18-nbinom2-phylo-q1-formal-audit.md`
- `docs/design/74-phase-18-nbinom2-phylo-q1-ademp.md`
- `docs/design/34-validation-debt-register.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `inst/sim/README.md`
- `vignettes/source-map.Rmd`
- `ROADMAP.md`
- `NEWS.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-24-nb2-phylo-q1-formal-audit-slices-541-555.md`

The generated artifact directories live under ignored `inst/sim/results/` and
are not package source files.

## Checks Run

```sh
Rscript tools/codex-checkpoint.R --goal "run NB2 phylogenetic q1 formal-grid audit slices 541-555" --next "preflight formal grid cardinality and runtime before launching local artifacts"
Rscript -e '... phase18_nbinom2_phylo_q1_formal_grid_spec(... n_rep = 500L ...) ...'
Rscript inst/sim/run/sim_run_actions_cell.R --task=nbinom2_phylo_q1_formal --dry-run=true --n-reps=500 --cores=10 --backend=multicore --profile-parameters=log_sd_phylo --output-dir=inst/sim/results/actions/nbinom2_phylo_q1_formal_541_555
Rscript -e 'devtools::load_all(quiet = TRUE); ... phase18_summarise_nbinom2_phylo_q1_smoke(... one formal-shaped cell ..., profile_parameters = "log_sd_phylo")'
Rscript -e 'devtools::load_all(quiet = TRUE); source("inst/sim/run/sim_run_actions_cell.R"); phase18_actions_main(c("--task=nbinom2_phylo_q1_formal", "--output-dir=inst/sim/results/actions/nbinom2_phylo_q1_formal_541_555_sentinel", "--n-reps=1", "--master-seed=20260603", "--cores=10", "--backend=multicore", "--profile-parameters=log_sd_phylo", "--overwrite=true"))'
Rscript -e 'devtools::load_all(quiet = TRUE); ... phase18_write_nbinom2_phylo_q1_formal_grid_outputs(output_dir = "inst/sim/results/actions/nbinom2_phylo_q1_formal_541_555_replicate_audit", conditions = representative_conditions, n_rep = 5L, master_seed = 20260604L, profile_parameters = "log_sd_phylo", cores = 10L, backend = "multicore", overwrite = TRUE)'
Rscript -e '... phase18_read_nbinom2_phylo_q1_grid_outputs(...); phase18_qa_nbinom2_phylo_q1_grid_outputs(...); phase18_nbinom2_phylo_q1_promotion_decision(...) ...'
gh issue list --repo itchyshin/drmTMB --state open --search "NB2 phylo q1 formal" --limit 20 --json number,title,state,url,labels
gh issue list --repo itchyshin/drmTMB --state open --search "nbinom2 phylogenetic formal" --limit 20 --json number,title,state,url,labels
gh issue list --repo itchyshin/drmTMB --state open --search "Phase 18 NB2 phylogenetic" --limit 20 --json number,title,state,url,labels
air format NEWS.md ROADMAP.md inst/sim/README.md vignettes/source-map.Rmd docs/design/34-validation-debt-register.md docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/74-phase-18-nbinom2-phylo-q1-ademp.md docs/design/75-phase-18-nbinom2-phylo-q1-formal-audit.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-24-nb2-phylo-q1-formal-audit-slices-541-555.md
Rscript -e "devtools::test(filter = 'phase18-nbinom2-phylo-q1', reporter = 'summary')"
rg -n '541|555|hold_smoke_only|nbinom2_phylo_q1_formal_541_555|75-phase-18-nbinom2-phylo-q1-formal-audit|500-replicate formal' NEWS.md ROADMAP.md inst/sim/README.md vignettes/source-map.Rmd docs/design/34-validation-debt-register.md docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/74-phase-18-nbinom2-phylo-q1-ademp.md docs/design/75-phase-18-nbinom2-phylo-q1-formal-audit.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-24-nb2-phylo-q1-formal-audit-slices-541-555.md
rg -n 'NB2.*q1.*formal recovery.*(now|passed|complete|closed)|NB2.*q1.*coverage.*(now|passed|complete|closed)|nbinom2_phylo_q1.*promote_narrowly|broad NB2 structured.*(ready|now)|NB2 sigma phylogeny.*now|zero-inflated NB2 phylogeny.*now|NB2 phylogenetic slopes.*now' NEWS.md ROADMAP.md README.md inst/sim/README.md docs/design vignettes tests -g '!*.html'
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "pkgdown::build_site()"
rg -n '541|555|hold_smoke_only|NB2 q1 formal|formal-audit|500-replicate formal|nbinom2_phylo_q1_formal_541_555' pkgdown-site/ROADMAP.html pkgdown-site/news/index.html pkgdown-site/articles/source-map.html
rg -n 'NB2.*q1.*formal recovery.*(now|passed|complete|closed)|NB2.*q1.*coverage.*(now|passed|complete|closed)|nbinom2_phylo_q1.*promote_narrowly|broad NB2 structured.*(ready|now)|NB2 sigma phylogeny.*now|zero-inflated NB2 phylogeny.*now|NB2 phylogenetic slopes.*now' pkgdown-site -g '*.html'
Rscript -e "devtools::check(error_on = 'never')"
rmdir tmp
Rscript -e "devtools::check(error_on = 'never')"
```

- `air format` completed without output.
- The focused NB2 q1 test passed.
- The source positive scan found the Slices 541-555 rows, audit doc, artifact
  paths, and `hold_smoke_only` wording.
- The source stale-support scan found no false claims that formal recovery or
  coverage is complete, no `promote_narrowly` wording, and no broad NB2
  structured-count promotion.
- `pkgdown::check_pkgdown()` reported no problems.
- `pkgdown::build_site()` completed successfully.
- The rendered positive scan found the Slices 541-555 ROADMAP rows, NEWS entry,
  source-map row, audit doc, artifact paths, and `hold_smoke_only` wording.
- The rendered stale-support scan found no false promotion or completed
  recovery/coverage claims.
- The first `devtools::check(error_on = "never")` had 0 errors and 0 warnings
  but 1 note from an empty top-level `tmp` directory created during validation.
  I removed only that empty directory.
- The final `devtools::check(error_on = "never")` completed in about 5m37s with
  0 errors, 0 warnings, and 0 notes.

## Evidence Summary

The default formal grid is too large to run casually from this dirty local
branch: 288 conditions x 500 replicates gives 144,000 target/comparator
replicate fits, plus direct `log_sd_phylo` profile requests. That full formal
gate was not run.

The all-cell sentinel ran all 288 formal cells once. It wrote all expected
CSV artifacts, returned 288 `ok` manifest rows and 1,728 replicate rows, and
had all target/comparator rows converged with `pdHess = TRUE`. Its 55
failure-ledger rows were warnings, all `collapsing to unique 'x' values`.
Direct profile intervals were 159 `ok` and 129 `failed`; failures concentrated
at true `sd_phylo = 0`.

The representative replicate audit ran 24 formal-shaped cells with five
replicates each. It wrote all expected artifacts, returned 120 `ok` manifest
rows and 720 replicate rows, and all parameter rows converged. The target fit
had `pdHess = TRUE` for 119 of 120 fits; the grouped comparator had
`pdHess = TRUE` for all 120 fits. Direct profiles were 74 `ok` and 46
`failed`: all true-zero SD cells failed to produce two-sided intervals, while
positive-SD cells produced 74 usable intervals out of 80.

The 5-replicate audit is too small for recovery claims, but it flagged the
right risk points. Fixed `mu` errors were modest in this small subset, the
phylogenetic SD RMSE was about 0.113, and the grouped comparator SD RMSE was
about 0.123. Fixed `sigma` rows had extreme errors in several low-count,
low-overdispersion cells, so Fisher should inspect those cells before any
larger recovery narrative is written.

## Tests Of The Tests

The formal-read-back QA is not just a file-existence check. It verifies required
artifacts, manifest rows, replicate rows, unique seeds, aggregate/manifest cell
alignment, grouped-comparator rows, and expected replicate counts. The
promotion helper then holds the route when the formal-spec gate does not meet
`n_rep >= 500`, even when artifact QA passes.

## Consistency Audit

The updated docs keep three states separate:

- fitted NB2 q=1 phylogenetic `mu` likelihood support;
- local formal-admission artifact evidence from Slices 526-555;
- still-missing 500-replicate formal recovery and coverage evidence.

No text claims broad NB2 structured parity, NB2 phylogenetic slopes, NB2
`sigma` phylogeny, zero-inflated NB2 phylogeny, spatial/animal/`relmat()` count
structure, or count-side covariance.

## GitHub Issue Maintenance

Issue searches for `NB2 phylo q1 formal` and `nbinom2 phylogenetic formal`
returned no direct open issue. The broader `Phase 18 NB2 phylogenetic` search
returned #59, the comprehensive simulation framework issue, and #128, a
random-slope documentation issue. I did not mutate GitHub issues from this
local uncommitted audit because #59 is broad infrastructure rather than a
specific NB2 q1 formal-run ticket, and the repository artifacts now record the
next clean compute action.

## What Did Not Go Smoothly

Two command issues were caught before the artifact run. A shell benchmark first
expanded `$` inside a double-quoted R expression, and a scratch source-only run
failed because `drmTMB()` was not loaded into the R session. The corrected
commands use single-quoted R expressions and `devtools::load_all(quiet = TRUE)`
before sourcing local simulation helpers.

The most important evidence wrinkle is statistical, not mechanical: direct
two-sided profile intervals often fail at the true-zero phylogenetic SD
boundary, and fixed `sigma` can be unstable in low-count, low-overdispersion
cells. Those rows stay in the artifact tables and should not be filtered away
before formal coverage is interpreted.

## Team Learning

For count-phylogeny grids, the all-cell sentinel and the replicate audit answer
different questions. The sentinel checks condition coverage and artifact
schemas; the small replicate audit checks whether repeated draws expose
Hessian, profile, or overdispersion instability. Future formal gates should
keep both layers before launching a 500-replicate run.

## Known Limitations

Slices 541-555 do not satisfy the formal recovery gate. They do not make
coverage claims, do not promote the NB2 q1 route beyond formal-admission
evidence, and do not open neighbouring NB2 structured routes. The 500-replicate
formal grid still needs to run from a clean pushed branch or manual Actions
dispatch.

## Next Actions

Run the full `nbinom2_phylo_q1_formal` grid with `n_rep = 500` and
`profile_parameters = "log_sd_phylo"` from a clean branch or manual Actions
dispatch. During that audit, preserve true-zero profile failures, warning rows,
Hessian rows, low-count fixed-`sigma` failures, and grouped-comparator summaries
as evidence rather than treating them as noise.
