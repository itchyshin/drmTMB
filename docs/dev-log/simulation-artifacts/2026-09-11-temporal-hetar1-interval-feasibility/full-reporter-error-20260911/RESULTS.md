# Superseded heterogeneous-AR1 full interval-feasibility output

This first 20-fixture run retained all 20 selected fits, 40 signed-start attempts and 60 finite fixed-mean Wald intervals. It is superseded only because the runner wrote `NA` to its optional `std_error` column: it matched the public covariance names as `mu_<term>` instead of `mu:<term>`. The estimates and interval endpoints remain retained in this directory. The repaired runner repeats the identical frozen 20-fixture configuration in `full/`, with no changes to source likelihood, fixture seeds, conditions or selection rule.
