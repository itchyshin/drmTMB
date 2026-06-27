# After-task: t-interval check — decomposing the small-g under-coverage

Meta: 2026-06-27 · Claude (ultracode) · maintainer hypothesis (use t-based, not
z-based, CIs at small group count). INDICATIVE post-hoc analysis, not t-based fits.

## Hypothesis (maintainer)

The slope under-coverage at the deployment g=8 may be because the Wald interval
uses the normal quantile z=1.96, but with only g groups the variance-component
estimate has ~g-1 effective df, so a t-quantile (Satterthwaite / Kenward-Roger)
gives a wider, better-calibrated interval. Worthwhile?

## Method (cheap, no new fits)

For each banked g=8 replicate, back out the Wald SE = (wald_upper - wald_lower) /
(2*1.96), then recompute coverage with t-quantiles at df=7 (=g-1) and df=6, and
compare to the z-based Wald and the profile interval.

## Result — YES, worthwhile; it decomposes the gap

| target class | Wald (z) | t (df=7) | profile |
|---|---|---|---|
| q2 mu-slopes (sd 0.9-1.05) | ~0.85 | ~0.88-0.91 | ~0.91 |
| q2 correlation (0.20) | ~0.78 | ~0.85 | ~0.90 |
| sigma intercepts (0.50) | ~0.87-0.93 | ~0.92-0.97 | ~0.95-0.96 |
| sigma slopes (0.38) | ~1.00 (conservative) | ~1.00 | ~0.97-0.99 |

(z reproduces the banked under-coverage exactly -- sanity check passes.)

**Two components of the under-coverage:**
1. **df-narrowness** (z vs t): t-quantile lifts coverage ~+3-5 pts. This is the
   part the maintainer identified -- a z-interval shipped where a t-interval
   belongs.
2. **SD shrinkage bias** (ML estimate biased low at small g): t cannot fix a
   biased centre. For sigma the bias is small, so t/profile reach ~nominal at g=8;
   for q2 the bias is larger (~ -0.08), so t closes ~half and a residual ~0.89-0.91
   remains -- needs REML/bias-correction or larger g.

## Implication

- **sigma**: t/profile at the deployment g=8 is ~nominal -> sigma is the stronger
  supported candidate AT g=8 (not only g=32).
- **q2**: t (df-corrected) + profile is a high near-miss (~0.91) at g=8; full
  nominal needs the bias fix (REML / larger g).
- **Scoped engine improvement**: adopt a t-quantile with a Satterthwaite/
  Kenward-Roger df as the default small-sample interval (closes df-narrowness for
  ALL lanes). This is the honest next interval-method step; it needs a real
  implementation + Fisher review (the df calibration is the tricky part, as the
  maintainer noted) -- this post-hoc is indicative, not a shipped interval.

## Boundary

Indicative post-hoc reanalysis of banked g=8 Wald intervals (SE backed out,
t-quantile applied); NOT t-based fits and NOT a coverage claim. Promotes nothing.
The proper version is a t/Satterthwaite interval in confint.drmTMB + a fresh
coverage grid + Fisher verification.
