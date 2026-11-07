# ri_10: inferior R boundary solution

Independent mathematical review, Noether, 2026-11-06. The returned R point was supplied by the coordinator from `/home/snakagaw/hsq_work/ri-priors-final-r-validation-20261106/grid/r-native/ri_10.json`; this review did not retrieve that remote JSON. It evaluated the supplied numbers independently against the unchanged frozen fixture. No engine source, fixture, threshold or reference was changed. No full suite was rerun.

## Finding

The supplied R result approaches a genuine constrained local minimum at zero group variance. It is inferior to the frozen positive-variance reference and remains a validation failure. The calculation supports an optimizer basin/search problem; it supplies no evidence of a likelihood or prior-formula mismatch at the returned point. Local optimality does not establish the required best-objective agreement.

The supplied natural-coordinate point is

`beta = [0.7992020652099601, 1.0266594110070215]`

`gamma = [-0.6434776321230752, -2.3309838259182207]`

`tau = 4.370565582893776e-6`.

The standalone dense evaluator gives NLL `7.2163047579214785`, agreeing with the supplied R objective `7.216304757921474` to floating-point precision. With `v=tau²`, its variance-direction score is `dL/dv = +15.179223902573444`. The log-SD gradient is `dL/dlog(tau) = 2 v dL/dv = 5.799023193132556e-10`. Thus a small log-SD gradient is expected while approaching this boundary branch; it does not distinguish that branch from a better separated interior basin.

At the same beta/gamma with tau set to exact zero, the objective is `7.2163047576315265`, the variance score is `+15.179223915352466`, and the largest absolute beta/gamma score is `1.2301271112846734e-13`. The positive variance score satisfies the one-sided condition for minimizing over `v >= 0`: a sufficiently small increase from zero raises the objective. The beta/gamma Hessian eigenvalues are

`[0.7832199947365313, 17.607361503247223, 19.661884284805463, 50.15367801295232]`.

The free-coordinate Hessian is positive definite. Together with the strictly positive variance score and negligible free scores, this establishes a strict constrained local minimum of the zero-variance branch. The profiled variance curvature at that point is negative, approximately `-2353.44558`; it does not invalidate the boundary minimum because the positive first-order variance term controls sufficiently small feasible steps. The likelihood surface can bend down farther away.

## Independent exact-boundary optimization

Holding variance at exact zero, beta was profiled using the exact conditional penalized solution. A separate SciPy BFGS calculation optimized gamma from three starts `[-0.5,0]`, `[0,0]` and `[0.5,0]`. All three reported successful termination after 10, 11 and 9 iterations and found the same objective within floating-point precision: `7.216304757631527`, `7.2163047576315265` and `7.216304757631527`. Their largest free-score magnitudes were `1.82e-10`, `1.37e-11` and `4.94e-10`. This confirms the boundary solution independently of the R optimizer.

The frozen oracle had already retained this branch as three eligible boundary attempts before candidate results. Its selected interior solution instead has NLL `3.7499093360931792` and tau `0.8708035636558249`. The boundary objective is higher by about `3.46639542154`. The selected reference's beta/gamma are also different: `[-0.3588074413033878, 0.26373177990104024]` and `[-1.7765738748767435, 2.442881359057074]`.

ri_10 therefore remains an interior-reference case. Its R output cannot be accepted under the boundary-limit qualification used for fixtures whose best frozen references are at zero. Preserve the failed R attempt, optimizer status and diagnostics; investigate starts and basin search without changing the oracle or tolerances. At the returned positive tau, the candidate is not an exact stationary point in variance coordinates, but its objective differs from this inferior boundary endpoint by only about `2.90e-10`. Calling it a numerical approach to an inferior local boundary solution is supported; calling it agreement with the best frozen solution is not.

## Evidence and limits

Standalone work was estimated at under five seconds per calculation, used one BLAS thread locally, and called no package engine. The exact-boundary three-start calculation took 0.881 seconds. The first dense score/Hessian check and boundary optimization completed in a single short process; no simulation campaign was launched.

Fixture SHA-256: `c2bfa7c8e4c4300e72595548593999f0f14ed7a08e28b74d9f9bc31e7a6180b3`. Frozen fitted-reference SHA-256: `85db00122f23a2d9fc408cfc11ec85d4a1ca62d1f822dd3f544c36249603833f`. The earlier source-review pass concerned objective wiring and admission; this numerical basin failure limits the present validation result without contradicting those source identities. Outcomes for cases 11/12 or a revised R search were not reviewed here.

Naturalness self-review: technical diagnosis, entire draft, perceived AI-like style 2/10 with moderate confidence. Located examples “strict constrained local minimum” and “higher by about 3.46639542154” give the mathematical classification and its consequence directly. Science gate: pass for the constrained first/second-order argument and dense calculations. Facts gate: pass for independently computed values and frozen-file hashes; the remote JSON and subsequent runs remain outside coverage. References gate: local frozen artifacts and the coordinator-supplied point only. Exact-draft prose-validator assessment: NOTASSESSED. Mechanical slop check is recorded separately in the tool receipt.
