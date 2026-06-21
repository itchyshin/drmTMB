# q4 REML-vs-ML among-axis SD recovery pilot (2026-06-21)

**Lane:** direct DRM.jl — the restricted-likelihood q4 estimator the drmTMB
`biv_q4_phylo_reml` bridge cell forwards. Native TMB cannot fit q4 phylo REML, so
there is no engine-vs-engine comparison; this is a recovery comparison of ML vs
REML against a KNOWN truth.

**Design:** balanced phylogeny (`random_balanced_tree(p = 16, branch_length = 0.3)`),
m = 5 obs/tip (n = 80), among-axis covariance Λ with genuine variance on both scale
axes; per replicate fit the q4 PLSM `bf(mu1, mu2, sigma1, sigma2, rho12)` by ML and
by REML (`q4_vcov = false`) and record the four among-axis SDs `sqrt(diag(Sigma_a))`.
Seeded `Random.seed!(20260621)`, R = 40 replicates. **This is a PILOT, not a full
(>= 200-rep) calibration.** Reproduce with `run.jl`.

True among-axis SDs = `sqrt(diag(Λ))` = **[0.5, 0.5, 0.4, 0.4]**.

## Result (40 reps)

| axis   | truth | ML mean | REML mean | ML MAE | REML MAE | REML closer |
|--------|-------|---------|-----------|--------|----------|-------------|
| mu1    | 0.50  | 0.432   | 0.446     | 0.133  | 0.131    | 57%         |
| mu2    | 0.50  | 0.409   | 0.426     | 0.131  | 0.124    | 60%         |
| sigma1 | 0.40  | 0.357   | 0.386     | 0.134  | 0.125    | 62%         |
| sigma2 | 0.40  | 0.330   | 0.358     | 0.134  | 0.125    | 62%         |

Overall: **ML MAE 0.133 → REML MAE 0.127.**

Per-axis bias and Monte-Carlo significance (z = mean bias / MC SE of the mean, R = 40):

| axis   | ML bias | ML z | REML bias | REML z |
|--------|---------|------|-----------|--------|
| mu1    | -0.068  | -2.8 | -0.054    | -2.2   |
| mu2    | -0.091  | -3.9 | -0.074    | -3.2   |
| sigma1 | -0.043  | -1.6 | -0.014    | -0.5   |
| sigma2 | -0.070  | -3.0 | -0.042    | -1.8   |

## Reading

ML is downward-biased on every axis (the classic ML variance-component bias); REML
corrects upward toward the truth on every axis — lower MAE on all four, and a
closer estimate in 57–62% of individual draws. This is the genuine REML benefit
(less bias / closer recovery), and it is the same estimator the bridge forwards.

## Honest scope

- 40 reps = a pilot. ML's downward bias is significant (|z| > 2) on three of the four
  axes (mu1, mu2, sigma2: z −2.8, −3.9, −3.0) and weaker on the least-identified axis
  sigma1 (z −1.6). REML reduces the bias on every axis, and on the scale axes the
  REML residual bias is no longer significant (sigma1 z −0.5, sigma2 z −1.8). A full
  (>= 200-rep) calibration would tighten these.
- The per-draw "REML closer" win-rate (57–62%) is DESCRIPTIVE only — not individually
  significant at R = 40 (two-sided sign-test p 0.15–0.43). The load-bearing signal is
  the mean-bias reduction (the table above), not the win-rate.
- At p = 16 even REML still lands slightly under truth: small-sample bias is
  *reduced*, not erased.
- The per-*draw* spread is much wider than the SE-of-the-mean — single q4 fits are
  noisy, and on a poorly-conditioned tree a scale axis can be weakly identified, in
  which case ML can *overshoot* and REML corrects downward (still toward truth). So
  the brittle "REML >= ML" inequality is NOT the right gate; "closer to truth" is.
- No interval-coverage or power claim. Direct-DRM.jl lane only.
