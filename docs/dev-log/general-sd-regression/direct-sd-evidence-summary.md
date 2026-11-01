# Direct-SD implementation evidence reconciliation

Frozen candidate rows: 20350. Evidence receipt records: 303. Distinct candidate rows with at least one hash-verified receipt: 262. Candidate rows without linked receipts: 20088.

This is an evidence-only join. A receipt does not establish general support, identifiability, admission, or calibrated interval coverage; no candidate row is promoted by this report.

Evidence counts by exact row dimensions (rows with receipts / candidate rows):

## engine

| Value | Receipted rows | Candidate rows |
|---|---:|---:|
| Julia | 93 | 10247 |
| native | 169 | 10103 |

## family_route

| Value | Receipted rows | Candidate rows |
|---|---:|---:|
| beta | 4 | 292 |
| beta_binomial | 4 | 292 |
| binomial | 168 | 432 |
| biv_gaussian | 0 | 3808 |
| biv_lognormal | 0 | 3808 |
| biv_student | 0 | 5932 |
| cumulative_logit | 4 | 144 |
| gamma | 14 | 292 |
| gaussian | 11 | 292 |
| hurdle_nbinom2 | 4 | 544 |
| lognormal | 5 | 292 |
| nbinom2 | 16 | 292 |
| poisson | 23 | 144 |
| skew_normal | 0 | 544 |
| student | 0 | 544 |
| truncated_nbinom2 | 1 | 292 |
| tweedie | 2 | 544 |
| zero_one_beta | 2 | 1012 |
| zi_nbinom2 | 0 | 544 |
| zi_poisson | 4 | 306 |

## mechanism_id

| Value | Receipted rows | Candidate rows |
|---|---:|---:|
| animal_correlated_block | 22 | 672 |
| animal_intercept | 18 | 336 |
| animal_labelled_block | 0 | 4584 |
| animal_numeric_slope | 17 | 336 |
| iid_additive_terms | 6 | 224 |
| iid_correlated_block | 27 | 784 |
| iid_intercept | 23 | 112 |
| iid_labelled_cross_parameter | 0 | 1070 |
| iid_numeric_slope | 25 | 112 |
| paired_phylo_temporal_ou | 0 | 112 |
| phylo_interaction_intercept | 6 | 112 |
| phylo_interaction_numeric_slope | 4 | 112 |
| phylo_intercept | 5 | 336 |
| phylo_labelled_block | 0 | 1528 |
| phylo_numeric_slope | 5 | 112 |
| relmat_intercept | 8 | 224 |
| relmat_labelled_block | 0 | 3056 |
| relmat_numeric_slope | 4 | 224 |
| simultaneous_iid_structured | 33 | 672 |
| simultaneous_structured_structured | 43 | 1680 |
| spatial_coordinate_intercept | 6 | 112 |
| spatial_coordinate_labelled_block | 0 | 3056 |
| spatial_coordinate_slope | 4 | 224 |
| spatial_mesh_intercept | 3 | 112 |
| spatial_mesh_slope | 3 | 112 |
| temporal_ar1 | 0 | 112 |
| temporal_homtoep | 0 | 112 |
| temporal_ou | 0 | 112 |

## provider

| Value | Receipted rows | Candidate rows |
|---|---:|---:|
| animal | 57 | 5928 |
| animal:A_covariance+relmat:K_covariance | 3 | 112 |
| animal:A_covariance+relmat:Q_precision | 3 | 112 |
| animal:A_covariance+spatial:coordinates | 3 | 112 |
| animal:Ainv_precision+relmat:K_covariance | 3 | 112 |
| animal:Ainv_precision+relmat:Q_precision | 2 | 112 |
| animal:Ainv_precision+spatial:coordinates | 3 | 112 |
| animal:pedigree+relmat:K_covariance | 3 | 112 |
| animal:pedigree+relmat:Q_precision | 2 | 112 |
| animal:pedigree+spatial:coordinates | 3 | 112 |
| iid | 81 | 2302 |
| iid:group_factor+animal:A_covariance | 6 | 112 |
| iid:group_factor+animal:Ainv_precision | 6 | 112 |
| iid:group_factor+animal:pedigree | 4 | 112 |
| iid:group_factor+phylo:tree | 8 | 112 |
| iid:group_factor+relmat:K_covariance | 5 | 112 |
| iid:group_factor+relmat:Q_precision | 4 | 112 |
| phylo | 10 | 1976 |
| phylo plus temporal | 0 | 112 |
| phylo:tree+animal:A_covariance | 3 | 112 |
| phylo:tree+animal:Ainv_precision | 3 | 112 |
| phylo:tree+animal:pedigree | 3 | 112 |
| phylo:tree+relmat:K_covariance | 3 | 112 |
| phylo:tree+relmat:Q_precision | 3 | 112 |
| phylo:tree+spatial:coordinates | 3 | 112 |
| phylo_interaction | 10 | 224 |
| relmat | 12 | 3504 |
| spatial | 16 | 3616 |
| temporal | 0 | 336 |

## effect_type

| Value | Receipted rows | Candidate rows |
|---|---:|---:|
| Gaussian process covariance | 0 | 112 |
| additive independent latent fields | 76 | 2352 |
| additive stable phylo field and OU process | 0 | 112 |
| covariance across distributional endpoints | 0 | 1070 |
| cross-endpoint structured covariance | 0 | 12224 |
| independent random slope | 25 | 112 |
| intercept and numeric slope(s) | 27 | 784 |
| multiple independent intercept/slope fields | 6 | 224 |
| pair-level structured intercept | 6 | 112 |
| pair-level structured numeric slope | 4 | 112 |
| random intercept | 23 | 112 |
| stationary Gaussian process intercept | 0 | 224 |
| structured intercept plus one independent numeric slope | 30 | 896 |
| structured mesh field | 3 | 112 |
| structured mesh random slope | 3 | 112 |
| structured random intercept | 37 | 1008 |
| within-endpoint correlated intercept and one numeric slope | 22 | 672 |

Rows with multiple receipts are counted once. Candidate rows remain obligations until separately reviewed against the implementation contract and the complete required scope.
