# Figure Audit: Profile-Likelihood Article

## Target

`vignettes/profile-likelihood.Rmd`, chunk `plot(prof)`, rendered with
`pkgdown::build_article("profile-likelihood")` on 2026-06-08.

## Figure

Rendered copy:
`docs/dev-log/figure-audits/2026-06-08-profile-likelihood-article/profile-likelihood-sigma-curve.png`

## Audit Table

| Figure | Source object | Visual data grain | Uncertainty source | Reader risk | Verdict |
| --- | --- | --- | --- | --- | --- |
| Residual SD profile | `profile.drmTMB` table from `profile(fit, parm = "sigma", compare = TRUE, profile_precision = "fast")` | Profiled residual-SD target values and likelihood-ratio distances | 95% profile-likelihood cutoff and profile endpoint lines | Caption clipping or endpoint lines mistaken for Wald intervals | Pass after local caption removal and short title/subtitle; the curve crosses the cutoff on both sides of the fitted estimate. |

## Role-Perspective Notes

Ada: the article now shows full-curve inspection before endpoint-only
`confint()`.

Florence: the rendered figure is legible, nonblank, and not clipped; the
estimate, cutoff, endpoints, and profile curve are visible.

Fisher: the plotted uncertainty is explicitly profile-likelihood, not Wald,
bootstrap, posterior, or Monte Carlo uncertainty.

Pat: the title and subtitle tell an applied reader what the dotted and dashed
reference lines mean without requiring them to inspect the code.

Grace: `pkgdown::build_article("profile-likelihood")` completed, and the
rendered PNG was inspected directly.

## Remaining Limitation

The article uses a small Gaussian demonstration target. It is a workflow and
visual-interpretation gate, not evidence that every profile-ready target is
fast, monotone, or well conditioned.
