# Independent completion reader check: SD article first delivery

**Role:** independent applied-ecology PhD reader and science-communication review. **Date:** 4 November 2026. **Scope:** read-only review of the R article, paired Julia page, fresh R render/figure, and recorded Julia browser check. No source or repository files were changed.

## Verdict

No blocking reader confusion found in the approved first delivery. The pages answer the core question—how a group-level predictor changes latent group variation—and make the scale and scope of each reported result clear. This is a communication/completion read, not a new numerical validation.

## Reader checks

- **Three SD quantities:** The R page distinguishes Gaussian residual `sigma` from latent group-effect SD. In its Gamma example, it says `sigma` is the conditional coefficient of variation and response SD is `mu * sigma`. It then identifies `s_g` as the latent SD multiplier and gives marginal latent SD as `s_g * sqrt(K_gg)`. The Julia page carries the same distinction and says why a non-unit diagonal of `K` matters. The plotted right-hand panel is labeled marginal group-effect SD, and the adjacent prose explains that its trend partly reflects `K`'s diagonal.
- **One fixture versus general recovery:** The generated examples show one-data-set estimates against generating values. The Gamma estimate (ratio 1.07297 versus 1.49182) is a visible miss, described as such on the Julia page; R similarly says the estimate is closer to one. The pages do not call this parameter recovery, repeated-sampling validation, or calibrated uncertainty. The independent Laplace comparison is correctly scoped to the objective for this one fixture, not interpreted as recovery evidence.
- **Prediction conventions:** Both pages distinguish stored R-bridge predictions, which include the retained fitted group contribution on the checked structured route, from bridge predictions with explicit `newdata`, which set random effects to zero. The Julia page separately states that direct Julia predictions and `fitted()` use the zero-effect convention. It also explains that setting effects to zero is not integration over their distribution. The examples and comparison table make this distinction findable without internal API knowledge.
- **Methods and scope:** The R route table separates native TMB Laplace, ordinary Julia adaptive Gauss-Hermite quadrature (5 nodes for Bernoulli and 41 for Poisson), and Julia structured Laplace for this Gamma fixture. The Julia page limits its Laplace statement to the supplied-matrix scalar-intercept Gamma model. Neither page implies broad engine parity, family coverage, or interval calibration. G5 calibration and D-342 REML policy remain deferred.
- **Rendered figure:** I inspected `execution/r-article-render/figure-1.png`. Panel titles, axes, legend, group predictor, and the two scales are readable. Fitted and generating values have distinct encodings; the caption states the data grain and absence of uncertainty bands. No visual cue suggests raw response observations or uncertainty intervals.

## Completion boundary

The Julia rendered-page check records a successful local build and visual inspection, including the model equation, covariance, estimate, and limits. Its raw GitHub asset links are explicitly marked pending push; the immutable commit is not yet externally available at this checkpoint. I treated that as a deployment/link check still pending, not as evidence of missing or defective data. No broader package, recovery, or calibration conclusion follows from these article checks.

**Reader decision:** acceptable for the approved ML-first first delivery, subject to the owner's separate source-bound and post-push checks. No reader-facing blocker identified.
