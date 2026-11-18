# Configured numerical evidence

SUMMARY.json and independent-verification.log describe the selected 36 checks: twelve native R fits under the recorded multiple-start policy, twelve native Julia fits and twelve bridge fits. Raw selected outputs are grouped by route. default-r-ri10-failed.json retains the inferior single-start R result.

The warnings-and-runtime directory contains original route logs for all twelve fixtures, including the separate continuation after the original driver stopped at ri_10. Its native Julia and bridge logs correspond to the accepted results, and retain singular-curvature and boundary warnings. Its R native logs describe the original single-start attempts, including the failed ri_10 optimization. Configured R logs, adapter checksum and start/end timestamps are separately in configured-r-runtime/. Do not interpret a missing warning field in JSON as evidence that no runtime warning occurred.

Each native engine has pointwise value checks on twelve fixtures and derivative checks at nine positive-group-SD points. The remaining three exact-zero points have value checks through a separate fixed-only model. Six fitted oracle optima lie on the group-variance boundary; these are a different count. No log-SD derivative at exact zero or arbitrary-point bridge Hessian is claimed.

Four bridge cases check retained raw-factor refusal before using an exactly matched numeric indicator design. The grid did not request the additional selector-mismatch control. Separate live focused tests cover those controls. No interval calibration, full posterior inference or global optimization guarantee follows from these numerical checks.
