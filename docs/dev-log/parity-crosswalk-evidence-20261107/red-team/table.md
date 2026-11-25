| id | dataset | route | family | R | Julia | logLik R | logLik Julia | J-R gap | flags | Julia message / R message |
|---|---|---|---|---|---|---|---|---|---|---|
| c001 | d00_baseline | ord | gaussian | fit | fit | -176.98 | -176.98 | 2.89901e-12 |  |  |
| c002 | d00_baseline | ord | poisson | fit | fit | -266.13 | -266.058 | 0.0718317 | LL-BASELINE-GAP |  |
| c003 | d00_baseline | ord | nb2 | fit | fit | -286.723 | -286.68 | 0.0433533 | LL-BASELINE-GAP |  |
| c004 | d00_baseline | ord | gamma | fit | fit | -198.152 | -198.114 | 0.037494 | LL-BASELINE-GAP |  |
| c005 | d00_baseline | ord | binomial | fit | fit-nonconv | -119.885 | -119.817 | 0.0678459 | LL-BASELINE-GAP |  |
| c006 | d00_baseline | ordq2 | gaussian | fit | fit | -195.632 | -195.632 | 1.90425e-12 |  |  |
| c007 | d00_baseline | ordq2 | poisson | fit | fit | -331.817 | -331.817 | 3.95801e-10 |  |  |
| c008 | d00_baseline | ordq2 | nb2 | fit | fit | -316.003 | -316.003 | -6.25278e-13 |  |  |
| c009 | d00_baseline | ordq2 | gamma | refuse | refuse |  |  |  |  | J: ArgumentError: Gamma random-effect SD regression requires exactly one SD target. / R: Only independent {.fn Gamma} `mu` random intercepts and slopes are implemented in this slice. ✖ Unsupported ra |
| c010 | d00_baseline | ordq2 | binomial | fit | fit | -122.925 | -122.726 | 0.198834 | LL-BASELINE-GAP |  |
| c011 | d00_baseline | animal | gaussian | fit | fit | -169.962 | -169.962 | 1.53477e-12 |  |  |
| c012 | d00_baseline | animal | poisson | fit | fit | -253.866 | -253.866 | -8.60609e-11 |  |  |
| c013 | d00_baseline | animal | nb2 | fit | fit | -293.929 | -293.929 | 1.33582e-11 |  |  |
| c014 | d00_baseline | animal | gamma | fit | fit | -166.249 | -166.249 | 6.53699e-13 |  |  |
| c015 | d00_baseline | animal | binomial | fit | fit | -129.059 | -129.059 | -3.40492e-11 |  |  |
| c016 | d00_baseline | phylo | gaussian | fit | fit | -142.781 | -142.781 | -1.70843e-10 |  |  |
| c017 | d00_baseline | phylo | poisson | fit | fit | -276.829 | -276.829 | 1.1562e-10 |  |  |
| c018 | d00_baseline | phylo | nb2 | fit | refuse | -321.845 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: NegBinomial2 `sd(group) ~ …` supports ordinary effects, an animal intercept with `A` or `Ainv`, a relmat intercept with `K`, or a coordinate `spatial(0 + x / g)` slope with `coords`; other structured covariance routes are not |
| c019 | d00_baseline | phylo | gamma | fit | fit | -248.975 | -248.975 | -1.41341e-10 |  |  |
| c020 | d00_baseline | phylo | binomial | fit | fit | -126.734 | -126.734 | 9.96323e-11 |  |  |
| c021 | d00_baseline | spatial | gaussian | fit | fit | -169.177 | -169.177 | -9.09495e-13 |  |  |
| c022 | d00_baseline | spatial | poisson | fit | refuse | -309.359 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: Poisson SD regression currently targets one ordinary mean random-effect coefficient. |
| c023 | d00_baseline | spatial | nb2 | fit | refuse | -318.008 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: NegBinomial2 spatial SD regression supports only the slope-only `spatial(0 + x / g)` term with `coords = …`. |
| c024 | d00_baseline | spatial | gamma | fit | fit | -203.222 | -203.287 | -0.0647588 | LL-BASELINE-GAP |  |
| c025 | d00_baseline | spatial | binomial | fit | fit | -131.521 | -131.567 | -0.0456771 | LL-BASELINE-GAP; J-NONFINITE-SE |  |
| c026 | d01a_one_singleton_group | ord | gaussian | fit | fit | -172.08 | -172.08 | -2.84217e-14 |  |  |
| c027 | d01a_one_singleton_group | ord | poisson | fit | fit | -258.565 | -258.493 | 0.0726046 | LL-BASELINE-METHOD-GAP |  |
| c028 | d01a_one_singleton_group | ord | nb2 | fit | fit | -277.941 | -277.898 | 0.0431537 | LL-BASELINE-METHOD-GAP |  |
| c029 | d01a_one_singleton_group | ord | gamma | fit | fit | -189.044 | -189.008 | 0.0360925 | LL-BASELINE-METHOD-GAP |  |
| c030 | d01a_one_singleton_group | ord | binomial | fit | fit | -114.812 | -114.741 | 0.0703776 | LL-BASELINE-METHOD-GAP |  |
| c031 | d01a_one_singleton_group | ordq2 | gaussian | fit | fit | -189.792 | -189.792 | 1.73372e-12 |  |  |
| c032 | d01a_one_singleton_group | ordq2 | poisson | fit | fit | -316.05 | -316.05 | 7.44649e-11 |  |  |
| c033 | d01a_one_singleton_group | ordq2 | nb2 | fit | fit | -309.505 | -309.505 | 1.01409e-10 |  |  |
| c034 | d01a_one_singleton_group | ordq2 | gamma | refuse | refuse |  |  |  |  | J: ArgumentError: Gamma random-effect SD regression requires exactly one SD target. / R: Only independent {.fn Gamma} `mu` random intercepts and slopes are implemented in this slice. ✖ Unsupported ra |
| c035 | d01a_one_singleton_group | ordq2 | binomial | fit | fit | -118.013 | -117.932 | 0.0802028 | LL-DISAGREE(J higher) |  |
| c036 | d01a_one_singleton_group | animal | gaussian | fit | fit | -165.583 | -165.583 | 1.9611e-12 |  |  |
| c037 | d01a_one_singleton_group | animal | poisson | fit | fit | -243.636 | -243.636 | 1.98952e-11 |  |  |
| c038 | d01a_one_singleton_group | phylo | gaussian | fit | fit | -138.515 | -138.515 | -1.7522e-10 |  |  |
| c039 | d01a_one_singleton_group | phylo | poisson | fit | fit | -267.596 | -267.596 | -1.4366e-09 |  |  |
| c040 | d01a_one_singleton_group | spatial | gaussian | fit | fit | -165.615 | -165.615 | 1.56319e-12 |  |  |
| c041 | d01a_one_singleton_group | spatial | poisson | fit | refuse | -299.797 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: Poisson SD regression currently targets one ordinary mean random-effect coefficient. |
| c042 | d01b_all_singletons | ord | gaussian | refuse | fit |  | -25.3202 |  | J-FITS-WHERE-R-REFUSES | Random-effect grouping variable g has only singleton groups. ✖ At least one group must have repeated observations in this initial   random-effect implementation. |
| c043 | d01b_all_singletons | ord | poisson | refuse | fit-nonconv |  | -39.7189 |  | J-FITS-WHERE-R-REFUSES | Random-effect grouping variable g has only singleton groups. ✖ At least one group must have repeated observations in this initial   random-effect implementation. |
| c044 | d01b_all_singletons | ord | nb2 | refuse | fit |  | -35.5075 |  | J-FITS-WHERE-R-REFUSES | Random-effect grouping variable g has only singleton groups. ✖ At least one group must have repeated observations in this initial   random-effect implementation. |
| c045 | d01b_all_singletons | ord | gamma | refuse | fit |  | -40.0237 |  | J-FITS-WHERE-R-REFUSES | Random-effect grouping variable g has only singleton groups. ✖ At least one group must have repeated observations in this initial   random-effect implementation. |
| c046 | d01b_all_singletons | ord | binomial | refuse | fit |  | -12.7885 |  | J-FITS-WHERE-R-REFUSES | Random-effect grouping variable g has only singleton groups. ✖ At least one group must have repeated observations in this initial   random-effect implementation. |
| c047 | d01b_all_singletons | ordq2 | gaussian | refuse | fit |  | -25.855 |  | J-FITS-WHERE-R-REFUSES | Random-effect grouping variable g has only singleton groups. ✖ At least one group must have repeated observations in this initial   random-effect implementation. |
| c048 | d01b_all_singletons | ordq2 | poisson | refuse | fit |  | -46.974 |  | J-FITS-WHERE-R-REFUSES | Random-effect grouping variable g has only singleton groups. ✖ At least one group must have repeated observations in this initial   random-effect implementation. |
| c049 | d01b_all_singletons | ordq2 | nb2 | refuse | fit-nonconv |  | -38.6746 |  | J-FITS-WHERE-R-REFUSES | Random-effect grouping variable g has only singleton groups. ✖ At least one group must have repeated observations in this initial   random-effect implementation. |
| c050 | d01b_all_singletons | ordq2 | gamma | refuse | refuse |  |  |  |  | J: ArgumentError: Gamma random-effect SD regression requires exactly one SD target. / R: Only independent {.fn Gamma} `mu` random intercepts and slopes are implemented in this slice. ✖ Unsupported ra |
| c051 | d01b_all_singletons | ordq2 | binomial | refuse | error |  |  |  | J-NON-ARGUMENTERROR(R refuses clearly) | J: Binomial() correlated random slope `(1 + x / g)` needs within-group variation in the slope predictor — it is c / R: Random-effect grouping variable g has only singleton groups. ✖ At least one group must have repeated observati |
| c052 | d01b_all_singletons | animal | gaussian | fit | fit | -27.5434 | -27.5434 | 7.4607e-14 |  |  |
| c053 | d01b_all_singletons | animal | poisson | fit | fit | -33.9261 | -33.9261 | 3.55271e-14 |  |  |
| c054 | d01b_all_singletons | phylo | gaussian | fit | fit | -21.2108 | -21.2108 | -4.46963e-10 | R-NONFINITE-SE |  |
| c055 | d01b_all_singletons | phylo | poisson | fit | fit | -35.5029 | -35.5029 | 1.29698e-09 | J-NONFINITE-SE |  |
| c056 | d01b_all_singletons | spatial | gaussian | fit | fit | -27.2222 | -27.2221 | 6.19728e-07 |  |  |
| c057 | d01b_all_singletons | spatial | poisson | fit | refuse | -37.6294 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: Poisson SD regression currently targets one ordinary mean random-effect coefficient. |
| c058 | d02_identical_y_in_group | ord | gaussian | fit | fit | -175.356 | -175.356 | 1.22213e-12 |  |  |
| c059 | d02_identical_y_in_group | ord | poisson | fit | fit | -260.642 | -260.556 | 0.0860388 | LL-BASELINE-METHOD-GAP |  |
| c060 | d02_identical_y_in_group | ord | nb2 | fit | fit | -285.467 | -285.411 | 0.0557729 | LL-BASELINE-METHOD-GAP |  |
| c061 | d02_identical_y_in_group | ord | gamma | fit | fit | -203.96 | -203.923 | 0.0371359 | LL-BASELINE-METHOD-GAP |  |
| c062 | d02_identical_y_in_group | ord | binomial | fit | fit | -115.272 | -115.171 | 0.100528 | LL-BASELINE-METHOD-GAP |  |
| c063 | d02_identical_y_in_group | ordq2 | gaussian | fit | fit | -193.486 | -193.486 | -2.55795e-13 |  |  |
| c064 | d02_identical_y_in_group | ordq2 | poisson | fit | fit | -320.688 | -320.688 | 6.70752e-12 |  |  |
| c065 | d02_identical_y_in_group | ordq2 | nb2 | fit | fit | -309.428 | -309.428 | 1.06297e-11 |  |  |
| c066 | d02_identical_y_in_group | ordq2 | gamma | refuse | refuse |  |  |  |  | J: ArgumentError: Gamma random-effect SD regression requires exactly one SD target. / R: Only independent {.fn Gamma} `mu` random intercepts and slopes are implemented in this slice. ✖ Unsupported ra |
| c067 | d02_identical_y_in_group | ordq2 | binomial | fit | fit | -119.442 | -119.225 | 0.216795 | LL-BASELINE-METHOD-GAP |  |
| c068 | d02_identical_y_in_group | animal | gaussian | fit | fit | -167.867 | -167.867 | 1.44951e-12 |  |  |
| c069 | d02_identical_y_in_group | animal | poisson | fit | fit | -252.491 | -252.491 | -1.31337e-10 |  |  |
| c070 | d02_identical_y_in_group | phylo | gaussian | fit | fit | -140.559 | -140.559 | -1.72804e-10 |  |  |
| c071 | d02_identical_y_in_group | phylo | poisson | fit | fit | -278.615 | -278.615 | 4.94538e-12 |  |  |
| c072 | d02_identical_y_in_group | spatial | gaussian | fit | fit | -168.826 | -168.826 | 9.37916e-13 |  |  |
| c073 | d02_identical_y_in_group | spatial | poisson | fit | refuse | -311.094 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: Poisson SD regression currently targets one ordinary mean random-effect coefficient. |
| c074 | d03_single_level_group | ord | gaussian | refuse | refuse |  |  |  |  | J: ArgumentError: drm: `sd(g) ~ …` models the SD of the random effects over the levels of `g`, but `g` has only o / R: Random-effect grouping variable g has fewer than two levels. ✖ At least two groups are needed to estimate a ra |
| c075 | d03_single_level_group | ord | poisson | refuse | refuse |  |  |  |  | J: ArgumentError: drm: `sd(g) ~ …` models the SD of the random effects over the levels of `g`, but `g` has only o / R: Random-effect grouping variable g has fewer than two levels. ✖ At least two groups are needed to estimate a ra |
| c076 | d03_single_level_group | ord | nb2 | refuse | refuse |  |  |  |  | J: ArgumentError: drm: `sd(g) ~ …` models the SD of the random effects over the levels of `g`, but `g` has only o / R: Random-effect grouping variable g has fewer than two levels. ✖ At least two groups are needed to estimate a ra |
| c077 | d03_single_level_group | ord | gamma | refuse | refuse |  |  |  |  | J: ArgumentError: drm: `sd(g) ~ …` models the SD of the random effects over the levels of `g`, but `g` has only o / R: Random-effect grouping variable g has fewer than two levels. ✖ At least two groups are needed to estimate a ra |
| c078 | d03_single_level_group | ord | binomial | refuse | refuse |  |  |  |  | J: ArgumentError: drm: `sd(g) ~ …` models the SD of the random effects over the levels of `g`, but `g` has only o / R: Random-effect grouping variable g has fewer than two levels. ✖ At least two groups are needed to estimate a ra |
| c079 | d03_single_level_group | ordq2 | gaussian | refuse | refuse |  |  |  |  | J: ArgumentError: drm: `sd(g) ~ …` models the SD of the random effects over the levels of `g`, but `g` has only o / R: Random-effect grouping variable g has fewer than two levels. ✖ At least two groups are needed to estimate a ra |
| c080 | d03_single_level_group | ordq2 | poisson | refuse | refuse |  |  |  |  | J: ArgumentError: drm: `sd(g) ~ …` models the SD of the random effects over the levels of `g`, but `g` has only o / R: Random-effect grouping variable g has fewer than two levels. ✖ At least two groups are needed to estimate a ra |
| c081 | d03_single_level_group | ordq2 | nb2 | refuse | refuse |  |  |  |  | J: ArgumentError: drm: `sd(g) ~ …` models the SD of the random effects over the levels of `g`, but `g` has only o / R: Random-effect grouping variable g has fewer than two levels. ✖ At least two groups are needed to estimate a ra |
| c082 | d03_single_level_group | ordq2 | gamma | refuse | refuse |  |  |  |  | J: ArgumentError: drm: `sd(g) ~ …` models the SD of the random effects over the levels of `g`, but `g` has only o / R: Only independent {.fn Gamma} `mu` random intercepts and slopes are implemented in this slice. ✖ Unsupported ra |
| c083 | d03_single_level_group | ordq2 | binomial | refuse | refuse |  |  |  |  | J: ArgumentError: drm: `sd(g) ~ …` models the SD of the random effects over the levels of `g`, but `g` has only o / R: Random-effect grouping variable g has fewer than two levels. ✖ At least two groups are needed to estimate a ra |
| c084 | d03_single_level_group | animal | gaussian | refuse | refuse |  |  |  |  | J: ArgumentError: drm: `sd(g) ~ …` models the SD of the random effects over the levels of `g`, but `g` has only o / R: `animal()` grouping variable g has fewer than two observed levels. ✖ At least two levels are needed to estimat |
| c085 | d03_single_level_group | animal | poisson | refuse | refuse |  |  |  |  | J: ArgumentError: drm: `sd(g) ~ …` models the SD of the random effects over the levels of `g`, but `g` has only o / R: `animal()` grouping variable g has fewer than two observed levels. ✖ At least two levels are needed to estimat |
| c086 | d03_single_level_group | phylo | gaussian | refuse | refuse |  |  |  |  | J: ArgumentError: drm: phylo LSS full input for `g` must contain all tree tips; absent: g02, g03, g04, g05, g06,  / R: Phylogenetic grouping variable g has fewer than two observed species. ✖ At least two species are needed to est |
| c087 | d03_single_level_group | phylo | poisson | refuse | refuse |  |  |  |  | J: ArgumentError: drm: phylo LSS full input for `g` must contain all tree tips; absent: g02, g03, g04, g05, g06,  / R: Phylogenetic grouping variable g has fewer than two observed species. ✖ At least two species are needed to est |
| c088 | d03_single_level_group | spatial | gaussian | refuse | refuse |  |  |  |  | J: ArgumentError: drm: `sd(g) ~ …` models the SD of the random effects over the levels of `g`, but `g` has only o / R: Spatial grouping variable g has fewer than two observed sites. ✖ At least two sites are needed to estimate a s |
| c089 | d03_single_level_group | spatial | poisson | refuse | refuse |  |  |  |  | J: ArgumentError: drm: `sd(g) ~ …` models the SD of the random effects over the levels of `g`, but `g` has only o / R: Spatial grouping variable g has fewer than two observed sites. ✖ At least two sites are needed to estimate a s |
| c090 | d04_separated_bernoulli | ord | binomial | fit | fit | -2.44631e-07 | 0 | 2.44631e-07 | J-NONFINITE-SE |  |
| c091 | d04_separated_bernoulli | ordq2 | binomial | fit | fit-nonconv | -7.59989e-08 | 0.00396383 | 0.0039639 | LL-DISAGREE(J higher) [a fit is non-converged]; J-NONFINITE-SE; R-NONFINITE-SE |  |
| c092 | d04_separated_bernoulli | animal | binomial | fit | fit | -4.09278e-07 | -1.57396e-07 | 2.51881e-07 | J-NONFINITE-SE |  |
| c093 | d04_separated_bernoulli | phylo | binomial | fit | fit | -1.78193e-07 | -7.24106e-09 | 1.70952e-07 | J-NONFINITE-SE |  |
| c094 | d04_separated_bernoulli | spatial | binomial | fit | fit | -4.73067e-07 | -2.79356e-08 | 4.45132e-07 | J-NONFINITE-SE |  |
| c095 | d05_zero_counts_in_group | ord | poisson | fit | fit | -245.216 | -245.131 | 0.0852663 | LL-BASELINE-METHOD-GAP |  |
| c096 | d05_zero_counts_in_group | ord | nb2 | fit | fit | -279.669 | -279.604 | 0.0641856 | LL-BASELINE-METHOD-GAP |  |
| c097 | d05_zero_counts_in_group | ord | binomial | fit | fit | -119.257 | -119.095 | 0.16172 | LL-DISAGREE(J higher) |  |
| c098 | d05_zero_counts_in_group | ordq2 | poisson | fit | fit | -311.224 | -311.224 | -3.45608e-10 |  |  |
| c099 | d05_zero_counts_in_group | ordq2 | nb2 | fit | fit | -308.678 | -308.678 | 1.68257e-11 |  |  |
| c100 | d05_zero_counts_in_group | ordq2 | binomial | fit | fit | -121.656 | -121.417 | 0.238996 | LL-BASELINE-METHOD-GAP |  |
| c101 | d05_zero_counts_in_group | animal | poisson | fit | fit | -247.049 | -247.049 | -2.90839e-10 |  |  |
| c102 | d05_zero_counts_in_group | animal | nb2 | fit | fit | -284.204 | -284.204 | 7.10543e-12 |  |  |
| c103 | d05_zero_counts_in_group | animal | binomial | fit | fit | -126.449 | -126.449 | -2.1595e-09 |  |  |
| c104 | d05_zero_counts_in_group | phylo | poisson | fit | fit | -273.149 | -273.149 | 1.97815e-11 |  |  |
| c105 | d05_zero_counts_in_group | phylo | nb2 | fit | refuse | -314.832 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: NegBinomial2 `sd(group) ~ …` supports ordinary effects, an animal intercept with `A` or `Ainv`, a relmat intercept with `K`, or a coordinate `spatial(0 + x / g)` slope with `coords`; other structured covariance routes are not |
| c106 | d05_zero_counts_in_group | phylo | binomial | fit | fit | -129.057 | -129.057 | 1.3074e-12 |  |  |
| c107 | d05_zero_counts_in_group | spatial | poisson | fit | refuse | -304.797 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: Poisson SD regression currently targets one ordinary mean random-effect coefficient. |
| c108 | d05_zero_counts_in_group | spatial | nb2 | fit | refuse | -311.952 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: NegBinomial2 spatial SD regression supports only the slope-only `spatial(0 + x / g)` term with `coords = …`. |
| c109 | d05_zero_counts_in_group | spatial | binomial | fit | fit | -130.241 | -130.259 | -0.0179175 | LL-BASELINE-METHOD-GAP |  |
| c110 | d06a_duplicate_coords | spatial | gaussian | fit | fit | -171.007 | -171.007 | 1.74509e-11 |  |  |
| c111 | d06a_duplicate_coords | spatial | poisson | fit | refuse | -309.057 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: Poisson SD regression currently targets one ordinary mean random-effect coefficient. |
| c112 | d06a_duplicate_coords | spatial | nb2 | fit | refuse | -317.28 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: NegBinomial2 spatial SD regression supports only the slope-only `spatial(0 + x / g)` term with `coords = …`. |
| c113 | d06a_duplicate_coords | spatial | gamma | fit | fit-nonconv | -203.085 | -203.228 | -0.143082 | LL-DISAGREE(R higher) [a fit is non-converged] |  |
| c114 | d06a_duplicate_coords | spatial | binomial | fit | fit-nonconv | -131.511 | -1e+18 | -1e+18 | J-SENTINEL-LL(-1e18); LL-DISAGREE(R higher) [a fit is non-converged]; J-NONFINITE-SE |  |
| c115 | d06b_all_coords_identical | spatial | gaussian | refuse | refuse |  |  |  |  | J: ArgumentError: Spatial coordinates for `g` contain no positive distances; at least two sites must have distinc / R: Spatial coordinates for g contain no positive distances. ✖ At least two sites must have distinct coordinates. |
| c116 | d06b_all_coords_identical | spatial | poisson | refuse | refuse |  |  |  |  | J: ArgumentError: Poisson SD regression currently targets one ordinary mean random-effect coefficient. / R: Spatial coordinates for g contain no positive distances. ✖ At least two sites must have distinct coordinates. |
| c117 | d07a_tree_zero_internal_branches | phylo | gaussian | refuse | refuse |  |  |  |  | J: ArgumentError: branch length for edge 27 -> 25 must be finite and > 0 (got 0.0) / R: `tree` branch lengths must be positive to build sparse precision. |
| c118 | d07a_tree_zero_internal_branches | phylo | poisson | refuse | refuse |  |  |  |  | J: ArgumentError: branch length for edge 27 -> 25 must be finite and > 0 (got 0.0) / R: `tree` branch lengths must be positive to build sparse precision. |
| c119 | d07a_tree_zero_internal_branches | phylo | nb2 | refuse | refuse |  |  |  |  | J: ArgumentError: NegBinomial2 `sd(group) ~ …` supports ordinary effects, an animal intercept with `A` or `Ainv`, / R: `tree` branch lengths must be positive to build sparse precision. |
| c120 | d07a_tree_zero_internal_branches | phylo | gamma | refuse | refuse |  |  |  |  | J: ArgumentError: branch length for edge 27 -> 25 must be finite and > 0 (got 0.0) / R: `tree` branch lengths must be positive to build sparse precision. |
| c121 | d07a_tree_zero_internal_branches | phylo | binomial | refuse | refuse |  |  |  |  | J: ArgumentError: branch length for edge 27 -> 25 must be finite and > 0 (got 0.0) / R: `tree` branch lengths must be positive to build sparse precision. |
| c122 | d07b_tree_zero_terminal_branches | phylo | gaussian | refuse | refuse |  |  |  |  | J: ArgumentError: branch length for edge 25 -> 1 must be finite and > 0 (got 0.0) / R: `tree` branch lengths must be positive to build sparse precision. |
| c123 | d07b_tree_zero_terminal_branches | phylo | poisson | refuse | refuse |  |  |  |  | J: ArgumentError: branch length for edge 25 -> 1 must be finite and > 0 (got 0.0) / R: `tree` branch lengths must be positive to build sparse precision. |
| c124 | d07b_tree_zero_terminal_branches | phylo | nb2 | refuse | refuse |  |  |  |  | J: ArgumentError: NegBinomial2 `sd(group) ~ …` supports ordinary effects, an animal intercept with `A` or `Ainv`, / R: `tree` branch lengths must be positive to build sparse precision. |
| c125 | d07b_tree_zero_terminal_branches | phylo | gamma | refuse | refuse |  |  |  |  | J: ArgumentError: branch length for edge 25 -> 1 must be finite and > 0 (got 0.0) / R: `tree` branch lengths must be positive to build sparse precision. |
| c126 | d07b_tree_zero_terminal_branches | phylo | binomial | refuse | refuse |  |  |  |  | J: ArgumentError: branch length for edge 25 -> 1 must be finite and > 0 (got 0.0) / R: `tree` branch lengths must be positive to build sparse precision. |
| c127 | d08a_A_near_singular_1e-9 | animal | gaussian | fit | fit | -169.565 | -169.565 | -8.82201e-09 |  |  |
| c128 | d08a_A_near_singular_1e-9 | animal | poisson | fit | fit-nonconv | -253.72 | -261.663 | -7.94376 | LL-DISAGREE(R higher) [a fit is non-converged]; J-NONFINITE-SE |  |
| c129 | d08a_A_near_singular_1e-9 | animal | nb2 | fit | fit-nonconv | -294.188 | -298.828 | -4.64041 | LL-DISAGREE(R higher) [a fit is non-converged]; J-NONFINITE-SE |  |
| c130 | d08a_A_near_singular_1e-9 | animal | gamma | fit | fit-nonconv | -167.141 | -167.141 | -7.43531e-08 |  |  |
| c131 | d08a_A_near_singular_1e-9 | animal | binomial | fit | fit-nonconv | -129.003 | -129.68 | -0.676832 | LL-DISAGREE(R higher) [a fit is non-converged]; J-NONFINITE-SE |  |
| c132 | d08b_A_exactly_singular | animal | gaussian | refuse | fit |  | -169.565 |  | J-FITS-WHERE-R-REFUSES | `drmTMB()` failed in all `stats::nlminb()` optimizer preset attempts. ℹ Attempted presets: "default", "careful", and "robust". ℹ Inspect model structure, starting values, and data scale before increasing   optimizer complexity. Caused by er |
| c133 | d08b_A_exactly_singular | animal | poisson | fit-nonconv | refuse | -253.397 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: sparse-Laplace Poisson animal SD regression: the covariance matrix for `g` is not positive definite (identical rows and columns, e.g. duplicated individuals, make it singular). Merge or remove the duplicated individuals, or s |
| c134 | d08b_A_exactly_singular | animal | nb2 | refuse | refuse |  |  |  |  | J: ArgumentError: animal covariance precision must be positive definite / R: `drmTMB()` failed in all `stats::nlminb()` optimizer preset attempts. ℹ Attempted presets: "default", "careful |
| c135 | d08b_A_exactly_singular | animal | gamma | refuse | refuse |  |  |  |  | J: ArgumentError: Gamma structured covariance matrix must be positive definite / R: `drmTMB()` failed in all `stats::nlminb()` optimizer preset attempts. ℹ Attempted presets: "default", "careful |
| c136 | d08b_A_exactly_singular | animal | binomial | refuse | fit-nonconv |  | -1e+18 |  | J-FITS-WHERE-R-REFUSES; J-SENTINEL-LL(-1e18) | `drmTMB()` failed in all `stats::nlminb()` optimizer preset attempts. ℹ Attempted presets: "default", "careful", and "robust". ℹ Inspect model structure, starting values, and data scale before increasing   optimizer complexity. Caused by er |
| c137 | d09_x_constant_within_group | ord | gaussian | fit | fit | -195.855 | -195.855 | 2.13163e-12 |  |  |
| c138 | d09_x_constant_within_group | ord | poisson | fit | fit | -295.604 | -295.517 | 0.0866096 | LL-BASELINE-METHOD-GAP |  |
| c139 | d09_x_constant_within_group | ord | nb2 | fit | fit | -291.322 | -291.282 | 0.0403494 | LL-BASELINE-METHOD-GAP |  |
| c140 | d09_x_constant_within_group | ord | gamma | fit | fit | -220.762 | -220.719 | 0.0427326 | LL-BASELINE-METHOD-GAP |  |
| c141 | d09_x_constant_within_group | ord | binomial | fit | fit | -125.268 | -125.212 | 0.0557487 | LL-BASELINE-METHOD-GAP |  |
| c142 | d09_x_constant_within_group | ordq2 | gaussian | fit | fit | -240.493 | -240.847 | -0.35406 | LL-DISAGREE(R higher); J-NONFINITE-SE |  |
| c143 | d09_x_constant_within_group | ordq2 | poisson | fit | fit | -399.513 | -399.513 | -1.02054e-06 | J-NONFINITE-SE |  |
| c144 | d09_x_constant_within_group | ordq2 | nb2 | refuse | fit |  | -324.85 |  | J-FITS-WHERE-R-REFUSES | Correlated q = 2 NB2 random effects need within-group variation in the slope predictor. ✖ x is constant within every level of g. ℹ The slope SD and group-level `rho_re` are unidentified in that design. ℹ Use a predictor that varies within g |
| c145 | d09_x_constant_within_group | ordq2 | gamma | refuse | refuse |  |  |  |  | J: ArgumentError: Gamma random-effect SD regression requires exactly one SD target. / R: Only independent {.fn Gamma} `mu` random intercepts and slopes are implemented in this slice. ✖ Unsupported ra |
| c146 | d09_x_constant_within_group | ordq2 | binomial | refuse | error |  |  |  | J-NON-ARGUMENTERROR(R refuses clearly) | J: Binomial() correlated random slope `(1 + x / g)` needs within-group variation in the slope predictor — it is c / R: Correlated q = 2 binomial random effects need within-group variation in the slope predictor. ✖ x is constant w |
| c147 | d09_x_constant_within_group | animal | gaussian | fit | fit | -192.272 | -192.272 | -2.359e-12 |  |  |
| c148 | d09_x_constant_within_group | animal | poisson | fit | fit | -260.512 | -260.512 | 7.33849e-11 |  |  |
| c149 | d09_x_constant_within_group | phylo | gaussian | fit | fit | -179.645 | -176.26 | 3.38504 | LL-DISAGREE(J higher) |  |
| c150 | d09_x_constant_within_group | phylo | poisson | fit | fit | -280.114 | -280.114 | 1.10845e-11 |  |  |
| c151 | d09_x_constant_within_group | spatial | gaussian | fit | fit | -193.284 | -193.284 | -2.30216e-12 |  |  |
| c152 | d09_x_constant_within_group | spatial | poisson | fit | refuse | -318.499 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: Poisson SD regression currently targets one ordinary mean random-effect coefficient. |
| c153 | d10_x_huge_1e6 | ord | gaussian | fit | fit | -176.98 | -176.98 | -2.81375e-12 |  |  |
| c154 | d10_x_huge_1e6 | ord | poisson | fit | fit | -266.13 | -266.058 | 0.0718317 | LL-BASELINE-METHOD-GAP; R-NONFINITE-SE |  |
| c155 | d10_x_huge_1e6 | ord | nb2 | fit | fit | -286.723 | -286.68 | 0.0433533 | LL-BASELINE-METHOD-GAP; R-NONFINITE-SE |  |
| c156 | d10_x_huge_1e6 | ord | gamma | fit | fit-nonconv | -198.152 | -198.114 | 0.037494 | LL-BASELINE-METHOD-GAP; R-NONFINITE-SE |  |
| c157 | d10_x_huge_1e6 | ord | binomial | fit | fit-nonconv | -119.885 | -119.817 | 0.0678459 | LL-BASELINE-METHOD-GAP; R-NONFINITE-SE |  |
| c158 | d10_x_huge_1e6 | ordq2 | gaussian | fit | fit-nonconv | -195.64 | 3.6185e+76 | 3.6185e+76 | J-ABSURD-POSITIVE-LL; LL-DISAGREE(J higher) [a fit is non-converged]; J-NONFINITE-SE |  |
| c159 | d10_x_huge_1e6 | ordq2 | poisson | fit-nonconv | fit | -581.342 | -331.833 | 249.51 | LL-DISAGREE(J higher) [a fit is non-converged]; J-NONFINITE-SE; R-NONFINITE-SE |  |
| c160 | d10_x_huge_1e6 | ordq2 | nb2 | fit | fit | -316.376 | -328.164 | -11.7881 | LL-DISAGREE(R higher); J-NONFINITE-SE; R-NONFINITE-SE |  |
| c161 | d10_x_huge_1e6 | ordq2 | gamma | refuse | refuse |  |  |  |  | J: ArgumentError: Gamma random-effect SD regression requires exactly one SD target. / R: Only independent {.fn Gamma} `mu` random intercepts and slopes are implemented in this slice. ✖ Unsupported ra |
| c162 | d10_x_huge_1e6 | ordq2 | binomial | fit | fit-nonconv | -122.828 | -123.04 | -0.212268 | LL-DISAGREE(R higher) [a fit is non-converged]; R-NONFINITE-SE |  |
| c163 | d10_x_huge_1e6 | animal | gaussian | fit | fit | -169.962 | -169.962 | -3.69482e-13 |  |  |
| c164 | d10_x_huge_1e6 | animal | poisson | fit | fit | -253.866 | -256.96 | -3.09402 | LL-DISAGREE(R higher); J-NONFINITE-SE; R-NONFINITE-SE |  |
| c165 | d10_x_huge_1e6 | phylo | gaussian | fit | fit | -142.781 | -142.781 | -1.709e-10 |  |  |
| c166 | d10_x_huge_1e6 | phylo | poisson | fit | fit | -276.829 | -276.972 | -0.143501 | LL-DISAGREE(R higher); J-NONFINITE-SE; R-NONFINITE-SE |  |
| c167 | d10_x_huge_1e6 | spatial | gaussian | fit | fit | -169.177 | -169.177 | 2.07478e-12 |  |  |
| c168 | d10_x_huge_1e6 | spatial | poisson | fit | refuse | -309.359 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: Poisson SD regression currently targets one ordinary mean random-effect coefficient. |
| c169 | d11_x_tiny_1e-6 | ord | gaussian | fit | fit | -177.016 | -176.98 | 0.0361788 | LL-DISAGREE(J higher) |  |
| c170 | d11_x_tiny_1e-6 | ord | poisson | fit | fit | -266.148 | -267.043 | -0.894743 | LL-DISAGREE(R higher) |  |
| c171 | d11_x_tiny_1e-6 | ord | nb2 | fit | fit | -286.723 | -286.68 | 0.0433984 | LL-BASELINE-METHOD-GAP |  |
| c172 | d11_x_tiny_1e-6 | ord | gamma | fit | fit | -198.187 | -198.114 | 0.0725054 | LL-BASELINE-METHOD-GAP |  |
| c173 | d11_x_tiny_1e-6 | ord | binomial | fit | fit-nonconv | -119.902 | -119.817 | 0.0845672 | LL-BASELINE-METHOD-GAP |  |
| c174 | d11_x_tiny_1e-6 | ordq2 | gaussian | fit | fit | -234.829 | -195.632 | 39.1975 | LL-DISAGREE(J higher); R-NONFINITE-SE |  |
| c175 | d11_x_tiny_1e-6 | ordq2 | poisson | fit | fit-nonconv | -373.341 | -353.511 | 19.8298 | LL-DISAGREE(J higher) [a fit is non-converged]; R-NONFINITE-SE |  |
| c176 | d11_x_tiny_1e-6 | ordq2 | nb2 | fit | fit | -319.23 | -319.23 | 8.0934e-06 | J-NONFINITE-SE; R-NONFINITE-SE |  |
| c177 | d11_x_tiny_1e-6 | ordq2 | gamma | refuse | refuse |  |  |  |  | J: ArgumentError: Gamma random-effect SD regression requires exactly one SD target. / R: Only independent {.fn Gamma} `mu` random intercepts and slopes are implemented in this slice. ✖ Unsupported ra |
| c178 | d11_x_tiny_1e-6 | ordq2 | binomial | fit | fit-nonconv | -126.751 | -127.792 | -1.04101 | LL-DISAGREE(R higher) [a fit is non-converged]; J-NONFINITE-SE; R-NONFINITE-SE |  |
| c179 | d11_x_tiny_1e-6 | animal | gaussian | fit | fit | -171.572 | -169.962 | 1.61028 | LL-DISAGREE(J higher) |  |
| c180 | d11_x_tiny_1e-6 | animal | poisson | fit | fit | -256.96 | -253.866 | 3.0939 | LL-DISAGREE(J higher) |  |
| c181 | d11_x_tiny_1e-6 | phylo | gaussian | fit | fit | -143.14 | -142.781 | 0.359064 | LL-DISAGREE(J higher) |  |
| c182 | d11_x_tiny_1e-6 | phylo | poisson | fit | fit | -276.972 | -276.829 | 0.14348 | LL-DISAGREE(J higher) |  |
| c183 | d11_x_tiny_1e-6 | spatial | gaussian | fit | fit | -169.241 | -169.177 | 0.0641523 | LL-DISAGREE(J higher) |  |
| c184 | d11_x_tiny_1e-6 | spatial | poisson | fit | refuse | -309.651 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: Poisson SD regression currently targets one ordinary mean random-effect coefficient. |
| c185 | d12_sdpred_huge_1e6 | ord | gaussian | fit | fit | -176.98 | -176.98 | 8.23718e-09 | R-NONFINITE-SE |  |
| c186 | d12_sdpred_huge_1e6 | ord | poisson | fit | fit | -266.13 | -266.058 | 0.0718317 | LL-BASELINE-METHOD-GAP; R-NONFINITE-SE |  |
| c187 | d12_sdpred_huge_1e6 | ord | nb2 | fit | fit | -286.723 | -286.68 | 0.0433533 | LL-BASELINE-METHOD-GAP; R-NONFINITE-SE |  |
| c188 | d12_sdpred_huge_1e6 | ord | gamma | fit | fit | -198.152 | -198.114 | 0.037494 | LL-BASELINE-METHOD-GAP; R-NONFINITE-SE |  |
| c189 | d12_sdpred_huge_1e6 | ord | binomial | fit | fit-nonconv | -119.885 | -119.817 | 0.0678459 | LL-BASELINE-METHOD-GAP; R-NONFINITE-SE |  |
| c190 | d12_sdpred_huge_1e6 | ordq2 | gaussian | fit | fit | -195.632 | -195.632 | 5.88085e-09 | R-NONFINITE-SE |  |
| c191 | d12_sdpred_huge_1e6 | ordq2 | poisson | fit | fit-nonconv | -331.817 | -352.884 | -21.0666 | LL-DISAGREE(R higher) [a fit is non-converged]; R-NONFINITE-SE |  |
| c192 | d12_sdpred_huge_1e6 | ordq2 | nb2 | fit | fit-nonconv | -316.003 | -327.58 | -11.577 | LL-DISAGREE(R higher) [a fit is non-converged]; J-NONFINITE-SE; R-NONFINITE-SE |  |
| c193 | d12_sdpred_huge_1e6 | ordq2 | gamma | refuse | refuse |  |  |  |  | J: ArgumentError: Gamma random-effect SD regression requires exactly one SD target. / R: Only independent {.fn Gamma} `mu` random intercepts and slopes are implemented in this slice. ✖ Unsupported ra |
| c194 | d12_sdpred_huge_1e6 | ordq2 | binomial | fit | fit-nonconv | -122.925 | -122.723 | 0.202002 | LL-BASELINE-METHOD-GAP; J-NONFINITE-SE; R-NONFINITE-SE |  |
| c195 | d12_sdpred_huge_1e6 | animal | gaussian | fit | fit | -169.962 | -169.962 | 5.30662e-09 | R-NONFINITE-SE |  |
| c196 | d12_sdpred_huge_1e6 | animal | poisson | fit | fit-nonconv | -253.866 | -261.744 | -7.87793 | LL-DISAGREE(R higher) [a fit is non-converged]; R-NONFINITE-SE |  |
| c197 | d12_sdpred_huge_1e6 | phylo | gaussian | fit | fit | -142.781 | -142.781 | 3.64082e-10 | R-NONFINITE-SE |  |
| c198 | d12_sdpred_huge_1e6 | phylo | poisson | fit | fit-nonconv | -276.829 | -278.261 | -1.43196 | LL-DISAGREE(R higher) [a fit is non-converged]; R-NONFINITE-SE |  |
| c199 | d12_sdpred_huge_1e6 | spatial | gaussian | fit | fit | -169.177 | -169.177 | 1.06791e-08 | R-NONFINITE-SE |  |
| c200 | d12_sdpred_huge_1e6 | spatial | poisson | fit | refuse | -309.359 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: Poisson SD regression currently targets one ordinary mean random-effect coefficient. |
| c201 | d13_sdpred_tiny_1e-6 | ord | gaussian | fit | fit | -181.108 | -176.98 | 4.12847 | LL-DISAGREE(J higher) |  |
| c202 | d13_sdpred_tiny_1e-6 | ord | poisson | fit | fit | -271.393 | -266.058 | 5.33515 | LL-DISAGREE(J higher) |  |
| c203 | d13_sdpred_tiny_1e-6 | ord | nb2 | fit | fit | -286.925 | -286.68 | 0.245187 | LL-DISAGREE(J higher) |  |
| c204 | d13_sdpred_tiny_1e-6 | ord | gamma | fit | fit | -205.768 | -198.114 | 7.65381 | LL-DISAGREE(J higher) |  |
| c205 | d13_sdpred_tiny_1e-6 | ord | binomial | fit | fit | -120.962 | -119.817 | 1.14502 | LL-DISAGREE(J higher); R-NONFINITE-SE |  |
| c206 | d13_sdpred_tiny_1e-6 | ordq2 | gaussian | fit | fit | -200.732 | -195.632 | 5.09981 | LL-DISAGREE(J higher) |  |
| c207 | d13_sdpred_tiny_1e-6 | ordq2 | poisson | fit | fit | -335.463 | -331.903 | 3.56021 | LL-DISAGREE(J higher) |  |
| c208 | d13_sdpred_tiny_1e-6 | ordq2 | nb2 | fit | fit | -318.952 | -316.709 | 2.24257 | LL-DISAGREE(J higher); J-NONFINITE-SE |  |
| c209 | d13_sdpred_tiny_1e-6 | ordq2 | gamma | refuse | refuse |  |  |  |  | J: ArgumentError: Gamma random-effect SD regression requires exactly one SD target. / R: Only independent {.fn Gamma} `mu` random intercepts and slopes are implemented in this slice. ✖ Unsupported ra |
| c210 | d13_sdpred_tiny_1e-6 | ordq2 | binomial | fit | fit | -127.49 | -122.748 | 4.74177 | LL-DISAGREE(J higher); J-NONFINITE-SE |  |
| c211 | d13_sdpred_tiny_1e-6 | animal | gaussian | fit | fit | -173.157 | -169.962 | 3.19545 | LL-DISAGREE(J higher) |  |
| c212 | d13_sdpred_tiny_1e-6 | animal | poisson | fit | fit | -255.66 | -253.866 | 1.794 | LL-DISAGREE(J higher) |  |
| c213 | d13_sdpred_tiny_1e-6 | phylo | gaussian | fit | fit | -185.633 | -149.431 | 36.2021 | LL-DISAGREE(J higher); R-NONFINITE-SE |  |
| c214 | d13_sdpred_tiny_1e-6 | phylo | poisson | fit | fit | -278.149 | -276.829 | 1.31981 | LL-DISAGREE(J higher); R-NONFINITE-SE |  |
| c215 | d13_sdpred_tiny_1e-6 | spatial | gaussian | fit | fit | -174.294 | -169.177 | 5.11687 | LL-DISAGREE(J higher); R-NONFINITE-SE |  |
| c216 | d13_sdpred_tiny_1e-6 | spatial | poisson | fit | refuse | -314.499 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: Poisson SD regression currently targets one ordinary mean random-effect coefficient. |
| c217 | d14_extreme_outliers | ord | gaussian | fit | fit | -653.322 | -653.322 | 4.13797e-09 |  |  |
| c218 | d14_extreme_outliers | ord | poisson | fit | fit | -21972.7 | -21972.5 | 0.2593 | LL-DISAGREE(J higher) |  |
| c219 | d14_extreme_outliers | ord | nb2 | fit | fit | -407.066 | -406.535 | 0.531337 | LL-DISAGREE(J higher) |  |
| c220 | d14_extreme_outliers | ord | gamma | fit | fit | -395.151 | -394.915 | 0.235788 | LL-DISAGREE(J higher) |  |
| c221 | d14_extreme_outliers | ordq2 | gaussian | fit | fit | -656.647 | -657.431 | -0.784162 | LL-DISAGREE(R higher); R-NONFINITE-SE |  |
| c222 | d14_extreme_outliers | ordq2 | poisson | fit | fit | -4303.82 | -4303.82 | -1.52249e-09 |  |  |
| c223 | d14_extreme_outliers | ordq2 | nb2 | fit | fit-nonconv | -422.521 | -422.521 | -1.66406e-06 |  |  |
| c224 | d14_extreme_outliers | ordq2 | gamma | refuse | refuse |  |  |  |  | J: ArgumentError: Gamma random-effect SD regression requires exactly one SD target. / R: Only independent {.fn Gamma} `mu` random intercepts and slopes are implemented in this slice. ✖ Unsupported ra |
| c225 | d14_extreme_outliers | animal | gaussian | fit | fit | -658.984 | -658.984 | 3.06954e-12 |  |  |
| c226 | d14_extreme_outliers | animal | poisson | fit | fit | -19879.2 | -19879.2 | -7.27596e-11 |  |  |
| c227 | d14_extreme_outliers | phylo | gaussian | fit | fit | -658.805 | -658.805 | 3.70289e-09 |  |  |
| c228 | d14_extreme_outliers | phylo | poisson | fit | fit | -15518.9 | -15506.2 | 12.6281 | LL-DISAGREE(J higher) |  |
| c229 | d14_extreme_outliers | spatial | gaussian | fit | fit | -661.041 | -661.041 | 2.88117e-09 | R-NONFINITE-SE |  |
| c230 | d14_extreme_outliers | spatial | poisson | fit | refuse | -17327 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: Poisson SD regression currently targets one ordinary mean random-effect coefficient. |
| c231 | d15a_missing_y_scattered | ord | gaussian | fit | fit | -174.281 | -174.281 | 9.66338e-13 |  |  |
| c232 | d15a_missing_y_scattered | ord | poisson | fit | refuse | -258.305 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: Poisson random-effect SD regression does not yet support missing responses; drop incomplete rows before fitting so the group SD design remains aligned. |
| c233 | d15a_missing_y_scattered | ord | nb2 | fit | refuse | -276.087 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: NegBinomial2 random-effect SD regression does not yet support missing responses; drop incomplete rows before fitting so the group SD design remains aligned. |
| c234 | d15a_missing_y_scattered | ord | gamma | fit | refuse | -193.461 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: Gamma random-effect SD regression requires observed responses; remove incomplete rows before fitting. |
| c235 | d15a_missing_y_scattered | ord | binomial | fit | refuse | -115.118 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: Binomial random-effect SD regression does not yet support missing responses; drop incomplete rows before fitting so the fitted group SD design and bootstrap rows remain aligned. |
| c236 | d15a_missing_y_scattered | ordq2 | gaussian | fit | refuse | -190.446 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: drm: Gaussian correlated-block SD regression requires observed responses; remove incomplete rows first. |
| c237 | d15a_missing_y_scattered | ordq2 | poisson | fit | refuse | -321.443 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: Poisson `(1 + x / g)` SD regression requires observed responses; remove incomplete rows before fitting. |
| c238 | d15a_missing_y_scattered | ordq2 | nb2 | fit | refuse | -303.022 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: NegBinomial2 two-field SD regression requires observed responses; remove incomplete rows before fitting. |
| c239 | d15a_missing_y_scattered | ordq2 | gamma | refuse | refuse |  |  |  |  | J: ArgumentError: Gamma random-effect SD regression requires exactly one SD target. / R: Only independent {.fn Gamma} `mu` random intercepts and slopes are implemented in this slice. ✖ Unsupported ra |
| c240 | d15a_missing_y_scattered | ordq2 | binomial | fit | refuse | -119.35 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: Binomial random-effect SD regression does not yet support missing responses; drop incomplete rows before fitting so the fitted group SD design and bootstrap rows remain aligned. |
| c241 | d15a_missing_y_scattered | animal | gaussian | fit | refuse | -165.001 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: drm: Gaussian structured intercept SD regression requires observed responses; remove incomplete rows first. |
| c242 | d15a_missing_y_scattered | animal | poisson | fit | refuse | -243.71 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: Poisson animal SD regression requires observed responses; remove incomplete rows before fitting. |
| c243 | d15a_missing_y_scattered | phylo | gaussian | fit | fit | -139.483 | -139.483 | -1.69422e-10 |  |  |
| c244 | d15a_missing_y_scattered | phylo | poisson | fit | refuse | -267.607 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: Poisson phylogenetic SD regression requires observed responses; remove incomplete rows before fitting. |
| c245 | d15a_missing_y_scattered | spatial | gaussian | fit | refuse | -164.262 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: drm: Gaussian structured intercept SD regression requires observed responses; remove incomplete rows first. |
| c246 | d15a_missing_y_scattered | spatial | poisson | fit | refuse | -301.211 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: Poisson SD regression currently targets one ordinary mean random-effect coefficient. |
| c247 | d15b_missing_y_whole_group | ord | gaussian | fit | fit | -170.089 | -170.089 | 1.53477e-12 |  |  |
| c248 | d15b_missing_y_whole_group | ord | poisson | fit | refuse | -256.567 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: Poisson random-effect SD regression does not yet support missing responses; drop incomplete rows before fitting so the group SD design remains aligned. |
| c249 | d15b_missing_y_whole_group | ord | nb2 | fit | refuse | -274.303 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: NegBinomial2 random-effect SD regression does not yet support missing responses; drop incomplete rows before fitting so the group SD design remains aligned. |
| c250 | d15b_missing_y_whole_group | ord | gamma | fit | refuse | -189.666 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: Gamma random-effect SD regression requires observed responses; remove incomplete rows before fitting. |
| c251 | d15b_missing_y_whole_group | ord | binomial | fit | refuse | -115.476 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: Binomial random-effect SD regression does not yet support missing responses; drop incomplete rows before fitting so the fitted group SD design and bootstrap rows remain aligned. |
| c252 | d15b_missing_y_whole_group | ordq2 | gaussian | fit | refuse | -187.182 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: drm: Gaussian correlated-block SD regression requires observed responses; remove incomplete rows first. |
| c253 | d15b_missing_y_whole_group | ordq2 | poisson | fit | refuse | -319.835 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: Poisson `(1 + x / g)` SD regression requires observed responses; remove incomplete rows before fitting. |
| c254 | d15b_missing_y_whole_group | ordq2 | nb2 | fit | refuse | -307.04 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: NegBinomial2 two-field SD regression requires observed responses; remove incomplete rows before fitting. |
| c255 | d15b_missing_y_whole_group | ordq2 | gamma | refuse | refuse |  |  |  |  | J: ArgumentError: Gamma random-effect SD regression requires exactly one SD target. / R: Only independent {.fn Gamma} `mu` random intercepts and slopes are implemented in this slice. ✖ Unsupported ra |
| c256 | d15b_missing_y_whole_group | ordq2 | binomial | fit | refuse | -117.281 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: Binomial random-effect SD regression does not yet support missing responses; drop incomplete rows before fitting so the fitted group SD design and bootstrap rows remain aligned. |
| c257 | d15b_missing_y_whole_group | animal | gaussian | fit | refuse | -162.684 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: drm: Gaussian structured intercept SD regression requires observed responses; remove incomplete rows first. |
| c258 | d15b_missing_y_whole_group | animal | poisson | fit | refuse | -243.451 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: Poisson animal SD regression requires observed responses; remove incomplete rows before fitting. |
| c259 | d15b_missing_y_whole_group | phylo | gaussian | fit | fit | -137.869 | -137.869 | -1.72037e-10 |  |  |
| c260 | d15b_missing_y_whole_group | phylo | poisson | fit | refuse | -267.624 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: Poisson phylogenetic SD regression requires observed responses; remove incomplete rows before fitting. |
| c261 | d15b_missing_y_whole_group | spatial | gaussian | refuse | refuse |  |  |  |  | J: ArgumentError: drm: Gaussian structured intercept SD regression requires observed responses; remove incomplete / R: `coords` must have one row per g level or one row per observation. ✖ g has 23 observed levels and 184 observat |
| c262 | d15b_missing_y_whole_group | spatial | poisson | refuse | refuse |  |  |  |  | J: ArgumentError: Poisson SD regression currently targets one ordinary mean random-effect coefficient. / R: `coords` must have one row per g level or one row per observation. ✖ g has 23 observed levels and 184 observat |
| c263 | d16a_missing_sdpred_whole_group | ord | gaussian | fit | fit | -169.543 | -169.543 | -1.25056e-12 |  |  |
| c264 | d16a_missing_sdpred_whole_group | ord | poisson | fit | refuse | -257.429 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: drm: predictor `z` contains a non-finite value (missing) at row 41. |
| c265 | d16a_missing_sdpred_whole_group | ord | nb2 | fit | refuse | -275.775 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: drm: predictor `z` contains a non-finite value (missing) at row 41. |
| c266 | d16a_missing_sdpred_whole_group | ord | gamma | fit | refuse | -197.362 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: drm: predictor `z` contains a non-finite value (missing) at row 41. |
| c267 | d16a_missing_sdpred_whole_group | ord | binomial | fit | refuse | -115.171 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: drm: predictor `z` contains a non-finite value (missing) at row 41. |
| c268 | d16a_missing_sdpred_whole_group | ordq2 | gaussian | fit | fit | -188.6 | -188.6 | 5.96856e-13 |  |  |
| c269 | d16a_missing_sdpred_whole_group | ordq2 | poisson | fit | refuse | -315.715 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: drm: predictor `z0` contains a non-finite value (missing) at row 41. |
| c270 | d16a_missing_sdpred_whole_group | ordq2 | nb2 | fit | refuse | -292.3 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: drm: predictor `z0` contains a non-finite value (missing) at row 41. |
| c271 | d16a_missing_sdpred_whole_group | ordq2 | gamma | refuse | refuse |  |  |  |  | J: ArgumentError: Gamma random-effect SD regression requires exactly one SD target. / R: Only independent {.fn Gamma} `mu` random intercepts and slopes are implemented in this slice. ✖ Unsupported ra |
| c272 | d16a_missing_sdpred_whole_group | ordq2 | binomial | fit | refuse | -117.011 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: drm: predictor `z0` contains a non-finite value (missing) at row 41. |
| c273 | d16a_missing_sdpred_whole_group | animal | gaussian | fit | refuse | -160.42 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: drm: dropping the 8 rows with a missing value would change the levels of `g`, or their order of first appearance, and `animal(1 / g)` matches its matrix to those levels by position. Drop the rows yourself (`drm_listwise`) and |
| c274 | d16a_missing_sdpred_whole_group | animal | poisson | fit | refuse | -245.501 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: drm: predictor `z` contains a non-finite value (missing) at row 41. |
| c275 | d16a_missing_sdpred_whole_group | phylo | gaussian | fit | refuse | -134.245 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: drm: phylo LSS full input for `g` must contain all tree tips; absent: g06. The tree has tips with no row in the data; prune the tree to the species in the data (for example `ape::keep.tip(tree, observed_species)` in R) before |
| c276 | d16a_missing_sdpred_whole_group | phylo | poisson | fit | refuse | -266.303 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: drm: predictor `z` contains a non-finite value (missing) at row 41. |
| c277 | d16a_missing_sdpred_whole_group | spatial | gaussian | refuse | refuse |  |  |  |  | J: ArgumentError: drm: dropping the 8 rows with a missing value would change the levels of `g`, or their order of / R: `coords` must have one row per g level or one row per observation. ✖ g has 23 observed levels and 184 observat |
| c278 | d16a_missing_sdpred_whole_group | spatial | poisson | refuse | refuse |  |  |  |  | J: ArgumentError: Poisson SD regression currently targets one ordinary mean random-effect coefficient. / R: `coords` must have one row per g level or one row per observation. ✖ g has 23 observed levels and 184 observat |
| c279 | d16b_missing_sdpred_one_row | ord | gaussian | fit | fit | -174.871 | -174.871 | 9.37916e-13 |  |  |
| c280 | d16b_missing_sdpred_one_row | ord | poisson | fit | refuse | -262.148 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: drm: predictor `z` contains a non-finite value (missing) at row 50. |
| c281 | d16b_missing_sdpred_one_row | ord | nb2 | fit | refuse | -284.375 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: drm: predictor `z` contains a non-finite value (missing) at row 50. |
| c282 | d16b_missing_sdpred_one_row | ord | gamma | fit | refuse | -195.721 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: drm: predictor `z` contains a non-finite value (missing) at row 50. |
| c283 | d16b_missing_sdpred_one_row | ord | binomial | fit | refuse | -119.601 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: drm: predictor `z` contains a non-finite value (missing) at row 50. |
| c284 | d16b_missing_sdpred_one_row | ordq2 | gaussian | fit | fit | -195.159 | -195.159 | -3.69482e-13 |  |  |
| c285 | d16b_missing_sdpred_one_row | ordq2 | poisson | fit | refuse | -330.55 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: drm: predictor `z0` contains a non-finite value (missing) at row 50. |
| c286 | d16b_missing_sdpred_one_row | ordq2 | nb2 | fit | refuse | -314.279 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: drm: predictor `z0` contains a non-finite value (missing) at row 50. |
| c287 | d16b_missing_sdpred_one_row | ordq2 | gamma | refuse | refuse |  |  |  |  | J: ArgumentError: Gamma random-effect SD regression requires exactly one SD target. / R: Only independent {.fn Gamma} `mu` random intercepts and slopes are implemented in this slice. ✖ Unsupported ra |
| c288 | d16b_missing_sdpred_one_row | ordq2 | binomial | fit | refuse | -122.918 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: drm: predictor `z0` contains a non-finite value (missing) at row 50. |
| c289 | d16b_missing_sdpred_one_row | animal | gaussian | fit | fit | -169.531 | -169.531 | -2.67164e-12 |  |  |
| c290 | d16b_missing_sdpred_one_row | animal | poisson | fit | refuse | -252.816 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: drm: predictor `z` contains a non-finite value (missing) at row 50. |
| c291 | d16b_missing_sdpred_one_row | phylo | gaussian | fit | fit | -142.379 | -142.379 | -1.72378e-10 |  |  |
| c292 | d16b_missing_sdpred_one_row | phylo | poisson | fit | refuse | -273.193 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: drm: predictor `z` contains a non-finite value (missing) at row 50. |
| c293 | d16b_missing_sdpred_one_row | spatial | gaussian | fit | fit | -168.793 | -168.793 | -1.10845e-12 |  |  |
| c294 | d16b_missing_sdpred_one_row | spatial | poisson | fit | refuse | -308.335 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: Poisson SD regression currently targets one ordinary mean random-effect coefficient. |
| c295 | d17_unused_level_extra_kernel_members | ord | gaussian | fit | fit | -176.98 | -176.98 | 2.89901e-12 |  |  |
| c296 | d17_unused_level_extra_kernel_members | ord | poisson | fit | fit | -266.13 | -266.058 | 0.0718317 | LL-BASELINE-METHOD-GAP |  |
| c297 | d17_unused_level_extra_kernel_members | ord | nb2 | fit | fit | -286.723 | -286.68 | 0.0433533 | LL-BASELINE-METHOD-GAP |  |
| c298 | d17_unused_level_extra_kernel_members | ord | gamma | fit | fit | -198.152 | -198.114 | 0.037494 | LL-BASELINE-METHOD-GAP |  |
| c299 | d17_unused_level_extra_kernel_members | ord | binomial | fit | fit-nonconv | -119.885 | -119.817 | 0.0678459 | LL-BASELINE-METHOD-GAP |  |
| c300 | d17_unused_level_extra_kernel_members | ordq2 | gaussian | fit | fit | -195.632 | -195.632 | 1.90425e-12 |  |  |
| c301 | d17_unused_level_extra_kernel_members | ordq2 | poisson | fit | fit | -331.817 | -331.817 | 3.95801e-10 |  |  |
| c302 | d17_unused_level_extra_kernel_members | ordq2 | nb2 | fit | fit | -316.003 | -316.003 | -6.25278e-13 |  |  |
| c303 | d17_unused_level_extra_kernel_members | ordq2 | gamma | refuse | refuse |  |  |  |  | J: ArgumentError: Gamma random-effect SD regression requires exactly one SD target. / R: Only independent {.fn Gamma} `mu` random intercepts and slopes are implemented in this slice. ✖ Unsupported ra |
| c304 | d17_unused_level_extra_kernel_members | ordq2 | binomial | fit | fit | -122.925 | -122.726 | 0.198834 | LL-BASELINE-METHOD-GAP |  |
| c305 | d17_unused_level_extra_kernel_members | animal | gaussian | fit | fit | -170.054 | -170.054 | -9.09495e-13 |  |  |
| c306 | d17_unused_level_extra_kernel_members | animal | poisson | fit | fit | -253.924 | -253.924 | -1.06297e-11 |  |  |
| c307 | d17_unused_level_extra_kernel_members | phylo | gaussian | fit | refuse | -142.274 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: drm: phylo LSS full input for `g` must contain all tree tips; absent: g25, g26. The tree has tips with no row in the data; prune the tree to the species in the data (for example `ape::keep.tip(tree, observed_species)` in R) b |
| c308 | d17_unused_level_extra_kernel_members | phylo | poisson | fit | refuse | -278.478 |  |  | J-REFUSES-WHERE-R-FITS | ArgumentError: drm: phylo LSS full input for `g` must contain all tree tips; absent: g25, g26. The tree has tips with no row in the data; prune the tree to the species in the data (for example `ape::keep.tip(tree, observed_species)` in R) b |
| c309 | d17_unused_level_extra_kernel_members | spatial | gaussian | refuse | fit |  | -169.177 |  | J-FITS-WHERE-R-REFUSES | `coords` must have one row per g level or one row per observation. ✖ g has 24 observed levels and 192 observations, but `coords` has 26 rows. |
| c310 | d17_unused_level_extra_kernel_members | spatial | poisson | refuse | refuse |  |  |  |  | J: ArgumentError: Poisson SD regression currently targets one ordinary mean random-effect coefficient. / R: `coords` must have one row per g level or one row per observation. ✖ g has 24 observed levels and 192 observat |
| c311 | d18_groups_missing_from_kernel | animal | gaussian | refuse | refuse |  |  |  |  | J: ArgumentError: drm: 2 level(s) of `g` have no row in `A` (e.g. "g23", "g24"). Every level must be one of the l / R: `animal()` matrix A does not cover every observed g level. ✖ Missing levels: "g23" and "g24". |
| c312 | d18_groups_missing_from_kernel | animal | poisson | refuse | refuse |  |  |  |  | J: ArgumentError: drm: 2 level(s) of `g` have no row in `A` (e.g. "g23", "g24"). Every level must be one of the l / R: `animal()` matrix A does not cover every observed g level. ✖ Missing levels: "g23" and "g24". |
| c313 | d18_groups_missing_from_kernel | phylo | gaussian | refuse | refuse |  |  |  |  | J: ArgumentError: drm: phylo LSS group label `g23` for `g` is not a tree tip name / R: All observed species must be represented in `tree`. ✖ Missing tip labels: "g23" and "g24". |
| c314 | d18_groups_missing_from_kernel | phylo | poisson | refuse | refuse |  |  |  |  | J: ArgumentError: drm: phylo LSS group label `g23` for `g` is not a tree tip name / R: All observed species must be represented in `tree`. ✖ Missing tip labels: "g23" and "g24". |
| c315 | d18_groups_missing_from_kernel | spatial | gaussian | refuse | refuse |  |  |  |  | J: ArgumentError: drm: 2 level(s) of `g` have no row in `coords` (e.g. "g23", "g24"). Every level must be one of  / R: `coords` must have one row per g level or one row per observation. ✖ g has 24 observed levels and 192 observat |
| c316 | d18_groups_missing_from_kernel | spatial | poisson | refuse | refuse |  |  |  |  | J: ArgumentError: drm: 2 level(s) of `g` have no row in `coords` (e.g. "g23", "g24"). Every level must be one of  / R: `coords` must have one row per g level or one row per observation. ✖ g has 24 observed levels and 192 observat |
| c317 | d19_A_rownames_unsorted | animal | gaussian | fit | fit | -169.962 | -169.962 | 1.53477e-12 |  |  |
| c318 | d19_A_rownames_unsorted | animal | poisson | fit | fit | -253.866 | -253.866 | -8.60609e-11 |  |  |
| c319 | d20_sdpred_varies_within_group | ord | gaussian | refuse | refuse |  |  |  |  | J: ArgumentError: sd(g): predictor `z` varies within a level of `g` — sd() predictors must be constant within eac / R: `sd(g)` formulas are group-level random-effect scale models. ✖ Predictor z varies within g level "g01". ℹ Use  |
| c320 | d20_sdpred_varies_within_group | ord | poisson | refuse | refuse |  |  |  |  | J: ArgumentError: sd(g): predictor `z` varies within a level of `g` — sd() predictors must be constant within eac / R: `sd(g)` formulas are group-level random-effect scale models. ✖ Predictor z varies within g level "g01". ℹ Use  |
| c321 | d20_sdpred_varies_within_group | ord | nb2 | refuse | refuse |  |  |  |  | J: ArgumentError: sd(g): predictor `z` varies within a level of `g` — sd() predictors must be constant within eac / R: `sd(g)` formulas are group-level random-effect scale models. ✖ Predictor z varies within g level "g01". ℹ Use  |
| c322 | d20_sdpred_varies_within_group | ord | gamma | refuse | refuse |  |  |  |  | J: ArgumentError: sd(g): predictor `z` varies within a level of `g` — sd() predictors must be constant within eac / R: `sd(g)` formulas are group-level random-effect scale models. ✖ Predictor z varies within g level "g01". ℹ Use  |
| c323 | d20_sdpred_varies_within_group | ord | binomial | refuse | refuse |  |  |  |  | J: ArgumentError: sd(g): predictor `z` varies within a level of `g` — sd() predictors must be constant within eac / R: `sd(g)` formulas are group-level random-effect scale models. ✖ Predictor z varies within g level "g01". ℹ Use  |
| c324 | d20_sdpred_varies_within_group | ordq2 | gaussian | refuse | refuse |  |  |  |  | J: ArgumentError: sd(g): predictor `z0` varies within a level of `g` — sd() predictors must be constant within ea / R: `sd(g, coef = "(Intercept)")` formulas are group-level random-effect scale models. ✖ Predictor z0 varies withi |
| c325 | d20_sdpred_varies_within_group | ordq2 | poisson | refuse | refuse |  |  |  |  | J: ArgumentError: sd(g): predictor `z0` varies within a level of `g` — sd() predictors must be constant within ea / R: `sd(g, coef = "(Intercept)")` formulas are group-level random-effect scale models. ✖ Predictor z0 varies withi |
| c326 | d20_sdpred_varies_within_group | ordq2 | nb2 | refuse | refuse |  |  |  |  | J: ArgumentError: sd(g): predictor `z0` varies within a level of `g` — sd() predictors must be constant within ea / R: `sd(g, coef = "(Intercept)")` formulas are group-level random-effect scale models. ✖ Predictor z0 varies withi |
| c327 | d20_sdpred_varies_within_group | ordq2 | gamma | refuse | refuse |  |  |  |  | J: ArgumentError: Gamma random-effect SD regression requires exactly one SD target. / R: Only independent {.fn Gamma} `mu` random intercepts and slopes are implemented in this slice. ✖ Unsupported ra |
| c328 | d20_sdpred_varies_within_group | ordq2 | binomial | refuse | refuse |  |  |  |  | J: ArgumentError: sd(g): predictor `z0` varies within a level of `g` — sd() predictors must be constant within ea / R: `sd(g, coef = "(Intercept)")` formulas are group-level random-effect scale models. ✖ Predictor z0 varies withi |
| c329 | d20_sdpred_varies_within_group | animal | gaussian | refuse | refuse |  |  |  |  | J: ArgumentError: sd(g): predictor `z` varies within a level of `g` — sd() predictors must be constant within eac / R: `sd_animal(g)` formulas are group-level random-effect scale models. ✖ Predictor z varies within g level "g01". |
| c330 | d20_sdpred_varies_within_group | animal | poisson | refuse | refuse |  |  |  |  | J: ArgumentError: sd(g): predictor `z` varies within a level of `g` — sd() predictors must be constant within eac / R: `sd_animal(g)` formulas are group-level random-effect scale models. ✖ Predictor z varies within g level "g01". |
| c331 | d20_sdpred_varies_within_group | phylo | gaussian | refuse | refuse |  |  |  |  | J: ArgumentError: sd(g): predictor `z` varies within a level of `g` — sd() predictors must be constant within eac / R: `sd_phylo(g)` formulas are group-level random-effect scale models. ✖ Predictor z varies within g level "g01".  |
| c332 | d20_sdpred_varies_within_group | phylo | poisson | refuse | refuse |  |  |  |  | J: ArgumentError: sd(g): predictor `z` varies within a level of `g` — sd() predictors must be constant within eac / R: `sd_phylo(g)` formulas are group-level random-effect scale models. ✖ Predictor z varies within g level "g01".  |
| c333 | d20_sdpred_varies_within_group | spatial | gaussian | refuse | refuse |  |  |  |  | J: ArgumentError: sd(g): predictor `z` varies within a level of `g` — sd() predictors must be constant within eac / R: `sd_spatial(g)` formulas are group-level random-effect scale models. ✖ Predictor z varies within g level "g01" |
| c334 | d20_sdpred_varies_within_group | spatial | poisson | refuse | refuse |  |  |  |  | J: ArgumentError: Poisson SD regression currently targets one ordinary mean random-effect coefficient. / R: `sd_spatial(g)` formulas are group-level random-effect scale models. ✖ Predictor z varies within g level "g01" |
| c335 | d21_A_unsorted_bare_matrix_positional | animal | gaussian | fit | fit | -169.962 | -177.701 | -7.73884 | LL-DISAGREE(R higher) |  |
| c336 | d21_A_unsorted_bare_matrix_positional | animal | poisson | fit | fit | -253.866 | -256.86 | -2.99426 | LL-DISAGREE(R higher) |  |
| c337 | d07c_tree_not_ultrametric | phylo | gaussian | refuse | refuse |  |  |  |  | J: ArgumentError: branch length for edge 27 -> 26 must be finite and > 0 (got 0.0) / R: `tree` must be ultrametric. ✖ Root-to-tip distances differ by 0.2815052444571, above the tolerance of   1.4901 |
| c338 | d07c_tree_not_ultrametric | phylo | poisson | refuse | refuse |  |  |  |  | J: ArgumentError: branch length for edge 27 -> 26 must be finite and > 0 (got 0.0) / R: `tree` must be ultrametric. ✖ Root-to-tip distances differ by 0.2815052444571, above the tolerance of   1.4901 |
| c339 | d07d_tree_not_ultrametric_positive | phylo | gaussian | refuse | fit |  | -143.421 |  | J-FITS-WHERE-R-REFUSES | `tree` must be ultrametric. ✖ Root-to-tip distances differ by 0.700000000336, above the tolerance of   4.02331352257133e-08 for this tree. ℹ That tolerance is 1.49011611938477e-08 scaled by the tree height   (2.700000000156), so it is relat |
| c340 | d07d_tree_not_ultrametric_positive | phylo | poisson | refuse | fit |  | -277.31 |  | J-FITS-WHERE-R-REFUSES | `tree` must be ultrametric. ✖ Root-to-tip distances differ by 0.700000000336, above the tolerance of   4.02331352257133e-08 for this tree. ℹ That tolerance is 1.49011611938477e-08 scaled by the tree height   (2.700000000156), so it is relat |
