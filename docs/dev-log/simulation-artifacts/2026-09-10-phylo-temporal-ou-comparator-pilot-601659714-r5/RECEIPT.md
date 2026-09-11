# Paired phylogenetic-OU comparator pilot receipt

At source `60165971414bf84d13b6b3ac232335a7ba0feddb`, this predeclared pilot
regenerated five frozen G11 draws in each of P1--P3 and fitted the same
additive phylogenetic-stable plus independent-OU Gaussian model in drmTMB and
glmmTMB 1.1.14. Every one of 30 fits had a positive-definite Hessian and every
one of 30 fixed-intercept profiles was available.

The 15 paired cover/not-cover outcomes were identical. Across all pairs, the
maximum absolute drmTMB--glmmTMB differences were `9.11370041e-06` for the
intercept estimate, `0.00179409504` for the lower endpoint, and
`0.00170011953` for the upper endpoint. The two engines also yielded the same
five-draw coverage fractions: 3/5, 4/5, and 5/5 in P1--P3. drmTMB mean
fit-plus-profile times were 6.444, 11.172, and 7.225 seconds; glmmTMB's were
1.169, 2.024, and 1.628 seconds.

This 15-dataset pre-run confirms comparator feasibility and close paired
agreement, not profile-interval calibration. glmmTMB documents both `ou` and
`propto` as experimental covariance structures, so it is a meaningful
implementation comparator, not a statistical ground truth.

SHA-256: `RESULTS.md` `0b8aaa25f741cda8de357b61c599d231d991d82aabede80eee59f720535fb70a`; `summary.csv` `09b42f47e6f351965bae4c8fb85bc2e9dc71c5b9d24fe9e75683726191cd57e0`; `replicates.csv` `f15f692e312cd554f5b92fca8ba5abcf50c83920167b8a0dff5404a4fa066151`.

Totoro retains the byte-matched output under
`/home/snakagaw/drmtmb-campaigns/phylo-ou-g12-384048d7-20260910/comparator-pilot-601659714-r5`.
