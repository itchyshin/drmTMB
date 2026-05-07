# After Task: Scaffold, Grammar, pkgdown, and Logo

Date: 2026-05-06

## Goal

Create the project scaffold and Codex-native infrastructure, refine the core
formula grammar, add initial parser stubs and tests, build pkgdown pages, and
create a sister-package hex logo for `drmTMB`.

## Created or Changed

- Added R API scaffold: `bf()`, `drmTMB()`, formula markers, and internal
  formula-entry parsing.
- Added tests for formula capture, `rho12`, `meta_known_V(V = V)`, `sd(group)`,
  and marker no-op behaviour.
- Added or refined design docs for formula grammar, family registry,
  likelihoods, random effects, distribution roadmap, meta-analysis,
  phylogenetic/SPDE plans, reference programme, and after-task protocol.
- Added collaboration files for Codex and Claude Code.
- Added project-local skills and agent configs.
- Added pkgdown configuration, GitHub Actions, vignettes, and generated
  pkgdown preview site.
- Added `man/figures/logo.svg`, `man/figures/logo.png`, and pkgdown favicons.
- Added `inst/COPYRIGHTS` stating no external modelling code has been ported.

## Checks Run

- `Rscript -e "devtools::document()"`: clean on final run.
- `Rscript -e "devtools::test()"`: 16 passed, 0 failed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `Rscript -e "pkgdown::build_favicons(overwrite = TRUE)"`: generated favicon
  set.
- `Rscript -e "pkgdown::build_site()"`: final build completed with URLs,
  favicons, Open Graph, articles, and reference metadata all OK.
- `Rscript -e "devtools::check(error_on = 'never')"`: 0 errors, 0 warnings,
  0 notes.
- `air format .`: not run because `air` is not installed in this environment.

## Outcome Checks

- Verified generated site artifacts exist:
  `pkgdown-site/index.html`, `articles/meta-analysis.html`,
  `articles/phylogenetic-spatial.html`, `man/figures/logo.png`, and
  `pkgdown-site/favicon.svg`.
- Searched generated HTML for `rho12`, `meta_known_V`, phylogenetic, and
  spatial content; all expected pages contain the updated syntax.
- Viewed `man/figures/logo.png` locally after rendering from SVG.

## Consistency Audit

Corrected stale `rho` references in:

- `docs/dev-log/decisions.md`;
- `docs/design/02-family-registry.md`;
- `docs/design/05-testing-strategy.md`;
- project skills and agent configs.

Remaining matches from stale-syntax scans are intentional guardrails:

- `AGENTS.md` forbids `meta_gaussian()` and `tau ~` without a design decision.
- `docs/design/10-after-task-protocol.md` contains the scan command itself.
- `ROADMAP.md` and `docs/design/01-formula-grammar.md` mention
  `mvbind(y1, y2) ~ x` only as shorthand for identical bivariate location
  formulas.

## Tests of the Tests

The first formula test failed because `deparse1(form$calls$rho12)` returns the
RHS-only formula `~x1 + x2`, not the parameter name. The test was corrected to
assert the parsed `dpar` field instead. This confirms the test now exercises
the parser output rather than a misleading deparse side effect.

## Known Limitations

- The fitting engine is still intentionally unimplemented.
- No TMB likelihood or simulation recovery test exists yet.
- `bf()` records parsed formula entries but does not yet validate every family
  rule.
- Root-level `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, and `ROADMAP.md` are
  rendered by pkgdown as standalone pages because pkgdown renders top-level
  Markdown files by default.

## Next Task

Implement the fixed-effect Gaussian location-scale MVP with:

- family registry minimum for `gaussian()`;
- TMB likelihood for `mu` and `sigma`;
- optimizer wrapper;
- prediction/simulation methods;
- deterministic simulation recovery tests.
