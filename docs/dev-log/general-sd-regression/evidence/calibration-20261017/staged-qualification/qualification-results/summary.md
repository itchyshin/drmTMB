# Native Bernoulli SD-regression calibration summary

Artifact hashes and exact result/supervisor/manifest identities passed. Campaign complete: FALSE; staged look-1 decision: incomplete; overall qualification: FALSE; prepared mode: qualification (master seed 2026101704). The two-look intervals use 97.5% confidence. Coverage and false-positive intervals use the planned denominator; invalid intervals are noncoverage. Conditional false-positive rate uses valid null intervals only. Bias intervals show finite-fit denominators. Qualification flags can be true only for a complete production look-1 campaign whose staged decision is accept. A staged fail is operational nonqualification, not proof that the method is invalid. Look two is frozen but not authorized or summarized by this first-look adapter.

    a planned attempted_process supervisor_started supervisor_completed
 -0.5       1                 1                  1                    1
  0.0       1                 1                  1                    1
  0.5       1                 1                  1                    1
 worker_errors launch_errors timeouts interrupted nonstarted fit_results
             0             0        0           0          0           1
             0             0        0           0          0           1
             0             0        0           0          0           1
 healthy_fits valid_intervals coverage_all_success coverage_all_n
            1               1                    1              1
            1               1                    1              1
            1               1                    1              1
 coverage_all_lo coverage_all_hi coverage_attempted_success
          0.0125               1                          1
          0.0125               1                          1
          0.0125               1                          1
 coverage_attempted_n coverage_attempted_lo coverage_attempted_hi
                    1                0.0125                     1
                    1                0.0125                     1
                    1                0.0125                     1
 coverage_conditional coverage_conditional_n valid_fraction
                    1                      1              1
                    1                      1              1
                    1                      1              1
 valid_fraction_exact_lo valid_fraction_exact_hi logsd_bias_mean
                  0.0125                       1       0.1093051
                  0.0125                       1      -0.1575956
                  0.0125                       1       0.0556786
 logsd_bias_mc_lo logsd_bias_mc_hi logsd_bias_n ratio_relative_bias_mean
               NA               NA            1               0.11550259
               NA               NA            1              -0.14580481
               NA               NA            1               0.05725783
 ratio_relative_bias_mc_lo ratio_relative_bias_mc_hi ratio_bias_n
                        NA                        NA            1
                        NA                        NA            1
                        NA                        NA            1
 false_positive_success false_positive_n false_positive_exact_lo
                     NA               NA                      NA
                      0                1                       0
                     NA               NA                      NA
 false_positive_exact_hi false_positive_conditional_success
                      NA                                 NA
                  0.9875                                  0
                      NA                                 NA
 false_positive_conditional_n false_positive_conditional_rate
                           NA                              NA
                            1                               0
                           NA                              NA
 false_positive_conditional_exact_lo false_positive_conditional_exact_hi
                                  NA                                  NA
                                   0                              0.9875
                                  NA                                  NA
 campaign_complete   design_mode staged_decision qualification_eligible
             FALSE qualification      incomplete                  FALSE
             FALSE qualification      incomplete                  FALSE
             FALSE qualification      incomplete                  FALSE
 qualification_denominator_complete coverage_threshold false_positive_threshold
                              FALSE              FALSE                       NA
                              FALSE              FALSE                    FALSE
                              FALSE              FALSE                       NA
 logsd_bias_threshold ratio_bias_threshold valid_fraction_threshold
                FALSE                FALSE                    FALSE
                FALSE                FALSE                    FALSE
                FALSE                FALSE                    FALSE
 overall_qualified
             FALSE
             FALSE
             FALSE

No acceptance claim is made; inspect source hashes, worker logs, warnings, and retained fit diagnostics.
