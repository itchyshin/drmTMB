| cell | seed | R P1-P7 | R P8 z mean/var | Julia P1-P7 | Julia P8 z mean/var (b = 0) | P9 shared-theta | P10 own fits | P11 bridge |
|---|---|---|---|---|---|---|---|---|
| gaussian_fixed | 20261016600 | PPPPPPP | 0.7/0.3 | PPPPP-P | -0.2/1.4 | P (link 4.0e-15) | P (link 1.3e-12) | PASS (5.6e-17) |
| gaussian_ri | 20261016601 | PPPPPPP | -0.4/-0.6; re.form=NULL 0.1/-0.1 | PPPPP-P | -0.1/1.0 (vs marginal var z -71.2) | P (link 4.4e-15) | P (link 2.4e-11) | refused |
| student_fixed | 20261016602 | PPPPPPP | -1.2/-0.1 | FFFPF-P | -1.1/-1.8 | F (link 4.0e-15) | P (link 6.8e-11) | PASS (0.0e+00) |
| student_ri | 20261016603 | PPPPPPP | -0.6/-0.7; re.form=NULL -1.0/1.0 | FFFPF-P | -1.7/-0.4 (vs marginal var z -51.5) | F (link 3.1e-15) | P (link 7.2e-11) | refused |
| skew_normal_fixed | 20261016604 | PPPPPPP | 0.0/-2.2 | FFFPF-F | -0.3/0.1 | F (link 4.9e-15) | P (link 1.1e-10) | PASS (5.6e-17) |
| skew_normal_ri | 20261016605 | PPPPPPP | 0.9/-0.8; re.form=NULL 0.1/0.8 | refused | NA | - | - | refused |
| lognormal_fixed | 20261016606 | PPPPPPP | 0.2/-2.9 | FPFPF-P | 1.3/-0.8 | P (link 4.7e-15) | P (link 3.0e-11) | PASS (2.2e-16) |
| lognormal_ri | 20261016607 | PPPPPPP | -0.0/-0.4; re.form=NULL 1.6/0.8 | FPFPF-P | 2.0/1.2 (vs marginal var z -38.8) | P (link 4.0e-15) | P (link 1.6e-12) | refused |
| gamma_fixed | 20261016608 | PPPPPPP | -0.9/0.3 | PPFPF-P | 0.2/-0.9 | P (link 8.4e-15) | P (link 2.5e-12) | PASS (2.8e-17) |
| gamma_ri | 20261016609 | PPPPPPP | 0.1/-0.1; re.form=NULL -1.2/-0.1 | PPFPF-P | -0.2/-0.1 (vs marginal var z -34.8) | P (link 6.4e-15) | F (link 7.7e-05) | refused |
| beta_fixed | 20261016610 | PPPPPPP | 0.8/0.0 | PPFPF-P | 1.0/1.2 | P (link 4.2e-15) | P (link 2.4e-11) | PASS (0.0e+00) |
| beta_ri | 20261016611 | PPPPPPP | -0.6/-0.3; re.form=NULL 1.1/0.9 | PPFPF-P | -0.5/-1.2 (vs marginal var z -238.1) | P (link 4.2e-15) | F (link 4.0e-04) | refused |
| zero_one_beta_fixed | 20261016612 | PPPPPPP | -1.5/1.2 | FFFPF-F | -1.4/1.5 | F (link 4.0e-15) | P (link 2.2e-12) | PASS (0.0e+00) |
| zero_one_beta_ri | 20261016613 | PPPPPPP | -0.5/0.2; re.form=NULL 0.1/-0.6 | FFFPF-F | 0.7/0.7 (vs marginal var z -21.7) | F (link 6.0e-15) | F (link 2.7e-04) | refused |
| beta_binomial_fixed | 20261016614 | PPPPPPP | -0.5/0.2 | PPFPF-P | -0.8/1.5 | P (link 2.0e-15) | P (link 3.5e-11) | PASS (0.0e+00) |
| beta_binomial_ri | 20261016615 | PPPPPPP | 0.2/1.8; re.form=NULL 1.8/-0.8 | PPFPF-P | 0.1/0.6 (vs marginal var z -73.3) | P (link 4.0e-15) | F (link 3.3e-04) | refused |
| binomial_fixed | 20261016616 | PPPPPPP | 0.9/-0.5 | PPFPF-P | 0.8/0.4 | P (link 3.3e-16) | P (link 2.2e-13) | PASS (0.0e+00) |
| binomial_ri | 20261016617 | PPPPPPP | 0.8/0.7; re.form=NULL -0.2/0.6 | PPFPF-P | -1.7/0.4 (vs marginal var z -148.5) | P (link 2.0e-15) | P (link 5.0e-11) | refused |
| poisson_fixed | 20261016618 | PPPPPPP | 0.5/-0.2 | PPFPF-P | 1.2/0.0 | P (link 3.1e-15) | P (link 8.0e-13) | PASS (0.0e+00) |
| poisson_ri | 20261016619 | PPPPPPP | 0.1/-1.3; re.form=NULL 0.7/0.4 | PPFPF-P | -0.7/-1.0 (vs marginal var z -223.4) | P (link 4.0e-15) | F (link 1.4e-08) | refused |
| nbinom2_fixed | 20261016620 | PPPPPPP | -2.0/-2.1 | PPFPF-P | 1.0/0.7 | P (link 2.9e-15) | P (link 1.1e-10) | PASS (2.2e-16) |
| nbinom2_ri | 20261016621 | PPPPPPP | -0.1/-0.9; re.form=NULL 1.3/0.6 | PPFPF-P | 1.6/1.2 (vs marginal var z -22.1) | P (link 5.3e-15) | F (link 1.2e-03) | refused |
| truncated_nbinom2_fixed | 20261016622 | PPPPPPP | 0.6/1.0 | FPFPF-P | 0.4/1.2 | P (link 4.9e-15) | P (link 1.2e-10) | PASS (5.6e-17) |
| truncated_nbinom2_ri | 20261016623 | PPPPPPP | 0.9/-1.5; re.form=NULL -0.1/0.1 | refused | NA | - | - | refused |
| tweedie_fixed | 20261016624 | PPPPP-P | 2.7/2.2 | PPFPF-P | -0.1/-1.1 | P (link 8.9e-15) | P (link 2.4e-11) | PASS (2.8e-17) |
| tweedie_ri | 20261016625 | PPPPP-P | -0.2/-0.5; re.form=NULL -1.0/-0.6 | PPFPF-P | 0.4/-0.3 (vs marginal var z -257.9) | P (link 7.1e-15) | F (link 1.0e-03) | refused |
| cumulative_logit_fixed | 20261016626 | PPPPPPP | 0.2/1.1 | FFEPE-F | -0.3/-0.4 | F | E | admitted; P11 NA (native predict errors) |
| cumulative_logit_ri | 20261016627 | PPPPPPP | 0.3/-0.6; re.form=NULL 0.3/-0.1 | FFEPE-F | 0.1/1.0 (vs marginal var z -43.6) | F | E | refused |

P = pass, F = fail, E = error, - = not applicable or not run. The seven letters are P1..P7 in order.
P8 cells give z for the global mean and the batch-means variance (pass |z| < 3).
P9/P10 give the overall status and the largest link-scale max |diff| over dpars on nd_main.
A P9 F with link ~1e-15 is a response-scale (inverse-link) failure.
Julia P6 is NA everywhere: there is no quantile API. R P6 for Tweedie: see the verifier note in the receipt.
