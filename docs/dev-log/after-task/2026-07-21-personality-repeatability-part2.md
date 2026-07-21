# After Task: Personality and Repeatability in Location-Scale-Scale Part II

## 1. Goal

Replace the Ayumi-adjacent comparative worked example in Part II with a
distinct repeated-measures personality example. Let sex predict the mean,
between-individual variation, and within-individual residual variation; call
the derived intraclass correlation repeatability. Reduce the phylogenetic
extension to one linear temperature predictor, familiar \(\sigma_a^2 A\)
notation, and no phylogenetic \(H^2\) detour. Add useful figures without making
the reader-facing page longer.

## 2. Implemented

Part II now starts with repeated exploration scores from 80 individuals, each
measured six times. The fitted Gaussian model uses the same individual-level
sex predictor in all three submodels:

```r
bf(
  exploration_score ~ sex + (1 | individual),
  sigma ~ sex,
  sd(individual) ~ sex
)
```

The article calculates sex-specific repeatability from the fitted
between-individual and within-individual SDs. It adds two compact figures: a
nested observation/individual/sex display and a three-panel fitted-component
comparison. Figure-construction code is hidden so the reader-facing desktop
page is 6,811 pixels high, down from 7,806 pixels for the prior live page.

The phylogenetic section now uses only `temperature` in `mu`, `sigma`, and
`sd(species, level = "phylogenetic")`. It starts from the familiar constant-SD
covariance \(\sigma_a^2 A\), then writes the two temperature-dependent log-SD
regressions without introducing diagonal \(D\) matrices. The prior quadratic
temperature/precipitation syntax and phylogenetic variance-ratio section were
removed.

## 3. Mathematical Contract

For observation \(j\) from individual \(i\),

\[
\begin{aligned}
y_{ij} &\sim \operatorname{Normal}(\mu_{ij}, \sigma_{e,i}^2),\\
\mu_{ij} &= \beta_0 + \beta_1\operatorname{sex}_i + b_i,\\
b_i &\sim \operatorname{Normal}(0, \sigma_{b,i}^2),\\
\log(\sigma_{e,i}) &= \gamma_0 + \gamma_1\operatorname{sex}_i,\\
\log(\sigma_{b,i}) &= \alpha_0 + \alpha_1\operatorname{sex}_i.
\end{aligned}
\]

The sex-specific repeatability point estimate is

\[
R_s = \frac{\sigma_{b,s}^2}
{\sigma_{b,s}^2 + \sigma_{e,s}^2}.
\]

The compact symbol/formula/DGP/extractor/interpretation alignment is recorded
in `docs/dev-log/designs/2026-07-21-personality-part2-alignment.md`.

## 3a. Decisions and Rejected Alternatives

The personality example leads because repeated measurements make the
distinction between `sd(individual)` and `sigma` visible and connect the model
to the familiar biological term repeatability. Sex is constant within
individual, satisfying the implemented group-level predictor rule.

Florence preferred one hierarchy-preserving figure; the Tufte review proposed
a second compact fitted-component display. Both were retained because they do
different work, while both plotting chunks are hidden from readers. Violin and
raincloud alternatives were rejected because marginal distributions cannot
separate within-individual from between-individual variation. Unsupported
error bars were also rejected.

The phylogenetic model does not incorrectly claim that a heterogeneous
temperature-dependent SD surface still has scalar covariance
\(\sigma_a^2 A\). That expression is explicitly the constant-SD starting
point; the log-SD regression is presented as its extension without introducing
new matrix notation.

## 4. Files Touched

- `vignettes/location-scale-scale.Rmd`: rewrote Part II and added two figures.
- `docs/design/226-reader-learning-path.md`: updated the article description
  and organism/predictor map.
- `docs/dev-log/designs/2026-07-21-personality-part2-alignment.md`: recorded the
  pre-edit symbolic/API alignment.
- `docs/dev-log/figure-audits/2026-07-21-personality-part2/figure-audit.md`:
  recorded Florence/Tufte visual review and per-figure evidence.
- `docs/dev-log/check-log.md` and this report: recorded checks and boundaries.

## 5. Checks Run

