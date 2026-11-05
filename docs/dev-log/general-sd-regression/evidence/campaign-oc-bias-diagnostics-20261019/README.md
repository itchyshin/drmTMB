# Current staged-rule synthetic operating-characteristic run

This run checks the revised staged decision rule under the fixed synthetic scenarios in `tools/general-sd-regression/campaign-oc.R`. The bias intervals are descriptive only. This is rule-level evidence and does not estimate fitted Bernoulli model performance or calibrate profile intervals.

The command ran 1,000 independent campaigns per scenario with seed `20261022`. It completed locally on Darwin arm64 in 157.18 seconds elapsed, using R 4.6.0, with `OPENBLAS_NUM_THREADS=1` and `OMP_NUM_THREADS=1`. The complete console output and timing are retained alongside this receipt.

The nominal scenario ended with 855 acceptances, 145 inconclusive decisions, and no failures. The `log_bias_boundary` and `relative_bias_boundary` scenarios ended with 852 and 847 acceptances. Those results reflect nominal interval rates; bias summaries no longer affect acceptance. The `log_sd_bias` scenario ended in failure for every campaign because its interval behavior falls outside the predeclared criteria. These counts describe only the chosen scenario inputs. They do not estimate fitted-estimator behavior.

Source hashes at run time:

- `campaign-oc.R`: `b68b4e1533ddc20b15ae6c488f27ce49fd5cffe458a5e939fe1d02908f80c35a`
- `staged-decision.R`: `8b518df817b070d4c5edb8aab2b586e60717bc5995523183c07166c369af4e38`
- `test-campaign-oc.R`: `974d713a65e4cd296712c013b26893f8e4512b463d926f338d46e2f32672fcd6`

The source checkout was the dirty goal worktree at `codex/general-sd-regression`; these hashes bind the run to the exact analyzer and campaign simulator source. The R process simulated campaigns locally; the recorded outcomes come from the synthetic generator.
