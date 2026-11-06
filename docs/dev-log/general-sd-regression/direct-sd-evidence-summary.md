# Direct-SD implementation evidence reconciliation

Frozen candidate rows: 21246. Evidence receipt records: 812. Distinct candidate rows with at least one hash-verified receipt: 369. Candidate rows without linked receipts: 20877.

This is an evidence-only join. A receipt does not establish general support, identifiability, admission, or calibrated interval coverage; no candidate row is promoted by this report.

Evidence counts by exact row dimensions (rows with receipts / candidate rows):

## engine

| Value | Receipted rows | Candidate rows |
|---|---:|---:|
| Julia | 108 | 10695 |
| native | 261 | 10551 |

## family_route

| Value | Receipted rows | Candidate rows |
|---|---:|---:|
| beta | 13 | 324 |
| beta_binomial | 4 | 324 |
| binomial | 182 | 480 |
| biv_gaussian | 0 | 3888 |
| biv_lognormal | 0 | 3888 |
| biv_student | 0 | 6028 |
| cumulative_logit | 4 | 160 |
| gamma | 36 | 324 |
| gaussian | 33 | 324 |
| hurdle_nbinom2 | 4 | 592 |
| lognormal | 5 | 324 |
| nbinom2 | 39 | 324 |
| poisson | 40 | 160 |
| skew_normal | 0 | 592 |
| student | 0 | 592 |
| truncated_nbinom2 | 1 | 324 |
| tweedie | 2 | 592 |
| zero_one_beta | 2 | 1076 |
| zi_nbinom2 | 0 | 592 |
| zi_poisson | 4 | 338 |

## mechanism_id

| Value | Receipted rows | Candidate rows |
|---|---:|---:|
| animal_correlated_block | 34 | 672 |
| animal_intercept | 24 | 336 |
| animal_labelled_block | 0 | 4584 |
| animal_numeric_slope | 25 | 336 |
| iid_additive_terms | 7 | 224 |
| iid_correlated_block | 30 | 784 |
| iid_intercept | 26 | 112 |
| iid_labelled_cross_parameter | 0 | 1070 |
| iid_numeric_slope | 26 | 112 |
| paired_phylo_temporal_ou | 0 | 112 |
| phylo_correlated_block | 8 | 224 |
| phylo_interaction_intercept | 8 | 112 |
| phylo_interaction_numeric_slope | 6 | 112 |
| phylo_intercept | 8 | 336 |
| phylo_labelled_block | 0 | 1528 |
| phylo_numeric_slope | 7 | 112 |
| relmat_correlated_block | 14 | 448 |
| relmat_intercept | 20 | 224 |
| relmat_labelled_block | 0 | 3056 |
| relmat_numeric_slope | 12 | 224 |
| simultaneous_iid_structured | 40 | 672 |
| simultaneous_structured_structured | 43 | 1680 |
| spatial_coordinate_intercept | 12 | 112 |
| spatial_coordinate_labelled_block | 0 | 3056 |
| spatial_coordinate_slope | 9 | 224 |
| spatial_correlated_block | 4 | 224 |
| spatial_mesh_intercept | 3 | 112 |
| spatial_mesh_slope | 3 | 112 |
| temporal_ar1 | 0 | 112 |
| temporal_homtoep | 0 | 112 |
| temporal_ou | 0 | 112 |

## provider

| Value | Receipted rows | Candidate rows |
|---|---:|---:|
| animal | 83 | 5928 |
| animal:A_covariance+relmat:K_covariance | 3 | 112 |
| animal:A_covariance+relmat:Q_precision | 3 | 112 |
| animal:A_covariance+spatial:coordinates | 3 | 112 |
| animal:Ainv_precision+relmat:K_covariance | 3 | 112 |
| animal:Ainv_precision+relmat:Q_precision | 2 | 112 |
| animal:Ainv_precision+spatial:coordinates | 3 | 112 |
| animal:pedigree+relmat:K_covariance | 3 | 112 |
| animal:pedigree+relmat:Q_precision | 2 | 112 |
| animal:pedigree+spatial:coordinates | 3 | 112 |
| iid | 89 | 2302 |
| iid:group_factor+animal:A_covariance | 9 | 112 |
| iid:group_factor+animal:Ainv_precision | 7 | 112 |
| iid:group_factor+animal:pedigree | 4 | 112 |
| iid:group_factor+phylo:tree | 9 | 112 |
| iid:group_factor+relmat:K_covariance | 6 | 112 |
| iid:group_factor+relmat:Q_precision | 5 | 112 |
| phylo | 23 | 2200 |
| phylo plus temporal | 0 | 112 |
| phylo:tree+animal:A_covariance | 3 | 112 |
| phylo:tree+animal:Ainv_precision | 3 | 112 |
| phylo:tree+animal:pedigree | 3 | 112 |
| phylo:tree+relmat:K_covariance | 3 | 112 |
| phylo:tree+relmat:Q_precision | 3 | 112 |
| phylo:tree+spatial:coordinates | 3 | 112 |
| phylo_interaction | 14 | 224 |
| relmat | 46 | 3952 |
| spatial | 31 | 3840 |
| temporal | 0 | 336 |

## effect_type

| Value | Receipted rows | Candidate rows |
|---|---:|---:|
| Gaussian process covariance | 0 | 112 |
| additive independent latent fields | 83 | 2352 |
| additive stable phylo field and OU process | 0 | 112 |
| covariance across distributional endpoints | 0 | 1070 |
| cross-endpoint structured covariance | 0 | 12224 |
| independent random slope | 26 | 112 |
| intercept and numeric slope(s) | 30 | 784 |
| multiple independent intercept/slope fields | 7 | 224 |
| pair-level structured intercept | 8 | 112 |
| pair-level structured numeric slope | 6 | 112 |
| random intercept | 26 | 112 |
| stationary Gaussian process intercept | 0 | 224 |
| structured intercept plus one independent numeric slope | 53 | 896 |
| structured mesh field | 3 | 112 |
| structured mesh random slope | 3 | 112 |
| structured random intercept | 64 | 1008 |
| within-endpoint correlated intercept and one numeric slope | 60 | 1568 |

Rows with multiple receipts are counted once. Candidate rows remain obligations until separately reviewed against the implementation contract and the complete required scope.
