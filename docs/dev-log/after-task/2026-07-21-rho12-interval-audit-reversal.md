# After-task report: regression-`rho12` interval — audit reversal

## 1. Goal

Answer one release question — does `confint(fit, parm = "rho12", newdata = ...)`
produce a supported 0.6.0 interval? — and propagate the answer to every surface
that had taken a position on it.

## 2. Implemented

Established by direct execution that a predictor-dependent `rho12 ~ x` **does**
yield row-specific intervals, then reverted the four PR #810 edits that had
removed that statement, corrected the release-scope manifest that was their
source, and corrected the two audit reports that had claimed the removals were
blocker fixes. Added the missing Gamma cell `mc-0242` to the manifest. Gave
`vignettes/julia-engine.Rmd` the same up-front deferred-status fence that
`cross-family.Rmd` already carried.

## 3a. Decisions and Rejected Alternatives

**The evidence.** A fitted `rho12 ~ x` bivariate Gaussian model (n = 250,
`bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~x, sigma2 = ~1, rho12 = ~x)`) was
exercised through all four APIs:

| call | result |
|---|---|
| `confint(fit, parm = "rho12", newdata = grid, method = "profile")` | finite row-specific bounds, `conf.status = "profile"`, `profile.message = "ok"`, no boundary hits |
| `predict_parameters(fit, newdata = grid, dpar = "rho12", conf.int = TRUE)` | finite bounds, `conf.status = "wald"` |
| `confint(fit, parm = "sigma1", newdata = grid, method = "profile")` | same route, works |
| `corpairs(fit, conf.int = TRUE)` (no `newdata`) | `conf.status = "newdata_required"`, bounds `NA` |

At x = -1 the profile route gave (-0.215, 0.130) and the Wald route (-0.218,
0.128); at x = +1, (0.677, 0.809) versus (0.679, 0.811). Two independent
computations agreeing to three decimals.

**Root cause.** `conf.status = "newdata_required"` is an instruction, not a
denial. `R/predict-parameters.R:238` returns it inside `if (is.null(newdata))`;
the corresponding profile note is named `use_confint_newdata`
(`R/methods.R:4213`, mapped at `:4518`). A predictor-dependent parameter has no
single scalar target, so the interval is necessarily per-row.

**Rejected: reverting PR #810 wholesale.** Three of its seven corrections — the
Julia q4 parity claim, the cross-family inference workflow, and the
`rho12`/`rho_latent` naming — were real and are kept.

**Rejected: restoring the README capability row.** The landing-page rewrite
removed that whole table as an approved compaction, not as a targeted
correction. The compact README asserts nothing false and delegates to the model
and implementation maps, which were already accurate. Leaving it alone is the
smaller change.

**Rejected: "available" as an unqualified claim.** Every restored statement
carries the distinction the original text lacked: these intervals are
*computed*, not *coverage-certified*. Only the constant `rho12 ~ 1` profile
interval is a certified reporting target.

## 4. Files Touched

Reverted with qualifier: `vignettes/bivariate-coscale.Rmd`,
`vignettes/model-workflow.Rmd`, `vignettes/figure-gallery.Rmd` (panel, caption,
and the pre-existing prose at the section on fitted correlation summaries, which
was the origin of the misreading).
Corrected: `docs/dev-log/release-audits/2026-07-20-0.6.0-release-scope-manifest.md`
(§3, §4 deferred table, §5, plus new §1b-2 for `mc-0242`);
`docs/dev-log/release-audits/2026-07-21-pre-cran-pkgdown-rd-audit.md`;
`docs/dev-log/after-task/2026-07-21-pre-cran-content-audit.md`.
Fenced: `vignettes/julia-engine.Rmd` (opener, and the cross-family pointer).
Unchanged and correct: `README.md`, `vignettes/model-map.Rmd`,
`vignettes/implementation-map.Rmd`, `R/profile.R` roxygen and the generated
`man/confint.drmTMB.Rd`.

## 5. Checks Run

The capability probe above, run against installed `drmTMB 0.6.0.9000`. No
vignette re-render, no `R CMD check`, no site build, no compute campaign. The
frozen tarball-clean rung was not rerun.

## 6. Tests of the Tests

The probe was designed so a false positive was detectable: it fitted a genuine
*regression* `rho12 ~ x` (not a constant), used three distinct covariate values,
and cross-checked the profile route against the independent Wald route. Their
agreement to three decimals is the control — a stub or a mis-transformed
interval would not reproduce another estimator's bounds. The negative control is
row D: `corpairs()` without `newdata` still returns `NA`, confirming the status
token means what the source says it means.

## 7a. Issue Ledger

Issue **#802** ("Regression-`rho12` interval") was filed on the misreading and
needs reframing: the interval exists; what is deferred is its coverage evidence.
Not yet actioned on GitHub — left for the maintainer.

## 8. Consistency Audit

Grepped `parm = "rho12"` across `vignettes/`, `man/`, `R/`, and `NEWS.md`. The
surviving instances in `model-map.Rmd`, `implementation-map.Rmd`, and the
`R/profile.R` roxygen were the *correct* ones and were left intact; an earlier
audit recommendation to "fix" them would have introduced false claims into the
shipped reference manual.

## 9. What Did Not Go Smoothly

The handover's stated premise — that the four `rho12` corrections were sound —
was wrong, so the recommended plan changed mid-task after the maintainer
questioned it.

Separately, this session read the handover at `7692a32b`, where the untracked
code-content review draft was listed `CARRIED-OVER`. Commit `1d2a0d31`
relabelled it *discarded* and the file was removed. Because this worktree's HEAD
advanced mid-session, two readers of "the same" handover reached opposite and
individually correct conclusions about that file's status, and the draft was
briefly restored here before the relabelling was found and the restoration
undone. **Lesson: re-read `git log` before trusting a handover fact, and treat a
worktree whose HEAD moves under you as a concurrency signal** — the house rule
is one tool at a time per repo.

## 10. Known Residuals

Coverage of the row-specific `rho12` intervals is unestablished and remains
unestablished. The probe ran against installed `0.6.0.9000` rather than a fresh
build of the release candidate; a re-run against the frozen candidate is the
clean confirmation. The restored vignettes have not been re-rendered. The #806
cross-family extractor defect (`df.residual()` returning `integer(0)`, `vcov()`
and `fitted()` returning `NULL`) is untouched and still post-0.6.

## 11. Team Learning

**Do not infer a capability's absence from a status token.** A status string is
an API message, not a capability verdict. To establish that something is
missing, call it. Here a single misread token produced four "blockers", four
documentation regressions, a wrong line in the truth-ceiling manifest, and a
GitHub issue — and each artifact cited the previous one, so three documents
agreed with each other and none checked the code.

**An audit that cites one line must grep the token.** Declaring a claim
discharged from a single edited line is how the same claim survived on three
other pages, one of which ships inside the tarball.

## 12. Cross-Product Coverage

This task does NOT cover: coverage evidence for regression-`rho12` intervals;
re-rendering the corrected vignettes; the #806 Julia extractor repair; tarball
re-freeze or re-check; the platform matrix; CRAN submission; or any change to a
likelihood, estimator, formula grammar, capability tier, or coverage floor.