```sh
R_PROFILE_USER=/dev/null Rscript --no-init-file -e \
  'pkgdown::build_article("location-scale-scale", quiet = FALSE, new_process = FALSE)'
R_PROFILE_USER=/dev/null Rscript --no-init-file -e \
  'devtools::test(filter = "gaussian-random-effect-scale|sd-level-grammar", reporter = "summary")'
R_PROFILE_USER=/dev/null Rscript --no-init-file -e \
  'pkgdown::check_pkgdown()'
R_PROFILE_USER=/dev/null Rscript --no-init-file -e \
  'pkgdown::build_site(new_process = FALSE)'
rg -n 'D_a|D_e|H\^2|H2_|precip|temp_z|climate|same predictors|Ayumi' \
  vignettes/location-scale-scale.Rmd docs/design/226-reader-learning-path.md
rg -n '[[:blank:]]+$' <changed text files>
git diff --check
```

Results: the focused article render passed; both focused test files passed
(with the expected legacy `sd_phylo()` deprecation warning); `check_pkgdown()`
reported no problems; and the full site build completed. The stale-content,
trailing-whitespace, and diff checks returned no findings.

The example fit had optimizer convergence code 0, `pdHess = TRUE`, and
`check_drm()` returned 14 OK checks, zero notes, warnings, or errors. The fitted
female/male repeatabilities were 0.781 and 0.221, matching the intended contrast
in the simulated DGP.

## 6. Tests of the Tests

The first article render stopped because `round(sex_grid, 3)` tried to round
the factor-valued `sex` column. The display code was corrected to round only
numeric columns, and the complete article then rendered.

The first focused-test command called `testthat::test_file()` without loading
the package and produced only namespace errors (`drmTMB` and `bf` not found).
Rerunning through `devtools::test()` exercised the installed development
package and passed. This confirms that the initial failures were a harness
mistake rather than model regressions.

The full site build first stopped because sandboxed DNS could not resolve
`cloud.r-project.org` and the sass cache was not writable. The approved rerun
with network/cache access completed the home page, references, every article,
news, sitemap, search index, and final problem check.

## 7a. Issue Ledger

An open-issue search for `personality repeatability location scale scale`
returned no exact issue. No issue was created or modified. This is a focused
documentation correction on branch
`codex/personality-repeatability-article`.

## 8. Consistency Audit

The equations, formula, DGP, predictions, figures, table, and prose all use the
same three quantities: expected score `mu`, within-individual residual SD
`sigma`, and between-individual random-intercept SD `sd(individual)`. The first
figure shows observations only on the response axis; the second shows fitted
parameter values only. Captions and alt text name the data grain and state that
no uncertainty intervals are drawn.

The phylogenetic syntax uses `species` consistently, one linear `temperature`
predictor, the generic `sd(..., level = "phylogenetic")` formula spelling, and
the retained extractor label `sd_phylo(species)`. No family, likelihood,
parser, C++, capability tier, `NEWS.md`, or `ROADMAP.md` claim changed.

## 9. What Did Not Go Smoothly

The table-rounding bug and package-unaware test invocation were both caught
and corrected. The full-site network failure required an approved rerun. The
figure audit was formally loaded after the first figure draft rather than
before it; its Rose scan and hard gates were then applied, the direct fitted-
mean labels were added, and both final PNGs plus desktop and 390-pixel layouts
were inspected.

## 10. Known Residuals

Repeatability is reported as a point estimate only. The article does not claim
a calibrated interval for this nonlinear ratio. The phylogenetic block is a
syntax-and-math extension rather than a second runnable fit, keeping the page
short and distinct from a collaborator's planned analysis. The page teaches
the Gaussian route and does not generalize it to every non-Gaussian family.

## 11. Team Learning

A hierarchy-preserving raw-data figure teaches this model better than a
marginal distribution plot because it reveals the two levels of variation the
two scale formulas target. For short statistical tutorials, hidden plotting
code can increase visual explanation while reducing reader-facing length.

## 12. Cross-Product Coverage

Covers: one-response Gaussian repeated measures; a fixed sex effect in `mu`,
`sigma`, and ordinary `sd(individual)`; population-level prediction of all
three quantities; a derived repeatability point estimate; and the documented
Gaussian q1 phylogenetic direct-SD syntax with one linear predictor.

Does NOT cover: repeatability intervals, random slopes or random right-hand-
side terms inside `sd()`, generic spatial/animal/`relmat()` direct-SD surfaces,
bivariate models, REML, posterior trees, or broad non-Gaussian support.

## 13. Next Actions

Push the focused branch, merge only after GitHub checks pass, wait for the
Pages workflow, verify the live Part II text and both images, and open the live
HTML for the user.
