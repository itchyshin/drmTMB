# After Task: ML-vs-REML guidance + weak-ID doc updates (#20)

Meta: 2026-07-08 · Claude (Opus 4.8) · repo `drmTMB` · branch
`drmtmb/fix-16-phylo-mu-diagnostics` off `main` `bed29701`.

## 1. Goal

Give users guidance on when to use maximum likelihood vs REML (#20), and close the
code→doc loop for the #18/#19 weak-ID work by documenting the inflated-SE-despite-clean-
Hessian pattern where users would look for it.

## 2. Implemented

Two additions to `vignettes/convergence.Rmd` (the "Improving convergence" article):

- **New section "Choosing between maximum likelihood and REML."** ML is the default
  (`REML = FALSE`); REML corrects the order-`p/n` downward bias in variance components;
  mean and variance are information-orthogonal so ML→REML leaves the mean coefficients
  essentially unchanged and adjusts the variance component (the phylo SD and its
  `sd_phylo(...) ~ x` surface). Guidance is keyed on `p/n`, not tip count alone, with the
  fit-both-and-compare recommendation and a runnable snippet.
- **Weak-ID paragraph** in the near-boundary section: a near-boundary phylo
  cross-correlation with a large SE despite `pdHess = TRUE` is weak identification (one
  trait's phylo SD → 0, correlation runs to ±1 on a flat ridge); `check_drm()` flags it
  via `biv_phylo_mu_covariance` (warning) + `standard_errors_inflated` (note); the profile
  is flat; the fix is to drop the cross-correlation or report it as non-identified. Added
  `standard_errors_inflated` to the staged-workflow `check_drm()` row list.

## 3a. Decisions and Rejected Alternatives

- **Extended `convergence.Rmd` rather than a new vignette.** It already carries the
  neighbouring material (pdHess, near-boundary phylo correlations, MAP/penalty,
  model-specific advice), so the guidance lands where a user fighting a weak variance
  component is already reading; a standalone article would fragment it.
- **Corrected the handover's phrasing with evidence.** The handover said "REML shifts the
  SD level not the coefficients on `sd_phylo`." A real n=16 ML-vs-REML fit
  (`scratchpad/proto`/inline) showed the opposite for the *surface* coefficients: mean
  coefficients moved < 0.005, but the `sd_phylo` intercept AND slope moved ~0.04–0.06 —
  because those coefficients *are* the variance component REML debiases. The doc states
  the accurate version (REML adjusts the variance component; the MEAN coefficients are the
  ones left unchanged). Repo/empirics over the handover lead.

## 4. Files Touched

- `vignettes/convergence.Rmd` — new ML/REML section + weak-ID paragraph + workflow row.
- `docs/dev-log/after-task/2026-07-08-issue20-ml-reml-guidance.md` — this note.

## 5. Checks Run

- `rmarkdown::render("vignettes/convergence.Rmd")` → renders cleanly (chunks are
  `eval = FALSE` globally, so the illustrative snippet does not execute).
- Grounding fit (n=16, `sd_phylo(species) ~ z_species`): default estimator is ML; mean
  coefficients ML≈REML (|Δ| < 0.005); `sd_phylo` intercept/slope moved 0.043/0.060.

## 6. Tests of the Tests

- No unit test (prose/vignette). The statistical claims were reviewed by Fisher
  (inference_reviewer) — see §9.

## 7a. Issue Ledger

- Closes #20. No new issues.

## 8. Consistency Audit

- The vignette now names the exact `check_drm()` rows shipped in #18/#19
  (`biv_phylo_mu_covariance`, `standard_errors_inflated`) with the correct severities
  (warning, note) — verified against `R/check.R`.

## 9. What Did Not Go Smoothly

- Fisher review flagged two SHOULD-FIX qualifications, both applied: (1) the guidance
  originally keyed on tip count, dropping `p` from the `p/n` law — reworded to key on
  `p/n` and to warn that a rich fixed-effect surface raises `p`; (2) the `p/n` factor is
  the *variance* bias — added that the SD correction is ~half (`p/2n`, delta method).
  Nit: softened "means and SEs are unaffected" → "largely unaffected."

## 10. Known Residuals

- pkgdown site not rebuilt here (local-checks discipline; the user/Codex rebuilds before a
  release). The `.Rmd` change is committed; `pkgdown::build_site()` is a separate step.
- The n=16 anchor gives movement magnitudes without the baseline scale; a reader wanting
  to judge "0.04–0.06" would need the log-SD intercept (Fisher's optional nit, not applied
  to keep the prose tight).

## 11. Team Learning

- The handover is a *lead, not authority* (D-21): its "REML doesn't shift `sd_phylo`
  coefficients" claim was empirically false for the surface coefficients. A 30-second
  ML-vs-REML fit caught it. Ground quantitative doc claims before shipping them.

## 12. Cross-Product Coverage

- **covers ✓**: ML-vs-REML choice guidance (p/n framing, orthogonality, small-subclade
  vs large-clade, fit-both); documentation of the #18/#19 weak-ID pattern in the article
  users read for convergence problems.
- **does NOT cover ✗**: no new vignette or pkgdown rebuild; no ML/REML coverage *numbers*
  beyond the single n=16 anchor and the cited 10,440-tip 0.05%; the location-scale-scale
  (C2) and REML provider-unlock (C1) capability slices remain unbuilt.
