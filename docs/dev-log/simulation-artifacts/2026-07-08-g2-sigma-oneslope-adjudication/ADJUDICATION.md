# G2 adjudication — sigma one-slope cells (2026-07-08, LOCAL, N=600 uncensored)

Confirms Fisher's SOFT verdict (2026-07-08) on FRESH, independent evidence. Ran
`tools/run-structured-re-sigma-slope-coverage-grid.R` shards 1,2,5,6,7 at
`n_rep=600 n_each=20` (g=8), then `tools/gate-inference-ready-driver.R`
(uncensored denominators, min_miss=40). Full run on this Mac, ~25 min, no cluster.

## Result — binding gate (`docs/dev-log/dashboard/inference-gate-results.tsv`)

| cell | verdict | driving member |
| --- | --- | --- |
| qseries_phylo_q1_sigma_one_slope  | **FAIL** | sigma:(Intercept) cov 0.930/0.915, ratio 4.25/3.25, p 7e-5/2e-4 |
| qseries_animal_q1_sigma_one_slope | **FAIL** | sigma:(Intercept) profile cov 0.898, ratio 9.17, p 5e-11 |
| qseries_relmat_q1_sigma_one_slope | **FAIL** | sigma:(Intercept) cov 0.927/0.905, ratio 3.4, p 4e-4/5e-5 |
| qseries_phylo_q2_mu1_mu2_one_slope  | **FAIL** | mu2:x wald ratio 18.7 (p 1e-13); bc ratio 5.75 |
| qseries_relmat_q2_mu1_mu2_one_slope | **FAIL** | mu2:x wald ratio 19.0 (p 6e-14); bc ratio 7.67 |
| qseries_{phylo,spatial,relmat}_q1_mu_intercept | **INSUFFICIENT** | over-cover 0.97–0.99, n_miss < 40 on the censored evidence |

**5 of 8 FAIL; 3 unadjudicated; 0 PASS.** The sigma cells fail on their INTERCEPT
member and are underpowered (over-cover) on their SLOPE member. The q2 cells fail on
mu2:x even under the bias-corrected channel.

## What this does NOT settle

The 3 mu-intercept cells need their own N≈800–1600 campaign (their existing raw
replicates over-cover, so `n_miss < 40` — insufficient, not passing). Until then they
are `interval_feasible` at most, not `inference_ready`.

Board status NOT changed by this run (Shinichi: "investigate first"). The demotion
decision (G3) is his; this file is the evidence.
