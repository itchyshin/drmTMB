# Poisson relatedness-matrix SD regression

| Check | Command or evidence | Result |
|---|---|---|
| Test-first admission | Focused test before builder change | Failed as expected: Poisson rejected `sd_relmat(id)` as an unsupported parameter. |
| Focused implementation | `Rscript -e 'devtools::test(filter = "poisson-relmat-sd-regression", reporter = "summary")'` | 19 expectations passed; zero failures, warnings, or skips. The fixture uses a 1.7-scaled, non-unit-diagonal covariance and checks recovery on the supplied covariance scale. |
| Neighboring routes | `Rscript -e 'devtools::test(filter = "poisson-(relmat|phylo)-sd-regression|binomial-relmat-sd", stop_on_failure = TRUE)'` | 46 expectations passed across Poisson relmat, Poisson phylo, and Bernoulli relmat; zero failures, warnings, or skips; 21.4 seconds. |
| Tutorial example | `devtools::load_all()` followed by `rmarkdown::render("vignettes/predictor-dependent-random-sd.Rmd", ...)` | Rendered to `/private/tmp/predictor-dependent-random-sd-check-20261020.html` using this worktree's source. A standalone render first selected an older installed package from another worktree and failed before the changed section. |
| pkgdown checks | `Rscript -e 'pkgdown::check_pkgdown()'` | No problems found; existing Pandoc `--mathml` deprecation warnings. |
| Full site build | `Rscript -e 'pkgdown::build_site(preview = FALSE)'` | Not completed: pkgdown could not resolve `cloud.r-project.org` in this network-restricted environment. No site was published. |
| Diff whitespace | Scoped `git diff --check` across `R/drmTMB.R`, `R/methods.R`, the new test, README/NEWS, design and roadmap notes, the two check-log files, the after-task report, and the three updated vignettes | Passed. |
| Prose lint | `python3 /Users/z3437171/shinichi-brain/tools/slop_check.py <absolute paths to the changed prose files>` | Zero findings in the after-task report and detail log; all scanned project prose files remained below the configured review threshold. |
| After-task report | `CHECK_AFTER_TASK_ACTIVE=1 Rscript --no-environ --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-10-20-poisson-relmat-sd-regression.md')"` | Structure passed after repair; the recursive programme-ledger pass was intentionally skipped by the checker. |
| Programme ledger status | `node /Users/z3437171/.codex/skills/unlazy/scripts/gate-check.mjs --status .unlazy/general-sd-regression/GATES.md` | 8 parent gates, 7 unmet; G2 met, G5 deferred. G3/G4/G6 remain open with this slice recorded as partial evidence. |
| Status inventory | `rg -n 'sd\(group\)|Poisson relmat|sd\(id, level = "relmat"\)' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/design/34-validation-debt-register.md vignettes/formula-grammar.Rmd vignettes/model-map.Rmd vignettes/predictor-dependent-random-sd.Rmd` | Reviewed; claims and limits are present in the applicable inventory files. No navigation change required in `_pkgdown.yml`. |
| Open issue search | `gh issue list --state open --search 'Poisson relmat SD' --limit 10 --json number,title`; `gh issue list --state open --search 'random-effect scale' --limit 10 --json number,title`; `gh issue list --state open --search 'general SD-regression' --limit 10 --json number,title` | No issue dedicated to this narrow implementation slice; no issue changed. |

## Test design note

The first generated predictor was a smooth trend against a smooth relatedness
kernel. The fitted slope missed truth by 0.43, revealing weak separation in
that one synthetic realization. The fixture now uses a balanced alternating
contrast and retains a fixed absolute slope tolerance of 0.30. The test checks
fitting, group-SD and parameter prediction, random-effect scaling, marginal
simulation, save/reload prediction, and constant-SD equivalence.

This is one native Poisson q=1 `relmat()` cell. Julia's existing Poisson
related-matrix route normalizes supplied matrices to correlations; native TMB
uses the supplied covariance scale. Non-unit-scale cross-engine parity remains
open. This result does not qualify interval calibration, other structured
Poisson providers, or broader structured-SD coverage.
